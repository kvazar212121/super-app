import os
import re

def fix_imports(content):
    if '.tr' in content or '.tr)' in content or '.tr,' in content or '.tr]' in content or '.tr}' in content:
        # Check if imported
        if 'locale_controller.dart' not in content and 'translations.dart' not in content:
            # add import
            import_statement = "import 'package:super_app/l10n/locale_controller.dart';\n"
            # find last import
            imports = list(re.finditer(r"^import\s+['\"].*?['\"];", content, flags=re.MULTILINE))
            if imports:
                last_import = imports[-1]
                idx = last_import.end()
                content = content[:idx] + "\n" + import_statement + content[idx:]
            else:
                content = import_statement + content
    return content

def fix_consts(content):
    # We remove const if it's right before Text, InputDecoration, SnackBar, Padding, Center, Align, SizedBox
    # when .tr is on the same line or next few lines. It's safer to just remove `const ` in lines that have `.tr`.
    # Wait, removing all `const ` on a line with `.tr` might remove `const SizedBox(width: 10)` which is fine.
    
    # Let's replace 'const Text(' with 'Text(' if the line has .tr
    # Actually, a multi-line regex is better:
    # We replace `const <Widget>( ... .tr ... )`
    # Since python regex doesn't easily do balanced parentheses, we can just replace `const\s+(Text|InputDecoration|SnackBar|Padding|Center|Align|SizedBox|Column|Row|ListView)\b` with `\1` 
    # ONLY if the content between it and `.tr` has no other `const` or maybe just do it iteratively.
    
    # Simple line-by-line approach for single-line consts
    lines = content.split('\n')
    for i in range(len(lines)):
        if '.tr' in lines[i]:
            # remove const from the same line
            lines[i] = re.sub(r'\bconst\s+', '', lines[i])
            # if previous line ends with const, or has const SnackBar( etc
            if i > 0 and 'const ' in lines[i-1]:
                # if lines[i-1] is something like `const SnackBar(`
                lines[i-1] = re.sub(r'\bconst\s+', '', lines[i-1])
            if i > 1 and 'const ' in lines[i-2]:
                lines[i-2] = re.sub(r'\bconst\s+(SnackBar|InputDecoration|Padding|Center)\b', r'\1', lines[i-2])
    return '\n'.join(lines)

def main():
    root_dir = 'lib'
    files_changed = 0
    
    for subdir, _, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(subdir, file)
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                new_content = fix_imports(content)
                new_content = fix_consts(new_content)
                
                if new_content != content:
                    with open(filepath, 'w', encoding='utf-8') as f:
                        f.write(new_content)
                    files_changed += 1
                    
    print(f"Fixed {files_changed} files.")

if __name__ == '__main__':
    main()
