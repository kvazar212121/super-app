#!/usr/bin/env python3
"""Butun ilovani "qora + oltin" premium palitraga ko'chiradi.

NEGA SKRIPT: 346 ta Dart faylida rang qiymatlari qattiq kodlangan
(0xFF6366F1 kabi). Qo'lda o'zgartirish uzoq va xatoga moyil. Skript
bir xil qoidani hamma joyda qo'llaydi va qayta ishga tushirilsa ham
natija o'zgarmaydi (idempotent).

QAMROV (nima o'zgaradi):
  1. BREND urg'u ranglari (ko'k/indigo/binafsha) -> oltin.
  2. Slate/gray SIRT ranglari -> lux qora sirtlar.
  3. Matn ranglari -> lux matn ierarxiyasi.

NIMA O'ZGARMAYDI (ataylab):
  • Semantik ranglar: yashil (muvaffaqiyat), qizil (xato/o'chirish),
    sariq/to'q sariq (ogohlantirish). Ular MA'NO tashiydi, bezak emas.
    Ularni oltinga aylantirish holatni o'qib bo'lmas qilardi.
  • `Colors.white` — juda ko'p kontekstda ishlatiladi (rasm ustidagi
    matn, tugma ichidagi yozuv). Ko'r-ko'rona almashtirish xavfli,
    shuning uchun alohida, qo'lda ko'rib chiqiladi.

Ishlatish:
    python3 scripts/lux_migratsiya.py --tekshir   # faqat hisobot
    python3 scripts/lux_migratsiya.py             # o'zgartiradi
"""

from __future__ import annotations

import argparse
import re
import sys
from collections import Counter
from pathlib import Path

ILDIZ = Path(__file__).resolve().parent.parent
LIB = ILDIZ / "lib"

# Tegilmaydigan fayllar: palitra manbai, tarjimalar va ALLAQACHON qo'lda
# lux'ga ko'chirilgan fayllar. Oxirgilarida `isDark ? lux : eski` shaklidagi
# ikki tarmoqli mantiq bor; ularni ko'r-ko'rona almashtirish light tarmog'ini
# buzadi va kod chalkashadi.
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

# ── 1. BREND urg'u ranglari -> oltin ────────────────────────────────
# Chapdagi qiymat "bu element muhim/bosiladigan" degan ma'noda
# ishlatilgan. Premium palitrada bu rol OLTINGA tegishli.
BREND = {
    "0xFF6366F1": "0xFFC9A227",  # indigo   -> oltin
    "0xFF3B82F6": "0xFFC9A227",  # ko'k     -> oltin
    "0xFF2563EB": "0xFFB8921F",  # to'q ko'k-> to'q oltin
    "0xFF4F46E5": "0xFFB8921F",  # indigo-6 -> to'q oltin
    "0xFF8B5CF6": "0xFFE3C766",  # binafsha -> ochiq oltin
    "0xFFA855F7": "0xFFE3C766",  # binafsha -> ochiq oltin
    "0xFF7C3AED": "0xFFB8921F",  # binafsha -> to'q oltin
    "0xFF06B6D4": "0xFFE3C766",  # cyan     -> ochiq oltin
    "0xFF0EA5E9": "0xFFC9A227",  # ko'k     -> oltin
    "0xFF60A5FA": "0xFFE3C766",  # och ko'k -> ochiq oltin
    "0xFF93C5FD": "0xFFEBD79B",  # och ko'k -> juda och oltin
    "0xFF818CF8": "0xFFE3C766",
    "0xFFEC4899": "0xFFE3C766",  # pushti   -> ochiq oltin
    "0xFFF472B6": "0xFFEBD79B",
    "0xFF1D4ED8": "0xFF9C7B15",
    "0xFF1E40AF": "0xFF6E5A1E",  # to'q ko'k tasma -> to'q oltin
    "0xFF4338CA": "0xFF9C7B15",
    "0xFF0D9488": "0xFFB8921F",  # teal     -> to'q oltin
}

# ── 2. SIRT ranglari -> lux qora sirtlar ────────────────────────────
# Slate palitrasi (Tailwind) qora-ko'kish, lux esa neytral qora.
# Yonma-yon turganda farq sezilib, ekran "yamoq" bo'lib ko'rinadi.
SIRT = {
    "0xFF0B0B1A": "0xFF0A0A0B",  # eski sahifa foni
    "0xFF0F172A": "0xFF0A0A0B",  # slate-900
    "0xFF0F1724": "0xFF0A0A0B",
    "0xFF111827": "0xFF0A0A0B",  # gray-900
    "0xFF1E1E2E": "0xFF141416",
    "0xFF1E293B": "0xFF141416",  # slate-800
    "0xFF1F2937": "0xFF141416",  # gray-800
    "0xFF151530": "0xFF141416",
    "0xFF334155": "0xFF26262A",  # slate-700 (chegara)
    "0xFF374151": "0xFF26262A",  # gray-700
    "0xFF475569": "0xFF33333A",  # slate-600
}

