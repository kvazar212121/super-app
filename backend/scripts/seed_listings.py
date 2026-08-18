"""Demo SAVDO e'lonlari — OLX kabi turli buyumlar.

Har toifadan (telefon, kompyuter, avto, mebel...) bir nechta e'lon
yaratadi. E'lonlar DEMO FOYDALANUVCHILAR nomidan bo'ladi, shunda
haqiqiy foydalanuvchi qidirganda ular ko'rinadi (o'z e'loni
qidiruvda ko'rinmaydi — bu ataylab shunday).

Rasm: `assets/images/services3d/` dagi mavjud fayllar ishlatiladi
(`/uploads/services3d/...`). Har e'londa 3 ta rasm — minimal talab.

Ishlatish (serverda):
    CID=$(docker compose ps -q backend | head -1)
    docker cp scripts/seed_listings.py "$CID":/app/seed_listings.py
    docker exec "$CID" python /app/seed_listings.py

⚠️ Mavjud e'lonlarga TEGMAYDI. Qayta yurgizilsa faqat yetishmaganini
   qo'shadi (nom bo'yicha tekshiradi).
"""
from __future__ import annotations

import argparse
import asyncio
import os
import random
import sys
from datetime import datetime, timedelta, timezone

_ILDIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _ILDIZ not in sys.path:
    sys.path.insert(0, _ILDIZ)
if "/app" not in sys.path and os.path.isdir("/app/app"):
    sys.path.insert(0, "/app")

