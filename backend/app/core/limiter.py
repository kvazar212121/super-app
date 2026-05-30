"""
Rate-limiter sozlamalari — SlowAPI + Redis.
Redis mavjud bo'lmasa, xotira (memory) rejimiga o'tadi.
"""
import logging
from slowapi import Limiter
from slowapi.util import get_remote_address
from redis import Redis, ConnectionError, RedisError

from app.core.config import settings

logger = logging.getLogger(__name__)


def _redis_available(url: str) -> bool:
    """Redis ulanishini tekshiradi."""
    try:
        client = Redis.from_url(url)
        client.ping()
        return True
    except (ConnectionError, RedisError, Exception) as exc:
        logger.warning("Redis mavjud emas, rate-limiting xotira rejimida: %s", exc)
        return False


# Redis mavjud bo'lsa — undan foydalan, aks holda xotira
if _redis_available(settings.redis_url):
    limiter = Limiter(
        key_func=get_remote_address,
        storage_uri=settings.redis_url,
    )
else:
    limiter = Limiter(
        key_func=get_remote_address,
        storage_uri="memory://",
    )
