"""Redis'ga asoslangan oddiy kesh — kam o'zgaradigan ma'lumotlar uchun.

NEGA KERAK
----------
Yuklama tahlilida (`YUKLAMA_TAHLILI.md`) aniqlandi: to'siq — protsessor.
Backend CPU 109% ga chiqqanda baza atigi 21% da edi. Ya'ni vaqt ko'proq
so'rovni qayta-qayta ishlashga (SQL + JSON yig'ish) ketadi.

`/categories` va `/config/categories` kabi yo'llar deyarli o'zgarmaydigan
29 ta kategoriyani HAR SO'ROVDA bazadan o'qiydi. Bu ilova ochilganda
har bir foydalanuvchi uchun takrorlanadi. Natijani 60 soniyaga
saqlash — eng arzon tezlashtirish.

ISHLASH TAMOYILI
----------------
Ikki qavatli kesh:

1. **Lokal (protsess ichida)** — 2 soniya. Redis'ga ham urilmaslik uchun.
   Bir sekundda kelgan yuzlab so'rov bitta natijani ulashadi.
2. **Redis** — TTL (standart 60s). Barcha worker'lar bo'lishadi, shuning
   uchun 4 ta worker 4 marta emas, 1 marta bazaga boradi.

Redis o'chib qolsa kesh shunchaki chetlab o'tiladi — xato bermaydi.
Kesh hech qachon so'rovni buzmasligi kerak.

ISHLATISH
---------
    from app.core.cache import cached_json, invalidate

    data = await cached_json("categories:v1", 60, yuklovchi_funksiya)

Ma'lumot o'zgarganda (admin kategoriya qo'shdi/o'chirdi):

    invalidate("categories:v1")
"""
from __future__ import annotations

import json
import logging
import time
from typing import Any, Awaitable, Callable

from app.core.redis_client import get_redis

logger = logging.getLogger(__name__)

# Lokal mikro-kesh: {kalit: (tugash_vaqti, qiymat)}
_local: dict[str, tuple[float, Any]] = {}
_LOCAL_TTL = 2.0


async def cached_json(
    key: str,
    ttl: int,
    loader: Callable[[], Awaitable[Any]],
) -> Any:
    """Keshdan o'qiydi; bo'lmasa `loader()` ni chaqirib, natijani saqlaydi.

    key    — kesh kaliti. Ma'lumot shakli o'zgarsa versiyani oshiring
             (`categories:v1` → `categories:v2`), aks holda eski
             keshdagi noto'g'ri shakl qaytib qoladi.
    ttl    — Redis'da necha soniya saqlansin.
    loader — keshda yo'q bo'lsa chaqiriladigan async funksiya.
    """
    now = time.time()

    # 1-qavat: lokal
    hit = _local.get(key)
    if hit and hit[0] > now:
        return hit[1]

    # 2-qavat: Redis
    try:
        raw = get_redis().get(f"cache:{key}")
        if raw:
            value = json.loads(raw)
            _local[key] = (now + _LOCAL_TTL, value)
            return value
    except Exception as e:
        # Redis yo'q/o'chgan — kesh shunchaki chetlab o'tiladi.
        logger.debug(f"Kesh o'qishda xato ({key}): {e}")

    # Keshda yo'q — bazadan yuklaymiz
    value = await loader()

    try:
        get_redis().setex(f"cache:{key}", ttl, json.dumps(value, default=str))
    except Exception as e:
        logger.debug(f"Kesh yozishda xato ({key}): {e}")

    _local[key] = (now + _LOCAL_TTL, value)
    return value


def invalidate(*keys: str) -> None:
    """Keshni majburan tozalaydi (admin ma'lumotni o'zgartirganda).

    Diqqat: lokal mikro-kesh faqat SHU protsessда tozalanadi, boshqa
    worker'larda 2 soniya eski qiymat qolishi mumkin. Redis tozalangani
    uchun 2 soniyadan keyin hammasi yangilanadi. Admin uchun bu sezilarsiz.
    """
    for key in keys:
        _local.pop(key, None)
        try:
            get_redis().delete(f"cache:{key}")
        except Exception as e:
            logger.debug(f"Kesh tozalashda xato ({key}): {e}")


def clear_local() -> None:
    """Faqat testlar uchun: lokal keshni butunlay bo'shatadi."""
    _local.clear()
