import os
import re

APP_JS = '/home/devops/super-app/backend/app/static/admin/js/app.js'
OUT_DIR = '/home/devops/super-app/backend/app/static/admin/js'

with open(APP_JS, 'r', encoding='utf-8') as f:
    content = f.read()

# Clean up DOMContentLoaded
content = re.sub(r"document\.addEventListener\('DOMContentLoaded',\s*function\(\)\s*\{", "", content, count=1)
if content.endswith('});\n'):
    content = content[:-4]
elif content.endswith('});'):
    content = content[:-3]
else:
    parts = content.rsplit('});', 1)
    if len(parts) == 2:
        content = parts[0] + parts[1]

markers = [
    ("api", "// ===== AUTH TOKEN ====="),
    ("ui", "// ===== UTILITY FUNCTIONS ====="),
    ("router", "// ===== SIDEBAR ====="),
    ("dashboard", "// ===== PAGE: DASHBOARD ====="),
    ("users", "// ===== PAGE: USERS ====="),
    ("providers", "// ===== PAGE: PROVIDERS ====="),
    ("orders", "// ===== PAGE: ORDERS ====="),
    ("categories", "// ===== PAGE: CATEGORIES ====="),
    ("reviews", "// ===== PAGE: REVIEWS ====="),
    ("finance", "// ===== PAGE: FINANCE ====="),
    ("promos", "// ===== PAGE: PROMOS & BANNERS ====="),
    ("settings", "// ===== PAGE: SETTINGS ====="),
    ("notifications", "// ===== PAGE: NOTIFICATIONS ====="),
    ("reports", "// ===== PAGE: REPORTS ====="),
    ("search", "// ===== GLOBAL SEARCH ====="),
    ("analytics", "// ===== USER ANALYTICS ====="),
    ("userdata", "// ===== USER DATA ====="),
    ("products", "// ===== PAGE: PRODUCTS CATALOG ====="),
    ("init", "// ===== INIT ====="),
    ("END", "END_OF_FILE_MARKER_NEVER_MATCH")
]

blocks = {}
for i in range(len(markers) - 1):
    name = markers[i][0]
    start_str = markers[i][1]
    end_str = markers[i+1][1]
    
    start_idx = content.find(start_str)
    if end_str == "END_OF_FILE_MARKER_NEVER_MATCH":
        end_idx = len(content)
    else:
        end_idx = content.find(end_str)
        
    if start_idx != -1 and end_idx != -1:
        blocks[name] = content[start_idx:end_idx]
    elif start_idx != -1 and end_idx == -1:
        next_valid = len(content)
        for j in range(i+1, len(markers)-1):
            idx = content.find(markers[j][1])
            if idx != -1:
                next_valid = idx
                break
        blocks[name] = content[start_idx:next_valid]

api_base = "export const API_BASE = '/api/v1/admin';\nwindow.API_BASE = API_BASE;\n"

os.makedirs(f"{OUT_DIR}/pages", exist_ok=True)

exports_dict = {}

for name, code in blocks.items():
    funcs = re.findall(r"(?:async\s+)?function\s+([a-zA-Z0-9_]+)\s*\(", code)
    exports_dict[name] = list(set(funcs))

modules = []

for name, code in blocks.items():
    prefix = ""
    # Inject imports
    if name not in ["api"]:
        depth = "../" if name not in ["ui", "router", "init", "search", "analytics", "userdata"] else "./"
        
        api_funcs = exports_dict.get('api', [])
        if api_funcs:
            prefix += f"import {{ API_BASE, {', '.join(api_funcs)} }} from '{depth}api.js';\n"
            
    if name not in ["ui", "api"]:
        depth = "../" if name not in ["router", "init", "search", "analytics", "userdata"] else "./"
        ui_funcs = exports_dict.get('ui', [])
        if ui_funcs:
            prefix += f"import {{ {', '.join(ui_funcs)} }} from '{depth}ui.js';\n"
            
    if name not in ["router", "api", "ui"]:
        depth = "../" if name not in ["init", "search", "analytics", "userdata"] else "./"
        router_funcs = exports_dict.get('router', [])
        if router_funcs:
            prefix += f"import {{ {', '.join(router_funcs)} }} from '{depth}router.js';\n"
            
    if name == "api":
        code = api_base + code
        
    funcs = exports_dict[name]
    
    # We must EXPORT these functions so others can import them
    exports_str = ""
    if funcs:
        exports_str += "\n\n// Exports for ES6 modules\n"
        exports_str += f"export {{ {', '.join(funcs)} }};\n"
        # Also attach to window for inline onclick handlers
        exports_str += "// Expose to window for inline onclick handlers\n"
        exports_str += "\n".join([f"window.{f} = {f};" for f in funcs]) + "\n"
        
    code = prefix + "\n" + code + exports_str
    
    if name in ["api", "ui", "router", "init", "search", "analytics", "userdata"]:
        filename = f"{OUT_DIR}/{name}.js"
        module_path = f"./{name}.js"
    else:
        filename = f"{OUT_DIR}/pages/{name}.js"
        module_path = f"./pages/{name}.js"
        
    with open(filename, 'w', encoding='utf-8') as f:
        f.write(code)
    
    modules.append(module_path)

main_code = "".join([f"import '{m}';\n" for m in modules])
with open(f"{OUT_DIR}/main.js", 'w', encoding='utf-8') as f:
    f.write(main_code)

print("ES6 modules generated perfectly.")
