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


def _resolve_provider() -> tuple[str, str, str]:
    """Vision provayder+model tanlovini admin sozlamalaridan (DB) yoki env'dan oladi.

    OpenAI va Groq bir xil (OpenAI-mos) chat/completions formatidan foydalanadi.
    """
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


async def analyze_food(image_bytes: bytes, content_type: str) -> dict:
    """Taom rasmini vision model (OpenAI yoki Groq) orqali tahlil qiladi.

    VISION_PROVIDER sozlamasiga qarab provayder tanlanadi. Normallashgan dict qaytaradi.
    """
    if len(image_bytes) > MAX_IMAGE_BYTES:
        raise HTTPException(
            status_code=400,
            detail="Rasm hajmi juda katta. Iltimos, kichikroq rasm yuboring (3MB gacha).",
        )

    b64 = base64.b64encode(image_bytes).decode()
    data_url = f"data:{content_type};base64,{b64}"

    def payload(model: str) -> dict:
        return {
            "model": model,
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
            "max_tokens": 1500,  # Gemini "thinking" modeli uchun zaxira token
        }

    # ZAXIRA ZANJIRI: bitta provayder band bo'lsa (Gemini 503 "high
    # demand") keyingisi ishlaydi. Ilgari bunda kaloriya hisoblagich
    # butunlay to'xtardi va foydalanuvchi "ishlamayapti" derdi.
    from app.services.ai_providers import call_with_fallback

    try:
        javob, provider, model = await call_with_fallback(
            "vision", payload, timeout=60.0
        )
    except RuntimeError as exc:
        logger.error("Vision: %s", exc)
        raise HTTPException(
            status_code=503,
            detail="AI xizmati hozircha band. Biroz keyinroq urinib ko'ring.",
        )

    try:
        content = javob["choices"][0]["message"]["content"]
        parsed = json.loads(content)
    except (KeyError, IndexError, json.JSONDecodeError) as exc:
        logger.error(f"Vision ({provider}/{model}) javobini o'qib bo'lmadi: {exc}")
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


FOOD_TEXT_SYSTEM_PROMPT = """Siz ovqat ta'rifini tahlil qiluvchi mutaxassis dietolog AI siz.
Foydalanuvchi nima yeganini MATN bilan yozadi (masalan: "2 ta non, bir piyola shirin choy"
yoki "bir kosa osh"). Shu ta'rifga qarab UMUMIY ozuqaviy qiymatni baholang.

FAQAT quyidagi JSON formatda javob bering (boshqa hech qanday matn yozmang):
{
  "is_food": true yoki false (matn ovqatni tasvirlaydimi),
  "dish_name_uz": "taom nomi o'zbekcha lotin alifbosida (qisqa umumlashma)",
  "portion_grams": taxminiy umumiy og'irlik grammda (son) yoki 0,
  "calories": umumiy kaloriya kkal (son),
  "protein_g": oqsil grammda (son),
  "fat_g": yog' grammda (son),
  "carbs_g": uglevod grammda (son),
  "confidence": 0 dan 1 gacha ishonch darajasi (son)
}

Miqdor ko'rsatilgan bo'lsa (2 ta, bir kosa) shuni hisobga oling. Agar matn ovqatga
aloqasiz bo'lsa: {"is_food": false} qaytaring."""


