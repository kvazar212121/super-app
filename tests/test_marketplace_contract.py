"""Savdo: Flutter modeli backend javobiga MOS kelishini tekshiradi.

Dart'da yo'q maydonni o'qish jimgina `null` beradi — masalan kartada
narx bo'sh ko'rinadi va buni na `flutter analyze`, na backend testi
ushlaydi. Shuning uchun `Listing.to_dict()` kalitlari bilan
`lib/models/marketplace/listing.dart` kutayotgan kalitlarni
solishtiramiz.

Bundan tashqari TELEFON RAQAMI oqib chiqmasligini ham shu yerda
qo'riqlaymiz: bu loyihaning qat'iy qoidasi.
"""
import os
import re
import sys
from datetime import datetime, timedelta, timezone

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(PROJ, "backend"))
# Bu test BAZAGA murojaat qilmaydi (faqat model va matn tekshiruvi),
# lekin import zanjiri engine yaratadi — shuning uchun fayl bazasi.
import tempfile

_tmp = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
_tmp.close()
os.environ.setdefault("DATABASE_URL", f"sqlite+aiosqlite:///{_tmp.name}")
os.environ.setdefault("DATABASE_SYNC_URL", f"sqlite:///{_tmp.name}")
os.environ["REQUIRE_OTP_AUTH"] = "false"

ok, fail = [], []


def check(name, cond, detail=""):
    (ok if cond else fail).append(f"{name}{'' if cond else ': ' + detail}")


def dart_keys(path: str, cls: str) -> set[str]:
    src = open(os.path.join(PROJ, path)).read()
    i = src.index(f"factory {cls}.fromJson")
    j = src.index("\n  }", i)
    return set(re.findall(r"json\['([a-z_]+)'\]", src[i:j]))


def main():
    from app.models.marketplace import Listing, ListingCondition, ListingPhoto

    now = datetime.now(timezone.utc)
    listing = Listing(
        id=1, user_id=2, category_key="telefon", title="iPhone 13",
        description="Ideal", price=4_500_000, currency="UZS",
        is_negotiable=False, condition=ListingCondition.like_new,
        attributes={"xotira": "256GB"}, address="Toshkent",
        lat=41.31, lng=69.24, views=5,
        expires_at=now + timedelta(days=7), created_at=now,
    )
    listing.photos = [ListingPhoto(listing_id=1, url="/a.jpg", sort_order=0)]
    data = listing.to_dict(distance_km=2.0, price_uzs=4_500_000)

    kutilgan = dart_keys("lib/models/marketplace/listing.dart", "Listing")
    check("Dart modeli maydonlarni o'qiydi", len(kutilgan) > 10,
          f"{kutilgan}")

    yetishmagan = kutilgan - set(data)
    check("Dart kutgan HAR bir kalit backend javobida bor",
          not yetishmagan, f"yo'q: {sorted(yetishmagan)}")

    # Muhim maydonlar aniq ro'yxat bo'yicha (kelajakda o'chib ketmasin).
    for kalit in ("id", "user_id", "title", "price", "price_uzs", "currency",
                  "is_negotiable", "condition", "attributes", "address",
                  "status", "views", "photos", "expires_at", "created_at",
                  "distance_km"):
        check(f"javobda '{kalit}' bor", kalit in data, f"{sorted(data)}")

    check("rasmlar URL ro'yxati bo'lib keladi",
          data["photos"] == ["/a.jpg"], f"{data['photos']}")
    check("holat matn ko'rinishida (Dart uni shunday o'qiydi)",
          data["condition"] == "like_new", f"{data['condition']}")
    check("sana ISO matn", isinstance(data["created_at"], str),
          f"{type(data['created_at'])}")

    # ── TELEFON RAQAMI OQIB CHIQMASIN ────────────────────────────────
    check("javobda telefon maydoni YO'Q",
          not any("phone" in k for k in data), f"{sorted(data)}")

    dart_src = open(
        os.path.join(PROJ, "lib/models/marketplace/listing.dart")
    ).read()
    check("Dart modelida ham telefon maydoni yo'q",
          "phone" not in dart_src.lower(), "phone topildi")

    modal = open(
        os.path.join(PROJ, "lib/widgets/marketplace/listing_modal.dart")
    ).read()
    check("modalda telefonga qo'ng'iroq tugmasi yo'q",
          "tel:" not in modal and "launchUrl" not in modal, "raqamga havola bor")

    # ── Backend yo'llari Flutter servisidagi bilan mos ───────────────
    api = open(os.path.join(PROJ, "lib/services/api_service.dart")).read()
    for yol in ("/marketplace/search", "/marketplace/my/list",
                "/marketplace/photo", "/marketplace/categories"):
        check(f"Flutter '{yol}' yo'lini chaqiradi", yol in api, "topilmadi")

    router = open(
        os.path.join(PROJ, "backend/app/api/v1/marketplace.py")
    ).read()
    for yol in ('"/search"', '"/my/list"', '"/photo"', '"/categories"',
                '"/{listing_id}/extend"', '"/{listing_id}/report"'):
        check(f"backendda {yol} endpointi bor", yol in router, "topilmadi")

    # ── AI tool'lari sxema bilan mos ─────────────────────────────────
    from app.services.ai_agent import HANDLERS, TOOLS
    nomlar = {t["function"]["name"] for t in TOOLS}
    for tool in ("start_listing_draft", "update_listing_draft",
                 "add_listing_photos", "publish_listing", "search_listings",
                 "get_listing", "my_listings", "close_listing"):
        check(f"'{tool}' sxemada bor", tool in nomlar, "yo'q")
        check(f"'{tool}' handleri bor", tool in HANDLERS, "yo'q")
    check("sxema va handler soni mos", len(nomlar) == len(HANDLERS),
          f"{len(nomlar)} != {len(HANDLERS)}")

    # ── Adminka bayrog'i ─────────────────────────────────────────────
    from app.services import settings_service
    check("adminkada savdo bo'limi bor",
          "marketplace" in {k for k, _ in settings_service.FEATURE_DEFS},
          "FEATURE_DEFS da yo'q")

    print()
    for x in ok:
        print("  ✓", x)
    if fail:
        print(f"\nYIQILDI ({len(fail)}):")
        for x in fail:
            print("  ✗", x)
        sys.exit(1)
    print(f"\nOK: {len(ok)} ta tekshiruv o'tdi")


main()
