import glob
import re

for filepath in glob.glob('/home/devops/super-app/backend/app/static/admin/js/pages/*.js'):
    with open(filepath, 'r') as f:
        content = f.read()

    # Avoid replacing window.categoriesCache to window.window.categoriesCache
    content = re.sub(r'(?<!window\.)\bcategoriesCache\b', 'window.categoriesCache', content)

    with open(filepath, 'w') as f:
        f.write(content)

print("categoriesCache fixed")
