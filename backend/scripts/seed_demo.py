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
import random
import sys

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


def _narx(min_n: int, max_n: int) -> int:
    """Chiroyli yumaloq narx (5 mingga karrali)."""
    return round(random.randint(min_n, max_n) / 5000) * 5000


async def main(force_banner: bool = False, force_meta: bool = False) -> None:
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

    print("Demo ma'lumot to'ldirildi:")
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
    args = parser.parse_args()
    asyncio.run(main(args.force_banner, args.force_meta))
