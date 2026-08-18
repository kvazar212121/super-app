"""Demo ma'lumot to'ldiruvchi — provayderlarni "tirik" ko'rinishga keltiradi.

Nima qiladi (mavjud ma'lumotni BUZMAYDI, faqat bo'sh joyni to'ldiradi):

  1. Har provayderga KAMIDA 4-5 ta xizmat + narx + ish vaqti
     (`metadata_json`). Toifasiga mos xizmatlar beriladi.
  2. Bo'sh BANNER (`cover_image`) ga toifaga mos rasm qo'yiladi.
  3. Har provayderga EGA (`owner_user_id`) va kirish hisobi:
     telefon = provayderning telefoni, parol = `demo1234`.
     Shunda provayder kabinetiga kirib ko'rish mumkin.
  4. Reyting va sharhlar (ishonch uchun) — bo'sh bo'lsa.

Ishlatish (serverda):
    docker compose exec -T backend python -m scripts.seed_demo
    docker compose exec -T backend python -m scripts.seed_demo --force-banner

⚠️ Bu skript ISHCHI bazada ishlaydi va shuning uchun HECH NARSANI
   O'CHIRMAYDI: faqat `UPDATE ... WHERE ustun IS NULL` va `INSERT`.
"""
from __future__ import annotations

import argparse
import asyncio
import os
import random
import sys

# Skript `python -m scripts.seed_demo` yoki to'g'ridan-to'g'ri
# (`python /app/seed_demo.py`) ishga tushirilishi mumkin. Ikkala
# holatda ham `app` paketi topilishi kerak.
_ILDIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _ILDIZ not in sys.path:
    sys.path.insert(0, _ILDIZ)
if "/app" not in sys.path and os.path.isdir("/app/app"):
    sys.path.insert(0, "/app")

from sqlalchemy import func, select

