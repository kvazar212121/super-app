"""Admin: AI provayder/model tanlovi va bo'lim (feature) flaglari.

Bularning barchasi PlatformSetting (DB) da saqlanadi va admin paneldan boshqariladi —
kod yoki .env o'zgartirmasдан kuchга kiradi.
"""
import json

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from typing import Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.user import User
from app.models.category import Category
from app.api.v1.admin.dependencies import require_admin
from app.core.config import settings
from app.services import settings_service
from app.services.ai_agent import SYSTEM_PROMPT as DEFAULT_CHAT_PROMPT

router = APIRouter()


# ── AI javob prompti (chat yordamchisi qanday javob berishi) ─────────────────

class AiPromptUpdate(BaseModel):
    prompt: str = ""  # bo'sh yuborilsa — standart promptga qaytadi


@router.get("/ai-prompt")
async def get_ai_prompt(_admin: User = Depends(require_admin)):
    saved = (settings_service.get("ai_chat_prompt", "") or "").strip()
    return {
        "prompt": saved or DEFAULT_CHAT_PROMPT,
        "is_custom": bool(saved),
        "default": DEFAULT_CHAT_PROMPT,
    }


@router.put("/ai-prompt")
async def update_ai_prompt(data: AiPromptUpdate, _admin: User = Depends(require_admin)):
    settings_service.set_value("ai_chat_prompt", (data.prompt or "").strip(),
                               description="AI chat yordamchisi tizim prompti")
    saved = (settings_service.get("ai_chat_prompt", "") or "").strip()
    return {"prompt": saved or DEFAULT_CHAT_PROMPT, "is_custom": bool(saved), "default": DEFAULT_CHAT_PROMPT}


# ── Bildirishnoma shablonlari (qayta ishlatiladigan statik matnlar) ──────────

class NotifTemplate(BaseModel):
    id: Optional[str] = None
    title: str
    message: str


class NotifTemplatesUpdate(BaseModel):
    templates: list[NotifTemplate]


def _load_templates() -> list[dict]:
    raw = settings_service.get("notif_templates", "") or ""
    if not raw:
        return []
    try:
        data = json.loads(raw)
        return data if isinstance(data, list) else []
    except (json.JSONDecodeError, TypeError):
        return []


@router.get("/notif-templates")
async def get_notif_templates(_admin: User = Depends(require_admin)):
    return {"templates": _load_templates()}


@router.put("/notif-templates")
async def update_notif_templates(data: NotifTemplatesUpdate, _admin: User = Depends(require_admin)):
    items = []
    for i, t in enumerate(data.templates):
        title = (t.title or "").strip()
        message = (t.message or "").strip()
        if not title and not message:
            continue
        items.append({"id": t.id or f"tpl_{i}", "title": title, "message": message})
    settings_service.set_value("notif_templates", json.dumps(items, ensure_ascii=False),
                               description="Bildirishnoma shablonlari")
    return {"templates": items}

# Provayderlar ro'yxati YAGONA manbadan (`ai_providers`) olinadi.
# Ilgari bu yerda qo'lda yozilgan edi va yangi provayder qo'shilganda
# (Gemini) tanlov ro'yxatida ko'rinmay qolardi.
def _provider_options() -> list[str]:
    from app.services.ai_providers import PROVIDER_URLS

    return list(PROVIDER_URLS)


PROVIDER_OPTIONS = _provider_options()


class AiFeatureConf(BaseModel):
    provider: str
    model: str


class AiConfigOut(BaseModel):
    provider_options: list[str]
    vision: AiFeatureConf
    chat: AiFeatureConf
    translate: AiFeatureConf


class AiConfigUpdate(BaseModel):
    vision: Optional[AiFeatureConf] = None
    chat: Optional[AiFeatureConf] = None
    translate: Optional[AiFeatureConf] = None


def _feature_conf(feature: str, env_provider: str, groq_model: str, openai_model: str) -> AiFeatureConf:
    provider = (settings_service.get(f"ai_{feature}_provider", env_provider) or "groq").strip().lower()
    model = settings_service.get(f"ai_{feature}_model", "") or (openai_model if provider == "openai" else groq_model)
    return AiFeatureConf(provider=provider, model=model)


@router.get("/ai-config", response_model=AiConfigOut)
async def get_ai_config(_admin: User = Depends(require_admin)):
    return AiConfigOut(
        provider_options=_provider_options(),
        vision=_feature_conf("vision", settings.vision_provider, settings.groq_vision_model, settings.openai_vision_model),
        chat=_feature_conf("chat", settings.chat_provider, settings.groq_model, settings.openai_chat_model),
        translate=_feature_conf("translate", settings.translate_provider, settings.groq_translate_model, settings.openai_translate_model),
    )


