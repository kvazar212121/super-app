import re
with open('/home/devops/super-app/backend/app/static/admin/js/router.js', 'r') as f:
    code = f.read()

# Replace bare render* calls with window.render*
code = re.sub(r'(\s+\w+:\s+)(render\w+)', r'\1window.\2', code)
code = code.replace('initDashboardCharts()', 'window.initDashboardCharts()')

with open('/home/devops/super-app/backend/app/static/admin/js/router.js', 'w') as f:
    f.write(code)

