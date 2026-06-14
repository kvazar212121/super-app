import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import 'api_service.dart';

class CallService extends ChangeNotifier {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  WebSocketChannel? _channel;
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;

  bool _inCall = false;
  bool _isMuted = false;
  bool _isSpeaker = false;

  int? _remoteUserId;
  String? _remoteUserName;
  
  // States to export to UI
  bool get inCall => _inCall;
  bool get isMuted => _isMuted;
  bool get isSpeaker => _isSpeaker;
  String get remoteUserName => _remoteUserName ?? 'Noma\'lum';
  
  // Callbacks for UI
  Function(Map<String, dynamic>)? onIncomingCall;
  Function()? onCallEnded;
  Function()? onCallAnswered;

  Future<void> connectWebSocket() async {
    final token = await ApiService().getToken();
    if (token == null) return;

    final wsUrl = AppConfig.apiBaseUrl
        .replaceFirst('http', 'ws')
        .replaceFirst('https', 'wss');

    final uri = Uri.parse('$wsUrl/calls/ws?token=$token');
    
    _channel = WebSocketChannel.connect(uri);
    _channel?.stream.listen((message) {
      final data = jsonDecode(message);
      _handleSignalingMessage(data);
    }, onDone: () {
      debugPrint("WebSocket Disconnected");
      // Reconnect logic could be added here
    }, onError: (error) {
      debugPrint("WebSocket Error: $error");
    });
  }

  void _handleSignalingMessage(Map<String, dynamic> data) async {
    final type = data['type'];
    final senderId = data['sender_id'];
    final senderName = data['sender_name'];
    final payload = data['data'];

    if (type == 'call_init') {
      // Incoming call request
      _remoteUserId = senderId;
      _remoteUserName = senderName;
      if (onIncomingCall != null) {
        onIncomingCall!(data);
      }
    } else if (type == 'call_accepted') {
      await processOffer();
    } else if (type == 'offer') {
      await _handleOffer(payload, senderId, senderName);
    } else if (type == 'answer') {
      await _handleAnswer(payload);
      if (onCallAnswered != null) onCallAnswered!();
    } else if (type == 'ice_candidate') {
      await _handleIceCandidate(payload);
    } else if (type == 'end_call' || type == 'reject_call') {
      endCall(sendSignal: false);
    } else if (type == 'target_offline') {
      // Target is offline
      endCall(sendSignal: false);
      // Could show a toast here
    }
  }

  void sendSignal(String type, Map<String, dynamic> data) {
    if (_remoteUserId == null || _channel == null) return;
    final msg = jsonEncode({
      'type': type,
      'target_id': _remoteUserId,
      'data': data,
    });
    _channel?.sink.add(msg);
  }

  Future<void> _createPeerConnection() async {
    final Map<String, dynamic> configuration = {
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"},
      ]
    };

    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": false,
      },
      "optional": [],
    };

    _peerConnection = await createPeerConnection(configuration, offerSdpConstraints);

    _peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      sendSignal('ice_candidate', {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex
      });
    };

    _peerConnection?.onAddStream = (MediaStream stream) {
      _remoteStream = stream;
      notifyListeners();
    };

    await _getUserMedia();
    _localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, _localStream!);
    });
  }

  Future<void> _getUserMedia() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': false,
    };
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
  }

  Future<void> startCall(int targetId, String targetName) async {
    _remoteUserId = targetId;
    _remoteUserName = targetName;
    _inCall = true;
    notifyListeners();
    
    // Notify target that a call is initiating
    sendSignal('call_init', {});
  }

  Future<void> processOffer() async {
    // Called when caller is ready to actually send offer
    await _createPeerConnection();
    RTCSessionDescription offer = await _peerConnection!.createOffer({});
    await _peerConnection!.setLocalDescription(offer);
    
    sendSignal('offer', {
      'sdp': offer.sdp,
      'type': offer.type,
    });
  }

  Future<void> answerCall(int callerId, String callerName) async {
    _remoteUserId = callerId;
    _remoteUserName = callerName;
    _inCall = true;
    notifyListeners();
  }

  Future<void> _handleOffer(Map<String, dynamic> offerData, int senderId, String senderName) async {
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

  void endCall({bool sendSignal = true}) {
    if (sendSignal) {
      this.sendSignal('end_call', {});
    }
    _inCall = false;
    _remoteUserId = null;
    _remoteUserName = null;
    
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _localStream = null;
    
    _peerConnection?.close();
    _peerConnection = null;
    
    notifyListeners();
    if (onCallEnded != null) onCallEnded!();
  }

  void toggleMute() {
    if (_localStream != null) {
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

  @override
  void dispose() {
    endCall();
    _channel?.sink.close();
    super.dispose();
  }
}