# Har toifa uchun demo e'lonlar.
# (nom, narx, valyuta, holat, atributlar, tavsif)
ELONLAR: dict[str, list[tuple]] = {
    "telefon": [
        ("iPhone 14 Pro 256GB", 8_500_000, "UZS", "like_new",
         {"model": "iPhone 14 Pro", "xotira": "256GB", "rang": "Deep Purple"},
         "Ideal holatda, qutisi va hujjati bor. Ekranda birorta ham "
         "chizilgan joy yo'q, batareya salomatligi 92%."),
        ("Samsung Galaxy S23 Ultra", 9_200_000, "UZS", "good",
         {"model": "S23 Ultra", "xotira": "512GB", "rang": "Qora"},
         "Bir yil ishlatilgan, ishlashi zo'r. Kamerasi juda yaxshi, "
         "S-Pen qalami bor."),
        ("Redmi Note 13 Pro", 2_900_000, "UZS", "new",
         {"model": "Redmi Note 13 Pro", "xotira": "256GB"},
         "Yangi, ochilmagan. Kafolat bilan, rasmiy do'kondan olingan."),
        ("iPhone 11 128GB", 3_400_000, "UZS", "used",
         {"model": "iPhone 11", "xotira": "128GB"},
         "Ishlatilgan, lekin yaxshi holatda. Ekran almashtirilgan, "
         "qolgan hammasi original."),
        ("Xiaomi Poco X6", 3_100_000, "UZS", "like_new",
         {"model": "Poco X6", "xotira": "256GB"},
         "3 oy ishlatilgan, chizilgan joyi yo'q. Zaryadlagichi bor."),
    ],
    "kompyuter": [
        ("MacBook Air M2 2023", 13_500_000, "UZS", "like_new",
         {"model": "MacBook Air M2", "protsessor": "Apple M2",
          "ram": "8GB", "xotira": "256GB SSD"},
         "Deyarli yangi, sikl soni 80 dan kam. Original quti va "
         "zaryadlagich bilan."),
        ("Lenovo IdeaPad Gaming 3", 7_800_000, "UZS", "good",
         {"model": "IdeaPad Gaming 3", "protsessor": "Ryzen 5 5600H",
          "ram": "16GB", "xotira": "512GB SSD", "videokarta": "RTX 3050"},
         "O'yin uchun zo'r noutbuk. Barcha zamonaviy o'yinlarni "
         "tortadi, sovutish tizimi tozalangan."),
        ("Gaming PC (RTX 4060)", 11_000_000, "UZS", "good",
         {"model": "Custom PC", "protsessor": "Intel i5-12400F",
          "ram": "32GB", "xotira": "1TB SSD", "videokarta": "RTX 4060"},
         "Yig'ma kompyuter, hammasi yaxshi ishlaydi. Monitor alohida "
         "kelishiladi."),
        ("HP EliteBook 840 G8", 6_200_000, "UZS", "used",
         {"model": "EliteBook 840", "protsessor": "Intel i7-1165G7",
          "ram": "16GB", "xotira": "512GB SSD"},
         "Ofis ishlari uchun ideal. Batareyasi 4-5 soat chidaydi."),
    ],
    "elektronika": [
        ("Samsung 55\" 4K Smart TV", 5_400_000, "UZS", "like_new",
         {"tur": "Televizor", "model": "UE55AU7100"},
         "Bir yil ishlatilgan, pikseli yaxshi. Devorga osadigan "
         "kronshteyni bilan."),
        ("Sony WH-1000XM4 quloqchin", 2_100_000, "UZS", "good",
         {"tur": "Quloqchin", "model": "WH-1000XM4"},
         "Shovqin bostirish funksiyasi zo'r ishlaydi. Futlyari bor."),
        ("iPad 10-avlod 64GB", 4_300_000, "UZS", "like_new",
         {"tur": "Planshet", "model": "iPad 10"},
         "Bolalar uchun ham, ish uchun ham. Ekrani himoya plyonkali."),
        ("JBL Charge 5 kolonka", 1_250_000, "UZS", "good",
         {"tur": "Kolonka", "model": "Charge 5"},
         "Ovozi baland va toza, suvdan himoyalangan."),
    ],
    "maishiy": [
        ("Artel muzlatgich 340L", 4_800_000, "UZS", "good",
         {"tur": "Muzlatgich", "brend": "Artel"},
         "3 yil ishlatilgan, sovutishi juda yaxshi. No Frost tizimi."),
        ("LG kir yuvish mashinasi 7kg", 3_900_000, "UZS", "like_new",
         {"tur": "Kir yuvish mashinasi", "brend": "LG"},
         "Kam ishlatilgan, barcha rejimlari ishlaydi. Inverter motor."),
        ("Changyutgich Samsung 2000W", 1_400_000, "UZS", "used",
         {"tur": "Changyutgich", "brend": "Samsung"},
         "Ishlaydi, so'rish kuchi yaxshi. Filtri yangi almashtirilgan."),
        ("Mikroto'lqinli pech LG", 900_000, "UZS", "good",
         {"tur": "Mikroto'lqinli pech", "brend": "LG"},
         "20 litrli, isitish va eritish rejimlari bor."),
    ],
    "avto": [
        ("Chevrolet Cobalt 2021", 145_000_000, "UZS", "good",
         {"model": "Cobalt", "yil": "2021", "probeg": "62000 km",
          "karobka": "Avtomat", "yoqilgi": "Benzin/Metan"},
         "Bir egasi bo'lgan, avariyaga tushmagan. Salon toza, "
         "texnik ko'rikdan o'tgan."),
        ("Chevrolet Malibu 2 2019", 235_000_000, "UZS", "good",
         {"model": "Malibu 2", "yil": "2019", "probeg": "88000 km",
          "karobka": "Avtomat", "yoqilgi": "Benzin"},
         "To'liq komplektatsiya, teri salon. Barcha xizmatlar "
         "rasmiy servisda qilingan."),
        ("Nexia 3 2018", 92_000_000, "UZS", "used",
         {"model": "Nexia 3", "yil": "2018", "probeg": "140000 km",
          "karobka": "Mexanika", "yoqilgi": "Benzin/Metan"},
         "Ishonchli mashina, dvigatel yaxshi ishlaydi. Metan bloki bor."),
        ("Spark 2020", 88_000_000, "UZS", "like_new",
         {"model": "Spark", "yil": "2020", "probeg": "45000 km",
          "karobka": "Avtomat"},
         "Shahar ichida yurish uchun ideal, yoqilg'ini kam yeydi."),
    ],
    "mebel": [
        ("Burchakli divan (yangi)", 4_500_000, "UZS", "new",
         {"tur": "Divan", "material": "Rogojka", "olcham": "280x180 sm"},
         "Yangi, fabrikadan. Yotoq sifatida ochiladi, ichida "
         "choyshab uchun joy bor."),
        ("Oshxona stoli + 6 stul", 2_800_000, "UZS", "good",
         {"tur": "Stol", "material": "Yog'och", "olcham": "160x90 sm"},
         "Massiv yog'ochdan, mustahkam. Bir oz ishlatilgan."),
        ("Yotoqxona garnituri", 7_200_000, "UZS", "like_new",
         {"tur": "Garnitur", "material": "MDF"},
         "Krovat, ikkita tumba va shkaf. Deyarli yangi holatda."),
        ("Yozuv stoli (bolalar uchun)", 950_000, "UZS", "good",
         {"tur": "Stol", "olcham": "120x60 sm"},
         "Balandligi rostlanadi, kitob javoni bilan."),
    ],
    "kiyim": [
        ("Erkaklar qishki kurtkasi", 650_000, "UZS", "like_new",
         {"tur": "Kurtka", "olcham": "L", "brend": "Columbia"},
         "Bir mavsum kiyilgan, issiq va yengil. Suv o'tkazmaydi."),
        ("Ayollar palto", 780_000, "UZS", "new",
         {"tur": "Palto", "olcham": "M", "brend": "Zara"},
         "Yangi, birkasi bilan. Rangi bej, kuz-qish uchun."),
        ("Nike Air Force 1 krossovka", 890_000, "UZS", "good",
         {"tur": "Poyabzal", "olcham": "42", "brend": "Nike"},
         "Original, bir necha marta kiyilgan. Qutisi bor."),
        ("Bolalar kiyim to'plami", 320_000, "UZS", "like_new",
         {"tur": "To'plam", "olcham": "5-6 yosh"},
         "5 ta komplekt, hammasi toza va butun."),
    ],
    "qurilish": [
        ("G'isht (qizil, 1000 dona)", 1_600_000, "UZS", "new",
         {"tur": "G'isht", "hajm": "1000 dona"},
         "Sifatli qizil g'isht, yetkazib berish bor."),
        ("Sement M400 (50 qop)", 2_250_000, "UZS", "new",
         {"tur": "Sement", "hajm": "50 qop x 50 kg"},
         "Yangi partiya, omborda turibdi. Ko'p olsangiz chegirma."),
        ("Laminat (25 m²)", 1_900_000, "UZS", "new",
         {"tur": "Laminat", "hajm": "25 m²"},
         "33-klass, suvga chidamli. Rangi yong'oq."),
        ("Profnastil (20 list)", 2_400_000, "UZS", "new",
         {"tur": "Profnastil", "hajm": "20 list"},
         "Tom yopish uchun, qalinligi 0.45 mm."),
    ],
    "hayvon": [
        ("Nemis ovcharkasi kuchukchasi", 3_500_000, "UZS", "new",
         {"turi": "It", "yoshi": "2 oylik", "zoti": "Nemis ovcharkasi"},
         "Sof zotli, emlangan. Ota-onasi hujjatli."),
        ("Fors mushukchasi", 1_200_000, "UZS", "new",
         {"turi": "Mushuk", "yoshi": "3 oylik", "zoti": "Fors"},
         "Juda ko'nikuvchan, tuvaletga o'rgatilgan."),
        ("Qo'y (qoraqo'l)", 4_200_000, "UZS", "good",
         {"turi": "Qo'y", "yoshi": "1 yosh", "zoti": "Qoraqo'l"},
         "Sog'lom, semiz. To'y va bayramlar uchun."),
    ],
    "boshqa": [
        ("Velosiped (tog' velosipedi)", 2_300_000, "UZS", "good",
         {"tur": "Velosiped"},
         "26-radius, 21 tezlik. Amortizatori ishlaydi."),
        ("Kolyaska 2 in 1", 1_800_000, "UZS", "like_new",
         {"tur": "Kolyaska"},
         "Yozgi va qishki bloki bor, g'ildiraklari butun."),
        ("Gitara (akustik)", 850_000, "UZS", "good",
         {"tur": "Musiqa asbobi"},
         "Yaxshi jaranglaydi, chexoli bilan."),
    ],
}

