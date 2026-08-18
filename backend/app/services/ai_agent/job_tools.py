"""AI orqali ish e'loni berish tool'lari.

Foydalanuvchi oqimi:
    "shu joyni tamirlash kerak, ertaga" + rasm
        -> AI start_job_draft chaqiradi
        -> yetishmagan ma'lumot bo'lsa AI SO'RAYDI
        -> update_job_draft bilan to'ldiradi
        -> publish_job(confirm=false) -> xulosa qaytadi
        -> foydalanuvchi "ha" deydi
        -> publish_job(confirm=true) -> E'LON YARATILADI

TASDIQ MAJBURIY: foydalanuvchi "ai o'zi yubormasin, tasdiq so'rasin"
dedi. Shu sababli publish_job confirm=true bo'lmasa e'lon
yaratmaydi — bu create_booking va cancel_order bilan bir xil naqsh.

Qoralama SUHBAT ICHIDA saqlanadi (bazaga yozilmaydi): yarim yozilgan
e'lon ustalar lentasiga chiqib qolmasligi kerak.
"""
from __future__ import annotations

import json
import logging
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.category import Category
from app.models.user import User
from app.services.ai_job import JobDraft, check_can_create_job
from app.services.ai_job.limits import expires_at_for
from app.services.ai_job.validator import missing_fields, next_question
from app.services.job_service import JobService

logger = logging.getLogger(__name__)

# Suhbat qoralamalari: {user_id: JobDraft}
# Jarayon xotirasida — bir suhbat davomida yashaydi. Server qayta
# ishga tushsa yo'qoladi, bu qabul qilinadi: foydalanuvchi qaytadan
# aytadi, e'lon esa hech qachon yarim holatda saqlanmaydi.
#
# Savdo qoralamasi kabi, bu ham Redis'da dublikatlanadi: prodda bir
# necha worker ishlaydi va foydalanuvchi ma'lumotni bir workerga
# yozib, tasdiqni boshqasiga yuborishi mumkin.
_DRAFTS: dict[int, JobDraft] = {}
_REDIS_KEY = "ai_draft:job:{}"
_REDIS_TTL = 7200


def _get_draft(user_id: int) -> JobDraft:
    draft = _DRAFTS.get(user_id)
    if draft is not None:
        return draft
    try:
        from app.core.redis_client import get_redis

        raw = get_redis().get(_REDIS_KEY.format(user_id))
        if raw:
            data = json.loads(raw)
            draft = JobDraft(
                category_id=data.get("category_id"),
                title=data.get("title"),
                description=data.get("description"),
                address=data.get("address"),
                photos=list(data.get("photos") or []),
                budget=data.get("budget"),
                needed_at=_parse_datetime(data.get("needed_at")),
                lat=data.get("lat"),
                lng=data.get("lng"),
            )
            _DRAFTS[user_id] = draft
            return draft
    except Exception as exc:
        logger.warning("Ish qoralamasini Redis'dan o'qib bo'lmadi: %s", exc)

    draft = JobDraft()
    _DRAFTS[user_id] = draft
    return draft


def _save_draft(user_id: int, draft: JobDraft) -> None:
    _DRAFTS[user_id] = draft
    try:
        from app.core.redis_client import get_redis

        data = {
            "category_id": draft.category_id,
            "title": draft.title,
            "description": draft.description,
            "address": draft.address,
            "photos": draft.photos,
            "budget": draft.budget,
            "needed_at": (draft.needed_at.isoformat()
                          if draft.needed_at else None),
            "lat": draft.lat,
            "lng": draft.lng,
        }
        get_redis().set(
            _REDIS_KEY.format(user_id),
            json.dumps(data, ensure_ascii=False),
            ex=_REDIS_TTL,
        )
    except Exception as exc:
        logger.warning("Ish qoralamasini Redis'ga yozib bo'lmadi: %s", exc)


def clear_draft(user_id: int) -> None:
    _DRAFTS.pop(user_id, None)
    try:
        from app.core.redis_client import get_redis

        get_redis().delete(_REDIS_KEY.format(user_id))
    except Exception:
        pass


async def _resolve_category(db: AsyncSession, hint: str | None) -> Category | None:
    """Kategoriya kalitidan (yoki nomidan) kategoriyani topadi.

    AI ba'zan "electrician" o'rniga "elektrik" deb yuboradi, shuning
    uchun kalit bo'yicha ham, nom bo'yicha ham qidiramiz.
    """
    if not hint:
        return None
    text = str(hint).strip().lower()
    if not text:
        return None

    rows = (await db.execute(select(Category))).scalars().all()
    # 1) Aniq kalit mosligi
    for cat in rows:
        if (cat.key or "").lower() == text:
            return cat
    # 2) Nom ichida qidirish (uz)
    for cat in rows:
        title = (cat.title_uz or "").lower()
        if text and (text in title or title in text):
            return cat
    return None


def _parse_datetime(value) -> datetime | None:
    """AI yuborgan sanani o'qiydi. Xato bo'lsa None (e'lon baribir chiqadi)."""
    if not value:
        return None
    if isinstance(value, datetime):
        return value
    try:
        text = str(value).replace("Z", "+00:00")
        dt = datetime.fromisoformat(text)
        return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
    except (TypeError, ValueError):
        return None


def _lang_of(args: dict) -> str:
    return "ru" if str(args.get("lang") or "uz").lower() == "ru" else "uz"


