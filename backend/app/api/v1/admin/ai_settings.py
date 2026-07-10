"""Admin: AI provayder/model tanlovi va bo'lim (feature) flaglari.

Bularning barchasi PlatformSetting (DB) da saqlanadi va admin paneldan boshqariladi —
kod yoki .env o'zgartirmasдан kuchга kiradi.
"""
import json

from fastapi import APIRouter, Depends
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

PROVIDER_OPTIONS = ["openai", "groq", "deepseek"]


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
        provider_options=PROVIDER_OPTIONS,
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
            if prov in PROVIDER_OPTIONS:
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