# Toifa -> banner rasmi (savdo uchun mos rasm tanlaymiz).
RASM_MOSLIK = {
    "telefon": "texnikaUstasi",
    "kompyuter": "kompUsta",
    "elektronika": "texnikaUstasi",
    "maishiy": "texnikaUstasi",
    "avto": "avtoYordam",
    "mebel": "usta",
    "kiyim": "bozorchi",
    "qurilish": "ishchi",
    "hayvon": "yana",
    "boshqa": "yana",
}

MANZILLAR = [
    ("Toshkent, Chilonzor tumani", 41.2756, 69.2035),
    ("Toshkent, Yunusobod tumani", 41.3651, 69.2896),
    ("Toshkent, Mirzo Ulug'bek tumani", 41.3253, 69.3345),
    ("Toshkent, Yashnobod tumani", 41.2894, 69.3216),
    ("Toshkent, Shayxontohur tumani", 41.3213, 69.2264),
    ("Toshkent, Olmazor tumani", 41.3542, 69.2103),
    ("Toshkent, Sergeli tumani", 41.2216, 69.2201),
    ("Toshkent, Mirobod tumani", 41.2926, 69.2761),
]


def _rasm(toifa: str) -> str:
    fayl = RASM_MOSLIK.get(toifa, "yana")
    kengaytma = "png" if fayl == "yana" else "jpg"
    return f"/uploads/services3d/{fayl}.{kengaytma}"


