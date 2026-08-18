"""AI orqali SAVDO: e'lon berish va e'lon qidirish tool'lari.

SOTUVCHI oqimi:
    "telefonimni sotmoqchiman"
      -> start_listing_draft: AI KERAKLI MAYDONLARNI RO'YXAT qilib beradi
      -> update_listing_draft: odam yozgani qo'shiladi, qolgani so'raladi
      -> add_listing_photos: kamida 3 ta rasm
      -> publish_listing(confirm=false) -> xulosa
      -> publish_listing(confirm=true)  -> E'LON

XARIDOR oqimi:
    "telefon olmoqchiman"
      -> search_listings -> chatda GRID (20 tagacha karta)
      -> get_listing -> modal oynadagi to'liq ma'lumot

TASDIQ MAJBURIY (loyihaning umumiy qoidasi): AI o'zi e'lon
yaratmaydi, foydalanuvchi xulosani ko'rib "ha" deydi.

TELEFON RAQAMI hech qayerda qaytarilmaydi — aloqa faqat ilova ichida.
"""
from __future__ import annotations

import json
import logging

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.services.marketplace import (
    ListingDraft, close_listing, create_listing, field_checklist, get_public,
    mark_sold, my_listings, resolve_category, search_listings,
)
from app.services.marketplace.currency import to_uzs, usd_rate
from app.services.marketplace.draft import parse_condition, parse_price
from app.services.marketplace.fields import category_of, optional_checklist
from app.services.marketplace.limits import (
    disabled_message, marketplace_enabled, min_photos,
)
from app.services.marketplace.photos import check as photos_check, normalize
from app.services.marketplace.safety import warning_text
from app.services.marketplace.validator import ask_text, missing_fields

logger = logging.getLogger(__name__)

# Suhbat qoralamalari. Bazaga YOZILMAYDI — yarim e'lon xaridorlar
# qidiruviga chiqmasligi kerak.
#
# Ikki qatlam: jarayon xotirasi + Redis (2 soat).
# NEGA REDIS: prodda bir necha worker ishlaydi (WEB_CONCURRENCY).
# Foydalanuvchi ma'lumotni bir workerga yozib, "ha" ni boshqasiga
# yuborishi mumkin — o'shanda qoralama BO'SH bo'lib chiqardi va
# e'lon berilmasdi. Bu haqiqiy chiqarishda uchradi.
_DRAFTS: dict[int, ListingDraft] = {}
_REDIS_KEY = "ai_draft:market:{}"
_REDIS_TTL = 7200  # 2 soat — suhbat shuncha davom etmaydi


def _get_draft(user_id: int) -> ListingDraft:
    draft = _DRAFTS.get(user_id)
    if draft is not None:
        return draft
    try:
        from app.core.redis_client import get_redis

        raw = get_redis().get(_REDIS_KEY.format(user_id))
        if raw:
            data = json.loads(raw)
            draft = ListingDraft(
                category_key=data.get("category_key"),
                title=data.get("title"),
                description=data.get("description"),
                price=data.get("price"),
                currency=data.get("currency") or "UZS",
                is_negotiable=bool(data.get("is_negotiable")),
                condition=parse_condition(data.get("condition")),
                address=data.get("address"),
                lat=data.get("lat"),
                lng=data.get("lng"),
                attributes=data.get("attributes") or {},
                photos=list(data.get("photos") or []),
            )
            _DRAFTS[user_id] = draft
            return draft
    except Exception as exc:
        # Redis yo'q bo'lsa ham savdo ISHLASHDA DAVOM ETADI —
        # bitta worker doirasida qoralama xotirada saqlanadi.
        logger.warning("Qoralamani Redis'dan o'qib bo'lmadi: %s", exc)

    draft = ListingDraft()
    _DRAFTS[user_id] = draft
    return draft


