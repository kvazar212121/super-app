import os
import re

def main():
    root_dir = 'lib'
    pattern = re.compile(r"(?:hintText|labelText|title)\s*:\s*'([^'$]+)'")
    pattern_double = re.compile(r'(?:hintText|labelText|title)\s*:\s*"([^"$]+)"')
    
    for subdir, _, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(subdir, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                    matches = pattern.findall(content) + pattern_double.findall(content)
                    
                    # only keep those not ending with .tr (which is hard to check because the regex only matched the string)
                    # let's just find the occurrences:
                    # Actually, if we match the whole string we can check what's after.
                    
if __name__ == '__main__':
    main()