async def main(soni_per_toifa: int | None = None) -> None:
    from sqlalchemy import func, select

    from app.core.security import hash_password
    from app.db.session import async_session
    from app.models.marketplace import Listing, ListingCondition, ListingPhoto
    from app.models.user import User

    random.seed(20260818)

    yaratilgan = 0
    otkazilgan = 0

    async with async_session() as db:
        # ── Demo sotuvchilar ─────────────────────────────────────────
        # E'lonlar HAR XIL odamlar nomidan bo'lishi kerak: bitta
        # odamning e'lonlari o'ziga qidiruvda ko'rinmaydi va chegara
        # (5 ta) ham urib qo'yadi.
        sotuvchilar: list[User] = []
        for i in range(1, 9):
            tel = f"+99893000{i:04d}"
            u = (await db.execute(
                select(User).where(User.phone == tel)
            )).scalars().first()
            if u is None:
                u = User(
                    name=["Aziz", "Dilshod", "Nodira", "Sardor", "Kamola",
                          "Bekzod", "Malika", "Jasur"][i - 1],
                    surname="Sotuvchi",
                    phone=tel,
                    hashed_password=hash_password("demo1234"),
                )
                db.add(u)
                await db.flush()
            sotuvchilar.append(u)
        await db.commit()

        # ── E'lonlar ─────────────────────────────────────────────────
        now = datetime.now(timezone.utc)
        idx = 0
        for toifa, royxat in ELONLAR.items():
            kerakli = royxat if soni_per_toifa is None else royxat[:soni_per_toifa]
            for (nom, narx, valyuta, holat, atrib, tavsif) in kerakli:
                bor = (await db.execute(
                    select(func.count(Listing.id))
                    .where(Listing.title == nom)
                )).scalar() or 0
                if bor:
                    otkazilgan += 1
                    continue

                sotuvchi = sotuvchilar[idx % len(sotuvchilar)]
                manzil, lat, lng = MANZILLAR[idx % len(MANZILLAR)]
                idx += 1

                listing = Listing(
                    user_id=sotuvchi.id,
                    category_key=toifa,
                    title=nom,
                    description=tavsif,
                    price=float(narx),
                    currency=valyuta,
                    is_negotiable=random.random() < 0.3,
                    condition=ListingCondition(holat),
                    attributes=atrib,
                    address=manzil,
                    lat=lat + random.uniform(-0.01, 0.01),
                    lng=lng + random.uniform(-0.01, 0.01),
                    views=random.randint(5, 250),
                    # Muddat turlicha: ba'zilari tez tugaydi, bu
                    # "muddati tugagan" holatini ham ko'rsatadi.
                    expires_at=now + timedelta(days=random.randint(3, 30)),
                )
                db.add(listing)
                await db.flush()

                rasm = _rasm(toifa)
                for k in range(3):  # minimal talab — 3 ta rasm
                    db.add(ListingPhoto(listing_id=listing.id,
                                        url=rasm, sort_order=k))
                yaratilgan += 1

        await db.commit()

        jami = (await db.execute(select(func.count(Listing.id)))).scalar() or 0

    print("Demo e'lonlar:")
    print(f"  yaratildi         : {yaratilgan} ta")
    print(f"  o'tkazib yuborildi: {otkazilgan} ta (allaqachon bor)")
    print(f"  bazada jami       : {jami} ta e'lon")
    print(f"  sotuvchilar       : {len(sotuvchilar)} ta demo hisob")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--per-category", type=int, default=None,
                        help="Har toifadan nechta e'lon (standart: hammasi)")
    args = parser.parse_args()
    asyncio.run(main(args.per_category))
