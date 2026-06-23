import sys

with open('lib/screens/calls/call_screen.dart', 'r') as f:
    content = f.read()

# Update constructor
old_constructor = """  final bool isIncoming;
  final Map<String, dynamic>? incomingData;

  const CallScreen({
    super.key,
    this.isIncoming = false,
    this.incomingData,
  });"""

new_constructor = """  final bool isIncoming;
  final Map<String, dynamic>? incomingData;
  final bool isBookingCall;

  const CallScreen({
    super.key,
    this.isIncoming = false,
    this.incomingData,
    this.isBookingCall = true,
  });"""

content = content.replace(old_constructor, new_constructor)

# Update onCallEnded
old_onCallEnded = """        PostCallDialogs.show(
          context,
          _callService.remoteUserId,
          _callService.remoteUserName,
          widget.isIncoming,
          _callService.callDuration,
        );"""

new_onCallEnded = """        PostCallDialogs.show(
          context,
          _callService.remoteUserId,
          _callService.remoteUserName,
          widget.isIncoming,
          _callService.callDuration,
          widget.isBookingCall,
        );"""

content = content.replace(old_onCallEnded, new_onCallEnded)

with open('lib/screens/calls/call_screen.dart', 'w') as f:
    f.write(content)

with open('lib/screens/calls/post_call_dialogs.dart', 'r') as f:
    post_content = f.read()

old_show_def = """  static Future<void> show(
    BuildContext context,
    int? remoteUserId,
    String remoteUserName,
    bool isIncoming,
    String callDuration,
  ) async {"""

new_show_def = """  static Future<void> show(
    BuildContext context,
    int? remoteUserId,
    String remoteUserName,
    bool isIncoming,
    String callDuration,
    bool isBookingCall,
  ) async {"""

post_content = post_content.replace(old_show_def, new_show_def)

old_client_call = """    if (isProvider) {
      _showProviderDialog(context, remoteUserId, remoteUserName, appProvider);
    } else {
      _showClientDialog(context, remoteUserId, remoteUserName);
    }"""

new_client_call = """    if (isProvider) {
      _showProviderDialog(context, remoteUserId, remoteUserName, appProvider);
    } else {
      if (isBookingCall) {
        _showClientDialog(context, remoteUserId, remoteUserName);
      }
    }"""

post_content = post_content.replace(old_client_call, new_client_call)

with open('lib/screens/calls/post_call_dialogs.dart', 'w') as f:
    f.write(post_content)

print("Patched call_screen and post_call_dialogs")
