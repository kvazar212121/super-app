import re

filepath = '/home/devops/super-app/backend/app/static/admin/js/pages/products.js'
with open(filepath, 'r') as f:
    content = f.read()

# Replace string start + /window.api/v1/admin with window.API_BASE + '
content = content.replace("'/window.api/v1/admin", "window.API_BASE + '")

with open(filepath, 'w') as f:
    f.write(content)

