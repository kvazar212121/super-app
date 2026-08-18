"""AI provayderlarni BOSHQARISH — kalit, model va ZAXIRA zanjiri.

Nima uchun alohida modul:

1. **Zaxira (fallback).** Bitta provayder ishlamay qolsa (Gemini
   "high demand" 503 beradi, Groq limitga uriladi) butun funksiya
   to'xtab qolardi. Endi ro'yxat bo'ylab keyingisiga o'tiladi.
2. **Adminkadan boshqarish.** Kalitlar `.env` da qotib qolgan edi va
   ularni o'zgartirish uchun serverga kirib, konteynerni qayta ishga
   tushirish kerak edi. Endi kalit ham, model ham, zaxira tartibi ham
   admin panelidan o'zgaradi va ~2 soniyada kuchga kiradi.
3. **Vision qo'llab-quvvatlashi.** Har model rasmni ko'ra olmaydi
   (masalan DeepSeek chat modeli). Rasm tahliliga faqat vision
   qo'llab-quvvatlaydigan provayderlar tanlanadi.

Ustuvorlik: admin sozlamasi (DB) → `.env` → standart qiymat.
"""
from __future__ import annotations

import logging

logger = logging.getLogger(__name__)

# Barcha provayderlar OpenAI-mos `/chat/completions` formatidan
# foydalanadi, shuning uchun kod bitta.
PROVIDER_URLS: dict[str, str] = {
    "openai": "https://api.openai.com/v1/chat/completions",
    "gemini": "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions",
    "groq": "https://api.groq.com/openai/v1/chat/completions",
    "deepseek": "https://api.deepseek.com/v1/chat/completions",
    # Quyidagilar ham OpenAI-mos: kalit qo'yilsa darhol ishlaydi.
    "openrouter": "https://openrouter.ai/api/v1/chat/completions",
    "mistral": "https://api.mistral.ai/v1/chat/completions",
    "together": "https://api.together.xyz/v1/chat/completions",
    "xai": "https://api.x.ai/v1/chat/completions",
    "anthropic": "https://api.anthropic.com/v1/chat/completions",
}

# Provayder odam o'qiydigan nom (admin panelida ko'rinadi).
PROVIDER_LABELS: dict[str, str] = {
    "openai": "OpenAI (ChatGPT)",
    "gemini": "Google Gemini",
    "groq": "Groq",
    "deepseek": "DeepSeek",
    "openrouter": "OpenRouter (ko'p model)",
    "mistral": "Mistral AI",
    "together": "Together AI",
    "xai": "xAI (Grok)",
    "anthropic": "Anthropic (Claude)",
}

# RASMNI ko'ra oladigan provayderlar.
#
# DeepSeek'ning ommaviy chat modeli rasmni QABUL QILMAYDI — uni
# vision uchun tanlash "invalid request" beradi. Shuning uchun u
# rasm tahlilidan chetlab o'tiladi.
VISION_PROVIDERS = ("openai", "gemini", "openrouter", "xai", "anthropic",
                    "together", "mistral")

# Zaxira tartibi (standart). Admin buni o'zgartirishi mumkin.
#
# Gemini birinchi: rasm tahlili uchun bepul limiti katta. U band
# bo'lsa (503) OpenAI, keyin Groq ishlaydi.
DEFAULT_VISION_ORDER = ("openai", "gemini", "openrouter", "xai")
DEFAULT_CHAT_ORDER = ("openai", "gemini", "deepseek", "groq", "openrouter")

# Provayder ishlamay qolganda shu vaqtga chetlab o'tiladi (soniya).
# Har so'rovda qayta urinish sekinlik va bekorga xarajat.
COOLDOWN_SECONDS = 120

# {provayder: qachongacha ishlatilmaydi (unix vaqt)}
_cooldown: dict[str, float] = {}


def _sozlama(kalit: str, standart: str = "") -> str:
    """Admin sozlamasini o'qiydi (DB ishlamasa bo'sh qaytaradi)."""
    try:
        from app.services import settings_service

        return (settings_service.get(kalit, "") or "").strip()
    except Exception:
        return standart


def api_key(provider: str) -> str:
    """Provayder kaliti: avval adminkadan, keyin `.env` dan.

    Adminkadan kiritilgan kalit ustun turadi — shunda kalitni
    almashtirish uchun serverga kirish shart emas.
    """
    from app.core.config import settings

    admin_kalit = _sozlama(f"ai_key_{provider}")
    if admin_kalit:
        return admin_kalit

    # `.env` da faqat asosiy to'rttasi bor; qolganlari FAQAT
    # adminkadan kiritiladi (kod o'zgartirish shart emas).
    return {
        "openai": settings.openai_api_key,
        "groq": settings.groq_api_key,
        "deepseek": settings.deepseek_api_key,
        "gemini": settings.gemini_api_key,
    }.get(provider, "")