# Har toifa uchun: xizmatlar (nomi -> narx oralig'i) va banner rasmi.
# Narxlar 2026-yil Toshkent bozoriga taxminan mos.
TOIFA_XIZMATLARI: dict[str, dict] = {
    "sartarosh": {
        "xizmatlar": [
            ("Erkaklar kesimi", 40000, 70000),
            ("Soqol olish", 20000, 35000),
            ("Bolalar kesimi", 30000, 50000),
            ("Kamuflyaj (bo'yash)", 60000, 90000),
            ("Boshni yuvish", 15000, 25000),
        ],
        "banner": "sartarosh",
    },
    "salon": {
        "xizmatlar": [
            ("Soch turmagi", 80000, 150000),
            ("Manikyur", 60000, 100000),
            ("Pedikyur", 80000, 130000),
            ("Makiyaj", 120000, 250000),
            ("Kirpik qo'yish", 150000, 300000),
        ],
        "banner": "salon",
    },
    "tozalash": {
        "xizmatlar": [
            ("Kvartira tozalash", 150000, 350000),
            ("Ofis tozalash", 200000, 500000),
            ("Deraza yuvish", 50000, 120000),
            ("Ta'mirdan keyin tozalash", 400000, 900000),
            ("Yumshoq mebel kimyoviy tozalash", 180000, 400000),
        ],
        "banner": "tozalash",
    },
    "usta": {
        "xizmatlar": [
            ("Mebel yig'ish", 100000, 250000),
            ("Eshik o'rnatish", 150000, 400000),
            ("Devor teshish", 30000, 80000),
            ("Karniz o'rnatish", 50000, 120000),
            ("Kichik ta'mir ishlari", 80000, 200000),
        ],
        "banner": "usta",
    },
    "elektrik": {
        "xizmatlar": [
            ("Rozetka almashtirish", 40000, 80000),
            ("Lyustra o'rnatish", 60000, 150000),
            ("Simlarni yangilash", 200000, 600000),
            ("Avtomat qo'yish", 50000, 120000),
            ("Qisqa tutashuvni topish", 80000, 180000),
        ],
        "banner": "elektrik",
    },
    "santexnik": {
        "xizmatlar": [
            ("Kran almashtirish", 50000, 120000),
            ("Unitaz o'rnatish", 150000, 350000),
            ("Quvur tiqilishini ochish", 80000, 200000),
            ("Suv hisoblagich o'rnatish", 120000, 250000),
            ("Vanna/dush o'rnatish", 200000, 500000),
        ],
        "banner": "santexnik",
    },
    "avtoYordam": {
        "xizmatlar": [
            ("Akkumulyator quvvatlash", 50000, 100000),
            ("G'ildirak almashtirish", 40000, 90000),
            ("Evakuator", 150000, 400000),
            ("Yoqilg'i yetkazish", 60000, 120000),
            ("Eshikni ochish", 70000, 150000),
        ],
        "banner": "avtoYordam",
    },
    "repetitor": {
        "xizmatlar": [
            ("Matematika (1 dars)", 60000, 120000),
            ("Ingliz tili (1 dars)", 70000, 150000),
            ("Fizika (1 dars)", 70000, 130000),
            ("Ona tili (1 dars)", 50000, 100000),
            ("Imtihonga tayyorlash", 100000, 200000),
        ],
        "banner": "repetitor",
    },
    "enaga": {
        "xizmatlar": [
            ("Soatlik enaga", 30000, 60000),
            ("Kunlik enaga", 200000, 400000),
            ("Kechasi qarash", 250000, 500000),
            ("Bola bilan mashg'ulot", 60000, 120000),
            ("Kasal bolaga qarash", 80000, 160000),
        ],
        "banner": "enaga",
    },
    "hamshira": {
        "xizmatlar": [
            ("Ukol qilish", 30000, 60000),
            ("Kapelnitsa", 80000, 150000),
            ("Bosim o'lchash", 20000, 40000),
            ("Bemorga qarash (soatlik)", 50000, 100000),
            ("Bog'lam almashtirish", 40000, 80000),
        ],
        "banner": "hamshira",
    },
    "stomatologiya": {
        "xizmatlar": [
            ("Ko'rik va maslahat", 50000, 100000),
            ("Tish davolash", 200000, 500000),
            ("Tish olish", 150000, 350000),
            ("Tosh tozalash", 150000, 300000),
            ("Plomba qo'yish", 180000, 400000),
        ],
        "banner": "stamatolg",
    },
    "massajHijoma": {
        "xizmatlar": [
            ("Klassik massaj", 120000, 250000),
            ("Hijoma", 100000, 200000),
            ("Bel massaji", 100000, 180000),
            ("Bolalar massaji", 80000, 150000),
            ("Sport massaji", 150000, 300000),
        ],
        "banner": "massajHijoma",
    },
    "dezinfeksiya": {
        "xizmatlar": [
            ("Kvartira dezinfeksiya", 200000, 400000),
            ("Suvarak yo'qotish", 150000, 350000),
            ("Kanalarga qarshi", 180000, 400000),
            ("Ofis dezinfeksiya", 300000, 700000),
            ("Hid yo'qotish", 150000, 300000),
        ],
        "banner": "dezinfeksiya",
    },
    "futbol": {
        "xizmatlar": [
            ("1 soat (kunduzi)", 120000, 200000),
            ("1 soat (kechqurun)", 180000, 300000),
            ("Dush va kiyinish xonasi", 20000, 40000),
            ("To'p ijarasi", 20000, 30000),
            ("Hakam xizmati", 80000, 150000),
        ],
        "banner": "futbol",
    },

    "tadbirlar": {
        "xizmatlar": [
            ("To'y tashkil qilish", 3000000, 8000000),
            ("Boshlovchi (ovoz)", 1500000, 4000000),
            ("Fotograf", 800000, 2500000),
            ("Videograf", 1200000, 3500000),
            ("Bezash va gullar", 700000, 2000000),
        ],
        "banner": "tadbirlar",
    },
    "konditsioner": {
        "xizmatlar": [
            ("Konditsioner o'rnatish", 300000, 700000),
            ("Tozalash va profilaktika", 120000, 250000),
            ("Freon to'ldirish", 150000, 300000),
            ("Ta'mirlash", 200000, 500000),
            ("Ko'chirib o'rnatish", 350000, 800000),
        ],
        "banner": "konditsioner",
    },
    "texnikaUstasi": {
        "xizmatlar": [
            ("Kir yuvish mashinasi ta'miri", 150000, 400000),
            ("Muzlatgich ta'miri", 200000, 500000),
            ("Mikroto'lqinli pech", 100000, 250000),
            ("Televizor ta'miri", 150000, 400000),
            ("Uyga chiqib diagnostika", 50000, 100000),
        ],
        "banner": "texnikaUstasi",
    },
    "ishchi": {
        "xizmatlar": [
            ("Yuk tashish (1 ishchi/soat)", 40000, 80000),
            ("Ko'chish yordami", 200000, 500000),
            ("Qurilish yordamchisi (kunlik)", 200000, 400000),
            ("Hovli tozalash", 100000, 250000),
            ("Yuk ortish/tushirish", 80000, 200000),
        ],
        "banner": "ishchi",
    },
    "bozorchi": {
        "xizmatlar": [
            ("Bozordan xarid (ro'yxat bo'yicha)", 30000, 70000),
            ("Sabzavot-meva yetkazish", 25000, 60000),
            ("Go'sht xaridi", 30000, 70000),
            ("Katta xarid (haftalik)", 60000, 150000),
            ("Tezkor yetkazish", 40000, 90000),
        ],
        "banner": "bozorchi",
    },
    "oshxona": {
        "xizmatlar": [
            ("Osh (1 porsiya)", 30000, 60000),
            ("To'y oshi (100 kishi)", 2500000, 6000000),
            ("Uyga taom yetkazish", 40000, 100000),
            ("Kunlik ovqat (obuna)", 500000, 1200000),
            ("Sho'rva va lagmon", 25000, 55000),
        ],
        "banner": "oshxona",
    },
    "kompyuterUsta": {
        "xizmatlar": [
            ("Windows o'rnatish", 80000, 150000),
            ("Chang tozalash + termopasta", 100000, 200000),
            ("Virus tozalash", 70000, 150000),
            ("SSD/RAM o'rnatish", 80000, 180000),
            ("Uyga chiqib xizmat", 60000, 120000),
        ],
        "banner": "kompUsta",
    },
    "telefonUsta": {
        "xizmatlar": [
            ("Ekran almashtirish", 200000, 900000),
            ("Batareya almashtirish", 150000, 400000),
            ("Suvdan tozalash", 150000, 350000),
            ("Dasturiy ta'minot (proshivka)", 100000, 250000),
            ("Razyom almashtirish", 120000, 300000),
        ],
        "banner": "texnikaUstasi",
    },
    "itXizmat": {
        "xizmatlar": [
            ("Sayt yaratish (vizitka)", 2000000, 6000000),
            ("Internet-do'kon", 5000000, 15000000),
            ("Logotip va brending", 800000, 2500000),
            ("SMM boshqaruvi (oylik)", 1500000, 4000000),
            ("Texnik qo'llab-quvvatlash (oylik)", 700000, 2000000),
        ],
        "banner": "kompUsta",
    },
    "game_zona": {
        "xizmatlar": [
            ("PlayStation 5 (1 soat)", 20000, 40000),
            ("VR o'yin (30 daqiqa)", 30000, 60000),
            ("Bilyard (1 soat)", 25000, 50000),
            ("Kompyuter klub (1 soat)", 15000, 30000),
            ("Tug'ilgan kun paketi", 300000, 800000),
        ],
        "banner": "gameZona",
    },
    "sport_maydon": {
        "xizmatlar": [
            ("Tennis korti (1 soat)", 80000, 150000),
            ("Basketbol maydoni (1 soat)", 70000, 140000),
            ("Voleybol maydoni (1 soat)", 60000, 120000),
            ("Yopiq zal (1 soat)", 100000, 200000),
            ("Trenajyor zali (1 kirish)", 25000, 50000),
        ],
        "banner": "sportMaydon",
    },
    "kompyuter_usta": {
        "xizmatlar": [
            ("Windows o'rnatish", 80000, 150000),
            ("Chang tozalash", 100000, 200000),
            ("Virus tozalash", 70000, 150000),
            ("Qism almashtirish", 80000, 180000),
            ("Uyga chiqish", 60000, 120000),
        ],
        "banner": "kompUsta",
    },
    "boshqa_xizmatlar": {
        "xizmatlar": [
            ("Konsultatsiya", 50000, 150000),
            ("Tezkor xizmat", 100000, 250000),
            ("Kompleks xizmat", 200000, 500000),
            ("Uyga chiqish", 50000, 120000),
            ("Qo'shimcha ish", 80000, 200000),
        ],
        "banner": "yana",
    },
    "kuryerlik": {
        "xizmatlar": [
            ("Shahar ichida yetkazish", 25000, 50000),
            ("Tezkor yetkazish (2 soat)", 45000, 90000),
            ("Hujjat yetkazish", 20000, 40000),
            ("Yirik yuk", 80000, 200000),
            ("Kunlik kuryer", 250000, 500000),
        ],
        "banner": "kuryerlik",
    },
}