async def analyze_food_text(description: str) -> dict:
    """Foydalanuvchi YOZGAN ovqat ta'rifidan ozuqaviy qiymatni baholaydi (rasm emas).

    Rasmga olib bo'lmagan holatda ishlatiladi — foydalanuvchi nima yeganini yozadi,
    AI kaloriyani taxminlaydi (keyin foydalanuvchi qo'lda to'g'rilay oladi).
    """
    text = (description or "").strip()
    if not text:
        raise HTTPException(status_code=400, detail="Ovqat ta'rifi bo'sh")

    def payload(model: str) -> dict:
        return {
            "model": model,
            "messages": [
                {"role": "system", "content": FOOD_TEXT_SYSTEM_PROMPT},
                {"role": "user", "content": text},
            ],
            "response_format": {"type": "json_object"},
            "temperature": 0.2,
            "max_tokens": 1500,  # Gemini "thinking" modeli uchun zaxira token
        }

    # Matn uchun `chat` zanjiri: bu yerda rasm yo'q, shuning uchun
    # DeepSeek kabi vision'siz provayder ham ishlatilaveradi.
    from app.services.ai_providers import call_with_fallback

    try:
        javob, provider, model = await call_with_fallback(
            "chat", payload, timeout=60.0
        )
    except RuntimeError as exc:
        logger.error("Food-text: %s", exc)
        raise HTTPException(
            status_code=503,
            detail="AI xizmati hozircha band. Biroz keyinroq urinib ko'ring.",
        )

    try:
        content = javob["choices"][0]["message"]["content"]
        parsed = json.loads(content)
    except (KeyError, IndexError, json.JSONDecodeError) as exc:
        logger.error(f"Food-text ({provider}/{model}) javobini o'qib bo'lmadi: {exc}")
        raise HTTPException(status_code=502, detail="AI javobini o'qib bo'lmadi")

    if not parsed.get("is_food"):
        raise HTTPException(status_code=422, detail="Matndan taom aniqlanmadi")

    return {
        "is_food": True,
        "dish_name_uz": str(parsed.get("dish_name_uz") or text[:60]),
        "portion_grams": _num(parsed.get("portion_grams"), 0.0) or None,
        "calories": _num(parsed.get("calories")),
        "protein_g": _num(parsed.get("protein_g")),
        "fat_g": _num(parsed.get("fat_g")),
        "carbs_g": _num(parsed.get("carbs_g")),
        "confidence": min(max(_num(parsed.get("confidence"), 0.5), 0.0), 1.0),
    }


VERIFY_SYSTEM_PROMPT = """Siz rasmni tekshiruvchi AI siz. Foydalanuvchi budilnikni o'chirish uchun
ma'lum bir narsani rasmga olishi kerak. Rasmda talab qilingan narsa haqiqatan bor-yo'qligini aniqlang.

FAQAT quyidagi JSON formatda javob bering (boshqa matn yozmang):
{
  "matched": true yoki false (talab qilingan narsa rasmda aniq ko'rinyaptimi),
  "confidence": 0 dan 1 gacha ishonch darajasi (son),
  "detail_uz": "qisqa izoh o'zbekcha (nima ko'rinayotgani)"
}

Qattiqqo'l bo'ling: agar talab qilingan narsa aniq ko'rinmasa yoki shubhali bo'lsa matched=false qiling."""


async def verify_photo_contains(image_bytes: bytes, content_type: str, target: str) -> dict:
    """Budilnik vazifasi: rasmda `target` (masalan 'bathroom sink') bor-yo'qligini AI orqali tekshiradi."""
    api_url, api_key, model = _resolve_provider()
    if not api_key:
        raise HTTPException(status_code=503, detail="AI xizmati hozircha sozlanmagan")

    if len(image_bytes) > MAX_IMAGE_BYTES:
        raise HTTPException(
            status_code=400,
            detail="Rasm hajmi juda katta. Iltimos, kichikroq rasm yuboring (3MB gacha).",
        )

    b64 = base64.b64encode(image_bytes).decode()
    data_url = f"data:{content_type};base64,{b64}"
    user_text = f"{VERIFY_SYSTEM_PROMPT}\n\nTALAB QILINGAN NARSA: {target}"

    async with httpx.AsyncClient(timeout=60.0) as client:
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
                                {"type": "text", "text": user_text},
                                {"type": "image_url", "image_url": {"url": data_url}},
                            ],
                        }
                    ],
                    "response_format": {"type": "json_object"},
                    "temperature": 0.0,
                    "max_tokens": 1500,  # Gemini "thinking" modeli uchun zaxira token
                },
            )
        except httpx.HTTPError as exc:
            logger.error(f"Vision ({model}) verify so'rovi muvaffaqiyatsiz: {exc}")
            raise HTTPException(status_code=502, detail="AI xizmatiga ulanib bo'lmadi")

    if response.status_code != 200:
        logger.error(f"Vision ({model}) verify status {response.status_code}: {response.text[:300]}")
        raise HTTPException(status_code=502, detail="AI xizmati vaqtincha ishlamayapti")

    try:
        content = response.json()["choices"][0]["message"]["content"]
        parsed = json.loads(content)
    except (KeyError, IndexError, json.JSONDecodeError) as exc:
        logger.error(f"Vision ({model}) verify javobini o'qib bo'lmadi: {exc}")
        raise HTTPException(status_code=502, detail="AI javobini o'qib bo'lmadi")

    return {
        "matched": bool(parsed.get("matched")),
        "confidence": min(max(_num(parsed.get("confidence"), 0.5), 0.0), 1.0),
        "detail": str(parsed.get("detail_uz") or ""),
    }