def _save_draft(user_id: int, draft: ListingDraft) -> None:
    """Qoralamani xotiraga va Redis'ga yozadi."""
    _DRAFTS[user_id] = draft
    try:
        from app.core.redis_client import get_redis

        data = {
            "category_key": draft.category_key,
            "title": draft.title,
            "description": draft.description,
            "price": draft.price,
            "currency": draft.currency,
            "is_negotiable": draft.is_negotiable,
            "condition": draft.condition.value if draft.condition else None,
            "address": draft.address,
            "lat": draft.lat,
            "lng": draft.lng,
            "attributes": draft.attributes,
            "photos": draft.photos,
        }
        get_redis().set(
            _REDIS_KEY.format(user_id),
            json.dumps(data, ensure_ascii=False),
            ex=_REDIS_TTL,
        )
    except Exception as exc:
        logger.warning("Qoralamani Redis'ga yozib bo'lmadi: %s", exc)


def clear_draft(user_id: int) -> None:
    _DRAFTS.pop(user_id, None)
    try:
        from app.core.redis_client import get_redis

        get_redis().delete(_REDIS_KEY.format(user_id))
    except Exception:
        pass


def _lang(args: dict) -> str:
    return "ru" if str(args.get("lang") or "uz").lower() == "ru" else "uz"


def _off_response(lang: str) -> tuple[str, None]:
    """Bo'lim adminkadan o'chirilgan bo'lsa — tool ishlamaydi."""
    return json.dumps({
        "status": "disabled",
        "message": disabled_message(),
    }, ensure_ascii=False), None


def _apply(draft: ListingDraft, args: dict, ctx: dict | None) -> None:
    """AI yuborgan argumentlarni qoralamaga qo'shadi."""
    if args.get("category"):
        draft.merge(category_key=resolve_category(args.get("category")))
    if draft.category_key is None and args.get("title"):
        # Toifa aytilmasa nomdan taxmin qilamiz ("iPhone 13 sotaman").
        draft.merge(category_key=resolve_category(args.get("title")))

    narx, kelishamiz = parse_price(args.get("price"))
    valyuta = str(args.get("currency") or "").upper() or None
    if valyuta not in (None, "UZS", "USD"):
        valyuta = None

    draft.merge(
        title=args.get("title"),
        description=args.get("description"),
        price=narx,
        currency=valyuta,
        condition=parse_condition(args.get("condition")),
        address=args.get("address"),
        attributes=args.get("attributes"),
        photos=normalize(args.get("photos")),
    )
    if kelishamiz or args.get("is_negotiable"):
        draft.is_negotiable = True
    if narx is not None:
        # Narx aytilgach "kelishamiz" bekor bo'ladi (odam fikrini o'zgartirdi).
        draft.is_negotiable = bool(args.get("is_negotiable"))

    # Joylashuv: hudud bo'yicha saralash uchun. Ilova yuborgan bo'lsa.
    if ctx and draft.lat is None and ctx.get("lat") is not None:
        draft.merge(lat=ctx.get("lat"), lng=ctx.get("lng"))


def _draft_state(draft: ListingDraft, lang: str) -> dict:
    """Qoralamaning hozirgi holati — AI shu asosda gapiradi."""
    missing = missing_fields(draft)
    rasm_xato = photos_check(draft.photos, None, lang)
    return {
        "category": draft.category_key,
        "missing": missing,
        "ask_user": ask_text(draft, lang),
        "photos": len(draft.photos),
        "photos_needed": rasm_xato,
        "summary": draft.summary(lang) if not missing else None,
    }


