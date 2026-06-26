import os
import re

APP_JS = '/home/devops/super-app/backend/app/static/admin/js/app.js'
OUT_DIR = '/home/devops/super-app/backend/app/static/admin/js'

with open(APP_JS, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the DOMContentLoaded wrapper to make them ES6 module scoped
# It starts around line 4: document.addEventListener('DOMContentLoaded', function() {
# and ends at the very end.
content = re.sub(r"document\.addEventListener\('DOMContentLoaded',\s*function\(\)\s*\{", "", content, count=1)
# Remove the last });
content = content.rsplit("});", 1)[0]

sections = [
    ("api", r"// ===== AUTH TOKEN =====.*?// ===== UTILITY FUNCTIONS ====="),
    ("ui", r"// ===== UTILITY FUNCTIONS =====.*?// ===== SIDEBAR ====="),
    ("router", r"// ===== SIDEBAR =====.*?// ===== PAGE: DASHBOARD ====="),
    ("dashboard", r"// ===== PAGE: DASHBOARD =====.*?// ===== PAGE: USERS ====="),
    ("users", r"(?s)// ===== PAGE: USERS =====.*?// ===== PAGE: PROVIDERS ====="),
    ("providers", r"// ===== PAGE: PROVIDERS =====.*?// ===== PAGE: ORDERS ====="),
    ("orders", r"// ===== PAGE: ORDERS =====.*?// ===== PAGE: CATEGORIES ====="),
    ("categories", r"// ===== PAGE: CATEGORIES =====.*?// ===== PAGE: REVIEWS ====="),
    ("reviews", r"// ===== PAGE: REVIEWS =====.*?// ===== PAGE: FINANCE ====="),
    ("finance", r"// ===== PAGE: FINANCE =====.*?// ===== PAGE: PROMOS & BANNERS ====="),
    ("promos", r"// ===== PAGE: PROMOS & BANNERS =====.*?// ===== PAGE: SETTINGS ====="),
    ("settings", r"// ===== PAGE: SETTINGS =====.*?// ===== PAGE: NOTIFICATIONS ====="),
    ("notifications", r"// ===== PAGE: NOTIFICATIONS =====.*?// ===== PAGE: REPORTS ====="),
    ("reports", r"// ===== PAGE: REPORTS =====.*?// ===== GLOBAL SEARCH ====="),
    ("search", r"// ===== GLOBAL SEARCH =====.*?// ===== USER ANALYTICS ====="),
    ("analytics", r"// ===== USER ANALYTICS =====.*?// ===== USER DATA ====="),
    ("userdata", r"// ===== USER DATA =====.*?// ===== PAGE: PRODUCTS CATALOG ====="),
    ("products", r"// ===== PAGE: PRODUCTS CATALOG =====.*?// ===== INIT ====="),
    ("init", r"// ===== INIT =====.*")
]

os.makedirs(f"{OUT_DIR}/pages", exist_ok=True)

# Also API BASE is at the very top before DOMContentLoaded
api_base = "const API_BASE = '/api/v1/admin';\nwindow.API_BASE = API_BASE;\n"

modules = []

for name, pattern in sections:
    match = re.search(pattern, content, re.DOTALL)
    if not match:
        print(f"Failed to find {name}")
        continue
    code = match.group(0)
    
    if name == "api":
        code = api_base + code
        
    # Extract all functions and attach to window
    funcs = re.findall(r"(?:async\s+)?function\s+([a-zA-Z0-9_]+)\s*\(", code)
    exports = "\n".join([f"window.{f} = {f};" for f in set(funcs)])
    
    if exports:
        code += "\n\n// Expose to window for inline onclick handlers\n" + exports + "\n"

    # Also for constants like API_BASE, we'll export them if needed. 
    # Let's also attach variables like searchTimeout if they are shared? 
    # Actually, let's just write the code.
    
    if name in ["api", "ui", "router", "init", "search", "analytics", "userdata"]:
        filename = f"{OUT_DIR}/{name}.js"
        module_path = f"./{name}.js"
    else:
        filename = f"{OUT_DIR}/pages/{name}.js"
        module_path = f"./pages/{name}.js"
        
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(code)
    
    modules.append(module_path)

# Create main.js
main_code = "".join([f"import '{m}';\n" for m in modules])
with open(f"{OUT_DIR}/main.js", 'w', encoding='utf-8') as f:
    f.write(main_code)

print("Split completed successfully.")