# ── 3. MATN ranglari -> lux ierarxiya ───────────────────────────────
MATN = {
    "0xFFF8FAFC": "0xFFF2F2F0",  # slate-50  -> asosiy matn
    "0xFFF1F5F9": "0xFFF2F2F0",  # slate-100 -> asosiy matn
    "0xFFE2E8F0": "0xFFD6D6D2",  # slate-200
    "0xFFCBD5E1": "0xFF9A9A96",  # slate-300 -> ikkilamchi
    "0xFF94A3B8": "0xFF9A9A96",  # slate-400 -> ikkilamchi
    "0xFF64748B": "0xFF6B6B68",  # slate-500 -> xira
    "0xFF6B7280": "0xFF6B6B68",  # gray-500  -> xira
    "0xFF9CA3AF": "0xFF9A9A96",  # gray-400
}

XARITA: dict[str, str] = {**BREND, **SIRT, **MATN}

# Kichik/katta harf farqiga bardosh: 0xff6366f1 ham topiladi.
NAQSH = re.compile(
    "|".join(re.escape(k) for k in XARITA), re.IGNORECASE
)
PAST_XARITA = {k.lower(): v for k, v in XARITA.items()}

# ── 4. Material rang KONSTANTALARI -> oltin ─────────────────────────
# `Colors.blue` kabi nomlar ham brend urg'usi sifatida ishlatilgan
# (chat pufagi, ikon foni). Ular hex emas, shuning uchun alohida naqsh.
#
# DIQQAT: `Colors.green/red/orange/amber` TEGILMAYDI — semantik.
MATERIAL = {
    "Colors.blueAccent": "LuxTokens.goldSoft",
    "Colors.lightBlueAccent": "LuxTokens.goldSoft",
    "Colors.lightBlue": "LuxTokens.goldSoft",
    "Colors.blueGrey": "LuxTokens.textMuted",
    "Colors.blue": "LuxTokens.gold",
    "Colors.indigoAccent": "LuxTokens.goldSoft",
    "Colors.indigo": "LuxTokens.gold",
    "Colors.deepPurpleAccent": "LuxTokens.goldSoft",
    "Colors.deepPurple": "LuxTokens.gold",
    "Colors.purpleAccent": "LuxTokens.goldSoft",
    "Colors.purple": "LuxTokens.gold",
    "Colors.cyanAccent": "LuxTokens.goldSoft",
    "Colors.cyan": "LuxTokens.gold",
    "Colors.tealAccent": "LuxTokens.goldSoft",
    "Colors.teal": "LuxTokens.gold",
    "Colors.pinkAccent": "LuxTokens.goldSoft",
    "Colors.pink": "LuxTokens.gold",
}
# Uzunroq nomlar oldin kelishi kerak ("Colors.blueAccent" "Colors.blue" dan
# oldin), aks holda qisman moslik bo'ladi. `sorted(key=len, reverse=True)`
# shuni ta'minlaydi.
#
# `(?!\w|\.shade)` — ikki himoya:
#   • `\w` — "Colors.blueGrey" ni "Colors.blue" deb qirqib olmaslik uchun.
#   • `\.shade` — `Colors.blue.shade700` MaterialColor'ga tegishli; oddiy
#     `Color` da `.shade` YO'Q, almashtirsak kod kompilyatsiya bo'lmaydi.
#     Bunday joylar alohida, qo'lda ko'rib chiqiladi.
MATERIAL_NAQSH = re.compile(
    "(?:"
    + "|".join(
        re.escape(k) for k in sorted(MATERIAL, key=len, reverse=True)
    )
    + r")(?!\w|\.shade)"
)

# `LuxTokens` ishlatilsa import kerak. Nisbiy yo'l fayl chuqurligiga bog'liq.
IMPORT_NAQSH = re.compile(r"^import\s+['\"].+['\"];", re.M)

