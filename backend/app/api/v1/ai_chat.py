"""
AI Agent Proxy — Groq API orqali Function Calling (Tool Calls).

Foydalanuvchi iltimosiga ko'ra avtomatik ravishda reja qo'shish,
moliya xarajatlarini qayd etish yoki bozorlik ro'yxatiga narsa qo'shish
mumkin bo'lgan Agentic AI yordamchisi.
"""
import logging
from datetime import datetime, timezone

import httpx
from fastapi import APIRouter, Depends, File, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession
from starlette.requests import Request

from app.api.dependencies import get_current_user
from app.core.config import settings
from app.core.limiter import limiter
from app.db.session import get_db
from app.models.user import User
from app.services.ai_agent import (
    TOOLS,
    ChatRequest,
    ChatResponse,
    build_system_prompt,
    clean_for_mobile,
    handle_tool_call,
    fallback_local_parse,
)

router = APIRouter(prefix="/ai", tags=["ai"])
logger = logging.getLogger(__name__)


@router.post("/chat", response_model=ChatResponse)
@limiter.limit("20/minute")
async def ai_chat(
    request: Request,
    body: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    AI Agent Proxy — Groq API orqali foydalanuvchi so'rovlarini qabul qiladi
    va kerak bo'lganda avtomatik ravishda bazaga ma'lumot kiritish (tools) ni amalga oshiradi.
    """
    user_msg = body.messages[-1].content
    
    # Emojilarni va mikrofon belgilarini tozalash (masalan, 🎤, 💸)
    import re
    emoji_pattern = re.compile(
        "["
        "\U00010000-\U0010ffff"
        "\u2600-\u27BF"
        "\U0001F300-\U0001F9FF"
        "]+", flags=re.UNICODE
    )
    user_msg_clean = emoji_pattern.sub(r'', user_msg).strip()

    # Chat provayderi — admin panelдан (DB) tanlanadi, aks holda env (CHAT_PROVIDER).
    # settings_service DB'ga murojaat qiladi — xato bo'lsa 500 emas, lokal fallback.
    from app.services import settings_service
    try:
        _chat_url, _chat_key, _chat_model = settings_service.resolve_ai(
            feature="chat",
            env_provider=settings.chat_provider,
            keys={
                "openai": settings.openai_api_key,
                "groq": settings.groq_api_key,
                "deepseek": settings.deepseek_api_key,
            },
            default_models={
                "openai": settings.openai_chat_model,
                "groq": settings.groq_model,
                "deepseek": settings.deepseek_chat_model,
            },
        )
        # Admin paneldan tahrirlangan prompt bo'lsa o'shani, aks holda standart
        custom_prompt = (settings_service.get("ai_chat_prompt", "") or "").strip()
    except Exception as e:
        logger.error(
            f"ai_chat settings/provider resolve error: {e}. Falling back to local parse."
        )
        return await fallback_local_parse(user_msg_clean, current_user.id, db)

    if not _chat_key:
        return await fallback_local_parse(user_msg_clean, current_user.id, db)

    current_time_str = datetime.now(timezone.utc).isoformat()
    # (custom yoki standart) prompt + DB'dagi DINAMIK kategoriyalar ro'yxati —
    # AI search_providers'ga har doim ANIQ category_key uzatishi uchun.
    active_prompt = await build_system_prompt(db, base=custom_prompt or None)
    if "{current_time}" not in active_prompt:
        active_prompt += "\n\nHozirgi sana va vaqt (UTC): {current_time}"
    system_prompt_formatted = active_prompt.replace("{current_time}", current_time_str)

    # Initial message list
    groq_messages = [{"role": "system", "content": system_prompt_formatted}]
    for msg in body.messages[:-1]:
        groq_messages.append({"role": msg.role, "content": msg.content})
    # Clean the last user message from emoji
    groq_messages.append({"role": "user", "content": user_msg_clean})

    async def call_groq(messages):
        async with httpx.AsyncClient(timeout=30.0) as client:
            return await client.post(
                _chat_url,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {_chat_key}",
                },
                json={
                    "model": _chat_model,
                    "messages": messages,
                    "tools": TOOLS,
                    "tool_choice": "auto",
                    "temperature": 0.7,
                    "max_tokens": settings.groq_max_tokens,
                },
            )

    # Tool konteksti — foydalanuvchi joylashuvi (ilova yuborsa) "eng yaqin"
    # qidiruvида ishlatiladi.
    tool_ctx = {"lat": body.lat, "lng": body.lng} if body.lat is not None and body.lng is not None else None

    try:
        # Agentic loop — model bir turда bir necha tool chaqira oladi (masalan: search → book → javob).
        actions: list[dict] = []
        final_reply = ""
        MAX_TOOL_ROUNDS = 5
        for _round in range(MAX_TOOL_ROUNDS):
            response = await call_groq(groq_messages)
            if response.status_code != 200:
                logger.warning(f"AI API status {response.status_code}. Falling back to local parse.")
                return await fallback_local_parse(user_msg_clean, current_user.id, db)

            message = response.json()["choices"][0]["message"]

            if not message.get("tool_calls"):
                final_reply = message.get("content") or ""
                break

            # Model tool(lar) chaqirdi — bajarib, natijani qaytaramiz
            groq_messages.append(message)
            for tool_call in message["tool_calls"]:
                tool_result_str, action = await handle_tool_call(
                    db, current_user.id, tool_call, ctx=tool_ctx
                )
                if action:
                    actions.append(action)
                groq_messages.append({
                    "role": "tool",
                    "tool_call_id": tool_call["id"],
                    "name": tool_call["function"]["name"],
                    "content": tool_result_str,
                })
        else:
            final_reply = "So'rovingiz bajarildi."  # tool rounds limiti

        # Clean <think> blocks just in case
        final_reply = re.sub(r"<think>.*?</think>", "", final_reply, flags=re.DOTALL).strip()
        # Mobil ilova markdown'ni render qilmaydi — jadval/qalin belgilarni
        # kafolatli tozalaymiz (model promptga har doim ham amal qilavermaydi).
        final_reply = clean_for_mobile(final_reply)
        return ChatResponse(reply=final_reply, actions=actions)

    except (httpx.TimeoutException, httpx.HTTPError) as e:
        logger.error(f"Groq API communication error ({type(e).__name__}): {e}. Falling back to local parse.")
        return await _safe_fallback(user_msg_clean, current_user.id, db)
    except Exception as e:
        logger.error(f"Unexpected error in ai_chat: {e}. Falling back to local parse.")
        return await _safe_fallback(user_msg_clean, current_user.id, db)


async def _safe_fallback(user_msg: str, user_id: int, db: AsyncSession) -> ChatResponse:
    """Zaxira javob. HECH QACHON 500 bermaydi.

    Nega kerak: asosiy oqim yiqilganda sessiya allaqachon rollback
    qilingan bo'lishi mumkin. Ilgari fallback o'sha sessiyada ishlashga
    urinardi va MissingGreenlet bilan yiqilardi — foydalanuvchi
    chatda xom Dio xatosini ("status code of 500") ko'rardi.

    Endi fallback ham yiqilsa, tushunarli o'zbekcha javob qaytadi.
    """
    try:
        await db.rollback()
    except Exception:
        pass
    try:
        return await fallback_local_parse(user_msg, user_id, db)
    except Exception as exc:
        logger.error(f"Fallback ham yiqildi: {type(exc).__name__}: {exc}")
        return ChatResponse(
            reply=(
                "Kechirasiz, so'rovni bajara olmadim 😔\n"
                "Iltimos qaytadan yozing yoki biroz keyinroq urinib ko'ring."
            ),
            actions=[],
        )


@router.post("/job-photo")
@limiter.limit("10/minute")
async def ai_job_photo(
    request: Request,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    """Ish joyi rasmini AI chatga yuborish.

    Foydalanuvchi talabi: "ai agent chat bo'limida rasmga olishni ham
    qo'shimchasini qil va rasmga olib ... dep ai chatga yozadi".

    Ikki ish bir vaqtda bajariladi:
      1. Rasm saqlanadi (e'longa biriktirish uchun URL kerak)
      2. Vision model rasmni ko'rib ish tavsifini beradi

    AI shu tavsifni olib start_job_draft'ni chaqiradi, ya'ni
    foydalanuvchi "buni tuzatish kerak" desa ham AI nima haqida
    ketayotganini biladi.
    """
    from app.services.ai_job.vision import analyze_job_photo
    from app.services.upload_service import UploadService

    # Faylni bir marta o'qiymiz: birinchi vision'ga, keyin saqlashga.
    contents = await file.read()
    await file.seek(0)

    # 1) Saqlash (rasm e'londa ko'rinishi kerak)
    url = await UploadService.upload_job_photo(file)

    # 2) Tahlil. Vision ishlamasa ham rasm SAQLANGAN bo'ladi —
    # foydalanuvchi tavsifni o'zi yozib e'lon bera oladi.
    analysis = None
    try:
        analysis = await analyze_job_photo(
            contents, file.content_type or "image/jpeg"
        )
    except Exception as exc:
        logger.warning(f"Rasm tahlili bajarilmadi: {exc}")

    return {
        "url": url,
        "analysis": analysis,
        "message": (
            "Rasm yuklandi. Endi qachon va qayerga kerakligini yozing."
            if analysis and analysis.get("detected")
            else "Rasm yuklandi. Muammoni qisqacha yozing."
        ),
    }
