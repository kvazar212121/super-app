import re

with open('/home/devops/super-app/backend/app/static/admin/js/app.js', 'r', encoding='utf-8') as f:
    lines = f.readlines()

pages = []
for i, line in enumerate(lines):
    if '// ===== PAGE:' in line:
        pages.append((i+1, line.strip()))

for p in pages:
    print(p)

