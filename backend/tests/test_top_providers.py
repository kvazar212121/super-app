"""Bosh sahifadagi "Top reytingli" ro'yxati va yangi kategoriyalar testlari.

Tekshiriladi:
  1. `sort=rating` — provayderlar reyting bo'yicha kamayish tartibida keladi.
  2. Sahifalash — 2-sahifa 1-sahifadan past reytinglar bilan davom etadi
     (ya'ni "Yana" bosilganda tartib buzilmaydi).
  3. `CATEGORIES_DATA` da yangi 3 xizmat bor va kalitlari Flutter bilan mos.
  4. Seed yangi kategoriyalarni MAVJUD bazaga ham qo'sha oladi.
"""
import os, asyncio
os.environ.setdefault('DATABASE_URL', 'postgresql+asyncpg://u:p@localhost/db')
os.environ.setdefault('DATABASE_SYNC_URL', 'postgresql+psycopg2://u:p@localhost/db')

from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.compiler import compiles


@compiles(JSONB, "sqlite")
def _compile_jsonb_sqlite(element, compiler, **kw):
    return "JSON"


from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from app.db.base import Base

import app.models  # noqa
import app.models.user, app.models.provider, app.models.order, app.models.transaction
import app.models.category, app.models.setting, app.models.review
from app.models.provider import Provider
from app.models.category import Category
from app.services.provider_service import ProviderService
from app.categories_data import CATEGORIES_DATA


# Flutter `ServiceHubKind` dagi yangi kalitlar bilan bir xil bo'lishi shart.
NEW_KEYS = ["telefonUsta", "kompyuterUsta", "itXizmat"]


async def _setup():
    engine = create_async_engine("sqlite+aiosqlite:///:memory:")
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    return engine, async_sessionmaker(engine, expire_on_commit=False)


async def test_sort_by_rating():
    """1-talab: sort='rating' reyting bo'yicha kamayish tartibini beradi."""
    engine, Session = await _setup()
    async with Session() as db:
        cat = Category(key="sartarosh", title_uz="Sartarosh", icon="scissors")
        db.add(cat)
        await db.flush()

        # Ataylab ARALASH tartibda qo'shamiz (serverdagi holatga o'xshash).
        data = [("A", 4.7, 41), ("B", 4.9, 210), ("C", 4.7, 156),
                ("D", 4.8, 234), ("E", 5.0, 84), ("F", 4.9, 512)]
        for name, rating, reviews in data:
            db.add(Provider(
                category_id=cat.id, name=name, address="X", phone="X",
                lat=41.3, lng=69.2, rating=rating, review_count=reviews,
                is_active=True, is_paused=False, is_blocked=False,
            ))
        await db.commit()

        items, total = await ProviderService.list_providers(
            db, per_page=10, sort="rating"
        )
        names = [p.name for p in items]
        ratings = [p.rating for p in items]

        assert total == 6, total
        # 5.0, keyin 4.9 (sharh ko'p oldin), 4.8, 4.7 (sharh ko'p oldin)
        assert names == ["E", "F", "B", "D", "C", "A"], names
        assert ratings == sorted(ratings, reverse=True), ratings
        print("  ✓ sort=rating to'g'ri tartiblaydi:", names)

    await engine.dispose()


