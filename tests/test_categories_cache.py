"""Kategoriya keshi testi.

NIMA TEKSHIRILADI (`YUKLAMA_TAHLILI.md` §7.3 bo'yicha):
  1. Ikkinchi so'rov bazaga BORMAYDI (kesh ishlaydi)
  2. Kesh javobni O'ZGARTIRMAYDI (mazmun bir xil)
  3. Admin bo'limni yopsa \u2014 kesh 60 soniya kutmasdan DARHOL aks etadi
     (chunki flaglar keshlanmaydi, faqat baza qatorlari keshlanadi)
  4. `invalidate()` keshni haqiqatan tozalaydi
  5. Redis o'chgan bo'lsa \u2014 xato bermaydi, shunchaki bazadan o'qiydi

Test Redis'siz ishlaydi: `get_redis` soxta (fake) ob'ektga almashtiriladi.
"""
import asyncio
import sys
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "backend"))

# DIQQAT: bu test BAZAGA ULANMAYDI — Redis ham, Postgres ham soxta (fake).
# Shuning uchun db_guard kerak emas: ishchi bazaga tegish ehtimoli yo'q.


class FakeRedis:
    """Oddiy xotiradagi Redis o'rnini bosuvchi."""

    def __init__(self):
        self.store: dict[str, str] = {}
        self.get_calls = 0

    def get(self, key):
        self.get_calls += 1
        return self.store.get(key)

    def setex(self, key, ttl, value):
        self.store[key] = value

    def delete(self, key):
        self.store.pop(key, None)


class BrokenRedis:
    """Redis o'chgan holatni taqlid qiladi \u2014 har chaqiruv xato beradi."""

    def get(self, key):
        raise ConnectionError("Redis o'chgan")

    def setex(self, key, ttl, value):
        raise ConnectionError("Redis o'chgan")

    def delete(self, key):
        raise ConnectionError("Redis o'chgan")


def test_kesh_ikkinchi_martada_bazaga_bormaydi():
    from app.core import cache

    fake = FakeRedis()
    cache.clear_local()
    yuklash_soni = {"n": 0}

    async def loader():
        yuklash_soni["n"] += 1
        return [{"key": "barber", "name": "Sartarosh"}]

    with patch.object(cache, "get_redis", return_value=fake):

        async def run():
            a = await cache.cached_json("test:kat", 60, loader)
            cache.clear_local()  # lokal keshni tozalaymiz -> Redis sinaladi
            b = await cache.cached_json("test:kat", 60, loader)
            return a, b

        a, b = asyncio.run(run())

    assert yuklash_soni["n"] == 1, f"baza {yuklash_soni['n']} marta o'qildi, 1 kutilgandi"
    assert a == b, "kesh javobni o'zgartirdi"
    print("✓ kesh ishlaydi: baza 1 marta o'qildi, javob bir xil")


def test_invalidate_keshni_tozalaydi():
    from app.core import cache

    fake = FakeRedis()
    cache.clear_local()
    n = {"i": 0}

    async def loader():
        n["i"] += 1
        return {"son": n["i"]}

    with patch.object(cache, "get_redis", return_value=fake):

        async def run():
            a = await cache.cached_json("test:inv", 60, loader)
            cache.invalidate("test:inv")
            b = await cache.cached_json("test:inv", 60, loader)
            return a, b

        a, b = asyncio.run(run())

    assert a == {"son": 1} and b == {"son": 2}, f"invalidate ishlamadi: {a} {b}"
    print("✓ invalidate keshni tozalaydi \u2014 admin o'zgarishi darhol ko'rinadi")


def test_redis_ochgan_bolsa_xato_bermaydi():
    """Eng muhim xavfsizlik sharti: kesh hech qachon so'rovni buzmasin."""
    from app.core import cache

    cache.clear_local()

    async def loader():
        return {"holat": "bazadan"}

    with patch.object(cache, "get_redis", return_value=BrokenRedis()):
        natija = asyncio.run(cache.cached_json("test:broken", 60, loader))
        cache.invalidate("test:broken")  # bu ham xato bermasligi kerak

    assert natija == {"holat": "bazadan"}, natija
    print("✓ Redis o'chganda ham ishlaydi (bazadan o'qiydi, xato bermaydi)")


def test_admin_flaglari_keshlanmaydi():
    """Admin bo'limni yopsa, 60 soniya kutmasdan darhol yopilishi kerak.

    `load_categories` faqat baza qatorlarini keshlaydi; `is_enabled`
    har so'rovda `settings_service` dan yangi olinadi.
    """
    from app.api.v1 import categories as cat_api

    manba = Path(cat_api.__file__).read_text()

    # Keshlovchi funksiya ichida flag hisoblanmasligi kerak
    boshi = manba.index("async def load_categories")
    oxiri = manba.index("def _with_flags")
    kesh_qismi = manba[boshi:oxiri]

    assert "category_enabled" not in kesh_qismi, (
        "XATO: admin flagi kesh ichiga tushib qolgan \u2014 bo'lim yopilganda "
        "60 soniya eski holat ko'rinadi"
    )
    assert "category_enabled" in manba[manba.index("def _with_flags"):], (
        "flag umuman qo'shilmayapti"
    )
    print("✓ admin flaglari keshlanmaydi \u2014 bo'lim yopilishi darhol kuchga kiradi")


def test_admin_ozgartirsa_kesh_tozalanadi():
    """Admin endpointlari har o'zgarishdan keyin keshni tozalashi shart."""
    from app.api.v1.admin import categories as admin_cat

    manba = Path(admin_cat.__file__).read_text()

    for funksiya in ("create_category", "update_category", "delete_category"):
        boshi = manba.index(f"async def {funksiya}")
        # Keyingi funksiyagacha bo'lgan bo'lak
        keyingi = manba.find("\nasync def ", boshi + 10)
        tana = manba[boshi : keyingi if keyingi > 0 else len(manba)]
        assert "_drop_cache()" in tana, (
            f"XATO: {funksiya} kesh tozalamaydi \u2014 admin o'zgarishi "
            f"60 soniyagacha ko'rinmaydi"
        )
    print("✓ admin qo'shish/o'zgartirish/o'chirishda kesh tozalanadi")


if __name__ == "__main__":
    test_kesh_ikkinchi_martada_bazaga_bormaydi()
    test_invalidate_keshni_tozalaydi()
    test_redis_ochgan_bolsa_xato_bermaydi()
    test_admin_flaglari_keshlanmaydi()
    test_admin_ozgartirsa_kesh_tozalanadi()
    print("\nHammasi o'tdi ✅")
