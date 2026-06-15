import re

file_path = "backend/app/static/admin/index.html"
with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

replacements = {
    '&#128202;': '<i data-lucide="layout-dashboard"></i>',
    '&#128101;': '<i data-lucide="users"></i>',
    '&#127970;': '<i data-lucide="briefcase"></i>',
    '&#128230;': '<i data-lucide="shopping-bag"></i>',
    '&#128194;': '<i data-lucide="folder"></i>',
    '&#127881;': '<i data-lucide="tag"></i>',
    '&#11088;': '<i data-lucide="star"></i>',
    '&#128197;': '<i data-lucide="calendar-check"></i>',
    '&#128722;': '<i data-lucide="shopping-cart"></i>',
    '&#128181;': '<i data-lucide="wallet"></i>',
    '&#128200;': '<i data-lucide="trending-up"></i>',
    '&#128176;': '<i data-lucide="dollar-sign"></i>',
    '&#9881;': '<i data-lucide="settings"></i>',
    '&#128276;': '<i data-lucide="bell"></i>'
}

for old, new in replacements.items():
    content = content.replace(f'<span class="nav-icon">{old}</span>', f'<span class="nav-icon">{new}</span>')

# Call lucide.createIcons() at the end
content = content.replace('renderPage(\'dashboard\');', 'renderPage(\'dashboard\');\n        lucide.createIcons();')

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