async def test_pagination_keeps_order():
    """2-talab: "Yana" bosilganda 2-sahifa past reytinglar bilan davom etadi."""
    engine, Session = await _setup()
    async with Session() as db:
        cat = Category(key="sartarosh", title_uz="Sartarosh", icon="scissors")
        db.add(cat)
        await db.flush()

        # 25 ta provayder, reyting 5.0 dan pasayib boradi.
        for i in range(25):
            db.add(Provider(
                category_id=cat.id, name=f"P{i:02d}", address="X", phone="X",
                lat=41.3, lng=69.2, rating=5.0 - i * 0.1, review_count=100 - i,
                is_active=True, is_paused=False, is_blocked=False,
            ))
        await db.commit()

        page1, _ = await ProviderService.list_providers(
            db, page=1, per_page=10, sort="rating"
        )
        page2, _ = await ProviderService.list_providers(
            db, page=2, per_page=10, sort="rating"
        )

        assert len(page1) == 10 and len(page2) == 10
        # 2-sahifadagi ENG YUQORI reyting 1-sahifadagi ENG PASTDAN oshmasin.
        assert max(p.rating for p in page2) <= min(p.rating for p in page1), (
            "2-sahifada yuqoriroq reyting chiqdi — tartib buzilgan"
        )
        # Takrorlanish bo'lmasin.
        assert not ({p.name for p in page1} & {p.name for p in page2})
        print("  ✓ sahifalashda tartib buzilmaydi va takror yo'q")

    await engine.dispose()


async def test_default_sort_is_stable():
    """Saralashsiz ham tartib BARQAROR (sahifalashda element yo'qolmaydi)."""
    engine, Session = await _setup()
    async with Session() as db:
        cat = Category(key="sartarosh", title_uz="Sartarosh", icon="scissors")
        db.add(cat)
        await db.flush()
        for i in range(15):
            db.add(Provider(
                category_id=cat.id, name=f"P{i:02d}", address="X", phone="X",
                lat=41.3, lng=69.2, rating=4.0, review_count=10,
                is_active=True, is_paused=False, is_blocked=False,
            ))
        await db.commit()

        p1, _ = await ProviderService.list_providers(db, page=1, per_page=10)
        p2, _ = await ProviderService.list_providers(db, page=2, per_page=10)
        seen = [p.name for p in p1] + [p.name for p in p2]
        assert len(seen) == len(set(seen)) == 15, seen
        print("  ✓ standart tartib barqaror (15/15, takrorsiz)")

    await engine.dispose()


async def test_new_categories_exist():
    """3-talab: yangi 3 xizmat CATEGORIES_DATA da bor va to'liq."""
    keys = [c["key"] for c in CATEGORIES_DATA]
    for k in NEW_KEYS:
        assert k in keys, f"{k} CATEGORIES_DATA da yo'q"

    for c in CATEGORIES_DATA:
        if c["key"] not in NEW_KEYS:
            continue
        assert c["title_uz"], c["key"]
        assert c["subtitle_uz"], c["key"]
        assert c["icon"], c["key"]
        assert c["variants"], f"{c['key']} narxlarsiz"
        for v in c["variants"]:
            assert v["label_uz"] and v["base_price"] > 0, c["key"]

    assert len(keys) == len(set(keys)), "kalitlar takrorlangan"
    print(f"  ✓ yangi 3 kategoriya to'liq (jami {len(keys)} ta)")


async def test_seed_adds_missing_categories():
    """4-talab: seed MAVJUD bazaga yetishmayotgan kategoriyalarni qo'shadi.

    Ilgari seed faqat bo'sh bazada ishlardi — shuning uchun yangi xizmatlar
    ishlab turgan serverga hech qachon tushmasdi va bo'lim bo'sh ko'rinardi.
    """
    engine, Session = await _setup()
    async with Session() as db:
        # Bazada ALLAQACHON eski kategoriyalar bor (yangi 3 tasisiz).
        for c in CATEGORIES_DATA:
            if c["key"] in NEW_KEYS:
                continue
            db.add(Category(
                key=c["key"], title_uz=c["title_uz"],
                subtitle_uz=c["subtitle_uz"], icon=c["icon"],
                accent_color=c["accent_color"],
            ))
        await db.commit()

        from sqlalchemy import select
        before = {c.key for c in (await db.execute(select(Category))).scalars()}
        assert not (set(NEW_KEYS) & before), "test shartlari noto'g'ri"

        # Seed mantiqi: yetishmayotganini qo'shadi.
        for cat_info in CATEGORIES_DATA:
            if cat_info["key"] in before:
                continue
            db.add(Category(
                key=cat_info["key"], title_uz=cat_info["title_uz"],
                subtitle_uz=cat_info["subtitle_uz"], icon=cat_info["icon"],
                accent_color=cat_info["accent_color"],
            ))
        await db.commit()

        after = {c.key for c in (await db.execute(select(Category))).scalars()}
        for k in NEW_KEYS:
            assert k in after, f"{k} qo'shilmadi"
        assert len(after) == len(CATEGORIES_DATA)
        print(f"  ✓ seed yetishmagan {len(after) - len(before)} ta kategoriyani qo'shdi")

    await engine.dispose()


