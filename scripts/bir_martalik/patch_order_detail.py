import sys

with open('lib/screens/order_detail_screen.dart', 'r') as f:
    content = f.read()

if "import '../utils/call_helper.dart';" not in content:
    content = content.replace("import '../services/call_service.dart';", "import '../services/call_service.dart';\nimport '../utils/call_helper.dart';")

old_call = """                        CallService().startCall(order.providerId!, order.providerName);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const CallScreen(isIncoming: false),
                          ),
                        );"""

new_call = """                        CallHelper.startCallWithPurposeCheck(context, order.providerId!, order.providerName);"""

content = content.replace(old_call, new_call)

with open('lib/screens/order_detail_screen.dart', 'w') as f:
    f.write(content)

print("order_detail_screen patched")