@router.put("/ai-config", response_model=AiConfigOut)
async def update_ai_config(data: AiConfigUpdate, _admin: User = Depends(require_admin)):
    updates: dict[str, str] = {}
    for feature in ("vision", "chat", "translate"):
        conf = getattr(data, feature)
        if conf is not None:
            prov = (conf.provider or "").strip().lower()
            if prov in _provider_options():
                updates[f"ai_{feature}_provider"] = prov
            updates[f"ai_{feature}_model"] = conf.model.strip()
    if updates:
        settings_service.set_many(updates)
    return await get_ai_config(_admin)


# ── Feature flags ────────────────────────────────────────────────────────────

class FeatureFlag(BaseModel):
    key: str
    label: Optional[str] = None
    enabled: bool
    message: Optional[str] = None
    # Bo'lim premium obuna talab qiladimi. Masalan ish e'lonlari
    # bo'limini faqat premium foydalanuvchilarga ochish mumkin.
    premium: Optional[bool] = None


class FeatureFlagsUpdate(BaseModel):
    flags: list[FeatureFlag]


@router.get("/feature-flags")
async def get_feature_flags(_admin: User = Depends(require_admin)):
    return {"flags": settings_service.all_features()}


@router.put("/feature-flags")
async def update_feature_flags(data: FeatureFlagsUpdate, _admin: User = Depends(require_admin)):
    valid_keys = {k for k, _ in settings_service.FEATURE_DEFS}
    updates: dict[str, str] = {}
    for f in data.flags:
        if f.key not in valid_keys:
            continue
        updates[f"feature_{f.key}_enabled"] = "true" if f.enabled else "false"
        if f.message is not None:
            updates[f"feature_{f.key}_msg"] = f.message.strip()
        if f.premium is not None:
            updates[f"feature_{f.key}_premium"] = "true" if f.premium else "false"
    if updates:
        settings_service.set_many(updates)
    return {"flags": settings_service.all_features()}


# ── Xizmat kategoriyalari flaglari (26 ta xizmat) ────────────────────────────

async def _all_category_flags(db: AsyncSession) -> dict:
    cats = (await db.execute(select(Category).order_by(Category.id))).scalars().all()
    return {
        "categories": [
            {
                "key": c.key,
                "title": c.title_uz,
                "enabled": settings_service.category_enabled(c.key),
                "message": settings_service.category_message(c.key),
            }
            for c in cats
        ]
    }


@router.get("/category-flags")
async def get_category_flags(_admin: User = Depends(require_admin), db: AsyncSession = Depends(get_db)):
    return await _all_category_flags(db)


