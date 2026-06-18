import os
import glob

files = glob.glob("/home/devops/super-app/lib/screens/*booking_screen.dart")

for filepath in files:
    with open(filepath, 'r') as f:
        content = f.read()
    
    if r"\'" in content:
        content = content.replace(r"\'", "'")
        with open(filepath, 'w') as f:
            f.write(content)
            print(f"Fixed {filepath}")
