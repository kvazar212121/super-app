import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../services/call_service.dart';
import '../../theme/glass_tokens.dart';

class CallScreen extends StatefulWidget {
  final bool isIncoming;
  final Map<String, dynamic>? incomingData;

  const CallScreen({
    Key? key,
    this.isIncoming = false,
    this.incomingData,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  late CallService _callService;
  bool _isAccepted = false;

  @override
  void initState() {
    super.initState();
    _callService = CallService();
    _isAccepted = !widget.isIncoming;

    _callService.onCallEnded = () {
      if (mounted) Navigator.of(context).pop();
    };

    if (!widget.isIncoming) {
      // If we are making the call, we wait for answer, the service already sent call_init
    }
  }

  void _acceptCall() async {
    setState(() => _isAccepted = true);
    final payload = widget.incomingData!['data'];
    final senderId = widget.incomingData!['sender_id'];
    final senderName = widget.incomingData!['sender_name'];
    
    await _callService.answerCall(senderId, senderName);
    // Actually we don't have offer yet if they sent call_init. 
    // Wait, the flow is: caller sends 'call_init'. Callee accepts, then callee tells caller 'im ready'?
    // Let's adjust CallService: 
    // If caller sends 'call_init', callee shows IncomingCallScreen.
    // Callee accepts -> sends 'accept_init'. Caller receives 'accept_init' and generates offer -> sends 'offer'.
    // Callee receives 'offer' -> generates answer.
    // But since my CallService processes 'offer' when received, I can just let Caller send 'offer' immediately instead of 'call_init', 
    // or Caller sends 'call_init', and Caller generates offer when Callee accepts.
    // Let's keep it simple: Callee sends a special signal 'call_accepted' to Caller.
    _callService.sendSignal('call_accepted', {});
  }

  void _declineCall() {
    _callService.sendSignal('reject_call', {});
    Navigator.of(context).pop();
  }

  void _endCall() {
    _callService.endCall();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _callService,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Colors.black87,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E1E1E), Color(0xFF000000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 60),
                  Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(Icons.person, size: 60, color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _callService.remoteUserName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isAccepted ? 'Qo\'ng\'iroq ulandi...' : 'Qo\'ng\'iroq kelmoqda...',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: _isAccepted ? _buildActiveControls() : _buildIncomingControls(),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildIncomingControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CallButton(
          icon: Icons.call_end,
          color: Colors.red,
          onTap: _declineCall,
        ),
        _CallButton(
          icon: Icons.call,
          color: Colors.green,
          onTap: _acceptCall,
        ),
      ],
    );
  }

  Widget _buildActiveControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _CallButton(
          icon: _callService.isMuted ? Icons.mic_off : Icons.mic,
          color: _callService.isMuted ? Colors.white30 : Colors.white12,
          onTap: _callService.toggleMute,
        ),
        _CallButton(
          icon: Icons.call_end,
          color: Colors.red,
          onTap: _endCall,
        ),
        _CallButton(
          icon: _callService.isSpeaker ? Icons.volume_up : Icons.volume_down,
          color: _callService.isSpeaker ? Colors.white30 : Colors.white12,
          onTap: _callService.toggleSpeaker,
        ),
      ],
    );
  }
}

class _CallButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CallButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 32),
      ),
    );
  }
}