# Toifasi ro'yxatda bo'lmaganlar uchun.
STANDART = {
    "xizmatlar": [
        ("Asosiy xizmat", 50000, 150000),
        ("Qo'shimcha xizmat", 30000, 90000),
        ("Tezkor xizmat", 80000, 200000),
        ("Maslahat", 20000, 50000),
        ("Kompleks xizmat", 150000, 400000),
    ],
    "banner": "yana",
}

# Banner rasmlari — loyihada allaqachon bor `assets/images/services3d/`
# fayllari serverga `/uploads/services3d/` sifatida qo'yiladi
# (`scripts/upload_demo_banners.sh`). Yangi rasm chizish shart emas
# va ilova ularni allaqachon tanidi.
BANNER_BAZASI = "/uploads/services3d"

# Toifa kaliti -> rasm fayli (kalit bilan bir xil bo'lmaganlari).
BANNER_MOSLIK = {
    "stomatologiya": "stamatolg",
    "kompyuterUsta": "kompUsta",
    "kompyuter_usta": "kompUsta",
    "telefonUsta": "texnikaUstasi",
    "itXizmat": "kompUsta",
    "game_zona": "gameZona",
    "sport_maydon": "sportMaydon",
    "boshqa_xizmatlar": "yana",
    "ishchi": "ishchi",
    "bozorchi": "bozorchi",
    "oshxona": "oshxona",
    "tadbirlar": "tadbirlar",
    "konditsioner": "konditsioner",
    "texnikaUstasi": "texnikaUstasi",
}


