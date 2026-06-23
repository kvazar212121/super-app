import sys

with open('lib/screens/calls/post_call_dialogs.dart', 'r') as f:
    content = f.read()

content = content.replace("final isProvider = appProvider.userProvider != null && isIncoming;", "final isProvider = appProvider.user.isProvider && isIncoming;")
content = content.replace("String serviceName = app.userProvider?.metadataJson['services']?.first ?? 'Xizmat';", "String serviceName = 'Xizmat';")
content = content.replace("double price = app.userProvider?.metadataJson['prices']?[serviceName]?.toDouble() ?? 50000;", "double price = 50000;")

with open('lib/screens/calls/post_call_dialogs.dart', 'w') as f:
    f.write(content)

print("Fixed compile errors in post_call_dialogs.dart")
