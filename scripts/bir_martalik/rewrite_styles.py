import os
import glob
import re

directory = "/home/gvazar/Desktop/super-app./super-app/lib/screens/provider_side/widgets"

for filepath in glob.glob(os.path.join(directory, "*.dart")):
    with open(filepath, "r") as f:
        content = f.read()
    
    # Text styles with widget.accent
    content = re.sub(r'color:\s*widget\.accent', 'color: Colors.black', content)
    
    # withValues
    content = re.sub(r'widget\.accent\.withValues\(alpha:\s*0\.[1-2]\)', 'Colors.black12', content)
    content = re.sub(r'widget\.accent\.withValues\(alpha:\s*0\.[3-9]\)', 'Colors.black54', content)
    
    # Button styling
    content = re.sub(r'backgroundColor:\s*widget\.accent', 'backgroundColor: Colors.black, foregroundColor: Colors.white', content)
    content = re.sub(r'foregroundColor:\s*widget\.accent', 'foregroundColor: Colors.black', content)
    
    # checkmarkColor
    content = re.sub(r'checkmarkColor:\s*widget\.accent', 'checkmarkColor: Colors.black', content)

    # Some OutlinedButton borders
    content = re.sub(r'BorderSide\(color:\s*widget\.accent\)', 'BorderSide(color: Colors.black, width: 2)', content)

    # TextField decoration focusColor etc if any
    content = re.sub(r'focusColor:\s*widget\.accent', 'focusColor: Colors.black', content)

    with open(filepath, "w") as f:
        f.write(content)

print("Rewrote styles in all widgets")
