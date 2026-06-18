import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import 'api_service.dart';
import 'call_history_service.dart';

/// WhatsApp uslubidagi ovozli qo'ng'iroq xizmati.
/// WebSocket signaling + WebRTC peer connection bilan ishlaydi.
class CallService extends ChangeNotifier {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  WebSocketChannel? _channel;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  String? _currentCallLogId;

  bool _inCall = false;
  bool _isMuted = false;
  bool _isSpeaker = false;
  bool _isConnecting = false;
  bool _isRinging = false;
  bool _wsConnected = false;

  int? _remoteUserId;
  String? _remoteUserName;

  // Qo'ng'iroq vaqti
  DateTime? _callStartTime;
  Timer? _callTimer;
  String _callDuration = '00:00';

  // Auto-reconnect
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  // ICE servers (backenddan olinadi)
  List<Map<String, dynamic>> _iceServers = [
    {"urls": "stun:stun.l.google.com:19302"},
  ];

  // States to export to UI
  bool get inCall => _inCall;
  bool get isMuted => _isMuted;
  bool get isSpeaker => _isSpeaker;
  bool get isConnecting => _isConnecting;
  bool get isRinging => _isRinging;
  bool get wsConnected => _wsConnected;
  String get remoteUserName => _remoteUserName ?? 'Noma\'lum';
  String get callDuration => _callDuration;
  int? get remoteUserId => _remoteUserId;

  // Callbacks for UI
  Function(Map<String, dynamic>)? onIncomingCall;
  Function()? onCallEnded;
  Function()? onCallAnswered;
  Function(String)? onError;

  /// Backenddan ICE server konfiguratsiyasini olish
  Future<void> _fetchIceServers() async {
    try {
      final token = await ApiService().getToken();
      if (token == null) return;

      final dio = Dio(BaseOptions(
        baseUrl: '${AppConfig.apiBaseUrl}/api/v1',
        headers: {'Authorization': 'Bearer $token'},
      ));
      final response = await dio.get('/calls/ice-servers');
      if (response.data != null && response.data['iceServers'] != null) {
        _iceServers = List<Map<String, dynamic>>.from(response.data['iceServers']);
        debugPrint('ICE servers yuklandi: ${_iceServers.length} ta server');
      }
    } catch (e) {
      debugPrint('ICE servers yuklashda xatolik (fallback ishlatiladi): $e');
      // Fallback — faqat Google STUN
    }
  }

