#!/usr/bin/env python3
"""Migratsiyadan keyin XAVFLI naqshlarni topadi (kontrast buzilishi).

NEGA KERAK: `lux_sirtlar.py` kontekst bo'yicha almashtiradi, lekin regex
Dart AST emas. Ayrim holatlar noto'g'ri tushunilishi mumkin:

  1. QORA USTIDA QORA — `LuxTokens.surface` (deyarli qora) MATN rangi
     sifatida ishlatilsa, qora fonda matn ko'rinmaydi.
  2. OLTIN USTIDA OLTIN — oltin fon + oltin matn.
  3. Rangli/rasm gradient ustidagi OQ matn qora bo'lib qolgan bo'lsa.

Bu tekshiruv `flutter analyze` topa olmaydigan xatolarni ko'radi:
kod TO'G'RI kompilyatsiya bo'ladi, lekin ekran o'qib bo'lmas bo'ladi.

Ishlatish:  python3 scripts/lux_kontrast_tekshir.py
Chiqish kodi: 0 = toza, 1 = shubhali joylar bor.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ILDIZ = Path(__file__).resolve().parent.parent
LIB = ILDIZ / "lib"

# Qora/deyarli qora qiymatlar — MATN rangi sifatida shubhali.
QORA_SIRTLAR = ("LuxTokens.surface", "LuxTokens.surfaceHigh", "LuxTokens.bg")

# 1) `TextStyle(... color: LuxTokens.surface ...)` — qora matn.
MATN_QORA = re.compile(
    r"TextStyle\((?:[^()]|\([^()]*\)){0,300}?color:\s*"
    r"(?P<rang>" + "|".join(re.escape(q) for q in QORA_SIRTLAR) + r")\b"
)

# 2) `Icon(..., color: LuxTokens.surface)` — qora ikon.
IKON_QORA = re.compile(
    r"Icon\((?:[^()]|\([^()]*\)){0,200}?color:\s*"
    r"(?P<rang>" + "|".join(re.escape(q) for q in QORA_SIRTLAR) + r")\b"
)

# 3) `foregroundColor: LuxTokens.surface` — tugma matni qora.
OLD_QORA = re.compile(
    r"(?:foregroundColor|iconColor|labelColor|selectedItemColor|"
    r"unselectedItemColor|indicatorColor)\s*:\s*"
    r"(?P<rang>" + "|".join(re.escape(q) for q in QORA_SIRTLAR) + r")\b"
)

TEKSHIRUVLAR = [
    ("QORA MATN (TextStyle)", MATN_QORA),
    ("QORA IKON (Icon)", IKON_QORA),
    ("QORA old plan (foregroundColor va h.k.)", OLD_QORA),
]


def qator_raqami(matn: str, ofset: int) -> int:
    return matn.count("\n", 0, ofset) + 1


def main() -> int:
    topilgan: list[tuple[str, str, int, str]] = []

    for fayl in sorted(LIB.rglob("*.dart")):
        matn = fayl.read_text(encoding="utf-8")
        if "LuxTokens" not in matn:
            continue
        nisbiy = fayl.relative_to(ILDIZ).as_posix()
        for nom, naqsh in TEKSHIRUVLAR:
            for m in naqsh.finditer(matn):
                qator = qator_raqami(matn, m.start())
                parcha = matn.splitlines()[qator - 1].strip()[:90]
                topilgan.append((nom, nisbiy, qator, parcha))

    if not topilgan:
        print("✓ Kontrast tekshiruvi: shubhali joy topilmadi.")
        return 0

    print(f"⚠ {len(topilgan)} ta shubhali joy (qora fonda qora element):\n")
    for nom, fayl, qator, parcha in topilgan:
        print(f"  [{nom}]")
        print(f"    {fayl}:{qator}")
        print(f"    {parcha}\n")
    return 1


if __name__ == "__main__":
    sys.exit(main())
