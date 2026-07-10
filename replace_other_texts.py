import os
import re

def main():
    dirs_to_scan = ['lib/screens', 'lib/widgets']
    
    # Matches hintText: 'something' -> hintText: 'something'.tr
    # We use negative lookahead to ensure we don't add .tr if it's already there
    # the regex looks for: (key:\s*)('value')
    # and replaces with: \1\2.tr
    
    # keys we might want to translate: hintText, labelText, title (if it's just a string, but often title is a Widget, wait! "title: 'text'" is rare in Flutter, usually it's "title: Text('...')"). But for DropdownMenuItem it's often "value: '...', child: Text(...)".
    # Let's stick to hintText and labelText.
    pattern_single = re.compile(r"((?:hintText|labelText|tooltip|helperText)\s*:\s*)'([^'$]+)'(?!\.tr)")
    pattern_double = re.compile(r'((?:hintText|labelText|tooltip|helperText)\s*:\s*)"([^"$]+)"(?!\.tr)')
    
    files_changed = 0
    strings_changed = 0
    
    for root_dir in dirs_to_scan:
        if not os.path.exists(root_dir):
            continue
        for subdir, _, files in os.walk(root_dir):
            for file in files:
                if file.endswith('.dart'):
                    filepath = os.path.join(subdir, file)
                    with open(filepath, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    new_content = content
                    
                    def repl_single(m):
                        nonlocal strings_changed
                        strings_changed += 1
                        return f"{m.group(1)}'{m.group(2)}'.tr"
                        
                    def repl_double(m):
                        nonlocal strings_changed
                        strings_changed += 1
                        return f'{m.group(1)}"{m.group(2)}".tr'
                        
                    new_content = pattern_single.sub(repl_single, new_content)
                    new_content = pattern_double.sub(repl_double, new_content)
                    
                    if new_content != content:
                        files_changed += 1
                        with open(filepath, 'w', encoding='utf-8') as f:
                            f.write(new_content)
                        print(f"Updated {filepath}")
                        
    print(f"\nTotal files updated: {files_changed}")
    print(f"Total strings translated: {strings_changed}")

if __name__ == '__main__':
    main()
