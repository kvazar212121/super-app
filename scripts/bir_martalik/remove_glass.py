import os
import re

lib_dir = '/home/devops/super-app/lib'

def process_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # We want to remove BackdropFilter(...)
    # Because of nested brackets, regex is hard.
    # We can just replace ImageFilter.blur with something else, or leave it but ensure background colors are solid.

    # Let's replace commonly used semi-transparent colors
    content = re.sub(r'\.withValues\(alpha:\s*0\.[0-9]+\)', '', content)
    content = re.sub(r'\.withOpacity\(0\.[0-9]+\)', '', content)
    
    # Replace Colors.transparent with solid colors for scaffold/backgrounds?
    # No, that might break things.

    with open(filepath, 'w') as f:
        f.write(content)

for root, _, files in os.walk(lib_dir):
    for filename in files:
        if filename.endswith('.dart'):
            process_file(os.path.join(root, filename))

print("Done")