def model_for(feature: str, provider: str) -> str:
    """Shu funksiya va provayder uchun model nomi."""
    from app.core.config import settings

    # 1) Aniq juftlik: `ai_vision_gemini_model`
    aniq = _sozlama(f"ai_{feature}_{provider}_model")
    if aniq:
        return aniq

    # 2) Funksiya uchun umumiy: `ai_vision_model`
    #    DIQQAT: bu faqat ASOSIY provayderga tegishli, aks holda
    #    zaxiraga o'tganda boshqa provayderning modeli yuborilardi.
    if provider == primary_provider(feature):
        umumiy = _sozlama(f"ai_{feature}_model")
        if umumiy:
            return umumiy

    # 3) `.env` dagi standart
    vision = feature == "vision"
    standart = {
        "openai": (settings.openai_vision_model if vision
                   else settings.openai_chat_model),
        "groq": (settings.groq_vision_model if vision
                 else settings.groq_chat_model),
        "gemini": (settings.gemini_vision_model if vision
                   else settings.gemini_chat_model),
        "deepseek": settings.deepseek_chat_model,
        # Qo'shimcha provayderlar uchun keng tarqalgan modellar.
        # Boshqasini xohlasangiz adminkadan yozasiz.
        "openrouter": ("openai/gpt-4o-mini" if vision
                       else "openai/gpt-4o-mini"),
        "mistral": ("pixtral-12b-2409" if vision else "mistral-small-latest"),
        "together": ("meta-llama/Llama-Vision-Free" if vision
                     else "meta-llama/Llama-3.3-70B-Instruct-Turbo-Free"),
        "xai": ("grok-2-vision-1212" if vision else "grok-2-1212"),
        "anthropic": "claude-3-5-sonnet-20241022",
    }
    return standart.get(provider, "")


def primary_provider(feature: str) -> str:
    """Asosiy provayder (adminkadan yoki `.env` dan)."""
    from app.core.config import settings

    tanlov = _sozlama(f"ai_{feature}_provider")
    if tanlov in PROVIDER_URLS:
        return tanlov
    env = (settings.vision_provider if feature == "vision"
           else settings.chat_provider)
    env = (env or "").strip().lower()
    return env if env in PROVIDER_URLS else "gemini"


def provider_order(feature: str) -> list[str]:
    """Urinish tartibi: asosiy, keyin zaxiralar.

    Admin `ai_vision_order = "openai,groq"` deb yozishi mumkin.
    """
    standart = (DEFAULT_VISION_ORDER if feature == "vision"
                else DEFAULT_CHAT_ORDER)

    xom = _sozlama(f"ai_{feature}_order")
    if xom:
        royxat = [p.strip().lower() for p in xom.replace(";", ",").split(",")]
        royxat = [p for p in royxat if p in PROVIDER_URLS]
    else:
        royxat = list(standart)

    # Asosiy provayder DOIM birinchi bo'ladi.
    asosiy = primary_provider(feature)
    if asosiy in royxat:
        royxat.remove(asosiy)
    royxat.insert(0, asosiy)

    # Rasm tahlilida faqat vision qo'llab-quvvatlaydiganlar.
    if feature == "vision":
        royxat = [p for p in royxat if p in VISION_PROVIDERS]

    # Kaliti yo'q provayderni urinib ko'rish — bekorga kechikish.
    return [p for p in royxat if api_key(p)]


def mark_failed(provider: str) -> None:
    """Provayder ishlamadi — bir muddat chetlab o'tiladi."""
    import time

    _cooldown[provider] = time.time() + COOLDOWN_SECONDS
    logger.warning("AI provayder '%s' %d soniyaga chetlab o'tiladi",
                   provider, COOLDOWN_SECONDS)


def _is_cooling(provider: str) -> bool:
    import time

    tugash = _cooldown.get(provider)
    if tugash is None:
        return False
    if time.time() >= tugash:
        _cooldown.pop(provider, None)
        return False
    return True


def candidates(feature: str) -> list[tuple[str, str, str, str]]:
    """Urinish uchun ro'yxat: (provider, url, key, model).

    Cooldown'dagilar oxiriga suriladi — butunlay tashlab yuborilmaydi,
    chunki hammasi cooldown'da bo'lsa hech narsa qolmasdi.
    """
    tayyor: list[tuple[str, str, str, str]] = []
    kutayotgan: list[tuple[str, str, str, str]] = []

    for p in provider_order(feature):
        element = (p, PROVIDER_URLS[p], api_key(p), model_for(feature, p))
        if not element[3]:  # model nomi yo'q
            continue
        (kutayotgan if _is_cooling(p) else tayyor).append(element)

    return tayyor + kutayotgan


