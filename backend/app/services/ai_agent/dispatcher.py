"""Tool chaqiruvlarini tegishli handlerga yo'naltiruvchi markaz.

Har handler moduli o'z HANDLERS lug'atini beradi: {tool_nomi: async fn}.
Yangi tool qo'shish = tools_schema.py'ga sxema + mos modulга handler.
"""
import json
import logging

from sqlalchemy.ext.asyncio import AsyncSession

from .personal_tools import HANDLERS as _personal
from .provider_tools import HANDLERS as _provider
from .read_tools import HANDLERS as _read
from .manage_tools import HANDLERS as _manage
from .info_tools import HANDLERS as _info
from .nav_tools import HANDLERS as _nav

logger = logging.getLogger(__name__)

HANDLERS = {**_personal, **_provider, **_read, **_manage, **_info, **_nav}


async def handle_tool_call(
    db: AsyncSession,
    user_id: int,
    tool_call: dict,
    ctx: dict | None = None,
) -> tuple[str, dict | None]:
    """Tool (function) ni lokal bazada bajarish. (natija_json, client_action|None) qaytaradi.

    `ctx` — so'rov konteksti (masalan foydalanuvchining joriy joylashuvi:
    {"lat": .., "lng": ..}). Kerak bo'lgan handler o'zi o'qiydi.
    """
    try:
        func_name = tool_call["function"]["name"]
        args = json.loads(tool_call["function"]["arguments"])

        handler = HANDLERS.get(func_name)
        if handler is None:
            return '{"status": "error", "message": "Noma\'lum funksiya"}', None
        return await handler(db, user_id, args, ctx)
    except Exception as e:
        # Sessiyani tozalaymiz — aks holda keyingi barcha tool chaqiruvlari PendingRollbackError bilan yiqiladi
        try:
            await db.rollback()
        except Exception:
            pass
        logger.error(f"Tool execution failed: {e}")
        return '{"status": "error", "message": "Amalni bajarishda xatolik yuz berdi."}', None