@router.put("/category-flags")
async def update_category_flags(
    data: FeatureFlagsUpdate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    valid = set((await db.execute(select(Category.key))).scalars().all())
    updates: dict[str, str] = {}
    for f in data.flags:
        if f.key not in valid:
            continue
        updates[f"cat_{f.key}_enabled"] = "true" if f.enabled else "false"
        if f.message is not None:
            updates[f"cat_{f.key}_msg"] = f.message.strip()
    if updates:
        settings_service.set_many(updates)
    return await _all_category_flags(db)


# ── Huquqiy hujjatlar (shartlar, maxfiylik, FAQ) ─────────────────────────────

class LegalUpdate(BaseModel):
    terms: Optional[str] = None
    privacy: Optional[str] = None
    faq: Optional[str] = None


@router.get("/legal")
async def get_legal_docs(_admin: User = Depends(require_admin)):
    return {
        "docs": [{"key": k, "label": lbl, "content": settings_service.get_legal(k)} for k, lbl in settings_service.LEGAL_DOCS]
    }


@router.put("/legal")
async def update_legal_docs(data: LegalUpdate, _admin: User = Depends(require_admin)):
    updates = {}
    for doc in ("terms", "privacy", "faq"):
        val = getattr(data, doc)
        if val is not None:
            updates[f"legal_{doc}"] = val
    if updates:
        settings_service.set_many(updates)
    return {
        "docs": [{"key": k, "label": lbl, "content": settings_service.get_legal(k)} for k, lbl in settings_service.LEGAL_DOCS]
    }


# ── Savdo (marketplace) sozlamalari ──────────────────────────────────────────
# Bo'limni yoqish/o'chirish va premium talab qilish `feature-flags` orqali
# (marketplace kaliti). Bu yerda RAQAMLI sozlamalar: muddat, e'lon soni,
# rasm chegarasi va uzaytirish narxi.

MARKET_SETTINGS = [
    ("market_free_days", "Oddiy e'lon muddati (kun)", 7),
    ("market_premium_days", "Premium e'lon muddati (kun)", 30),
    ("market_free_limit", "Oddiy: bir vaqtda e'lon", 5),
    ("market_premium_limit", "Premium: bir vaqtda e'lon", 50),
    ("market_min_photos", "Kamida rasm", 3),
    ("market_max_photos", "Ko'pi bilan rasm", 6),
    ("market_premium_max_photos", "Premium: ko'pi bilan rasm", 10),
    ("market_extend_price", "Uzaytirish narxi (so'm)", 5000),
]


class MarketSettingsUpdate(BaseModel):
    values: dict[str, int]


def _market_payload() -> dict:
    return {
        "settings": [
            {
                "key": k,
                "label": label,
                "default": default,
                "value": int(settings_service.get(k, "") or default),
            }
            for k, label, default in MARKET_SETTINGS
        ]
    }


@router.get("/marketplace-settings")
async def get_marketplace_settings(_admin: User = Depends(require_admin)):
    return _market_payload()


@router.put("/marketplace-settings")
async def update_marketplace_settings(
    data: MarketSettingsUpdate, _admin: User = Depends(require_admin)
):
    """Raqamli sozlamalarni yangilaydi.

    Manfiy yoki juda katta qiymat qabul qilinmaydi: admin xato yozsa
    e'lon berish butunlay to'xtab qolmasligi kerak.
    """
    ruxsat = {k for k, _l, _d in MARKET_SETTINGS}
    updates: dict[str, str] = {}
    for key, value in (data.values or {}).items():
        if key not in ruxsat:
            continue
        updates[key] = str(max(0, min(int(value), 1_000_000)))
    if updates:
        settings_service.set_many(updates)
    return _market_payload()


# ── AI provayderlar: kalit, zaxira tartibi, holat ────────────────────────────
#
# NEGA: kalitlar `.env` da qotib qolgan edi va ularni almashtirish uchun
# serverga kirib konteynerni qayta ishga tushirish kerak edi. Endi
# hammasi shu yerdan boshqariladi va ~2 soniyada kuchga kiradi.
# Bu ko'p obunachili muhitda majburiy: bitta provayder limitga urilsa
# yoki qimmatlashsa, boshqasiga darhol o'tish kerak.

class AiKeyUpdate(BaseModel):
    """Provayder kaliti. Bo'sh satr — o'chirish (env'dagisi ishlatiladi)."""

    provider: str
    api_key: str = ""


class AiProviderUpdate(BaseModel):
    feature: str                      # vision | chat | translate
    primary: Optional[str] = None     # asosiy provayder
    order: Optional[list[str]] = None  # zaxira tartibi
    models: Optional[dict[str, str]] = None  # {provayder: model}


@router.get("/ai-providers")
async def get_ai_providers(_admin: User = Depends(require_admin)):
    """Har funksiya uchun provayder holati (kalitlar YASHIRILGAN)."""
    from app.services import ai_providers

    return {
        "features": [ai_providers.admin_view(f)
                     for f in ("vision", "chat", "translate")],
        "labels": ai_providers.PROVIDER_LABELS,
        "vision_capable": list(ai_providers.VISION_PROVIDERS),
    }


@router.put("/ai-providers")
async def update_ai_providers(
    data: AiProviderUpdate, _admin: User = Depends(require_admin)
):
    """Asosiy provayder, zaxira tartibi va modellarni saqlaydi."""
    from app.services import ai_providers

    feature = (data.feature or "").strip().lower()
    if feature not in ("vision", "chat", "translate"):
        raise HTTPException(status_code=400, detail="Noma'lum funksiya")

    updates: dict[str, str] = {}

    if data.primary:
        p = data.primary.strip().lower()
        if p not in ai_providers.PROVIDER_URLS:
            raise HTTPException(status_code=400, detail="Noma'lum provayder")
        updates[f"ai_{feature}_provider"] = p

    if data.order is not None:
        toza = [x.strip().lower() for x in data.order
                if x.strip().lower() in ai_providers.PROVIDER_URLS]
        updates[f"ai_{feature}_order"] = ",".join(toza)

    for prov, model in (data.models or {}).items():
        prov = prov.strip().lower()
        if prov in ai_providers.PROVIDER_URLS:
            updates[f"ai_{feature}_{prov}_model"] = (model or "").strip()

    if updates:
        settings_service.set_many(updates)
    return await get_ai_providers(_admin)


@router.put("/ai-key")
async def update_ai_key(
    data: AiKeyUpdate, _admin: User = Depends(require_admin)
):
    """Provayder API kalitini saqlaydi.

    Kalit DB'da saqlanadi va `.env` dagisidan USTUN turadi. Bo'sh
    yuborilsa o'chiriladi va yana `.env` ishlaydi.
    """
    from app.services import ai_providers

    prov = (data.provider or "").strip().lower()
    if prov not in ai_providers.PROVIDER_URLS:
        raise HTTPException(status_code=400, detail="Noma'lum provayder")

    settings_service.set_value(f"ai_key_{prov}", (data.api_key or "").strip())
    return await get_ai_providers(_admin)


@router.post("/ai-test")
async def test_ai_provider(
    data: AiKeyUpdate, _admin: User = Depends(require_admin)
):
    """Provayder HAQIQATAN ishlayaptimi — jonli tekshiruv.

    Admin kalitni kiritgach "ishladimi?" degan savolga darhol javob
    bo'lishi kerak, aks holda nosozlik faqat foydalanuvchida chiqadi.
    """
    import httpx

    from app.services import ai_providers

    prov = (data.provider or "").strip().lower()
    if prov not in ai_providers.PROVIDER_URLS:
        raise HTTPException(status_code=400, detail="Noma'lum provayder")

    kalit = (data.api_key or "").strip() or ai_providers.api_key(prov)
    if not kalit:
        return {"ok": False, "message": "Kalit kiritilmagan"}

    model = ai_providers.model_for("chat", prov)
    try:
        async with httpx.AsyncClient(timeout=20.0) as client:
            r = await client.post(
                ai_providers.PROVIDER_URLS[prov],
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {kalit}",
                },
                json={
                    "model": model,
                    "messages": [{"role": "user", "content": "salom"}],
                    "max_tokens": 5,
                },
            )
    except Exception as exc:
        return {"ok": False, "message": f"Ulanib bo'lmadi: {type(exc).__name__}"}

    if r.status_code == 200:
        return {"ok": True, "message": f"Ishlaydi ✅ ({model})", "model": model}
    if r.status_code == 401:
        return {"ok": False, "message": "Kalit noto'g'ri (401)"}
    if r.status_code == 429:
        return {"ok": False, "message": "Limit tugagan (429)"}
    if r.status_code == 503:
        return {"ok": False, "message": "Model band (503) — zaxira ishlaydi"}
    return {"ok": False, "message": f"HTTP {r.status_code}: {r.text[:120]}"}


