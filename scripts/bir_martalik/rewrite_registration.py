import os
import glob
import re

directory = "/home/gvazar/Desktop/super-app./super-app/lib/screens/provider_registration"

for root, _, files in os.walk(directory):
    for file in files:
        if not file.endswith(".dart"): continue
        filepath = os.path.join(root, file)
        with open(filepath, "r") as f:
            content = f.read()
        
        # Color(0xFF6366F1)
        content = re.sub(r'const Color\(0xFF6366F1\)', 'Colors.black', content)
        content = re.sub(r'Color\(0xFF6366F1\)', 'Colors.black', content)
        
        # Color(0xFF10B981) -> Usually success color, but we'll leave it unless it's used for standard accents.
        
        # .withValues(alpha: 0.1) after Colors.black
        content = re.sub(r'Colors\.black\s*\.withValues\(alpha:\s*0\.1\)', 'Colors.black12', content)

        # Border.all(color: Colors.grey.withValues(alpha: 0.2)) -> Border.all(color: Colors.black, width: 1.5)
        content = re.sub(r'Border\.all\(color:\s*Colors\.grey\.withValues\(alpha:\s*0\.2\)\)', 'Border.all(color: Colors.black, width: 1.5)', content)
        
        # FillButton styles
        content = re.sub(r'backgroundColor:\s*const Color\(0xFF6366F1\)', 'backgroundColor: Colors.black, foregroundColor: Colors.white', content)
        content = re.sub(r'backgroundColor:\s*Colors\.black', 'backgroundColor: Colors.black, foregroundColor: Colors.white', content)

        with open(filepath, "w") as f:
            f.write(content)

print("Rewrote registration styles")
