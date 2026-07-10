import os
import re

def main():
    root_dir = 'lib/screens'
    pattern = re.compile(r"Text\(\s*'([^'$]+)'\s*\)")
    pattern_double = re.compile(r'Text\(\s*"([^"$]+)"\s*\)')
    
    for subdir, _, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(subdir, file)
                with open(filepath, 'r') as f:
                    content = f.read()
                    matches = pattern.findall(content) + pattern_double.findall(content)
                    
                    untranslated = [m for m in matches if not m.endswith('.tr')]
                    if untranslated:
                        print(f"{filepath}: {len(untranslated)} untranslated constant strings")

if __name__ == '__main__':
    main()
