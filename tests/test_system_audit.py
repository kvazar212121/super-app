"""Butun tizim auditi: statik xatolar (backend + Flutter + web).

Foydalanuvchi so'radi: "butun tizimni monitoring qil, qanday xatoliklar
bor Flutterdan tortib backend va web saytgacha".

Bu test ishga tushirmasdan topiladigan xatolarni ushlaydi:
  1. Backend: aniqlanmagan nomlar (NameError manbai)
  2. Backend: har bir model uchun jadval yaratiladimi (create_all bor,
     lekin model ro'yxatga olinmasa jadval bo'lmaydi)
  3. Web/admin: JS sintaksisi
  4. Flutter: analyze (agar o'rnatilgan bo'lsa)

Bu xatolar odatda faqat foydalanuvchi o'sha tugmani bosgandagina
chiqadi, shuning uchun oldindan ushlash muhim.
"""
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BACKEND = os.path.join(ROOT, "backend")

ok, fail = [], []


def check(name, cond, detail=""):
    (ok if cond else fail).append(f"{name}{'' if cond else ': ' + detail}")


# ── 1. Backend: aniqlanmagan nomlar ──────────────────────────────────
# pyflakes 'undefined name' = ishga tushganda NameError. Bu ilgari
# barber_service/salon_service da 8 ta joyda bor edi va sartaroshxonaga
# xodim qabul qilish BUTUNLAY ishlamasdi.
py = shutil.which("pyflakes") or None
res = subprocess.run(
    [sys.executable, "-m", "pyflakes", os.path.join(BACKEND, "app")],
    capture_output=True, text=True,
)
if res.returncode == 2 and "No module named" in (res.stderr or ""):
    print("SKIP: pyflakes o'rnatilmagan (pip install pyflakes)")
else:
    lines = (res.stdout or "").strip().split("\n")
    undefined = [
        l for l in lines
        if "undefined name" in l
        # SQLAlchemy string annotatsiyalari yolg'on ogohlantirish beradi
        and "/models/" not in l
        # "import *" haqidagi eslatma — aniqlanmagan nom EMAS
        and "unable to detect undefined names" not in l
    ]
    check("backend'da aniqlanmagan nom yo'q (NameError manbai)",
          not undefined,
          " | ".join(u.replace(BACKEND + "/", "") for u in undefined[:5]))

    # Ishlatilmagan o'zgaruvchi — xato emas, lekin ko'pincha unutilgan kod
    unused = [l for l in lines if "assigned to but never used" in l]
    if unused:
        print(f"  (eslatma: {len(unused)} ta ishlatilmagan o'zgaruvchi)")


# ── 2. Har bir model jadval oladimi ──────────────────────────────────
sys.path.insert(0, BACKEND)
os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://x:x@127.0.0.1:1/x")
os.environ.setdefault("DATABASE_SYNC_URL", "postgresql://x:x@127.0.0.1:1/x")
try:
    import app.models  # noqa: F401
    from app.db.base import Base

    registered = set(Base.metadata.tables.keys())

    # Fayllardagi __tablename__ larni yig'amiz
    declared = set()
    models_dir = os.path.join(BACKEND, "app", "models")
    for f in os.listdir(models_dir):
        if not f.endswith(".py"):
            continue
        src = open(os.path.join(models_dir, f), encoding="utf8").read()
        declared |= set(re.findall(r'__tablename__\s*=\s*["\']([^"\']+)', src))

    missing = sorted(declared - registered)
    check("har bir model app.models da ro'yxatga olingan",
          not missing,
          f"ro'yxatdan tashqarida: {missing} — bu jadvallar create_all "
          f"paytida YARATILMAYDI")
except Exception as e:
    check("modellarni import qilish", False, str(e)[:200])


# ── 3. Admin panel JS sintaksisi ─────────────────────────────────────
node = shutil.which("node")
JS_DIR = os.path.join(BACKEND, "app", "static", "admin", "js")
if not node:
    print("SKIP: node topilmadi — JS tekshirilmadi")
elif not os.path.isdir(JS_DIR):
    print("SKIP: admin JS katalogi yo'q")
else:
    bad = []
    for root, _d, files in os.walk(JS_DIR):
        for f in sorted(files):
            if f.endswith(".js") and not f.endswith(".backup"):
                path = os.path.join(root, f)
                r = subprocess.run([node, "--check", path],
                                   capture_output=True, text=True)
                if r.returncode != 0:
                    bad.append(os.path.relpath(path, BACKEND))
    check("admin panel JS sintaksisi to'g'ri", not bad, f"{bad[:3]}")


# ── 4. Landing sahifa mavjudmi ───────────────────────────────────────
landing = os.path.join(BACKEND, "app", "static", "landing", "index.html")
check("web sayt (landing) fayli mavjud", os.path.isfile(landing),
      f"{landing} topilmadi")
if os.path.isfile(landing):
    html = open(landing, encoding="utf8").read()
    check("landing'da ochilmagan <script> yo'q",
          html.count("<script") == html.count("</script>"),
          f"<script>={html.count('<script')} </script>={html.count('</script>')}")


# ── 5. Flutter analyze ───────────────────────────────────────────────
flutter = shutil.which("flutter")
if not flutter:
    print("SKIP: flutter topilmadi")
else:
    r = subprocess.run([flutter, "analyze", "--no-pub"],
                       capture_output=True, text=True, cwd=ROOT, timeout=900)
    out = r.stdout + r.stderr
    errors = re.findall(r"^\s+error\s+•.*$", out, re.M)
    warnings = re.findall(r"^\s+warning\s+•.*$", out, re.M)
    # BuildContext xatosi ilova qulashiga olib keladi
    ctx = re.findall(r"use_build_context_synchronously", out)
    check("Flutter'da 'error' darajali muammo yo'q", not errors,
          f"{len(errors)} ta: {errors[:2]}")
    check("Flutter'da 'warning' yo'q", not warnings, f"{len(warnings)} ta")
    check("BuildContext async xatosi yo'q (ilova qulashi mumkin)",
          not ctx, f"{len(ctx)} ta joy")


print(f"\nO'TDI ({len(ok)}):")
for o in ok:
    print(f"  ✓ {o}")
if fail:
    print(f"\nYIQILDI ({len(fail)}):")
    for f in fail:
        print(f"  ✗ {f}")
    sys.exit(1)
print(f"\nOK: {len(ok)} ta tizim tekshiruvi o'tdi")