  /// WebSocket ga ulanish (signaling uchun)
  Future<void> connectWebSocket() async {
    if (_wsConnected && _channel != null) return;

    final token = await ApiService().getToken();
    if (token == null) {
      debugPrint('WebSocket: Token mavjud emas, ulanish bekor qilindi');
      return;
    }

    // ICE serverlarni olish
    await _fetchIceServers();

    final baseUrl = AppConfig.apiBaseUrl;
    String wsUrl;
    if (baseUrl.startsWith('https')) {
      wsUrl = baseUrl.replaceFirst('https', 'wss');
    } else {
      wsUrl = baseUrl.replaceFirst('http', 'ws');
    }

    final uri = Uri.parse('$wsUrl/api/v1/calls/ws?token=$token');
    debugPrint('WebSocket ulanmoqda: $uri');

    try {
      _channel = WebSocketChannel.connect(uri);
      _wsConnected = true;
      _reconnectAttempts = 0;

      _channel?.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            _handleSignalingMessage(data);
          } catch (e) {
            debugPrint('WebSocket xabar parse xatolik: $e');
          }
        },
        onDone: () {
          debugPrint('WebSocket uzildi');
          _wsConnected = false;
          notifyListeners();
          _scheduleReconnect();
        },
        onError: (error) {
          debugPrint('WebSocket xatolik: $error');
          _wsConnected = false;
          notifyListeners();
          _scheduleReconnect();
        },
      );

      notifyListeners();
      debugPrint('WebSocket muvaffaqiyatli ulandi');
    } catch (e) {
      debugPrint('WebSocket ulanish xatoligi: $e');
      _wsConnected = false;
      _scheduleReconnect();
    }
  }

  /// Avtomatik qayta ulanish
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('WebSocket: Maksimal qayta ulanish urinishlari tugadi');
      return;
    }

    _reconnectTimer?.cancel();
    final delay = Duration(seconds: (2 * (_reconnectAttempts + 1)).clamp(2, 30));
    _reconnectAttempts++;

    debugPrint('WebSocket: ${delay.inSeconds}s dan keyin qayta ulanish (#$_reconnectAttempts)');
    _reconnectTimer = Timer(delay, () {
      connectWebSocket();
    });
  }

  /// Signaling xabarlarini qayta ishlash
  void _handleSignalingMessage(Map<String, dynamic> data) async {
    final type = data['type'];
    final senderId = data['sender_id'];
    final senderName = data['sender_name'];
    final payload = data['data'] ?? {};

    debugPrint('WebSocket signal olindi: $type dan $senderId ($senderName)');

    if (type == 'call_init') {
      if (CallHistoryService().isUserBlocked(senderId)) {
        debugPrint('Bloklangan foydalanuvchidan qo\'ng\'iroq keldi. Rad etiladi.');
        // Rad etish signalini yuboramiz
        final msg = jsonEncode({
          'type': 'reject_call',
          'target_id': senderId,
          'data': {},
        });
        _channel?.sink.add(msg);
        return;
      }

      _currentCallLogId = DateTime.now().millisecondsSinceEpoch.toString();
      CallHistoryService().addCallLog(CallLog(
        id: _currentCallLogId!,
        userId: senderId,
        userName: senderName,
        isIncoming: true,
        timestamp: DateTime.now(),
        duration: '00:00',
        status: 'missed',
      ));

      // Kiruvchi qo'ng'iroq
      _remoteUserId = senderId;
      _remoteUserName = senderName;
      _isRinging = true;
      notifyListeners();

      if (onIncomingCall != null) {
        onIncomingCall!(data);
      }
    } else if (type == 'call_accepted') {
      // Qo'ng'iroq qabul qilindi — offer yaratish
      _isRinging = false;
      _isConnecting = true;
      notifyListeners();
      await processOffer();
    } else if (type == 'offer') {
      await _handleOffer(payload, senderId, senderName);
    } else if (type == 'answer') {
      await _handleAnswer(payload);
      _isConnecting = false;
      _startCallTimer();
      if (_currentCallLogId != null) {
        CallHistoryService().updateCallLog(_currentCallLogId!, status: 'connected');
      }
      notifyListeners();
      if (onCallAnswered != null) onCallAnswered!();
    } else if (type == 'ice_candidate') {
      await _handleIceCandidate(payload);
    } else if (type == 'end_call' || type == 'reject_call') {
      if (_currentCallLogId != null) {
        CallHistoryService().updateCallLog(
          _currentCallLogId!,
          status: type == 'reject_call' ? 'declined' : (_callStartTime != null ? 'connected' : 'missed'),
          duration: _callDuration,
        );
      }
      endCall(sendSignal: false);
    } else if (type == 'target_offline') {
      _isConnecting = false;
      _isRinging = false;
      notifyListeners();
      if (_currentCallLogId != null) {
        CallHistoryService().updateCallLog(_currentCallLogId!, status: 'cancelled');
      }
      endCall(sendSignal: false);
      if (onError != null) {
        onError!('Foydalanuvchi hozir oflayn');
      }
    }
  }

  void sendSignal(String type, Map<String, dynamic> data) {
    if (_remoteUserId == null || _channel == null || !_wsConnected) {
      debugPrint('Signal yuborib bo\'lmadi: ws=$_wsConnected, remote=$_remoteUserId');
      return;
    }
    final msg = jsonEncode({
      'type': type,
      'target_id': _remoteUserId,
      'data': data,
    });
    _channel?.sink.add(msg);
  }

  Future<void> _createPeerConnection() async {
    final Map<String, dynamic> configuration = {
      "iceServers": _iceServers,
      "sdpSemantics": "unified-plan",
    };

    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": false,
      },
      "optional": [],
    };

    _peerConnection =
        await createPeerConnection(configuration, offerSdpConstraints);

    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      sendSignal('ice_candidate', {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex
      });
    };

    _peerConnection?.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint('ICE ulanish holati: $state');
      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected) {
        _isConnecting = false;
        if (!_inCall) {
          _startCallTimer();
        }
        notifyListeners();
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        debugPrint('ICE ulanish uzildi yoki muvaffaqiyatsiz');
        // Qisqa vaqtda qayta ulanishga urinish yoki tugatish
        if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
          endCall(sendSignal: true);
          if (onError != null) {
            onError!('Ulanish muvaffaqiyatsiz');
          }
        }
      }
    };

    _peerConnection?.onAddStream = (MediaStream stream) {
      _remoteStream = stream;
      notifyListeners();
    };

    _peerConnection?.onTrack = (RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        notifyListeners();
      }
    };

    await _getUserMedia();
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });
  }

  Future<void> _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': {
        'echoCancellation': true,
        'noiseSuppression': true,
        'autoGainControl': true,
      },
      'video': false,
    };
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
  }

  /// Chiquvchi qo'ng'iroq boshlash
  Future<void> startCall(int targetId, String targetName) async {
    if (_inCall) {
      debugPrint('Allaqachon qo\'ng\'iroqda');
      return;
    }

    _remoteUserId = targetId;
    _remoteUserName = targetName;
    _inCall = true;
    _isConnecting = true;
    _isRinging = true;

    _currentCallLogId = DateTime.now().millisecondsSinceEpoch.toString();
    CallHistoryService().addCallLog(CallLog(
      id: _currentCallLogId!,
      userId: targetId,
      userName: targetName,
      isIncoming: false,
      timestamp: DateTime.now(),
      duration: '00:00',
      status: 'missed',
    ));

    notifyListeners();

    // Notify target that a call is initiating
    sendSignal('call_init', {});
  }

  /// Offer yaratish va yuborish
  Future<void> processOffer() async {
    await _createPeerConnection();
    RTCSessionDescription offer = await _peerConnection!.createOffer({});
    await _peerConnection!.setLocalDescription(offer);

    sendSignal('offer', {
      'sdp': offer.sdp,
      'type': offer.type,
    });
  }

  /// Kiruvchi qo'ng'iroqni qabul qilish
  Future<void> answerCall(int callerId, String callerName) async {
    _remoteUserId = callerId;
    _remoteUserName = callerName;
    _inCall = true;
    _isRinging = false;
    _isConnecting = true;

    if (_currentCallLogId != null) {
      CallHistoryService().updateCallLog(_currentCallLogId!, status: 'connected');
    }

    notifyListeners();

    // Callerga "qabul qildim" deb signal yuborish
    sendSignal('call_accepted', {});
  }

  /// Offer ni qayta ishlash
  Future<void> _handleOffer(
      Map<String, dynamic> offerData, int senderId, String senderName) async {
    _remoteUserId = senderId;
    _remoteUserName = senderName;

    await _createPeerConnection();
    await _peerConnection?.setRemoteDescription(
      RTCSessionDescription(offerData['sdp'], offerData['type']),
    );

    RTCSessionDescription answer = await _peerConnection!.createAnswer({});
    await _peerConnection?.setLocalDescription(answer);

    sendSignal('answer', {
      'sdp': answer.sdp,
      'type': answer.type,
    });

    _inCall = true;
    _isConnecting = false;
    _startCallTimer();
    notifyListeners();
  }

  Future<void> _handleAnswer(Map<String, dynamic> answerData) async {
    await _peerConnection?.setRemoteDescription(
      RTCSessionDescription(answerData['sdp'], answerData['type']),
    );
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> candidateData) async {
    if (candidateData['candidate'] != null) {
      RTCIceCandidate candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );
      await _peerConnection?.addCandidate(candidate);
    }
  }

  /// Qo'ng'iroq vaqt hisoblagichini boshlash
  void _startCallTimer() {
    _callStartTime = DateTime.now();
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_callStartTime != null) {
        final elapsed = DateTime.now().difference(_callStartTime!);
        final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
        final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
        _callDuration = '$minutes:$seconds';
        notifyListeners();
      }
    });
  }

  /// Qo'ng'iroqni tugatish
  void endCall({bool sendSignal = true}) {
    if (sendSignal && _remoteUserId != null) {
      this.sendSignal('end_call', {});
    }

    if (_currentCallLogId != null) {
      CallHistoryService().updateCallLog(
        _currentCallLogId!,
        duration: _callDuration,
        status: _callStartTime != null ? 'connected' : 'missed',
      );
    }

    _inCall = false;
    _isConnecting = false;
    _isRinging = false;
    _remoteUserId = null;
    _remoteUserName = null;
    _callDuration = '00:00';
    _callStartTime = null;

    _callTimer?.cancel();
    _callTimer = null;

    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;

    _peerConnection?.close();
    _peerConnection = null;

    _isMuted = false;
    _isSpeaker = false;

    notifyListeners();
    if (onCallEnded != null) onCallEnded!();
  }

  /// Rad etish (kiruvchi qo'ng'iroq)
  void rejectCall() {
    sendSignal('reject_call', {});

    if (_currentCallLogId != null) {
      CallHistoryService().updateCallLog(_currentCallLogId!, status: 'declined');
    }

    _isRinging = false;
    _remoteUserId = null;
    _remoteUserName = null;
    notifyListeners();
  }

  void toggleMute() {
    if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
      final audioTrack = _localStream!.getAudioTracks()[0];
      audioTrack.enabled = !audioTrack.enabled;
      _isMuted = !audioTrack.enabled;
      notifyListeners();
    }
  }

  void toggleSpeaker() {
    _isSpeaker = !_isSpeaker;
    if (_localStream != null) {
      Helper.setSpeakerphoneOn(_isSpeaker);
      notifyListeners();
    }
  }

  /// WebSocket ulanishni yopish
  void disconnectWebSocket() {
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    _wsConnected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    endCall();
    disconnectWebSocket();
    super.dispose();
  }
}