def banner_url(toifa_kaliti: str, shablon_nomi: str) -> str:
    """Toifaga mos banner rasmining URL manzili."""
    fayl = BANNER_MOSLIK.get(toifa_kaliti, shablon_nomi or toifa_kaliti or "yana")
    kengaytma = "png" if fayl in ("yana", "boshqa") else "jpg"
    return f"{BANNER_BAZASI}/{fayl}.{kengaytma}"


# Har toifada KAMIDA shuncha provayder bo'lsin. Bo'sh toifa ilovada
# "xizmat yo'q" bo'lib ko'rinadi va foydalanuvchi ketib qoladi.
MIN_PROVAYDER = 4

# Demo provayder nomlari (toifaga qarab tanlanadi).
NOM_QOLIPLARI = {
    "sartarosh": ["Barber House", "Elite Cut", "Men's Style", "Fresh Look",
                  "Zamon Barber"],
    "salon": ["Beauty Line", "Glamour Studio", "Nafisa Salon", "Style Room",
              "Zebo Beauty"],
    "tozalash": ["Toza Uy", "CleanPro", "Oq Bulut", "Servis Tozalash",
                 "Ideal Clean"],
    "usta": ["Mohir Usta", "Uy Ustasi", "Master Servis", "Aka Usta",
             "Tez Usta"],
    "elektrik": ["Elektro Servis", "Yorug'lik", "Volt Usta", "Elektrik Aka",
                 "Tok Servis"],
    "santexnik": ["Suv Servis", "Akva Usta", "Santex Pro", "Quvur Ustasi",
                  "Tez Santexnik"],
    "avtoYordam": ["Avto Yordam 24", "Yo'l Servis", "Tez Evakuator",
                   "Avto Nur", "Mobil Usta"],
    "repetitor": ["Bilim Markazi", "Ustoz Repetitor", "Smart School",
                  "Ilm Yo'li", "Zamon Ta'lim"],
    "enaga": ["Mehribon Enaga", "Bolajon Servis", "Oila Yordam",
              "Nazokat Enaga", "Kichkintoy"],
    "hamshira": ["Sog'lom Hayot", "Hamshira Servis", "Med Yordam",
                 "Shifo Hamshira", "Tez Med"],
    "stomatologiya": ["Dental Plus", "Oq Tish", "Smile Clinic",
                      "Stomatolog Servis", "Dentakor"],
    "massajHijoma": ["Shifo Massaj", "Salomatlik", "Relax Studio",
                     "Hijoma Markaz", "Tan Sog'lig'i"],
    "dezinfeksiya": ["Toza Havo", "Dezinfeksiya Pro", "Sanitar Servis",
                     "Eko Dezinfeksiya", "Himoya"],
    "futbol": ["Chempion Maydon", "Gol Arena", "Sport Maydon",
               "Yashil Maydon", "Futbol Klub"],
    "kuryerlik": ["Tez Kuryer", "Express Delivery", "Yetkazib Berish",
                  "Shahar Kuryer", "Chaqqon"],
    "tadbirlar": ["To'y Servis", "Bayram Studio", "Event Master",
                  "Shodiyona", "Prazdnik Plus"],
    "konditsioner": ["Salqin Havo", "Klimat Servis", "Konditsioner Pro",
                     "Sovuq Shamol", "Havo Servis"],
    "texnikaUstasi": ["Texnika Servis", "Master Texnik", "Uy Texnikasi",
                      "Remont Pro", "Tez Ta'mir"],
    "ishchi": ["Ishchi Yordam", "Yuk Servis", "Ko'chish Xizmati",
               "Mardikor Servis", "Kuch Ishchi"],
    "bozorchi": ["Bozor Yordam", "Xarid Servis", "Tez Bozorchi",
                 "Oila Bozor", "Mahsulot Servis"],
    "oshxona": ["Milliy Taomlar", "Osh Markaz", "Uy Taomi",
                "Choyxona Servis", "Mazza"],
    "kompyuterUsta": ["Komp Servis", "IT Master", "PC Doctor",
                      "Kompyuter Yordam", "Tez Komp"],
    "kompyuter_usta": ["Komp Servis Plus", "PC Master", "Kompyuter Pro",
                       "IT Yordam", "Servis Komp"],
    "telefonUsta": ["Telefon Servis", "Mobil Master", "Smart Fix",
                    "Telefon Klinika", "Ekran Servis"],
    "itXizmat": ["Web Studio", "Digital Agency", "IT Solutions",
                 "Raqamli Servis", "Tech Group"],
    "game_zona": ["Game Zone", "PlayStation Club", "VR Arena",
                  "Kiber Klub", "Play Time"],
    "sport_maydon": ["Sport Kompleks", "Arena Sport", "Olimp Maydon",
                     "Faol Sport", "Sport Hub"],
    "boshqa_xizmatlar": ["Universal Servis", "Har Xizmat", "Yordam Markaz",
                         "Servis Plus", "Kompleks Xizmat"],
    "yana": ["Qo'shimcha Servis", "Boshqa Xizmat", "Umumiy Servis",
             "Yordam Plus", "Servis Markaz"],
}

