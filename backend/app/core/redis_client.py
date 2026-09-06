from functools import lru_cache
from redis import Redis
from app.core.config import settings

@lru_cache
def get_redis() -> Redis:
    try:
        client = Redis.from_url(settings.redis_url, decode_responses=True, socket_connect_timeout=1)
        client.ping()
        return client
    except Exception:
        import fakeredis
        return fakeredis.FakeRedis(decode_responses=True)

