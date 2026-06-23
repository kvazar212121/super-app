import sys

with open('lib/screens/calls/call_history_screen.dart', 'r') as f:
    content = f.read()

if "import '../../utils/call_helper.dart';" not in content:
    content = content.replace("import '../../services/call_service.dart';", "import '../../services/call_service.dart';\nimport '../../utils/call_helper.dart';")

old_call = """                      CallService().startCall(log.userId, log.userName);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CallScreen(isIncoming: false),
                        ),
                      );"""

new_call = """                      CallHelper.startCallWithPurposeCheck(context, log.userId, log.userName);"""

content = content.replace(old_call, new_call)

with open('lib/screens/calls/call_history_screen.dart', 'w') as f:
    f.write(content)

print("call_history_screen patched")
