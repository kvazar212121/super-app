import sys

with open('lib/screens/calls/call_screen.dart', 'r') as f:
    content = f.read()

# 1. Add import for PostCallDialogs
if "import 'post_call_dialogs.dart';" not in content:
    content = content.replace(
        "import '../../services/ringtone_service.dart';",
        "import '../../services/ringtone_service.dart';\nimport 'post_call_dialogs.dart';"
    )

# 2. Modify onCallEnded
old_onCallEnded = """    _callService.onCallEnded = () {
      _stopRingingEffects();
      if (mounted) Navigator.of(context).pop();
    };"""

new_onCallEnded = """    _callService.onCallEnded = () {
      _stopRingingEffects();
      if (mounted) {
        PostCallDialogs.show(
          context,
          _callService.remoteUserId,
          _callService.remoteUserName,
          widget.isIncoming,
          _callService.callDuration,
        );
      }
    };"""

content = content.replace(old_onCallEnded, new_onCallEnded)

# 3. Modify _endCall
old_endCall = """  void _endCall() {
    _stopRingingEffects();
    RingtoneService().stop();
    _callService.endCall();
    Navigator.of(context).pop();
  }"""

new_endCall = """  void _endCall() {
    _stopRingingEffects();
    RingtoneService().stop();
    _callService.endCall();
    // Navigator.pop is handled by onCallEnded / PostCallDialogs.show
  }"""

content = content.replace(old_endCall, new_endCall)

with open('lib/screens/calls/call_screen.dart', 'w') as f:
    f.write(content)

print("CallScreen patched")