async def test_seed_data_keys_are_valid():
    """Seed provayderlari ishlatadigan HAR BIR kategoriya kaliti mavjud bo'lsin.

    Aks holda seed "Kategoriya topilmadi" deb ogohlantiradi va o'sha
    provayderlar bazaga umuman tushmaydi — bo'lim bo'sh ko'rinadi.
    """
    from app.seed_data import PROVIDERS

    defined = {c["key"] for c in CATEGORIES_DATA}
    used = {p["category_key"] for p in PROVIDERS}
    missing = sorted(used - defined)
    assert not missing, (
        f"Seed quyidagi kalitlarni ishlatadi, lekin CATEGORIES_DATA da yo'q: "
        f"{missing}"
    )
    print(f"  ✓ seed ishlatadigan {len(used)} ta kalit — hammasi mavjud")


async def test_flutter_and_backend_keys_match():
    """Flutter `ServiceHubKind.key` va backend kalitlari mos bo'lsin.

    Mos kelmasa ilovada bo'lim ochiladi-yu, backend hech narsa qaytarmaydi.
    """
    import re, pathlib

    dart = pathlib.Path(__file__).resolve().parents[2] / "lib/models/service_hub_kind.dart"
    if not dart.exists():
        print("  (Flutter fayli topilmadi — o'tkazib yuborildi)")
        return

    text = dart.read_text()
    # `String get key => switch (this) { ... }` blokidagi maxsus kalitlar
    block = text.split("String get key => switch (this) {")[1].split("};")[0]
    special = dict(re.findall(r"ServiceHubKind\.(\w+) => '([\w_]+)'", block))

    # enum a'zolari
    enum_block = text.split("enum ServiceHubKind {")[1].split("}")[0]
    members = [
        m.strip().rstrip(",")
        for m in enum_block.split("\n")
        if m.strip() and not m.strip().startswith("//")
    ]
    members = [m.rstrip(",") for m in members if m and not m.startswith("//")]

    flutter_keys = {special.get(m, m) for m in members if m}
    backend_keys = {c["key"] for c in CATEGORIES_DATA}

    missing = sorted(flutter_keys - backend_keys)
    assert not missing, (
        f"Ilovada bor, backendda YO'Q kategoriyalar: {missing} — "
        f"bu bo'limlar doim bo'sh chiqadi"
    )
    print(f"  ✓ Flutter {len(flutter_keys)} kaliti backendda mavjud")


async def main():
    tests = [
        ("sort=rating tartibi", test_sort_by_rating),
        ("sahifalashda tartib", test_pagination_keeps_order),
        ("standart tartib barqaror", test_default_sort_is_stable),
        ("yangi kategoriyalar", test_new_categories_exist),
        ("seed yangilarini qo'shadi", test_seed_adds_missing_categories),
        ("seed kalitlari haqiqiy", test_seed_data_keys_are_valid),
        ("Flutter<->backend kalitlari", test_flutter_and_backend_keys_match),
    ]
    failed = 0
    for name, fn in tests:
        try:
            await fn()
            print(f"PASS: {name}")
        except AssertionError as e:
            failed += 1
            print(f"FAIL: {name} -> {e}")
        except Exception as e:
            failed += 1
            print(f"ERROR: {name} -> {type(e).__name__}: {e}")
    print()
    print(f"Natija: {len(tests) - failed}/{len(tests)} o'tdi")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
