"""WebRTC signaling uchun WebSocket menejeri.

WebSocket bog'lanishlari protsess ichida yashaydi. Ko'p worker ishlatilganда
bir workerдаги foydalanuvchi boshqa workerдаги foydalanuvchiga signal yubora
olishi uchun Redis pub/sub ishlatiladi:
  - har worker o'zining lokal socketlarини `active_connections`да ushlaydi;
  - onlayn foydalanuvchilar Redis `call_online_users` to'plamида qayd etiladi;
  - target lokal bo'lsa — to'g'ridan yuboriladi (tez yo'l, bitta workerда shu ishlaydi);
  - aks holda Redis kanaliga e'lon qilinadi va targetni ushlab turган worker yetkazadi.

Redis mavjud bo'lmasa — hammasi lokal rejimга tushadi (bitta worker uchun to'liq ishlaydi).
"""
import asyncio
import json
import logging
from typing import Dict

from fastapi import WebSocket

from app.core.config import settings

logger = logging.getLogger(__name__)

CALL_CHANNEL = "call_signal"
ONLINE_KEY = "call_online_users"  # (eskisi — endi ishlatilmaydi, moslik uchun qoldirildi)
PRESENCE_PREFIX = "call_presence:"  # har user uchun alohida TTL kaliti
# Presence TTL: mijoz har ~20s ping yuboradi, server har xabarда TTL'ni yangilaydi.
# Agar telefon o'lsa/tarmoq uzilsa — ping kelmaydi, kalit ~60s ичида o'chadi va
# user "offline" bo'ladi → chaqiruvchi to'g'ri FCM push yuboradi (telefon jiringlaydi).
PRESENCE_TTL = 60


class CallManager:
    def __init__(self):
        self.active_connections: Dict[int, WebSocket] = {}
        self._redis = None
        self._redis_ready = False

    async def _get_redis(self):
        if self._redis_ready:
            return self._redis
        try:
            import redis.asyncio as aioredis
            self._redis = aioredis.from_url(settings.redis_url, decode_responses=True)
            await self._redis.ping()
        except Exception as e:
            logger.warning(f"CallManager: Redis mavjud emas, lokal rejim — {e}")
            self._redis = None
        self._redis_ready = True
        return self._redis

    async def connect(self, websocket: WebSocket, user_id: int):
        await websocket.accept()
        self.active_connections[user_id] = websocket
        await self._mark_online(user_id)
        logger.info(f"User {user_id} signaling WS ulandi. Lokal: {len(self.active_connections)}")

    async def _mark_online(self, user_id: int):
        """Presence kalitini TTL bilan yozadi/yangilaydi (SETEX)."""
        r = await self._get_redis()
        if r:
            try:
                await r.set(f"{PRESENCE_PREFIX}{user_id}", "1", ex=PRESENCE_TTL)
            except Exception:
                pass

    async def refresh_presence(self, user_id: int):
        """Mijozdan har qanday xabar (yoki server heartbeat) kelganda TTL'ni uzaytiradi.

        Faqat lokal socket hali tirik bo'lsa yangilaymiz — o'lik socket qayd etilib
        qolmasligi uchun. Bu presence'ni socket tirikligiga qattiq bog'laydi.
        """
        if user_id in self.active_connections:
            await self._mark_online(user_id)

    def disconnect(self, user_id: int):
        if user_id in self.active_connections:
            del self.active_connections[user_id]
            logger.info(f"User {user_id} signaling WS uzildi. Lokal: {len(self.active_connections)}")
        # Redis presence tozalashni best-effort fon vazifasi qilib bajaramiz
        if self._redis is not None:
            try:
                asyncio.create_task(self._redis_del_presence(user_id))
            except RuntimeError:
                pass

    async def _redis_del_presence(self, user_id: int):
        try:
            await self._redis.delete(f"{PRESENCE_PREFIX}{user_id}")
        except Exception:
            pass

    async def _deliver_local(self, message: dict, user_id: int) -> bool:
        websocket = self.active_connections.get(user_id)
        if not websocket:
            return False
        try:
            await websocket.send_json(message)
            return True
        except Exception as e:
            logger.error(f"Xabar yuborishda xato ({user_id}): {e}")
            self.disconnect(user_id)
            return False

    async def send_personal_message(self, message: dict, user_id: int) -> bool:
        """Foydalanuvchiga JSON xabar yuboradi. Onlayn bo'lsa True, aks holda False."""
        # 1) Lokal socket — tez yo'l
        if user_id in self.active_connections:
            return await self._deliver_local(message, user_id)

        # 2) Boshqa workerда bo'lishi mumkin — Redis orqali
        r = await self._get_redis()
        if r:
            try:
                is_online = await r.exists(f"{PRESENCE_PREFIX}{user_id}")
                if is_online:
                    await r.publish(CALL_CHANNEL, json.dumps({"target": user_id, "message": message}))
                    return True
            except Exception as e:
                logger.error(f"CallManager Redis publish xatosi: {e}")
        return False

    async def start_subscriber(self):
        """Har workerda ishlaydi: Redis kanalини tinglaydi va lokal socketlarga yetkazadi."""
        r = await self._get_redis()
        if not r:
            logger.info("CallManager: subscriber ishga tushmadi (Redis yo'q).")
            return
        try:
            pubsub = r.pubsub()
            await pubsub.subscribe(CALL_CHANNEL)
            logger.info("CallManager: Redis pub/sub subscriber ishga tushdi.")
            async for msg in pubsub.listen():
                if msg.get("type") != "message":
                    continue
                try:
                    data = json.loads(msg["data"])
                    target = int(data["target"])
                    if target in self.active_connections:
                        await self._deliver_local(data["message"], target)
                except Exception as e:
                    logger.error(f"CallManager subscriber xato: {e}")
        except asyncio.CancelledError:
            raise
        except Exception as e:
            logger.error(f"CallManager subscriber to'xtadi: {e}")


manager = CallManager()