# Toshkent tumanlari — manzil va koordinata uchun.
TUMANLAR = [
    ("Chilonzor tumani", 41.2756, 69.2035),
    ("Yunusobod tumani", 41.3651, 69.2896),
    ("Mirzo Ulug'bek tumani", 41.3253, 69.3345),
    ("Yashnobod tumani", 41.2894, 69.3216),
    ("Shayxontohur tumani", 41.3213, 69.2264),
    ("Olmazor tumani", 41.3542, 69.2103),
    ("Uchtepa tumani", 41.2891, 69.1815),
    ("Sergeli tumani", 41.2216, 69.2201),
    ("Mirobod tumani", 41.2926, 69.2761),
    ("Bektemir tumani", 41.2181, 69.3389),
]


VAQTLAR = ["09:00", "10:00", "11:00", "12:00", "14:00",
           "15:00", "16:00", "17:00", "18:00"]

SHARHLAR = [
    "Ish sifatli bajarildi, rahmat!",
    "Vaqtida keldi, narxi ham arzon.",
    "Juda professional, tavsiya qilaman.",
    "Hammasi yaxshi, yana murojaat qilaman.",
    "Tez va aniq ishladi.",
    "Munosabati juda yaxshi, mamnunman.",
]

DEMO_PAROL = "demo1234"

