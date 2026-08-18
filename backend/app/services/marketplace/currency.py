"""Valyuta: e'lon dollarda bo'lsa ham xaridor SO'MDA ko'radi.

Foydalanuvchi qarori: "Ko'rsatish faqat so'mda... chalg'itmasin".
Kurs CBU'dan olinadi va kunlik keshlanadi — har e'lon uchun tashqi
so'rov yuborilsa qidiruv sekinlashadi va limitga uriladi.

Tarmoq ishlamasa oxirgi ma'lum kurs (yoki standart) ishlatiladi:
narx ko'rsatilmay qolgandan ko'ra taxminiy bo'lgani yaxshi.
"""
from __future__ import annotations

import logging
import time

import httpx

logger = logging.getLogger(__name__)

# Oxirgi chora: tarmoq ham, kesh ham bo'lmasa. Taxminiy qiymat.
FALLBACK_USD = 12600.0
_CACHE_TTL = 24 * 3600  # kuniga bir marta yangilanadi

_rates: dict[str, float] = {}
_ts: float = 0.0


def _cached() -> dict[str, float]:
    return dict(_rates)


def set_rates(rates: dict[str, float]) -> None:
    """Kursni qo'lda o'rnatish (test va admin uchun)."""
    global _rates, _ts
    _rates = {k: float(v) for k, v in rates.items()}
    _ts = time.time()


async def usd_rate() -> float:
    """1 USD necha so'm. Xato bo'lsa oxirgi ma'lum/standart qiymat."""
    global _ts
    if _rates and (time.time() - _ts) < _CACHE_TTL:
        return _rates.get("USD", FALLBACK_USD)
    try:
        async with httpx.AsyncClient(timeout=8.0) as client:
            resp = await client.get(
                "https://cbu.uz/uz/arkhiv-kursov-valyut/json/"
            )
            resp.raise_for_status()
            data = resp.json()
            yangi = {
                i["Ccy"]: float(i["Rate"])
                for i in data if i.get("Ccy") in ("USD", "EUR", "RUB")
            }
            if yangi:
                set_rates(yangi)
    except Exception as e:  # tarmoq yo'q, CBU javob bermadi va h.k.
        logger.warning("Valyuta kursi olinmadi: %s", e)
        _ts = time.time()  # har so'rovda qayta urinmaslik uchun
    return _rates.get("USD", FALLBACK_USD)


def to_uzs(price: float | None, currency: str | None,
           rate: float) -> float | None:
    """Narxni so'mga aylantiradi. Narx yo'q bo'lsa (kelishamiz) None."""
    if price is None:
        return None
    cur = (currency or "UZS").upper()
    if cur == "UZS":
        return float(price)
    if cur == "USD":
        return float(price) * rate
    return float(price)


def format_uzs(price_uzs: float | None, *, original: float | None = None,
               currency: str = "UZS", lang: str = "uz") -> str:
    """Xaridorga ko'rinadigan matn: `4 500 000 so'm (350 $)`."""
    if price_uzs is None:
        return "Kelishamiz" if lang != "ru" else "Договорная"
    birlik = "сум" if lang == "ru" else "so'm"
    matn = f"{price_uzs:,.0f} {birlik}".replace(",", " ")
    if (currency or "UZS").upper() == "USD" and original:
        matn += f" ({original:,.0f} $)".replace(",", " ")
    return matn
