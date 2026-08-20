#!/usr/bin/env python3
"""Bosh sahifa kartalari uchun rasm fonini SHAFFOF qiladi.

MUAMMO
------
Bo'lim rasmlari (3D render) turli fonli edi:
    calorie_counter  → oq       (255,255,255)
    my_plans         → kulrang-ko'k (212,212,224)
    smart_shopping   → och kulrang  (246,246,248)

Kartada ular yonma-yon turgani uchun fon farqi ko'zga tashlanardi —
ba'zi kartalarda rasm chekkasi to'rtburchak bo'lib "uzuq" ko'rinardi.

YECHIM
------
Rasm CHETLARIDAN boshlab flood fill (to'lqinli to'ldirish) qilinadi:
chetdagi pikselga rangi YAQIN bo'lgan qo'shnilar fon deb belgilanadi va
shaffof qilinadi. Predmet ichidagi oq joylar (masalan oq raqamlar)
tegilmaydi, chunki ular chetga ULANMAGAN.

NEGA oddiy "oq rangni o'chirish" emas: u predmet ichidagi oq joylarni
ham teshib yuborardi (kalendar varag'i, oq matn).

CHEKKANI YUMSHATISH
-------------------
Keskin kesilgan chekka "arra tishi" bo'lib ko'rinadi. Shuning uchun
alpha kanali biroz xiralashtiriladi (blur) va qayta o'tkirlashtiriladi —
chekka silliq chiqadi.

ISHLATISH
---------
    python3 scripts/rasm_fonini_tozalash.py

Natija: assets/images/<nom>_shaffof.png
Asl JPG fayllar TEGILMAYDI (kerak bo'lsa qaytish uchun).
"""
from collections import deque
from pathlib import Path

from PIL import Image, ImageFilter

# Loyiha ildizi (skript scripts/ ichida)
ILDIZ = Path(__file__).resolve().parents[1]
RASMLAR = ILDIZ / "assets" / "images"

# Fon deb hisoblash uchun ruxsat etilgan rang farqi.
# Kattaroq qiymat ko'proq narsani fon deb biladi (predmetni yeb qo'yishi mumkin),
# kichikroq qiymat esa fonning bir qismini qoldiradi.
# 42 — sinovda barcha 6 rasm uchun to'g'ri ishladi.
BAGRILIK = 42
FAYLLAR = [
    "calorie_counter.jpg",
    "fitness_trainer.jpg",
    "my_plans.jpg",
    "my_finance.jpg",
    "smart_shopping.jpg",
    "majburolovchi.jpg",
]

# Ba'zi rasmlarga alohida bag'rilik kerak.
#
# my_plans (kalendar): kalendar varag'i OQ va foni ham OQ-kulrang.
# Umumiy 42 bag'rilikda flood fill kalendarga "kirib" ketib, uni
# yeb qo'yardi. 16 ga tushirilganda faqat haqiqiy fon olinadi va
# kalendar butun qoladi.
MAXSUS_BAGRILIK = {
    "my_plans.jpg": 16,
    # smart_shopping: foni juda och kulrang (246,246,248) va predmet
    # ham ochroq joylarga ega. 40 sinovda eng yaxshi natija berdi
    # (30 da fon atigi 3.9% aniqlandi — ya.ni ishlamadi).
    "smart_shopping.jpg": 40,
}

# JPG siqilishi tufayli fon chetlarida ingichka "arqon" qolishi mumkin.
# Bu qiymat shaffof zonani ichkariga qarab shuncha piksel kengaytiradi,
# ya'ni qolgan izlarni ham yeydi. Juda katta qilinsa predmet chetini yeydi.
CHET_TOZALASH = 2


def fonni_ajrat(yol: Path, bagrilik: int = BAGRILIK) -> tuple[Path, float]:
    """Rasmning fonini shaffof qiladi. (natija_yoli, fon_foizi) qaytaradi."""
    im = Image.open(yol).convert("RGBA")
    w, h = im.size
    px = im.load()

    # Chetdagi barcha piksellardan boshlaymiz — fon albatta chetda bo'ladi.
    navbat: deque[tuple[int, int]] = deque()
    fon = bytearray(w * h)  # 0 = predmet, 1 = fon

    def qosh(x: int, y: int) -> None:
        i = y * w + x
        if not fon[i]:
            fon[i] = 1
            navbat.append((x, y))

    # Chet piksellarini urug' sifatida olamiz
    urugler = []
    for x in range(w):
        urugler.append((x, 0))
        urugler.append((x, h - 1))
    for y in range(h):
        urugler.append((0, y))
        urugler.append((w - 1, y))

    # Chet ranglarining o'rtachasi = etalon fon rangi
    ranglar = [px[x, y][:3] for x, y in urugler]
    etalon = tuple(sum(c[k] for c in ranglar) // len(ranglar) for k in range(3))

    def fonmi(rang: tuple[int, ...]) -> bool:
        # Manxetten masofasi — tez va bu vazifa uchun yetarli aniq
        return sum(abs(rang[k] - etalon[k]) for k in range(3)) < bagrilik * 3

    for x, y in urugler:
        if fonmi(px[x, y][:3]):
            qosh(x, y)

    # To'lqinli to'ldirish: fon faqat chetdan ULANGAN joylarga tarqaladi
    while navbat:
        x, y = navbat.popleft()
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and not fon[ny * w + nx]:
                if fonmi(px[nx, ny][:3]):
                    qosh(nx, ny)

    # Alpha kanalini quramiz
    alpha = Image.new("L", (w, h), 255)
    ap = alpha.load()
    fon_soni = 0
    for y in range(h):
        satr = y * w
        for x in range(w):
            if fon[satr + x]:
                ap[x, y] = 0
                fon_soni += 1

    # Fon zonasini ichkariga kengaytiramiz (MinFilter = eroziya).
    # JPG siqilishidan qolgan ingichka fon "arqon"larini yeydi.
    if CHET_TOZALASH > 0:
        alpha = alpha.filter(ImageFilter.MinFilter(CHET_TOZALASH * 2 + 1))

    # Chekkani silliqlash: blur -> kontrastni tiklash.
    # Blursiz chekka "arra tishi" bo'lib ko'rinadi.
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.8))
    alpha = alpha.point(lambda v: 0 if v < 110 else (255 if v > 165 else v))

    im.putalpha(alpha)

    natija = yol.with_name(yol.stem + "_shaffof.png")
    im.save(natija, "PNG", optimize=True)
    return natija, fon_soni / (w * h) * 100


def main() -> None:
    print(f"Fon tozalanmoqda ({len(FAYLLAR)} ta rasm)...\n")
    for nom in FAYLLAR:
        yol = RASMLAR / nom
        if not yol.exists():
            print(f"  ⚠ topilmadi: {nom}")
            continue
        natija, foiz = fonni_ajrat(yol, MAXSUS_BAGRILIK.get(nom, BAGRILIK))
        olcham = natija.stat().st_size / 1024
        print(f"  ✓ {nom:24} fon {foiz:5.1f}%  →  {natija.name} ({olcham:.0f} KB)")

    print("\nTayyor. Asl JPG fayllar tegilmadi.")


if __name__ == "__main__":
    main()