async def start_listing_draft(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """Sotuv suhbatini boshlaydi va KERAKLI MAYDONLAR ro'yxatini beradi."""
    lang = _lang(args)
    if not marketplace_enabled():
        return _off_response(lang)

    _DRAFTS.pop(user_id, None)
    draft = ListingDraft()
    _apply(draft, args, ctx)
    if draft.category_key is None:
        draft.category_key = resolve_category(args.get("description"))
    _save_draft(user_id, draft)

    cat = category_of(draft.category_key)
    return json.dumps({
        "status": "collecting",
        "category": cat.key,
        "category_title": cat.title_ru if lang == "ru" else cat.title_uz,
        # Foydalanuvchi talabi: hammasini BIR YO'LA ro'yxat qilib bering.
        "required_fields": field_checklist(cat.key, lang),
        "optional_fields": optional_checklist(cat.key, lang),
        "min_photos": min_photos(),
        **_draft_state(draft, lang),
        "message": (
            "Покажите список одним сообщением и попросите заполнить."
            if lang == "ru" else
            "Ro'yxatni bitta xabarda ko'rsating va to'ldirishni so'rang."
        ),
    }, ensure_ascii=False), None


async def update_listing_draft(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """Qoralamaga yangi ma'lumot qo'shadi, faqat QOLGANINI so'raydi."""
    lang = _lang(args)
    if not marketplace_enabled():
        return _off_response(lang)

    draft = _get_draft(user_id)
    _apply(draft, args, ctx)
    _save_draft(user_id, draft)
    holat = _draft_state(draft, lang)
    return json.dumps({
        "status": "ready" if not holat["missing"] else "collecting",
        **holat,
    }, ensure_ascii=False), None


async def add_listing_photos(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """Rasm qo'shadi va yetarli/yetarsizligini aytadi."""
    lang = _lang(args)
    if not marketplace_enabled():
        return _off_response(lang)

    draft = _get_draft(user_id)
    draft.merge(photos=normalize(args.get("photos")))
    _save_draft(user_id, draft)
    xato = photos_check(draft.photos, None, lang)
    return json.dumps({
        "status": "need_photos" if xato else "photos_ok",
        "photos": len(draft.photos),
        "min_photos": min_photos(),
        "message": xato or ("Фото достаточно." if lang == "ru"
                            else "Rasmlar yetarli."),
        **_draft_state(draft, lang),
    }, ensure_ascii=False), None


async def publish_listing(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """E'lonni chop etadi. IKKI QADAMLI: avval xulosa, keyin confirm=true."""
    lang = _lang(args)
    if not marketplace_enabled():
        return _off_response(lang)

    draft = _get_draft(user_id)
    # Oxirgi daqiqada kelgan ma'lumot ham hisobga olinsin.
    _apply(draft, args, ctx)
    _save_draft(user_id, draft)

    missing = missing_fields(draft)
    if missing:
        return json.dumps({
            "status": "collecting",
            **_draft_state(draft, lang),
        }, ensure_ascii=False), None

    rasm_xato = photos_check(draft.photos, None, lang)
    if rasm_xato:
        return json.dumps({
            "status": "need_photos",
            "photos": len(draft.photos),
            "message": rasm_xato,
        }, ensure_ascii=False), None

    if not args.get("confirm"):
        return json.dumps({
            "status": "needs_confirmation",
            "summary": draft.summary(lang),
            "message": ("Покажите сводку и спросите: «Публикуем?»"
                        if lang == "ru" else
                        "Xulosani ko'rsatib «E'lon berilsinmi?» deb so'rang."),
        }, ensure_ascii=False), None

    user = await db.get(User, user_id)
    if user is None:
        return '{"status": "error", "message": "Foydalanuvchi topilmadi"}', None

    from fastapi import HTTPException
    try:
        listing = await create_listing(db, user, draft, lang)
    except HTTPException as exc:
        return json.dumps({
            "status": "limit_reached",
            "message": exc.detail,
        }, ensure_ascii=False), None

    clear_draft(user_id)
    return json.dumps({
        "status": "success",
        "listing_id": listing.id,
        "message": ("Объявление опубликовано. Покупатели уже видят его."
                    if lang == "ru" else
                    "E'lon joylandi. Xaridorlar uni ko'ra boshlaydi."),
    }, ensure_ascii=False), {"type": "listings_changed",
                             "listing_id": listing.id}


async def search_listings_tool(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """Xaridor qidiruvi. Natija chatda GRID bo'lib ko'rsatiladi."""
    lang = _lang(args)
    if not marketplace_enabled():
        return _off_response(lang)

    lat = args.get("lat")
    lng = args.get("lng")
    if lat is None and ctx:
        lat, lng = ctx.get("lat"), ctx.get("lng")

    items = await search_listings(
        db,
        query=args.get("query"),
        category=args.get("category"),
        price_min=args.get("price_min"),
        price_max=args.get("price_max"),
        condition=args.get("condition"),
        lat=lat, lng=lng,
        sort=str(args.get("sort") or "relevant"),
        exclude_user_id=user_id,
    )

    if not items:
        return json.dumps({
            "status": "empty",
            "message": ("Ничего не найдено. Предложите изменить фильтры."
                        if lang == "ru" else
                        "Hech narsa topilmadi. Shartlarni o'zgartirishni taklif qiling."),
        }, ensure_ascii=False), None

    # Model uchun qisqa ro'yxat (butun tavsif kerak emas — tokenlar).
    qisqa = [{
        "id": i["id"], "title": i["title"], "price_uzs": i["price_uzs"],
        "condition": i["condition"], "distance_km": i["distance_km"],
    } for i in items]

    return json.dumps({
        "status": "success",
        "count": len(items),
        "listings": qisqa,
        "message": ("Кратко скажите, сколько нашли. Карточки покажет приложение."
                    if lang == "ru" else
                    "Nechta topilganini qisqa ayting. Kartalarni ilova ko'rsatadi."),
    }, ensure_ascii=False), {"type": "listing_grid", "listings": items}


async def get_listing_tool(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """Bitta e'lonning to'liq ma'lumoti (modal oyna uchun)."""
    lang = _lang(args)
    if not marketplace_enabled():
        return _off_response(lang)

    listing_id = args.get("listing_id")
    if not listing_id:
        return '{"status": "error", "message": "listing_id kerak"}', None

    from fastapi import HTTPException
    try:
        data = await get_public(db, int(listing_id), viewer_id=user_id)
    except HTTPException as exc:
        return json.dumps({"status": "error", "message": exc.detail},
                          ensure_ascii=False), None

    return json.dumps({
        "status": "success",
        "listing": data,
        # Aloqadan OLDIN ogohlantirish — foydalanuvchi majburiy dedi.
        "safety_warning": warning_text(lang),
        "message": ("Телефон продавца не выдаётся: общение только в приложении."
                    if lang == "ru" else
                    "Sotuvchi raqami berilmaydi: aloqa faqat ilova ichida."),
    }, ensure_ascii=False), {"type": "listing_detail", "listing": data}


async def my_listings_tool(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """«Mening e'lonlarim» — holati va qolgan muddati bilan."""
    lang = _lang(args)
    if not marketplace_enabled():
        return _off_response(lang)

    rows = await my_listings(db, user_id)
    rate = await usd_rate()
    items = [r.to_dict(price_uzs=to_uzs(r.price, r.currency, rate))
             for r in rows]
    return json.dumps({
        "status": "success",
        "count": len(items),
        "listings": [{"id": i["id"], "title": i["title"],
                      "status": i["status"], "views": i["views"],
                      "expires_at": i["expires_at"]} for i in items],
    }, ensure_ascii=False), {"type": "my_listings", "listings": items}


async def close_listing_tool(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """E'lonni «sotildi» qilish yoki yashirish. TASDIQ bilan."""
    lang = _lang(args)
    if not marketplace_enabled():
        return _off_response(lang)

    listing_id = args.get("listing_id")
    if not listing_id:
        return '{"status": "error", "message": "listing_id kerak"}', None
    sotildi = bool(args.get("sold", True))

    if not args.get("confirm"):
        return json.dumps({
            "status": "needs_confirmation",
            "listing_id": int(listing_id),
            "message": (("Объявление будет отмечено как проданное."
                         if sotildi else "Объявление будет скрыто.")
                        if lang == "ru" else
                        ("E'lon «sotildi» deb belgilanadi."
                         if sotildi else "E'lon yashiriladi.")),
        }, ensure_ascii=False), None

    from fastapi import HTTPException
    try:
        amal = mark_sold if sotildi else close_listing
        listing = await amal(db, user_id, int(listing_id))
    except HTTPException as exc:
        return json.dumps({"status": "error", "message": exc.detail},
                          ensure_ascii=False), None

    return json.dumps({
        "status": "success",
        "listing_id": listing.id,
        "new_status": listing.status.value,
    }, ensure_ascii=False), {"type": "listings_changed",
                             "listing_id": listing.id}


HANDLERS = {
    "start_listing_draft": start_listing_draft,
    "update_listing_draft": update_listing_draft,
    "add_listing_photos": add_listing_photos,
    "publish_listing": publish_listing,
    "search_listings": search_listings_tool,
    "get_listing": get_listing_tool,
    "my_listings": my_listings_tool,
    "close_listing": close_listing_tool,
}
