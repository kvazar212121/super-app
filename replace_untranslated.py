import os
import re

def main():
    dirs_to_scan = ['lib/screens', 'lib/widgets']
    
    # Matches Text('something') but ignores if it already has .tr
    # We use negative lookahead to ensure we don't add .tr if it's already there
    # Wait, the simplest way is to replace Text('string') -> Text('string'.tr)
    # The negative lookahead for .tr can be placed after the closing parenthesis:
    # Actually, we just need to replace the content of the file.
    
    # pattern: Text( 'string' ) -> Text('string'.tr)
    # only string without $ inside
    pattern_single = re.compile(r"(Text\(\s*)'([^'$]+)'(\s*\))(?!\.tr)")
    pattern_double = re.compile(r'(Text\(\s*)"([^"$]+)"(\s*\))(?!\.tr)')
    
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
                    
                    # Store original to check if changed
                    new_content = content
                    
                    # Use a function to do the replacement so we can log
                    def repl_single(m):
                        nonlocal strings_changed
                        strings_changed += 1
                        return f"{m.group(1)}'{m.group(2)}'.tr{m.group(3)}"
                        
                    def repl_double(m):
                        nonlocal strings_changed
                        strings_changed += 1
                        return f'{m.group(1)}"{m.group(2)}".tr{m.group(3)}'
                        
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
