"""Ish joyi rasmidan tavsif ajratish.

Foydalanuvchi talabi: "rasmga olishni ham qo'shimchasini qil va
rasmga olib misol aytaylik 'shu joyni tamirlash kerak manabu kunga
hozr' dep ai chatga yozadi".

Mavjud `vision_service.py` uslubi takrorlanadi (bir xil provayder
tanlash, bir xil xato ishlash), lekin prompt boshqacha: taom emas,
TA'MIRLASH ishi tahlil qilinadi.
"""
from __future__ import annotations

import base64
import json
import logging

import httpx
from fastapi import HTTPException

logger = logging.getLogger(__name__)

# 3MB — vision_service bilan bir xil chegara.
MAX_IMAGE_BYTES = 3 * 1024 * 1024

ANALYZE_PROMPT = """Sen uy-ro'zg'or ta'mirlash bo'yicha yordamchisan.
Foydalanuvchi muammoli joyning rasmini yubordi.

Rasmga qarab aniqla:
1. Qanday muammo ko'rinyapti
2. Qaysi soha ustasi kerak
3. Ishni qisqa nomlash

FAQAT JSON qaytar, boshqa matn yozma:
{
  "detected": true/false,
  "title_uz": "qisqa nom, 3-60 belgi",
  "description_uz": "muammo tavsifi, 10-300 belgi",
  "category_hint": "electrician|plumber|cleaning|repair|furniture|
                    appliance|other",
  "confidence": 0.0-1.0
}

Agar rasmda ta'mirlashga aloqador narsa ko'rinmasa:
detected=false va description_uz'da nima ko'rinayotganini yoz."""


def _resolve_provider() -> tuple[str, str, str]:
    """Vision provayderi — vision_service bilan AYNAN bir xil manba.

    Alohida sozlama yaratmaymiz: admin bitta joydan boshqarsin.
    """
    from app.core.config import settings
    from app.services import settings_service

    return settings_service.resolve_ai(
        feature="vision",
        env_provider=settings.vision_provider,
        keys={
            "openai": settings.openai_api_key,
            "groq": settings.groq_api_key,
            "deepseek": settings.deepseek_api_key,
            "gemini": settings.gemini_api_key,
        },
        default_models={
            "openai": settings.openai_vision_model,
            "groq": settings.groq_vision_model,
            "deepseek": settings.deepseek_chat_model,
            "gemini": settings.gemini_vision_model,
        },
    )


async def analyze_job_photo(image_bytes: bytes, content_type: str) -> dict:
    """Rasmdan ish tavsifini ajratadi.

    Qaytaradi: {detected, title, description, category_hint, confidence}
    """
    api_url, api_key, model = _resolve_provider()
    if not api_key:
        raise HTTPException(
            status_code=503, detail="AI xizmati hozircha sozlanmagan"
        )

    if len(image_bytes) > MAX_IMAGE_BYTES:
        raise HTTPException(
            status_code=400,
            detail="Rasm hajmi juda katta (3MB gacha).",
        )

    b64 = base64.b64encode(image_bytes).decode()
    data_url = f"data:{content_type};base64,{b64}"

    # 60s juda uzun edi: vision provayderi 503 bersa foydalanuvchi
    # BIR DAQIQA kutib qolardi va "rasm yuborilmayapti" deb o'ylardi.
    # Rasm baribir SAQLANGAN bo'ladi — tahlil ixtiyoriy qulaylik.
    async with httpx.AsyncClient(timeout=20.0) as client:
        try:
            response = await client.post(
                api_url,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {api_key}",
                },
                json={
                    "model": model,
                    "messages": [
                        {
                            "role": "user",
                            "content": [
                                {"type": "text", "text": ANALYZE_PROMPT},
                                {
                                    "type": "image_url",
                                    "image_url": {"url": data_url},
                                },
                            ],
                        }
                    ],
                    "response_format": {"type": "json_object"},
                    "temperature": 0.0,
                    "max_tokens": 1500,
                },
            )
        except httpx.HTTPError as exc:
            logger.error(f"Job vision ({model}) so'rovi muvaffaqiyatsiz: {exc}")
            raise HTTPException(
                status_code=502, detail="AI xizmatiga ulanib bo'lmadi"
            )

    if response.status_code != 200:
        logger.error(
            f"Job vision ({model}) status {response.status_code}: "
            f"{response.text[:300]}"
        )
        raise HTTPException(
            status_code=502, detail="AI xizmati vaqtincha ishlamayapti"
        )

    try:
        content = response.json()["choices"][0]["message"]["content"]
        parsed = json.loads(content)
    except (KeyError, IndexError, json.JSONDecodeError) as exc:
        logger.error(f"Job vision javobini o'qib bo'lmadi: {exc}")
        raise HTTPException(status_code=502, detail="AI javobini o'qib bo'lmadi")

    return normalize_analysis(parsed)


def normalize_analysis(parsed: dict) -> dict:
    """AI javobini xavfsiz shaklga keltiradi.

    Model ba'zan uzun matn yoki noto'g'ri tur qaytaradi. Bularni
    JobCreate chegaralariga moslamasak, e'lon yaratishda 422 chiqadi.
    """
    title = str(parsed.get("title_uz") or "").strip()
    description = str(parsed.get("description_uz") or "").strip()

    # JobCreate: title max 200, description cheklovsiz lekin
    # amaliy chegara qo'yamiz
    title = title[:200]
    description = description[:2000]

    try:
        confidence = float(parsed.get("confidence", 0.5))
    except (TypeError, ValueError):
        confidence = 0.5
    confidence = min(max(confidence, 0.0), 1.0)

    return {
        "detected": bool(parsed.get("detected")),
        "title": title,
        "description": description,
        "category_hint": str(parsed.get("category_hint") or "other").strip(),
        "confidence": confidence,
    }