# Admin panelini ko'rib chiqish uchun (mavjud adminlarga TEGILMAYDI).
DEMO_ADMIN_LOGIN = "demoadmin"
DEMO_ADMIN_PAROL = "Demo2026!"


def _narx(min_n: int, max_n: int) -> int:
    """Chiroyli yumaloq narx (5 mingga karrali)."""
    return round(random.randint(min_n, max_n) / 5000) * 5000


async def main(force_banner: bool = False, force_meta: bool = False,
               demo_admin: bool = True) -> None:
    from app.core.security import hash_password
    from app.db.session import async_session
    from app.models.category import Category
    from app.models.provider import Provider
    from app.models.review import Review
    from app.models.user import User

    random.seed(2026)  # takrorlanadigan natija

    yangilangan_meta = 0
    yangilangan_banner = 0
    yaratilgan_ega = 0
    yaratilgan_sharh = 0

    yaratilgan_provayder = 0

    # ── 0. HAR TOIFADA kamida MIN_PROVAYDER ta bo'lsin ───────────────
    # Foydalanuvchi talabi: "sartaroshlar qolmagan hamma providerlarda
    # bo'lishi kerak, har bir providerni tekshir, bo'lmasa demo
    # ma'lumot qo'sh". Bo'sh toifa ilovada "xizmat yo'q" bo'lib
    # ko'rinadi va odam ketib qoladi.
    async with async_session() as db:
        toifalar = (await db.execute(select(Category))).scalars().all()
        for cat in toifalar:
            bor = (await db.execute(
                select(func.count(Provider.id))
                .where(Provider.category_id == cat.id)
            )).scalar() or 0
            if bor >= MIN_PROVAYDER:
                continue

            shablon = TOIFA_XIZMATLARI.get(cat.key, STANDART)
            nomlar = NOM_QOLIPLARI.get(
                cat.key, [f"{cat.title_uz} Servis {i}" for i in range(1, 6)]
            )
            for i in range(bor, MIN_PROVAYDER):
                nom = nomlar[i % len(nomlar)]
                # Nom takrorlanmasin (turli toifada bir xil nom bo'lishi
                # mumkin, lekin bitta toifada yo'q).
                mavjud_nom = (await db.execute(
                    select(func.count(Provider.id)).where(
                        Provider.category_id == cat.id, Provider.name == nom
                    )
                )).scalar() or 0
                if mavjud_nom:
                    nom = f"{nom} {i + 1}"

                tuman, lat, lng = TUMANLAR[(cat.id + i) % len(TUMANLAR)]
                # Telefon: demo diapazoni, takrorlanmaydi.
                tel = f"+9989{(70 + cat.id % 20):02d}{(100000 + cat.id * 100 + i):06d}"[:13]

                xizmatlar = [x[0] for x in shablon["xizmatlar"]][:5]
                narxlar = {x[0]: _narx(x[1], x[2])
                           for x in shablon["xizmatlar"][:5]}

                db.add(Provider(
                    category_id=cat.id,
                    name=nom,
                    address=f"Toshkent, {tuman}",
                    phone=tel,
                    lat=lat + random.uniform(-0.01, 0.01),
                    lng=lng + random.uniform(-0.01, 0.01),
                    rating=round(random.uniform(4.3, 5.0), 1),
                    review_count=random.randint(8, 60),
                    cover_image=banner_url(cat.key, shablon["banner"]),
                    metadata_json={
                        "services": xizmatlar,
                        "prices": narxlar,
                        "time_slots": VAQTLAR,
                        "about": f"{nom} — {cat.title_uz} yo'nalishida "
                                 "ishonchli xizmat, tajribali mutaxassislar "
                                 "va qulay narxlar.",
                        "is_demo": True,
                    },
                    is_active=True,
                    is_verified=True,
                ))
                yaratilgan_provayder += 1
        await db.commit()

    async with async_session() as db:
        cats = {c.id: c.key for c in
                (await db.execute(select(Category))).scalars().all()}
        provayderlar = (await db.execute(select(Provider))).scalars().all()

        for p in provayderlar:
            kalit = cats.get(p.category_id, "")
            shablon = TOIFA_XIZMATLARI.get(kalit, STANDART)

            # ── 1. Xizmatlar va narxlar ──────────────────────────────
            meta = dict(p.metadata_json or {})
            mavjud = meta.get("services") or []
            if force_meta or len(mavjud) < 4:
                # Mavjud xizmatlarni SAQLAB qolamiz, ustiga qo'shamiz.
                nomlar = list(mavjud)
                narxlar = dict(meta.get("prices") or {})
                for nom, min_n, max_n in shablon["xizmatlar"]:
                    if len(nomlar) >= 5:
                        break
                    if nom not in nomlar:
                        nomlar.append(nom)
                        narxlar[nom] = _narx(min_n, max_n)
                # Eski xizmatga narx yo'q bo'lsa qo'shamiz.
                for nom in nomlar:
                    if nom not in narxlar:
                        narxlar[nom] = _narx(50000, 150000)
                meta["services"] = nomlar
                meta["prices"] = narxlar
                meta.setdefault("time_slots", VAQTLAR)
                meta.setdefault("about",
                                f"{p.name} — ishonchli xizmat, tajribali "
                                "mutaxassislar va qulay narxlar.")
                p.metadata_json = meta
                yangilangan_meta += 1

            # ── 2. Banner ────────────────────────────────────────────
            if force_banner or not (p.cover_image or "").strip():
                p.cover_image = banner_url(kalit, shablon["banner"])
                yangilangan_banner += 1

            # ── 3. Reyting (bo'sh bo'lsa) ────────────────────────────
            if not p.rating:
                p.rating = round(random.uniform(4.3, 5.0), 1)
            if not p.review_count:
                p.review_count = random.randint(5, 40)

            # ── 4. Ega (provayder kabinetiga kirish) ─────────────────
            if p.owner_user_id is None and (p.phone or "").strip():
                telefon = p.phone.strip()
                mavjud_user = (await db.execute(
                    select(User).where(User.phone == telefon)
                )).scalars().first()
                if mavjud_user is None:
                    ismlar = (p.name or "Provayder").split()
                    mavjud_user = User(
                        name=ismlar[0][:50] or "Provayder",
                        surname=(ismlar[1] if len(ismlar) > 1 else "Xizmat")[:50],
                        phone=telefon,
                        hashed_password=hash_password(DEMO_PAROL),
                    )
                    db.add(mavjud_user)
                    await db.flush()
                    yaratilgan_ega += 1
                p.owner_user_id = mavjud_user.id

        await db.commit()

        # ── 5. Sharhlar ──────────────────────────────────────────────
        mijozlar = (await db.execute(
            select(User).limit(10)
        )).scalars().all()
        if mijozlar:
            for p in provayderlar:
                bor = (await db.execute(
                    select(func.count(Review.id))
                    .where(Review.provider_id == p.id)
                )).scalar() or 0
                if bor >= 2:
                    continue
                for _ in range(random.randint(2, 4)):
                    db.add(Review(
                        user_id=random.choice(mijozlar).id,
                        provider_id=p.id,
                        rating=random.choice([4, 5, 5, 5]),
                        comment=random.choice(SHARHLAR),
                    ))
                    yaratilgan_sharh += 1
            await db.commit()

    # ── 6. OTP'siz kirish uchun raqamlar ro'yxati ────────────────────
    # Prodda SMS OTP majburiy. Demo provayder kabinetiga kirib
    # ko'rish uchun ularning raqamlari whitelist'ga yoziladi
    # (`otp_whitelist.py` shu faylni o'qiydi). Kod: 111111.
    try:
        import os

        # Yo'lni MAVJUD modul faylidan olamiz. `app.services` —
        # namespace paket (`__init__.py` yo'q), shuning uchun uning
        # `__file__` i None bo'ladi; skript konteynerga alohida
        # nusxalanganda esa `__file__` ga nisbatan hisoblash xato
        # katalogni ko'rsatardi.
        from app.services import otp_whitelist as _wl

        yol = os.path.join(os.path.dirname(os.path.abspath(_wl.__file__)),
                           "demo_phones.txt")
        raqamlar = sorted({(p.phone or "").strip()
                           for p in provayderlar if (p.phone or "").strip()})
        with open(yol, "w", encoding="utf-8") as f:
            f.write("# Demo provayder raqamlari — OTP'siz kiradi (kod: 111111).\n")
            f.write("# `scripts/seed_demo.py` avtomatik yozadi.\n")
            for r in raqamlar:
                f.write(r + "\n")
        print(f"  OTP whitelist          : {len(raqamlar)} raqam -> {yol}")
    except Exception as exc:
        print(f"  ⚠️ whitelist yozilmadi: {exc}")

    # ── 7. DEMO ADMIN (admin paneliga kirish uchun) ─────────────────
    # Mavjud adminlarning paroli tegilmaydi. Ko'rib chiqish uchun
    # alohida demo admin yaratiladi/yangilanadi.
    if demo_admin:
        async with async_session() as db:
            mavjud = (await db.execute(
                select(User).where(User.phone == DEMO_ADMIN_LOGIN)
            )).scalars().first()
            if mavjud is None:
                mavjud = User(
                    name="Demo", surname="Admin",
                    phone=DEMO_ADMIN_LOGIN,
                    hashed_password=hash_password(DEMO_ADMIN_PAROL),
                )
                db.add(mavjud)
            else:
                mavjud.hashed_password = hash_password(DEMO_ADMIN_PAROL)
            mavjud.is_admin = True
            mavjud.is_super_admin = True
            mavjud.is_active = True
            await db.commit()
        print(f"  demo admin             : {DEMO_ADMIN_LOGIN} / {DEMO_ADMIN_PAROL}")

    print("Demo ma'lumot to'ldirildi:")
    print(f"  yangi provayder        : {yaratilgan_provayder} ta")
    print(f"  xizmat/narx yangilandi : {yangilangan_meta} provayder")
    print(f"  banner qo'yildi        : {yangilangan_banner} provayder")
    print(f"  kirish hisobi yaratildi: {yaratilgan_ega} ta (parol: {DEMO_PAROL})")
    print(f"  sharh qo'shildi        : {yaratilgan_sharh} ta")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--force-banner", action="store_true",
                        help="Banneri borlarni ham almashtirish")
    parser.add_argument("--force-meta", action="store_true",
                        help="Xizmat ro'yxatini majburan to'ldirish")
    parser.add_argument("--no-admin", action="store_true",
                        help="Demo admin yaratilmasin")
    args = parser.parse_args()
    asyncio.run(main(args.force_banner, args.force_meta,
                     demo_admin=not args.no_admin))
