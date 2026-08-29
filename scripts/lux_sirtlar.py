#!/usr/bin/env python3
"""OQ/kulrang SIRT ranglarini lux qora sirtlariga ko'chiradi.

NEGA ALOHIDA SKRIPT: `Colors.white` ikki xil rolda ishlatiladi —
  • FON (karta, panel, tugma orqasi)  -> qora sirtga o'tishi KERAK
  • MATN/IKON rangi (rasm yoki rangli tugma ustida) -> O'ZGARMASLIGI kerak
Ko'r-ko'rona almashtirish oq matnni qora qilib, uni ko'rinmas holga
keltiradi. Shuning uchun bu skript KONTEKSTNI tekshiradi.

FON deb hisoblanadi (almashtiriladi):
  • `decoration: BoxDecoration(` bloki ichidagi `color:`
  • `backgroundColor:`, `fillColor:`, `surfaceTintColor:`, `cardColor:`
  • `Container(color:`, `Material(color:`, `ColoredBox(color:`
  • `scaffoldBackgroundColor:`

MATN deb hisoblanadi (tegilmaydi):
  • `TextStyle(...)` ichidagi `color:`
  • `Icon(...)` ning `color:` argumenti
  • `foregroundColor:`, `iconColor:`, `shadowColor:`, `splashColor:`

Ishlatish:
    python3 scripts/lux_sirtlar.py --tekshir
    python3 scripts/lux_sirtlar.py
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import Counter
from pathlib import Path

ILDIZ = Path(__file__).resolve().parent.parent
LIB = ILDIZ / "lib"

CHETLATILGAN = {
    "lib/theme/lux_tokens.dart",
    "lib/theme/app_theme.dart",
    "lib/theme/glass_tokens.dart",
    "lib/l10n/translations.dart",
    "lib/screens/home_screen.dart",
    "lib/screens/all_categories_screen.dart",
    "lib/widgets/home_promo_section.dart",
    "lib/widgets/home_header_widget.dart",
    "lib/widgets/daily_utilities_widget.dart",
    "lib/widgets/search_input_widget.dart",
    "lib/widgets/glass/glass_bottom_bar.dart",
    "lib/widgets/glass/mesh_background.dart",
}

# Fon rolidagi nomlangan argumentlar.
FON_ARGUMENTLARI = (
    "backgroundColor",
    "fillColor",
    "cardColor",
    "surfaceTintColor",
    "scaffoldBackgroundColor",
    "barBackgroundColor",
)

# Oq/kulrang -> lux sirt. Kulrang darajalari: past = och = "ko'tarilgan" yuza.
SIRT_ALMASH = {
    "Colors.white": "LuxTokens.surface",
    "Colors.white70": "LuxTokens.surfaceHigh",
    "Colors.white60": "LuxTokens.surfaceHigh",
    "Colors.grey.shade50": "LuxTokens.surfaceHigh",
    "Colors.grey.shade100": "LuxTokens.surfaceHigh",
    "Colors.grey.shade200": "LuxTokens.border",
    "Colors.grey.shade300": "LuxTokens.border",
    "Colors.grey[50]": "LuxTokens.surfaceHigh",
    "Colors.grey[100]": "LuxTokens.surfaceHigh",
    "Colors.grey[200]": "LuxTokens.border",
    "Colors.grey[300]": "LuxTokens.border",
}

# Kulrang MATN ranglari (600-800) -> lux xira matn. Bular fon emas,
# shuning uchun kontekstdan qat'i nazar almashtiriladi.
MATN_ALMASH = {
    "Colors.grey[400]": "LuxTokens.textFaint",
    "Colors.grey[500]": "LuxTokens.textFaint",
    "Colors.grey[600]": "LuxTokens.textMuted",
    "Colors.grey[700]": "LuxTokens.textMuted",
    "Colors.grey[800]": "LuxTokens.textMuted",
    "Colors.grey.shade400": "LuxTokens.textFaint",
    "Colors.grey.shade500": "LuxTokens.textFaint",
    "Colors.grey.shade600": "LuxTokens.textMuted",
    "Colors.grey.shade700": "LuxTokens.textMuted",
    "Colors.grey.shade800": "LuxTokens.textMuted",
    "Colors.black87": "LuxTokens.text",
    "Colors.black54": "LuxTokens.textMuted",
    "Colors.black45": "LuxTokens.textFaint",
}

IMPORT_NAQSH = re.compile(r"^import\s+['\"].+['\"];", re.M)

_kalitlar = sorted(
    set(SIRT_ALMASH) | set(MATN_ALMASH), key=len, reverse=True
)
# `(?!\w|\.with)` — ikki himoya:
#   • `\w`     — "Colors.white70" ni "Colors.white" deb qirqmaslik uchun.
#   • `\.with` — `Colors.white.withValues(alpha: 0.2)` bu SHAFFOF QATLAM
#     (rangli gradient ustidagi yorug'lik urg'usi), fon emas. Uni qora
#     sirtga aylantirsak urg'u yo'qoladi va element yassi ko'rinadi.
_RANG = "(?:" + "|".join(re.escape(k) for k in _kalitlar) + r")(?!\w|\.with)"

# 1) Nomlangan fon argumenti: `backgroundColor: Colors.white`
FON_ARG_NAQSH = re.compile(
    r"(?P<arg>" + "|".join(FON_ARGUMENTLARI) + r")(?P<sep>:\s*)"
    r"(?P<rang>" + _RANG + r")"
)

# 2) `decoration: BoxDecoration(` blokidagi `color:` — matn oqimida
#    izlanadi, chunki Dart ichma-ich qavslarni regex bilan to'liq
#    tahlil qilib bo'lmaydi. Shuning uchun 400 belgi oynasi ichida
#    `color:` birinchi marta uchraganda fon deb hisoblanadi.
DEKOR_NAQSH = re.compile(
    r"(?P<bosh>(?:BoxDecoration|ShapeDecoration)\(\s*"
    r"(?:[^()]{0,200}?)?"
    r"color:\s*)"
    r"(?P<rang>" + _RANG + r")"
)

# 3) To'g'ridan-to'g'ri vidjet foni: `Container(color: ...)`
VIDJET_NAQSH = re.compile(
    r"(?P<bosh>(?:Container|ColoredBox|Material|Card)\(\s*color:\s*)"
    r"(?P<rang>" + _RANG + r")"
)

# 4) Matn/ikon ranglari — kontekstsiz almashtiriladi.
MATN_NAQSH = re.compile(
    "(?:"
    + "|".join(
        re.escape(k) for k in sorted(MATN_ALMASH, key=len, reverse=True)
    )
    + r")(?!\w|\.with)"
)


def lux_import_yoli(nisbiy: str) -> str:
    qismlar = nisbiy.split("/")[1:-1]
    if qismlar == ["theme"]:
        return "import 'lux_tokens.dart';"
    return f"import '{'../' * len(qismlar)}theme/lux_tokens.dart';"


def import_qoshish(matn: str, nisbiy: str) -> str:
    # `part` fayllar O'ZI import yoza olmaydi (Dart qoidasi): ular ota
    # kutubxonaning importlarini meros oladi. Import qo'shsak
    # `non_part_of_directive_in_part` xatosi chiqadi. Import ota-faylga
    # qo'lda qo'shilgan.
    if re.search(r"^part\s+of\s+", matn, re.M):
        return matn
    if "theme/lux_tokens.dart" in matn or "import 'lux_tokens.dart';" in matn:
        return matn
    qator = lux_import_yoli(nisbiy)
    mos = list(IMPORT_NAQSH.finditer(matn))
    if not mos:
        return qator + "\n" + matn
    return matn[: mos[-1].end()] + "\n" + qator + matn[mos[-1].end() :]


def almashtir(matn: str, nisbiy: str) -> tuple[str, Counter]:
    hisob: Counter = Counter()
    asl = matn

    def _fon(m: re.Match[str]) -> str:
        rang = m.group("rang")
        yangi = SIRT_ALMASH.get(rang) or MATN_ALMASH.get(rang)
        if yangi is None:
            return m.group(0)
        hisob[f"fon: {rang} -> {yangi}"] += 1
        return m.group(0)[: -len(rang)] + yangi

    for naqsh in (FON_ARG_NAQSH, DEKOR_NAQSH, VIDJET_NAQSH):
        matn = naqsh.sub(_fon, matn)

    def _matn(m: re.Match[str]) -> str:
        rang = m.group(0)
        yangi = MATN_ALMASH[rang]
        hisob[f"matn: {rang} -> {yangi}"] += 1
        return yangi

    matn = MATN_NAQSH.sub(_matn, matn)

    if matn != asl:
        matn = import_qoshish(matn, nisbiy)
    return matn, hisob


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--tekshir", action="store_true")
    args = p.parse_args()

    jami: Counter = Counter()
    tegilgan: list[tuple[str, int]] = []

    for fayl in sorted(LIB.rglob("*.dart")):
        nisbiy = fayl.relative_to(ILDIZ).as_posix()
        if nisbiy in CHETLATILGAN:
            continue
        asl = fayl.read_text(encoding="utf-8")
        yangi, hisob = almashtir(asl, nisbiy)
        if not hisob:
            continue
        jami.update(hisob)
        tegilgan.append((nisbiy, sum(hisob.values())))
        if not args.tekshir:
            fayl.write_text(yangi, encoding="utf-8")

    rejim = "TEKSHIRUV" if args.tekshir else "QO'LLANDI"
    print(f"── Lux sirtlar: {rejim} ──")
    print(f"Fayllar: {len(tegilgan)}   Almashtirishlar: {sum(jami.values())}")
    print("\nEng ko'p:")
    for nom, n in jami.most_common(20):
        print(f"  {n:4}  {nom}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
