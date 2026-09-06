"""Tool chaqiruvlarini tegishli handlerga yo'naltiruvchi markaz.

Har handler moduli o'z HANDLERS lug'atini beradi: {tool_nomi: async fn}.
Yangi tool qo'shish = tools_schema.py'ga sxema + mos modulга handler.
"""
import json
import logging
import re

from sqlalchemy.ext.asyncio import AsyncSession

from .personal_tools import HANDLERS as _personal
from .provider_tools import HANDLERS as _provider
from .read_tools import HANDLERS as _read
from .manage_tools import HANDLERS as _manage
from .info_tools import HANDLERS as _info
from .nav_tools import HANDLERS as _nav
from .job_tools import HANDLERS as _job
from .booking_tools import HANDLERS as _booking
from .market_tools import HANDLERS as _market
from .complaint_tools import HANDLERS as _complaint

logger = logging.getLogger(__name__)

HANDLERS = {**_personal, **_provider, **_read, **_manage, **_info,
            **_nav, **_job, **_booking, **_market, **_complaint}


def _parse_args(raw) -> dict:
    """Model bergan argumentlarni lug'atga aylantiradi.

    Nega alohida: LLM ba'zan BUZUQ JSON qaytaradi — ayniqsa uzun matnli
    maydonlarda (tavsif ichidagi qo'shtirnoq, yakunlanmagan qavs).
    Ilgari bu `json.loads` ni yiqitardi va butun tool chaqiruvi
    "Expecting ',' delimiter" xatosi bilan barbod bo'lardi. Foydalanuvchi
    tomondan bu "e'lon berilmadi" bo'lib ko'rinardi.

    Shuning uchun bir necha bosqichli tiklash qilinadi.
    """
    if isinstance(raw, dict):
        return raw
    if raw is None or raw == "":
        return {}
    text = str(raw)
    try:
        parsed = json.loads(text)
        return parsed if isinstance(parsed, dict) else {"value": parsed}
    except json.JSONDecodeError:
        pass

    # 1) Ba'zan JSON ikki marta kodlangan ("{\"a\": 1}")
    try:
        once = json.loads(json.dumps(text))
        parsed = json.loads(once)
        if isinstance(parsed, dict):
            return parsed
    except Exception:
        pass

    # 2) Matn oxiri kesilgan bo'lsa: oxirgi to'liq } gacha qirqamiz
    end = text.rfind("}")
    if end > 0:
        try:
            parsed = json.loads(text[: end + 1])
            if isinstance(parsed, dict):
                return parsed
        except Exception:
            pass

    # 3) Oxirgi chora: "kalit": "qiymat" juftliklarini qo'lda yig'amiz.
    #    To'liq bo'lmasa ham, bor ma'lumot yo'qolmaydi — handler
    #    yetishmaganini o'zi so'raydi.
    out: dict = {}
    # Qiymat KEYINGI kalitgacha (yoki oxirigacha) olinadi. Oddiy
    # `"..."` naqshi yetarli emas: matn ichida qo'shtirnoq bo'lsa
    # (`"title":"Kompyuterga "sistema" qilish"`) qiymat yarmida
    # kesilib qolardi va e'lon sarlavhasi chala chiqardi.
    juft = re.compile(
        r'"(\w+)"\s*:\s*"(.*?)"\s*(?=,\s*"\w+"\s*:|\}|$)',
        re.S,
    )
    for m in juft.finditer(text):
        out[m.group(1)] = m.group(2).replace('\\"', '"').strip()
    for m in re.finditer(r'"(\w+)"\s*:\s*(-?\d+(?:\.\d+)?)', text):
        out.setdefault(m.group(1), float(m.group(2)))
    if out:
        logger.warning("Buzuq JSON qisman tiklandi: %s", list(out))
        return out

    # Hech narsa tiklanmadi. XATO BERMAYMIZ, bo'sh lug'at qaytaramiz.
    #
    # Nega: ilgari bu yerda ValueError ko'tarilardi, dispatcher esa
    # xatoda `db.rollback()` qilardi. Rollback SQLAlchemy obyektlarini
    # EXPIRED qiladi (`expire_on_commit=False` bunga ta'sir qilmaydi),
    # shundan keyin endpointdagi `current_user.id` bazaga yashirin
    # so'rov yuborib "greenlet_spawn has not been called" bilan butun
    # chatni 500 ga olib borardi. Foydalanuvchi buni "javob olishda
    # xatolik" deb ko'rardi.
    #
    # Bo'sh lug'at zararsiz: handler o'zi nima yetishmayotganini
    # aytadi va AI qayta so'raydi.
    logger.warning("Tool argumentlari o'qilmadi, bo'sh deb qaraldi: %r", text[:200])
    return {}


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
        args = _parse_args(tool_call["function"]["arguments"])

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
        # Xato nomi + qisqa sababni model'ga qaytaramiz — u tuzatib qayta urinishi mumkin.
        func_name = None
        try:
            func_name = tool_call["function"]["name"]
        except Exception:
            pass
        logger.error(f"Tool execution failed ({func_name}): {e}")
        return json.dumps({
            "status": "error",
            "tool": func_name,
            "message": f"{type(e).__name__}: {e}",
        }, ensure_ascii=False), None
