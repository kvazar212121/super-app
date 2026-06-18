"""
AI Chat Proxy — Groq API ga xavfsiz proxy endpoint.

Kalit faqat serverda saqlanadi. APK faqat backendga so'rov yuboradi,
backend esa Groq API ga yo'naltiradi.

Rate-limit va timeout bilan himoyalangan — server osilib qolmaydi.
"""
import logging
from typing import List

import httpx
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.api.dependencies import get_current_user
from app.core.config import settings
from app.core.limiter import limiter
from app.models.user import User
from starlette.requests import Request

router = APIRouter(prefix="/ai", tags=["ai"])
logger = logging.getLogger(__name__)

# System prompt — ilova yordamchisi uchun
SYSTEM_PROMPT = """Siz HubServis SuperApp (universal ilovasi) uchun sun'iy intellekt yordamchisisiz. 
Sizning asosiy vazifangiz — foydalanuvchilarga ilovani qanday ishlatish bo'yicha yo'l-yo'riq ko'rsatish va savollariga xushmuomalalik bilan o'zbek tilida javob berishdir.

ILOVANING ASOSIY BO'LIMLARI VA FUNKSIYALARI:
1. Rejalarim (Kundalik vazifalar va eslatmalar): Foydalanuvchi ma'lum sana va vaqtga rejalar (Tasklar) qo'shishi mumkin. Belgilangan vaqt kelganda ilova eslatma yuboradi.
2. Mening moliyam (Finance Manager): Foydalanuvchi daromad va xarajatlarini kiritib boradi. Oylik byudjet tahlil qilinadi, qaysi sohaga qancha ketayotgani foizlarda ko'rsatiladi.
3. Aqlli savdo (Bozorlik ro'yxati): Foydalanuvchi bozorga borishdan oldin ro'yxat tuzadi. Ilova o'rtacha narxlar bo'yicha taxminiy narxni hisoblab beradi.
4. Barcha xizmatlar: 15 dan ortiq turdagi xizmatlarga buyurtma berish mumkin. Foydalanuvchilar o'zlari ham Provider sifatida ro'yxatdan o'tishlari mumkin.
5. Aksiyalar (Promos): Chegirma kodlari va aksiyalardan foydalanish.

QOIDALAR:
- Faqat o'zbek tilida javob bering.
- Qisqa, tushunarli va do'stona ohangda yozing.
- Ilova imkoniyatlaridan tashqari mavzulardagi savollarga: "Kechirasiz, men faqat HubServis SuperApp ilovasi bo'yicha yordam bera olaman" deb javob bering.
- Javoblarni punktlar va emojilar bilan bezatib bering."""


class ChatMessage(BaseModel):
    role: str = Field(..., pattern=r"^(user|assistant)$")
    content: str = Field(..., min_length=1, max_length=2000)


class ChatRequest(BaseModel):
    messages: List[ChatMessage] = Field(..., min_length=1, max_length=50)


class ChatResponse(BaseModel):
    reply: str


@router.post("/chat", response_model=ChatResponse)
@limiter.limit("20/minute")
async def ai_chat(
    request: Request,
    body: ChatRequest,
    current_user: User = Depends(get_current_user),
):
    """
    AI Chat proxy — Groq API ga so'rov yuboradi va javobni qaytaradi.
    
    - Rate limit: 20 so'rov/minut (har bir foydalanuvchi uchun)
    - Timeout: 30 sekund (server osilib qolmasligi uchun)
    - System prompt avtomatik qo'shiladi
    """
    if not settings.groq_api_key:
        raise HTTPException(
            status_code=503,
            detail="AI xizmati hozircha sozlanmagan. Iltimos, keyinroq urinib ko'ring.",
        )

    # System prompt + foydalanuvchi xabarlari
    groq_messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    for msg in body.messages:
        groq_messages.append({"role": msg.role, "content": msg.content})

    try:
        # httpx bilan asinxron so'rov — timeout bilan himoyalangan
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                "https://api.groq.com/openai/v1/chat/completions",
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {settings.groq_api_key}",
                },
                json={
                    "model": settings.groq_model,
                    "messages": groq_messages,
                    "temperature": 0.7,
                    "max_tokens": settings.groq_max_tokens,
                },
            )

        if response.status_code != 200:
            logger.error(
                "Groq API xatolik: status=%d body=%s",
                response.status_code,
                response.text[:500],
            )
            raise HTTPException(
                status_code=502,
                detail="AI xizmatidan javob olishda xatolik.",
            )

        data = response.json()
        choices = data.get("choices", [])
        if not choices:
            raise HTTPException(
                status_code=502,
                detail="AI xizmatidan bo'sh javob keldi.",
            )

        ai_reply = choices[0]["message"]["content"]
        # <think> bloklarini olib tashlash (ba'zi modellar qaytaradi)
        import re
        ai_reply = re.sub(r"<think>.*?</think>", "", ai_reply, flags=re.DOTALL).strip()

        return ChatResponse(reply=ai_reply)

    except httpx.TimeoutException:
        logger.warning("Groq API timeout: user_id=%d", current_user.id)
        raise HTTPException(
            status_code=504,
            detail="AI xizmati javob berishda vaqt tugadi. Qayta urinib ko'ring.",
        )
    except HTTPException:
        raise
    except Exception as e:
        logger.error("AI chat proxy xatolik: %s", str(e))
        raise HTTPException(
            status_code=500,
            detail="Kutilmagan xatolik yuz berdi.",
        )