async def start_job_draft(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """Yangi e'lon qoralamasini boshlaydi (eskisini o'chiradi)."""
    _DRAFTS.pop(user_id, None)
    _save_draft(user_id, JobDraft())
    return await update_job_draft(db, user_id, args, ctx)


async def update_job_draft(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """Qoralamaga yangi ma'lumot qo'shadi va nima yetishmayotganini aytadi."""
    draft = _get_draft(user_id)
    lang = _lang_of(args)

    category = await _resolve_category(db, args.get("category"))
    photos = args.get("photos")
    if isinstance(photos, str):
        photos = [photos]

    draft.merge(
        category_id=category.id if category else None,
        title=args.get("title"),
        description=args.get("description"),
        address=args.get("address"),
        budget=args.get("budget"),
        needed_at=_parse_datetime(args.get("needed_at")),
        photos=photos if isinstance(photos, list) else None,
    )

    # Foydalanuvchi joylashuvi (ilova yuborgan bo'lsa) — hudud
    # filtri uchun MUHIM: koordinatasiz e'lon hamma ustaga ko'rinadi.
    if ctx and draft.lat is None and ctx.get("lat") is not None:
        draft.merge(lat=ctx.get("lat"), lng=ctx.get("lng"))

    _save_draft(user_id, draft)

    missing = missing_fields(draft)
    if missing:
        return json.dumps({
            "status": "needs_more_info",
            "missing": missing,
            "ask_user": next_question(draft, lang),
            "collected": {
                "title": draft.title,
                "address": draft.address,
                "category_id": draft.category_id,
            },
        }, ensure_ascii=False), None

    cat_title = None
    if draft.category_id:
        cat = await db.get(Category, draft.category_id)
        cat_title = cat.title_uz if cat else None

    summary = draft.summary_ru(cat_title) if lang == "ru" else draft.summary_uz(cat_title)
    return json.dumps({
        "status": "ready",
        "summary": summary,
        "message": (
            "Покажите пользователю сводку и спросите подтверждение."
            if lang == "ru"
            else "Foydalanuvchiga xulosani ko'rsatib tasdiq so'rang."
        ),
    }, ensure_ascii=False), None


async def publish_job(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """Qoralamani HAQIQIY e'longa aylantiradi. Faqat confirm=true bilan."""
    draft = _get_draft(user_id)
    lang = _lang_of(args)

    # Oxirgi daqiqada kelgan ma'lumot ham qabul qilinsin
    if any(args.get(k) for k in ("title", "description", "address", "category")):
        await update_job_draft(db, user_id, args, ctx)
        draft = _get_draft(user_id)

    # Joylashuv: tasdiq bosqichida ham qo'shilishi kerak.
    # Ilgari u faqat update_job_draft ichida qo'shilardi, ya'ni
    # foydalanuvchi "ha" deganda (boshqa maydonsiz) koordinata
    # YO'QOLARDI va e'lon hudud filtriga tushmay, BUTUN respublika
    # ustalariga ko'rinib ketardi.
    if ctx and draft.lat is None and ctx.get("lat") is not None:
        draft.merge(lat=ctx.get("lat"), lng=ctx.get("lng"))

    missing = missing_fields(draft)
    if missing:
        return json.dumps({
            "status": "needs_more_info",
            "missing": missing,
            "ask_user": next_question(draft, lang),
        }, ensure_ascii=False), None

    cat_title = None
    if draft.category_id:
        cat = await db.get(Category, draft.category_id)
        cat_title = cat.title_uz if cat else None
    summary = draft.summary_ru(cat_title) if lang == "ru" else draft.summary_uz(cat_title)

    # ── TASDIQ SHART ─────────────────────────────────────────────────
    # Foydalanuvchi: "ha tasdiq so'rasin". AI xato tushunsa, ustalar
    # noto'g'ri e'longa taklif berib vaqt yo'qotadi.
    if not args.get("confirm"):
        return json.dumps({
            "status": "needs_confirmation",
            "summary": summary,
            "message": (
                "Покажите сводку и спросите: «Publikovat?»"
                if lang == "ru"
                else "Xulosani ko'rsatib «E'lon berilsinmi?» deb so'rang."
            ),
        }, ensure_ascii=False), None

    user = await db.get(User, user_id)
    if user is None:
        return '{"status": "error", "message": "Foydalanuvchi topilmadi"}', None

    # Chegara: 3 ta ochiq e'lon (premium 20). Xato tushunarli bo'ladi.
    from fastapi import HTTPException
    try:
        await check_can_create_job(db, user, lang)
    except HTTPException as exc:
        return json.dumps({
            "status": "limit_reached",
            "message": exc.detail,
        }, ensure_ascii=False), None

    payload = draft.to_job_payload()
    # Muddat: oddiy foydalanuvchiga 5 kun, premiumga cheksiz
    expires = expires_at_for(user)
    if expires is not None:
        payload["expires_at"] = expires

    try:
        job = await JobService.create(db, user_id, payload)
    except HTTPException as exc:
        return json.dumps({
            "status": "error",
            "message": exc.detail,
        }, ensure_ascii=False), None

    clear_draft(user_id)
    return json.dumps({
        "status": "success",
        "job_id": job.id,
        "message": (
            f"Заявка опубликована. Мастера рядом её увидят."
            if lang == "ru"
            else "E'lon berildi. Yaqin atrofdagi ustalar uni ko'radi."
        ),
    }, ensure_ascii=False), {"type": "jobs_changed", "job_id": job.id}


HANDLERS = {
    "start_job_draft": start_job_draft,
    "update_job_draft": update_job_draft,
    "publish_job": publish_job,
}
