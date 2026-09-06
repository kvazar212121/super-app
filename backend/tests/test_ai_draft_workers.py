"""AI qoralamasi KO'P WORKERDA to'g'ri ishlashini tekshiradi.

MUAMMO (tuzatilgan)
-------------------
`_get_draft` avval protsess ichidagi `_DRAFTS` lug'atini tekshirardi va uni
hech qachon Redis bilan solishtirmasdi. Prodda `WEB_CONCURRENCY=3`:

  1-xabar A workerga  -> {sarlavha} yozildi (A xotirasi + Redis)
  2-xabar B workerga  -> Redis'dan o'qidi, manzil qo'shdi (B + Redis)
  3-xabar yana A'ga   -> A O'Z ESKI nusxasini qaytardi, manzil YO'Q

Foydalanuvchi buni "agent aytganimni unutdi" deb ko'rardi. Bundan yomoni:
e'lon A'da joylangach `clear_draft` faqat A'ni tozalardi — B'dagi eski
nusxa qolib, tugallangan e'lon qayta ochilishi mumkin edi.

Bu test ikkita workerni bitta protsessda taqlid qiladi: `_DRAFTS` — o'sha
workerning xotirasi, `fakeredis` esa umumiy Redis.
"""
import os
import sys

os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://u:p@localhost/db")
os.environ.setdefault("DATABASE_SYNC_URL", "postgresql+psycopg2://u:p@localhost/db")

try:
    import fakeredis
except ImportError:  # pragma: no cover
    print("SKIP: fakeredis o'rnatilmagan (pip install fakeredis)")
    sys.exit(0)

import app.core.redis_client as redis_client

# Umumiy "Redis" — ikkala worker ham shunga uriladi.
_SHARED = fakeredis.FakeRedis(decode_responses=True)
redis_client.get_redis.cache_clear()
redis_client.get_redis = lambda: _SHARED

from app.services.ai_agent import job_tools, market_tools  # noqa: E402

USER = 4242
xato = 0


def check(nom: str, shart: bool, sabab: str = "") -> None:
    global xato
    if shart:
        print(f"  ✓ {nom}")
    else:
        xato += 1
        print(f"  ✗ {nom}" + (f" — {sabab}" if sabab else ""))


def worker(modul, xotira: dict) -> None:
    """Shu workerning xotirasiga o'tamiz (protsess almashuvini taqlid)."""
    modul._DRAFTS.clear()
    modul._DRAFTS.update(xotira)


def main() -> int:
    print("\n=== ISH E'LONI qoralamasi ===")
    _SHARED.flushall()
    job_tools._DRAFTS.clear()

    # --- A worker: sarlavha yozadi
    d = job_tools._get_draft(USER)
    d = d.merge(title="Kran oqyapti")
    job_tools._save_draft(USER, d)
    a_xotira = dict(job_tools._DRAFTS)
    check("A worker: saqlagach lokal nusxa qolmaydi",
          not job_tools._DRAFTS,
          f"lokalda qoldi: {list(job_tools._DRAFTS)}")

    # --- B worker: boshqa protsess, xotirasi bo'sh
    worker(job_tools, {})
    d = job_tools._get_draft(USER)
    check("B worker: A yozganini ko'radi", d.title == "Kran oqyapti",
          f"title={d.title!r}")
    d = d.merge(address="Chilonzor 5")
    job_tools._save_draft(USER, d)

    # --- A worker QAYTADI (eski xotirasi bilan) — asosiy sinov
    worker(job_tools, a_xotira)
    d = job_tools._get_draft(USER)
    check("A worker qaytganda B ning o'zgarishini ko'radi",
          d.address == "Chilonzor 5",
          f"address={d.address!r} — ESKI nusxa qaytdi")
    check("A worker: sarlavha ham saqlangan", d.title == "Kran oqyapti")

    # --- E'lon berildi: A tozalaydi, B da eski nusxa qolmasligi kerak
    worker(job_tools, {})
    job_tools.clear_draft(USER)
    worker(job_tools, a_xotira)          # B da eski nusxa "bor" edi
    d = job_tools._get_draft(USER)
    check("Tozalangach boshqa worker BO'SH qoralama oladi",
          d.title is None and d.address is None,
          f"title={d.title!r} address={d.address!r} — takroriy e'lon xavfi")

    print("\n=== SAVDO e'loni qoralamasi ===")
    _SHARED.flushall()
    market_tools._DRAFTS.clear()

    d = market_tools._get_draft(USER)
    d.title = "iPhone 13"
    market_tools._save_draft(USER, d)
    a_xotira = dict(market_tools._DRAFTS)
    check("A worker: saqlagach lokal nusxa qolmaydi",
          not market_tools._DRAFTS)

    worker(market_tools, {})
    d = market_tools._get_draft(USER)
    check("B worker: A yozganini ko'radi", d.title == "iPhone 13",
          f"title={d.title!r}")
    d.price = 3_000_000
    market_tools._save_draft(USER, d)

    worker(market_tools, a_xotira)
    d = market_tools._get_draft(USER)
    check("A worker qaytganda narxni ko'radi", d.price == 3_000_000,
          f"price={d.price!r} — ESKI nusxa qaytdi")

    worker(market_tools, {})
    market_tools.clear_draft(USER)
    worker(market_tools, a_xotira)
    d = market_tools._get_draft(USER)
    check("Tozalangach boshqa worker BO'SH qoralama oladi",
          d.title is None and d.price is None,
          f"title={d.title!r} — takroriy e'lon xavfi")

    print("\n=== Redis YO'Q bo'lganda ham ishlaydi ===")
    yiqiluvchi = type("Yiqiluvchi", (), {
        "get": lambda self, k: (_ for _ in ()).throw(ConnectionError("redis yo'q")),
        "set": lambda self, *a, **k: (_ for _ in ()).throw(ConnectionError("redis yo'q")),
        "delete": lambda self, k: (_ for _ in ()).throw(ConnectionError("redis yo'q")),
    })()
    redis_client.get_redis = lambda: yiqiluvchi
    job_tools._DRAFTS.clear()

    d = job_tools._get_draft(USER).merge(title="Redis yo'q holati")
    job_tools._save_draft(USER, d)
    check("Redis yo'q: lokal zaxiraga yoziladi", USER in job_tools._DRAFTS)
    check("Redis yo'q: o'sha workerda qoralama o'qiladi",
          job_tools._get_draft(USER).title == "Redis yo'q holati")

    print()
    if xato:
        print(f"YIQILDI: {xato} ta tekshiruv o'tmadi")
        return 1
    print("BARCHA TEKSHIRUVLAR O'TDI ✅")
    return 0


if __name__ == "__main__":
    sys.exit(main())
