import os
import re

dir_path = "/home/devops/super-app/lib/screens/"

files_to_check = [
    "dental_booking_screen.dart",
    "appliance_booking_screen.dart",
    "courier_booking_screen.dart",
    "barber_booking_screen.dart",
    "disinfection_booking_screen.dart",
    "nurse_booking_screen.dart",
    "auto_help_booking_screen.dart",
    "event_booking_screen.dart",
    "salon_booking_screen.dart",
    "auto_workshop_booking_screen.dart",
    "massage_booking_screen.dart"
]

for filename in files_to_check:
    filepath = os.path.join(dir_path, filename)
    if not os.path.exists(filepath):
        continue
        
    with open(filepath, 'r') as f:
        content = f.read()
        
    if "import '../services/call_service.dart';" not in content:
        content = re.sub(r'(import .*;\n)', r'\1import \'../services/call_service.dart\';\nimport \'calls/call_screen.dart\';\n', content, count=1)
        
    pattern = r'onSecondary:\s*\(\)\s*\{\s*ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\([\s\n]*content:\s*Text\([\s\n]*"[^"]*\$\{widget\.(\w+)\.phoneNumber\}[^"]*"\)\),\s*\);\s*\}'
    
    def repl(m):
        prop = m.group(1)
        return f'''onSecondary: () {{
                      final targetId = int.tryParse(widget.{prop}.id) ?? 0;
                      CallService().startCall(targetId, widget.{prop}.name);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CallScreen(isIncoming: false),
                        ),
                      );
                    }}'''
                    
    content, count = re.subn(pattern, repl, content)
    if count > 0:
        print(f"Updated {filename}")
    
    with open(filepath, 'w') as f:
        f.write(content)