# ── 5. `Colors.blue.shade700` shakli ────────────────────────────────
# MaterialColor darajalari (50..900) yorug'likni bildiradi: 50 eng och,
# 900 eng to'q. Ularni oltin shkalasiga shu mantiq bilan o'tkazamiz.
# Alohida ko'rib chiqiladi, chunki `LuxTokens.gold.shade700` mavjud emas.
SHADE_NAQSH = re.compile(
    r"Colors\.(?:blue|teal|cyan|purple|deepPurple|pink|indigo|lightBlue)"
    r"(?:Accent)?\.shade(\d+)"
)
SHADE_XARITA = {
    50: "LuxTokens.gold.withValues(alpha: 0.10)",
    100: "LuxTokens.gold.withValues(alpha: 0.16)",
    200: "LuxTokens.gold.withValues(alpha: 0.30)",
    300: "LuxTokens.goldSoft",
    400: "LuxTokens.goldSoft",
    500: "LuxTokens.gold",
    600: "LuxTokens.gold",
    700: "LuxTokens.goldDim",
    800: "LuxTokens.goldDim",
    900: "LuxTokens.goldDim",
}


def lux_import_yoli(nisbiy: str) -> str:
    """`lib/...` yo'lidan `lux_tokens.dart` ga nisbiy import qatorini yasaydi."""
    # lib/screens/calorie/x.dart -> chuqurlik 2 (screens, calorie)
    qismlar = nisbiy.split("/")[1:-1]  # "lib" va fayl nomini tashlaymiz
    if qismlar == ["theme"]:
        return "import 'lux_tokens.dart';"
    yuqoriga = "../" * len(qismlar)
    return f"import '{yuqoriga}theme/lux_tokens.dart';"


def import_qoshish(matn: str, nisbiy: str) -> str:
    # `part` fayllar O'ZI import yoza olmaydi (Dart qoidasi): ular ota
    # kutubxonaning importlarini meros oladi. Import qo'shsak
    # `non_part_of_directive_in_part` xatosi chiqadi. Import ota-faylga
    # qo'lda qo'shilgan.
    if re.search(r"^part\s+of\s+", matn, re.M):
        return matn
    """Faylga LuxTokens importini qo'shadi (agar hali bo'lmasa)."""
    if "theme/lux_tokens.dart" in matn or "import 'lux_tokens.dart';" in matn:
        return matn
    qator = lux_import_yoli(nisbiy)
    mos = list(IMPORT_NAQSH.finditer(matn))
    if not mos:
        return qator + "\n" + matn
    # Oxirgi import qatoridan KEYIN qo'yamiz — import bloki buzilmaydi.
    oxirgi = mos[-1]
    return matn[: oxirgi.end()] + "\n" + qator + matn[oxirgi.end() :]


def almashtir(matn: str, nisbiy: str) -> tuple[str, Counter]:
    hisob: Counter = Counter()
    asl_matn = matn

    def _hex(m: re.Match[str]) -> str:
        eski = m.group(0)
        yangi = PAST_XARITA[eski.lower()]
        if eski.lower() == yangi.lower():
            return eski
        hisob[f"{eski.upper()} -> {yangi}"] += 1
        return yangi

    matn = NAQSH.sub(_hex, matn)

    def _material(m: re.Match[str]) -> str:
        eski = m.group(0)
        yangi = MATERIAL[eski]
        hisob[f"{eski} -> {yangi}"] += 1
        return yangi

    yangi_matn = MATERIAL_NAQSH.sub(_material, matn)

    def _shade(m: re.Match[str]) -> str:
        daraja = int(m.group(1))
        yangi = SHADE_XARITA.get(daraja)
        if yangi is None:
            return m.group(0)
        hisob[f"{m.group(0)} -> {yangi}"] += 1
        return yangi

    yangi_matn = SHADE_NAQSH.sub(_shade, yangi_matn)

    if yangi_matn != asl_matn:
        yangi_matn = import_qoshish(yangi_matn, nisbiy)
    return yangi_matn, hisob


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument(
        "--tekshir",
        action="store_true",
        help="Fayllarni o'zgartirmasdan faqat hisobot chiqaradi",
    )
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

    rejim = "TEKSHIRUV (hech nima o'zgarmadi)" if args.tekshir else "QO'LLANDI"
    print(f"── Lux migratsiya: {rejim} ──")
    print(f"Fayllar: {len(tegilgan)}   Almashtirishlar: {sum(jami.values())}")
    print("\nEng ko'p almashtirishlar:")
    for nom, n in jami.most_common(15):
        print(f"  {n:4}  {nom}")
    print("\nEng ko'p tegilgan fayllar:")
    for nom, n in sorted(tegilgan, key=lambda x: -x[1])[:15]:
        print(f"  {n:4}  {nom}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
