"""TEST BAZASI QO'RIQCHISI — ishchi (prod) bazaga tegib ketmaslik uchun.

NEGA BOR: integratsiya testlari `DROP SCHEMA public CASCADE` qiladi.
Agar `SUPERAPP_TEST_DB` xato yozilsa (yoki serverda o'ylamasdan
yurgizilsa) BUTUN ISHCHI BAZA o'chib ketadi. Bu 2026-08-18 da
haqiqatan sodir bo'ldi: 61 provayder va 102 buyurtma yo'qoldi,
zaxiradan tiklashga to'g'ri keldi.

Har test shu modulni chaqiradi va faqat XAVFSIZ bazada davom etadi.

Xavfsiz deb hisoblanadi:
    • nomi `test` bilan tugaydigan yoki `test_` bilan boshlanadigan baza
    • SQLite fayli
    • `SUPERAPP_ALLOW_UNSAFE_TEST_DB=1` aniq berilgan (o'z javobgarligiga)

Xavfli deb rad etiladi:
    • `superapp`, `postgres`, `prod`, `production` nomli bazalar
"""
from __future__ import annotations

import os
import sys
from urllib.parse import urlparse

# Hech qachon tegilmaydigan nomlar.
TAQIQLANGAN = {"superapp", "postgres", "prod", "production", "main", "app"}


def _baza_nomi(url: str) -> str:
    """Ulanish satridan baza nomini ajratadi."""
    try:
        parsed = urlparse(url)
        yol = (parsed.path or "").lstrip("/")
        # `?host=...` ko'rinishidagi socket ulanishida ham yo'l shu.
        return yol.split("?")[0].strip().lower()
    except Exception:
        return ""


def is_safe(url: str) -> tuple[bool, str]:
    """(xavfsizmi, sabab) qaytaradi."""
    if not url:
        return False, "baza ko'rsatilmagan"

    if url.startswith("sqlite"):
        return True, "sqlite (vaqtinchalik fayl)"

    nomi = _baza_nomi(url)
    if not nomi:
        return False, "baza nomi aniqlanmadi"

    if nomi in TAQIQLANGAN:
        return False, f"'{nomi}' — ISHCHI baza nomi"

    if nomi.startswith("test_") or nomi.endswith("_test") or nomi == "test":
        return True, f"'{nomi}' — test bazasi"

    return False, (
        f"'{nomi}' test bazasiga o'xshamaydi "
        "(nomi 'test_' bilan boshlanishi yoki '_test' bilan tugashi kerak)"
    )


def guard(url: str | None = None) -> None:
    """Xavfli baza bo'lsa testni TO'XTATADI (SKIP, yiqilish emas).

    Yiqilish emas, chunki `tests/run.sh` uni xato deb ko'rsatadi va
    haqiqiy muammo ko'zdan qochadi. Sabab aniq yoziladi.
    """
    url = url or os.environ.get("SUPERAPP_TEST_DB") or ""

    if os.environ.get("SUPERAPP_ALLOW_UNSAFE_TEST_DB") == "1":
        return

    xavfsiz, sabab = is_safe(url)
    if xavfsiz:
        return

    print(
        "SKIP: XAVFLI BAZA RAD ETILDI — " + sabab + "\n"
        "      Testlar `DROP SCHEMA public CASCADE` qiladi va bu baza\n"
        "      ISHCHI ma'lumotni o'chirib yuborardi.\n"
        "      Alohida test bazasi yarating, masalan:\n"
        "        CREATE DATABASE superapp_test;\n"
        "        export SUPERAPP_TEST_DB="
        "'postgresql+asyncpg://postgres@localhost:5432/superapp_test'"
    )
    sys.exit(0)
