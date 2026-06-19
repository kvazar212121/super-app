import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:dio/dio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/app_config.dart';
import 'api_service.dart';
import 'call_history_service.dart';
import 'ringtone_service.dart';
import 'callkit_service.dart';

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

  // Remote description o'rnatilgunga qadar kelgan ICE candidate'lar
  // shu yerda buferlanadi (signaling race oldini olish uchun).
  final List<RTCIceCandidate> _pendingCandidates = [];
  bool _remoteDescriptionSet = false;

  // Signaling xabarlarini ketma-ket qayta ishlash uchun navbat.
  Future<void> _messageQueue = Future.value();

  // WebSocket ulanmagan vaqtda chiquvchi signallarni saqlab turish uchun navbat
  final List<String> _pendingOutgoingSignals = [];

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
        final List<dynamic> serversList = response.data['iceServers'];
        _iceServers = serversList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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
          Map<String, dynamic> data;
          try {
            data = jsonDecode(message);
          } catch (e) {
            debugPrint('WebSocket xabar parse xatolik: $e');
            return;
          }
          // Xabarlarni ketma-ket (serial) qayta ishlaymiz — offer/answer va
          // ice_candidate xabarlari noto'g'ri tartibda parallel ishlamasligi uchun.
          _messageQueue = _messageQueue.then((_) async {
            try {
              await _handleSignalingMessage(data);
            } catch (e) {
              debugPrint('Signaling xabarni qayta ishlashda xatolik: $e');
            }
          });
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

      _flushPendingOutgoingSignals();
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
  Future<void> _handleSignalingMessage(Map<String, dynamic> data) async {
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

      // CallKit ni boshlash (CallKit o'zi ringtone chaladi)
      CallKitService().showIncomingCall(
        callerName: senderName ?? 'Noma\'lum',
        callerId: senderId ?? 0,
      );
      WakelockPlus.enable();

      if (onIncomingCall != null) {
        onIncomingCall!(data);
      }
    } else if (type == 'call_accepted') {
      // Qo'ng'iroq qabul qilindi — offer yaratish
      _isRinging = false;
      _isConnecting = true;
      RingtoneService().stop(); // Dial tone to'xtatish
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
    if (_remoteUserId == null) {
      debugPrint('Signal yuborib bo\'lmadi: remoteUserId null');
      return;
    }
    final msg = jsonEncode({
      'type': type,
      'target_id': _remoteUserId,
      'data': data,
    });

    if (_channel == null || !_wsConnected) {
      debugPrint('WS bog\'lanmagan, signal navbatga qo\'shildi: $type');
      _pendingOutgoingSignals.add(msg);
      // Ulanishni tezlashtirish uchun connectWebSocket chaqiramiz
      connectWebSocket();
      return;
    }

    try {
      _channel?.sink.add(msg);
    } catch (e) {
      debugPrint('Signal yuborishda xatolik: $e, navbatga qo\'shildi');
      _pendingOutgoingSignals.add(msg);
      _wsConnected = false;
      connectWebSocket();
    }
  }

  void _flushPendingOutgoingSignals() {
    if (_pendingOutgoingSignals.isEmpty || _channel == null || !_wsConnected) return;
    debugPrint('Navbatdagi ${_pendingOutgoingSignals.length} ta signal yuborilmoqda');
    final signals = List<String>.from(_pendingOutgoingSignals);
    _pendingOutgoingSignals.clear();
    for (final msg in signals) {
      try {
        _channel?.sink.add(msg);
      } catch (e) {
        debugPrint('Navbatdagi signalni yuborishda xatolik: $e');
        _pendingOutgoingSignals.add(msg); // Qayta qo'shamiz
      }
    }
  }

  Future<void> _createPeerConnection() async {
    // Har bir yangi peer connection toza candidate buferi bilan boshlanadi.
    _pendingCandidates.clear();
    _remoteDescriptionSet = false;

    final Map<String, dynamic> configuration = {
      "iceServers": _iceServers,
      "sdpSemantics": "unified-plan",
    };
    debugPrint('WebRTC: createPeerConnection - ICE serverlar: $_iceServers');

    _peerConnection = await createPeerConnection(configuration);

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
    if (_localStream != null) {
      for (var track in _localStream!.getTracks()) {
        await _peerConnection?.addTrack(track, _localStream!);
      }
    }
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
    try {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw Exception('Mikrofon ruxsati berilmadi');
      }
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    } catch (e) {
      debugPrint('Mikrofon ruxsati olinmadi yoki xatolik: $e');
      if (onError != null) {
        onError!('Mikrofon ruxsati olinmadi');
      }
      rethrow; // Rethrow so caller knows it failed
    }
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

    // Chiquvchi qo'ng'iroq uchun dial tone va wakelock
    RingtoneService().playDialTone();
    WakelockPlus.enable();

    notifyListeners();

    // Notify target that a call is initiating
    sendSignal('call_init', {});
  }

  /// Offer yaratish va yuborish
  Future<void> processOffer() async {
    if (_peerConnection != null) return;
    try {
      await _createPeerConnection();
      final Map<String, dynamic> offerSdpConstraints = {
        "mandatory": {
          "OfferToReceiveAudio": true,
          "OfferToReceiveVideo": false,
        },
        "optional": [],
      };
      RTCSessionDescription offer = await _peerConnection!.createOffer(offerSdpConstraints);
      await _peerConnection!.setLocalDescription(offer);

      sendSignal('offer', {
        'sdp': offer.sdp,
        'type': offer.type,
      });
    } catch (e) {
      debugPrint('processOffer xatolik: $e');
      endCall(sendSignal: true);
    }
  }

  /// Kiruvchi qo'ng'iroqni qabul qilish
  Future<void> answerCall(int callerId, String callerName) async {
    if (_inCall) return; // Agar allaqachon qabul qilingan bo'lsa
    _remoteUserId = callerId;
    _remoteUserName = callerName;
    _inCall = true;
    _isRinging = false;
    _isConnecting = true;

    // Ringtone to'xtatish (CallKit o'zi qo'ng'iroqni aktiv holatga o'tkazadi, endAllCalls QILINMAYDI!)
    RingtoneService().stop();

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

    try {
      await _createPeerConnection();
      await _peerConnection?.setRemoteDescription(
        RTCSessionDescription(offerData['sdp'], offerData['type']),
      );
      // Remote description tayyor — buferlangan candidate'larni qo'shamiz.
      await _flushPendingCandidates();

      final Map<String, dynamic> answerSdpConstraints = {
        "mandatory": {
          "OfferToReceiveAudio": true,
          "OfferToReceiveVideo": false,
        },
        "optional": [],
      };
      RTCSessionDescription answer = await _peerConnection!.createAnswer(answerSdpConstraints);
      await _peerConnection?.setLocalDescription(answer);

      sendSignal('answer', {
        'sdp': answer.sdp,
        'type': answer.type,
      });

      _inCall = true;
      _isConnecting = false;
      _startCallTimer();
      notifyListeners();
    } catch (e) {
      debugPrint('_handleOffer xatolik: $e');
      endCall(sendSignal: true);
    }
  }

  Future<void> _handleAnswer(Map<String, dynamic> answerData) async {
    await _peerConnection?.setRemoteDescription(
      RTCSessionDescription(answerData['sdp'], answerData['type']),
    );
    // Remote description tayyor — buferlangan candidate'larni qo'shamiz.
    await _flushPendingCandidates();
  }

  Future<void> _handleIceCandidate(Map<String, dynamic> candidateData) async {
    if (candidateData['candidate'] == null) return;

    final candidate = RTCIceCandidate(
      candidateData['candidate']?.toString(),
      candidateData['sdpMid']?.toString(),
      candidateData['sdpMLineIndex'] != null
          ? int.tryParse(candidateData['sdpMLineIndex'].toString())
          : null,
    );

    // Agar peer connection yoki remote description hali tayyor bo'lmasa,
    // candidate'ni yo'qotmasdan buferlaymiz va keyinroq qo'shamiz.
    if (_peerConnection == null || !_remoteDescriptionSet) {
      _pendingCandidates.add(candidate);
      debugPrint('ICE candidate buferlandi (jami: ${_pendingCandidates.length})');
      return;
    }

    try {
      await _peerConnection?.addCandidate(candidate);
      debugPrint('ICE candidate muvaffaqiyatli qo\'shildi: ${candidate.candidate}');
    } catch (e) {
      debugPrint('addCandidate xatolik: $e');
    }
  }

  /// Remote description o'rnatilgandan keyin buferlangan candidate'larni qo'shish.
  Future<void> _flushPendingCandidates() async {
    if (_peerConnection == null) return;
    _remoteDescriptionSet = true;
    if (_pendingCandidates.isEmpty) return;

    debugPrint('Buferlangan ${_pendingCandidates.length} ta ICE candidate qo\'shilmoqda');
    final buffered = List<RTCIceCandidate>.from(_pendingCandidates);
    _pendingCandidates.clear();
    for (final candidate in buffered) {
      try {
        await _peerConnection?.addCandidate(candidate);
      } catch (e) {
        debugPrint('Buferlangan candidate qo\'shishda xatolik: $e');
      }
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

    // Ringtone, CallKit va WakeLock ni to'xtatish
    RingtoneService().stop();
    CallKitService().endAllCalls();
    WakelockPlus.disable();

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

    _pendingCandidates.clear();
    _remoteDescriptionSet = false;
    _pendingOutgoingSignals.clear();

    _isMuted = false;
    _isSpeaker = false;

    notifyListeners();
    if (onCallEnded != null) onCallEnded!();
  }

  /// Rad etish (kiruvchi qo'ng'iroq)
  void rejectCall() {
    sendSignal('reject_call', {});

    // Ringtone va CallKit ni to'xtatish
    RingtoneService().stop();
    CallKitService().endAllCalls();
    WakelockPlus.disable();

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
