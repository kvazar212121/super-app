import re
import os

html_path = '/home/devops/super-app/backend/app/static/admin/index.html'
base_dir = os.path.dirname(html_path)

with open(html_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Extract styles
style_match = re.search(r'<style>(.*?)</style>', content, re.DOTALL)
css_content = style_match.group(1) if style_match else ''
content = re.sub(r'<style>.*?</style>', '<link rel="stylesheet" href="/admin-assets/css/style.css">', content, flags=re.DOTALL)

# Extract scripts
script_match = re.search(r'<script>(.*?)</script>', content, re.DOTALL)
js_content = script_match.group(1) if script_match else ''
content = re.sub(r'<script>.*?</script>', '<script src="/admin-assets/js/app.js"></script>', content, flags=re.DOTALL)

# Save CSS
os.makedirs(os.path.join(base_dir, 'css'), exist_ok=True)
with open(os.path.join(base_dir, 'css', 'style.css'), 'w', encoding='utf-8') as f:
    f.write(css_content.strip())

# Save JS
os.makedirs(os.path.join(base_dir, 'js'), exist_ok=True)
with open(os.path.join(base_dir, 'js', 'app.js'), 'w', encoding='utf-8') as f:
    f.write(js_content.strip())

# Save clean HTML
with open(html_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Split completed successfully!")