@router.get("/ai-models/{provider}")
async def list_provider_models(
    provider: str, _admin: User = Depends(require_admin)
):
    """Provayderда HOZIR mavjud modellar ro'yxati.

    NEGA: provayderlar model nomlarini o'zgartiradi va eskisi 404
    beradi (Groq `llama-3.3-70b-versatile` ni olib tashladi va AI
    chat ishlamay qoldi). Admin ro'yxatdan tanlasa, xato model
    yozib qo'yish imkoni yo'qoladi.
    """
    import httpx

    from app.services import ai_providers

    prov = (provider or "").strip().lower()
    if prov not in ai_providers.PROVIDER_URLS:
        raise HTTPException(status_code=400, detail="Noma'lum provayder")

    kalit = ai_providers.api_key(prov)
    if not kalit:
        return {"provider": prov, "models": [], "message": "Kalit yo'q"}

    # Modellar ro'yxati `/models` da (chat/completions emas).
    baza = ai_providers.PROVIDER_URLS[prov].rsplit("/chat/completions", 1)[0]
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            r = await client.get(
                f"{baza}/models",
                headers={"Authorization": f"Bearer {kalit}"},
            )
    except Exception as exc:
        return {"provider": prov, "models": [],
                "message": f"Ulanib bo'lmadi: {type(exc).__name__}"}

    if r.status_code != 200:
        return {"provider": prov, "models": [],
                "message": f"HTTP {r.status_code}"}

    try:
        nomlar = sorted(m["id"] for m in r.json().get("data", []))
    except Exception:
        nomlar = []

    return {
        "provider": prov,
        "models": nomlar,
        "current": ai_providers.model_for("chat", prov),
        "message": f"{len(nomlar)} ta model",
    }
