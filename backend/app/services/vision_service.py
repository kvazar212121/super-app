"""
Groq Vision orqali taom rasmini tahlil qilish (kaloriya hisoblagich).

Rasm base64 ko'rinishida Groq'ning vision-modeliga yuboriladi,
model qat'iy JSON formatda taom nomi (o'zbekcha) va ozuqaviy
qiymat bahosini qaytaradi.
"""
import base64
import json
import logging

import httpx
from fastapi import HTTPException

from app.core.config import settings

logger = logging.getLogger(__name__)

# Groq base64 chegarasi ~4MB — xavfsiz zaxira bilan
MAX_IMAGE_BYTES = 3 * 1024 * 1024

VISION_SYSTEM_PROMPT = """Siz ovqat rasmlarini tahlil qiluvchi mutaxassis dietolog AI siz.
Rasmga qarab taomni aniqlang va ozuqaviy qiymatini baholang.

FAQAT quyidagi JSON formatda javob bering (boshqa hech qanday matn yozmang):
{
  "is_food": true yoki false (rasmda ovqat bormi),
  "dish_name_uz": "taom nomi o'zbek tilida lotin alifbosida (masalan: Osh, Lag'mon, Somsa)",
  "portion_grams": rasmdagi porsiya og'irligi taxminan grammda (son),
  "calories": shu porsiyadagi umumiy kaloriya kkal (son),
  "protein_g": oqsil grammda (son),
  "fat_g": yog' grammda (son),
  "carbs_g": uglevod grammda (son),
  "confidence": 0 dan 1 gacha ishonch darajasi (son)
}

Agar rasmda ovqat bo'lmasa: {"is_food": false} qaytaring, qolgan maydonlarni 0 yoki bo'sh qoldiring.
Baholar rasmdagi KO'RINGAN porsiya uchun bo'lsin, 100g uchun emas."""


def _num(value, default=0.0) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


async def analyze_food(image_bytes: bytes, content_type: str) -> dict:
    """Taom rasmini Groq vision orqali tahlil qiladi. Normallashgan dict qaytaradi."""
    if not settings.groq_api_key:
        raise HTTPException(status_code=503, detail="AI xizmati hozircha sozlanmagan")

    if len(image_bytes) > MAX_IMAGE_BYTES:
        raise HTTPException(
            status_code=400,
            detail="Rasm hajmi juda katta. Iltimos, kichikroq rasm yuboring (3MB gacha).",
        )

    b64 = base64.b64encode(image_bytes).decode()
    data_url = f"data:{content_type};base64,{b64}"

    async with httpx.AsyncClient(timeout=60.0) as client:
        try:
            response = await client.post(
                "https://api.groq.com/openai/v1/chat/completions",
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {settings.groq_api_key}",
                },
                json={
                    "model": settings.groq_vision_model,
                    "messages": [
                        {
                            "role": "user",
                            "content": [
                                {"type": "text", "text": VISION_SYSTEM_PROMPT},
                                {"type": "image_url", "image_url": {"url": data_url}},
                            ],
                        }
                    ],
                    "response_format": {"type": "json_object"},
                    "temperature": 0.2,
                    "max_tokens": 512,
                },
            )
        except httpx.HTTPError as exc:
            logger.error(f"Groq vision so'rovi muvaffaqiyatsiz: {exc}")
            raise HTTPException(status_code=502, detail="AI xizmatiga ulanib bo'lmadi")

    if response.status_code != 200:
        logger.error(f"Groq vision status {response.status_code}: {response.text[:300]}")
        raise HTTPException(status_code=502, detail="AI xizmati vaqtincha ishlamayapti")

    try:
        content = response.json()["choices"][0]["message"]["content"]
        parsed = json.loads(content)
    except (KeyError, IndexError, json.JSONDecodeError) as exc:
        logger.error(f"Groq vision javobini o'qib bo'lmadi: {exc}")
        raise HTTPException(status_code=502, detail="AI javobini o'qib bo'lmadi")

    if not parsed.get("is_food"):
        raise HTTPException(status_code=422, detail="Rasmda taom aniqlanmadi")

    return {
        "is_food": True,
        "dish_name_uz": str(parsed.get("dish_name_uz") or "Noma'lum taom"),
        "portion_grams": _num(parsed.get("portion_grams"), 0.0) or None,
        "calories": _num(parsed.get("calories")),
        "protein_g": _num(parsed.get("protein_g")),
        "fat_g": _num(parsed.get("fat_g")),
        "carbs_g": _num(parsed.get("carbs_g")),
        "confidence": min(max(_num(parsed.get("confidence"), 0.5), 0.0), 1.0),
    }
