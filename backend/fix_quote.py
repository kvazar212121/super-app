filepath = '/home/devops/super-app/backend/app/static/admin/js/pages/finance.js'
with open(filepath, 'r') as f:
    c = f.read()

# Just remove the apostrophe to avoid any escaping hell
c = c.replace("bo\\'sh", "bosh")
c = c.replace("bo\\'sh", "bosh") # in case of double backslash
c = c.replace("so\\'m", "som")
c = c.replace("so\\'m", "som")

c = c.replace(r"bo\'sh", "bosh")
c = c.replace(r"so\'m", "som")

with open(filepath, 'w') as f:
    f.write(c)