def admin_view(feature: str) -> dict:
    """Admin panel uchun holat (kalitlar YASHIRILGAN holda)."""
    def niqob(k: str) -> str:
        if not k:
            return ""
        return f"{k[:4]}…{k[-4:]}" if len(k) > 10 else "…"

    return {
        "feature": feature,
        "primary": primary_provider(feature),
        "order": provider_order(feature),
        "providers": [
            {
                "key": p,
                "label": PROVIDER_LABELS.get(p, p),
                "model": model_for(feature, p),
                "has_key": bool(api_key(p)),
                "key_preview": niqob(api_key(p)),
                "supports_vision": p in VISION_PROVIDERS,
                "cooling": _is_cooling(p),
            }
            for p in PROVIDER_URLS
        ],
    }


def adapt_payload(provider: str, model: str, payload: dict) -> dict:
    """So'rov tanasini provayder/model talabiga moslashtiradi.

    NEGA KERAK: OpenAI'ning yangi avlod modellari (gpt-5*, o1*, o3*)
    eski parametrlarni RAD ETADI:
      • `max_tokens` → `max_completion_tokens` bo'lishi kerak
      • `temperature` umuman qo'llab-quvvatlanmaydi (faqat standart)
    Bu 400 xatoga olib keladi va foydalanuvchi "taomni aniqlashda
    xatolik" degan xabarni ko'radi. Model nomini adminkadan
    o'zgartirish mumkin bo'lgani uchun bu holat kutilishi shart.
    """
    tana = dict(payload)
    tana["model"] = model
    nom = (model or "").lower()

    yangi_avlod = (
        provider == "openai"
        and (nom.startswith("gpt-5") or nom.startswith("o1")
             or nom.startswith("o3") or nom.startswith("o4"))
    )
    if yangi_avlod:
        if "max_tokens" in tana:
            tana["max_completion_tokens"] = tana.pop("max_tokens")
        # Faqat standart (1.0) qabul qilinadi — o'zgartirilganini
        # yuborsak 400 qaytadi.
        tana.pop("temperature", None)

    return tana


async def call_with_fallback(
    feature: str,
    payload_builder,
    *,
    timeout: float = 45.0,
    retry_statuses: tuple[int, ...] = (429, 500, 502, 503, 504),
) -> tuple[dict, str, str]:
    """Provayderlarni NAVBAT bilan sinab, birinchi muvaffaqiyatlisini qaytaradi.

    `payload_builder(model)` — model nomiga qarab so'rov tanasini
    qaytaradigan funksiya (har provayderning modeli boshqacha).

    Qaytaradi: (javob_json, provider, model)

    Nega kerak: Gemini "high demand" (503) berganda kaloriya
    hisoblagich butunlay ishlamay qolardi. Endi keyingi provayderga
    o'tiladi va foydalanuvchi buni sezmaydi.
    """
    import httpx

    royxat = candidates(feature)
    if not royxat:
        raise RuntimeError(
            f"'{feature}' uchun AI provayder sozlanmagan "
            "(admin panel → AI provayder va modellar)"
        )

    oxirgi_xato = ""
    for provider, url, key, model in royxat:
        try:
            async with httpx.AsyncClient(timeout=timeout) as client:
                javob = await client.post(
                    url,
                    headers={
                        "Content-Type": "application/json",
                        "Authorization": f"Bearer {key}",
                    },
                    json=adapt_payload(provider, model, payload_builder(model)),
                )
        except Exception as exc:
            oxirgi_xato = f"{provider}: {type(exc).__name__}"
            logger.warning("AI (%s/%s) ulanmadi: %s", provider, model, exc)
            mark_failed(provider)
            continue

        if javob.status_code == 200:
            if len(royxat) > 1 and provider != royxat[0][0]:
                logger.info("AI zaxira provayderi ishladi: %s/%s",
                            provider, model)
            return javob.json(), provider, model

        oxirgi_xato = f"{provider}: HTTP {javob.status_code}"
        logger.warning("AI (%s/%s) status %s: %s", provider, model,
                       javob.status_code, javob.text[:200])
        # Vaqtinchalik xatolarda keyingi provayderga o'tamiz.
        # 400/401 esa BIZNING xato (noto'g'ri kalit yoki so'rov) —
        # boshqa provayderda ham takrorlanadi, lekin baribir
        # urinib ko'ramiz: kalit faqat bittasida buzuq bo'lishi mumkin.
        if javob.status_code in retry_statuses or javob.status_code == 401:
            mark_failed(provider)
        continue

    raise RuntimeError(f"Barcha AI provayderlar javob bermadi ({oxirgi_xato})")
