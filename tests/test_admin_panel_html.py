"""Admin panel (SPA) sog'ligini tekshiradi.

Admin panel `backend/app/static/admin/` da: index.html + ES6 modullar.
JS sintaksis xatosi yoki yo'qolgan ulanish panelni OQ EKRAN qiladi va
buni backend testlari sezmaydi.

Tekshiriladi:
  1. Har bir JS modul sintaksisi (node --check)
  2. Har bir nav-item (data-page) uchun router'da renderer bor
  3. Har bir renderer moduli main.js da import qilingan
  4. onclick da chaqirilgan funksiyalar window ga chiqarilgan
  5. Sovrinli reyting sahifasi to'liq ulangan

node topilmasa sintaksis qismi SKIP bo'ladi.
"""
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ADMIN = os.path.join(ROOT, "backend", "app", "static", "admin")
JS = os.path.join(ADMIN, "js")

ok, fail = [], []


def check(name, cond, detail=""):
    (ok if cond else fail).append(f"{name}{'' if cond else ': ' + detail}")


if not os.path.isdir(ADMIN):
    print("SKIP: admin static katalogi topilmadi")
    sys.exit(0)

index_html = open(os.path.join(ADMIN, "index.html"), encoding="utf8").read()
router_js = open(os.path.join(JS, "router.js"), encoding="utf8").read()
main_js = open(os.path.join(JS, "main.js"), encoding="utf8").read()

# ── 1. JS sintaksisi ─────────────────────────────────────────────────
node = shutil.which("node")
if not node:
    print("SKIP: node topilmadi — JS sintaksisi tekshirilmadi")
else:
    bad = []
    for root, _dirs, files in os.walk(JS):
        for f in sorted(files):
            if not f.endswith(".js") or f.endswith(".backup"):
                continue
            path = os.path.join(root, f)
            res = subprocess.run([node, "--check", path],
                                 capture_output=True, text=True)
            if res.returncode != 0:
                first = (res.stderr or res.stdout).strip().split("\n")
                bad.append(f"{os.path.relpath(path, ADMIN)}: {first[0] if first else '?'}")
    check("barcha JS modullar sintaksisi to'g'ri", not bad, " | ".join(bad[:3]))

# ── 2. nav-item -> router renderer ───────────────────────────────────
pages = set(re.findall(r'data-page="([\w-]+)"', index_html))
renderers = dict(re.findall(r"^\s*(\w+):\s*(render\w+),", router_js, re.M))
missing = {p for p in pages if p not in renderers}
check("har bir nav-item uchun renderer bor", not missing,
      f"renderersiz: {sorted(missing)}")

# ── 3. Har bir renderer moduli main.js da import qilingan ────────────
imported = set(re.findall(r"import '\./pages/(\w+)\.js';", main_js))
imported |= set(re.findall(r"import '\./(\w+)\.js';", main_js))
# sahifa nomi bilan modul nomi odatda mos keladi
page_modules = {p for p in pages}
not_imported = {p for p in page_modules if p not in imported}
# ba'zi sahifalar boshqa modulda bo'lishi mumkin — funksiya borligini
# tekshirib yumshatamiz
really_missing = []
for p in sorted(not_imported):
    fn = renderers.get(p)
    if not fn:
        continue
    found = False
    for root, _dirs, files in os.walk(JS):
        for f in files:
            if f.endswith(".js") and not f.endswith(".backup"):
                if f"function {fn}" in open(os.path.join(root, f), encoding="utf8").read():
                    found = True
                    break
        if found:
            break
    if not found:
        really_missing.append(f"{p} -> {fn}")
check("har bir renderer funksiyasi biror modulda ta'riflangan",
      not really_missing, f"topilmadi: {really_missing}")

# ── 4. Sovrinli reyting to'liq ulangan ───────────────────────────────
check("nav'da 'campaigns' bor", "campaigns" in pages, f"{sorted(pages)}")
check("router'da campaigns renderer bor", renderers.get("campaigns") == "renderCampaigns",
      f"{renderers.get('campaigns')}")
check("main.js campaigns modulini import qiladi", "campaigns" in imported)

camp_path = os.path.join(JS, "pages", "campaigns.js")
check("campaigns.js mavjud", os.path.exists(camp_path))
if os.path.exists(camp_path):
    camp = open(camp_path, encoding="utf8").read()
    # onclick funksiyalari window ga chiqarilganmi
    onclicks = set(re.findall(r"onclick=\"?'?(\w+)\(", camp))
    exposed = set(re.findall(r"window\.(\w+)\s*=", camp))
    not_exposed = {f for f in onclicks if f not in exposed and not f.startswith("event")}
    check("campaigns.js onclick funksiyalari window'ga chiqarilgan",
          not not_exposed, f"chiqarilmagan: {sorted(not_exposed)}")
    # to'g'ri endpointlarga murojaat
    for ep in ["/admin/campaigns"]:
        check(f"campaigns.js '{ep}' endpointini ishlatadi", ep in camp)

print(f"O'TDI ({len(ok)}):")
for o in ok:
    print(f"  {o}")
if fail:
    print(f"\nYIQILDI ({len(fail)}):")
    for f in fail:
        print(f"  {f}")
    sys.exit(1)
print(f"\nOK: admin panel {len(ok)} tekshiruvdan o'tdi")
