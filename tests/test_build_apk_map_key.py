"""`build-apk.sh` xarita kalitini to'g'ri uzatishini tekshiradi.

Nega kerak: kalit noto'g'ri uzatilsa build baribir muvaffaqiyatli
tugaydi va APK tayyor bo'ladi — lekin xarita OSM demo serveriga
tushadi. Bu ommaviy relizda taqiqlangan va foydalanuvchi ko'paysa
xarita OQ bo'lib qoladi. Ya'ni xato jimgina o'tib ketadi, shuning
uchun aynan shu joyni test qo'riqlaydi.

Haqiqiy `flutter` chaqirilmaydi: PATH ga soxta `flutter` qo'yiladi va
u qanday argumentlar bilan chaqirilgani tekshiriladi.
"""
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCRIPT = os.path.join(ROOT, "build-apk.sh")

ok, fail = [], []


def check(name, cond, detail=""):
    (ok if cond else fail).append(f"{name}{'' if cond else ': ' + detail}")


def run(env_extra=None, env_file=None):
    """Skriptni soxta flutter bilan ishga tushiradi, chiqishni qaytaradi."""
    tmp = tempfile.mkdtemp(prefix="buildapk_")
    try:
        shutil.copy(SCRIPT, os.path.join(tmp, "build-apk.sh"))

        fake = os.path.join(tmp, "flutter")
        with open(fake, "w") as f:
            f.write('#!/bin/bash\necho "FLUTTER-CHAQIRUV: $*"\n')
        os.chmod(fake, 0o755)

        # Skript APK mavjudligini tekshiradi
        apk_dir = os.path.join(tmp, "build/app/outputs/flutter-apk")
        os.makedirs(apk_dir, exist_ok=True)
        open(os.path.join(apk_dir, "app-release.apk"), "w").close()

        if env_file:
            with open(os.path.join(tmp, ".env.local"), "w") as f:
                f.write(env_file)

        env = dict(os.environ)
        env.pop("MAPTILER_KEY", None)
        env["PATH"] = tmp + os.pathsep + env["PATH"]
        env.update(env_extra or {})

        r = subprocess.run(["bash", "build-apk.sh"], cwd=tmp, env=env,
                           capture_output=True, text=True, timeout=60)
        return r.stdout + r.stderr
    finally:
        shutil.rmtree(tmp, ignore_errors=True)


def main():
    check("build-apk.sh mavjud", os.path.exists(SCRIPT), SCRIPT)
    if not os.path.exists(SCRIPT):
        report()

    # 1) Kalitsiz: ogohlantirish chiqadi, --dart-define BERILMAYDI
    out = run()
    check("kalitsiz: ogohlantirish chiqadi",
          "OGOHLANTIRISH" in out and "MAPTILER_KEY" in out,
          "jim o'tib ketdi — xarita oq bo'lib qolishi mumkin")
    check("kalitsiz: ogohlantirish nima qilishni aytadi",
          "MAPTILER_KEY=" in out and "build-apk.sh" in out, out[-200:])
    check("kalitsiz: --dart-define berilmaydi",
          "--dart-define" not in out, out[-200:])
    check("kalitsiz: build baribir bajariladi (dev uchun)",
          "build apk --release" in out, out[-200:])

    # 2) Muhit o'zgaruvchisi orqali
    out = run({"MAPTILER_KEY": "ABC123"})
    check("MAPTILER_KEY berilsa flutter'ga uzatiladi",
          "--dart-define=MAPTILER_KEY=ABC123" in out, out[-200:])
    check("kalit bo'lsa ogohlantirish chiqmaydi",
          "OGOHLANTIRISH" not in out, out[-200:])

    # 3) .env.local fayli orqali (git'ga tushmaydi)
    out = run(env_file="MAPTILER_KEY=FROM_FILE\n")
    check(".env.local dan kalit o'qiladi",
          "--dart-define=MAPTILER_KEY=FROM_FILE" in out, out[-200:])

    # 4) Muhit o'zgaruvchisi fayldan USTUN
    out = run({"MAPTILER_KEY": "FROM_ENV"}, env_file="MAPTILER_KEY=FROM_FILE\n")
    check("muhit o'zgaruvchisi .env.local dan ustun",
          "--dart-define=MAPTILER_KEY=FROM_ENV" in out, out[-200:])

    # 5) Sir git'ga tushmasligi
    gitignore = open(os.path.join(ROOT, ".gitignore")).read()
    check(".env.local git'ga tushmaydi (sir saqlanadi)",
          ".env.local" in gitignore, "gitignore'da yo'q — kalit git'ga tushadi")

    tracked = subprocess.run(
        ["git", "ls-files", ".env.local"], cwd=ROOT,
        capture_output=True, text=True).stdout.strip()
    check(".env.local git'da kuzatilmayapti", tracked == "", tracked)

    report()


def report():
    print()
    for x in ok:
        print("  ✓", x)
    if fail:
        print(f"\nYIQILDI ({len(fail)}):")
        for x in fail:
            print("  ✗", x)
        sys.exit(1)
    print(f"\nOK: {len(ok)} ta tekshiruv o'tdi")
    sys.exit(0)


main()
