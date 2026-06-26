import os
import glob
import re

js_files = glob.glob('/home/devops/super-app/backend/app/static/admin/js/**/*.js', recursive=True)
globals_list = ['api', 'API_BASE', 'formatMoney', 'formatDate', 'statusBadge', 'renderStars', 'showToast', 'openModal', 'closeModal', 'renderPage', 'getInitials']

for filepath in js_files:
    if filepath.endswith('main.js'):
        continue
    with open(filepath, 'r') as f:
        code = f.read()

    # To avoid changing definitions like 'async function api(', we use negative lookbehind
    # or just replace function calls if they are not preceded by 'function '
    for g in globals_list:
        # replace standalone usages of the variable/function with window.X
        # word boundary, not preceded by 'function ' or 'window.' or '.'
        pattern = r'(?<!function )(?<!window\.)(?<!\.)\b' + g + r'\b'
        code = re.sub(pattern, f'window.{g}', code)

    with open(filepath, 'w') as f:
        f.write(code)

print("Patch globals completed.")
