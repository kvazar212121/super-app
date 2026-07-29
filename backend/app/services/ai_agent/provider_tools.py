"""Xizmat provayderlari toollari: qidiruv (QAT'IY filtrli) va bron yaratish.

QAT'IY QOIDA: kategoriya yoki nom bo'yicha ANIQ moslik topilmasa — hech narsa
qaytarilmaydi (barcha providerlarni aralashtirib "to'kib tashlash" YO'Q).
AI natija topilmaganda foydalanuvchidan xizmat turini aniqlashtiradi.
"""
import json
import logging
import math
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger(__name__)

# Masofa bo'yicha saralashda nechta nomzod olinadi (keyin Python'да saralanadi)
_DISTANCE_CANDIDATES = 200


def _distance_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Ikki nuqta orasidagi masofa (km) — haversine formulasi."""
    r = 6371.0  # Yer radiusi (km)
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lng2 - lng1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


async def search_providers(db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None) -> tuple[str, dict | None]:
    from app.models.provider import Provider
    from app.models.category import Category

    category_key = (args.get("category_key") or "").strip().lower()
    query = (args.get("service_query") or "").strip()
    location = (args.get("location") or "").strip()
    try:
        limit = int(args.get("limit") or 10)
    except (TypeError, ValueError):
        limit = 10
    limit = max(1, min(limit, 15))  # 1..15 oralig'i

    # ── "Eng yaqin" — foydalanuvchi joylashuvi bo'yicha saralash ──
    sort_by = (args.get("sort_by") or "").strip().lower()
    user_lat = user_lng = None
    if ctx:
        try:
            if ctx.get("lat") is not None and ctx.get("lng") is not None:
                user_lat, user_lng = float(ctx["lat"]), float(ctx["lng"])
        except (TypeError, ValueError):
            user_lat = user_lng = None
    by_distance = sort_by == "distance" and user_lat is not None

    cats = (await db.execute(select(Category))).scalars().all()
    cat_by_id = {c.id: c for c in cats}

    # ── Kategoriya aniqlash (qat'iy tartibda) ──
    matched_cat = None
    # 1) AI bergan category_key — aniq moslik (asosiy yo'l)
    if category_key:
        for c in cats:
            if (c.key or "").lower() == category_key:
                matched_cat = c
                break
    # 2) service_query key/nomga TO'LIQ mos kelsa
    ql = query.lower()
    if not matched_cat and ql:
        for c in cats:
            if (c.key or "").lower() == ql or (c.title_uz or "").lower() == ql:
                matched_cat = c
                break
    # 3) Qisman moslik — ENG UZUN mos kelgan kategoriya g'olib
    #    (masalan "sartaroshxona" ichida "sartarosh" bor → sartarosh)
    if not matched_cat and ql:
        best: tuple[int, object] | None = None
        for c in cats:
            key_l = (c.key or "").lower()
            name_l = (c.title_uz or "").lower()
            score = 0
            if key_l and (key_l in ql or ql in key_l):
                score = max(score, len(key_l))
            if name_l and (name_l in ql or ql in name_l):
                score = max(score, len(name_l))
            if score >= 4 and (best is None or score > best[0]):
                best = (score, c)
        if best:
            matched_cat = best[1]

    # Mobil ilova bilan bir xil filter: is_active + not paused + not blocked
    base_filter = [
        Provider.is_active == True,
        Provider.is_paused == False,
        Provider.is_blocked == False,
    ]

    # Masofa bo'yicha saralashда ko'proq nomzod olamiz (saralash Python'да),
    # aks holda to'g'ridan-to'g'ri reyting bo'yicha limit qo'yamiz.
    sql_limit = _DISTANCE_CANDIDATES if by_distance else limit

    provs = []
    matched_by_name = False
    if matched_cat:
        # FAQAT shu kategoriya — boshqa kategoriyalar ARALASHMAYDI
        pstmt = select(Provider).where(*base_filter, Provider.category_id == matched_cat.id)
        if location:
            pstmt = pstmt.where(Provider.address.ilike(f"%{location}%"))
        pstmt = pstmt.order_by(Provider.rating.desc()).limit(sql_limit)
        provs = (await db.execute(pstmt)).scalars().all()
    elif query:
        # Kategoriya aniqlanmadi — provider NOMI bo'yicha maqsadli qidiruv
        pstmt = select(Provider).where(*base_filter, Provider.name.ilike(f"%{query}%"))
        if location:
            pstmt = pstmt.where(Provider.address.ilike(f"%{location}%"))
        pstmt = pstmt.order_by(Provider.rating.desc()).limit(sql_limit)
        provs = (await db.execute(pstmt)).scalars().all()
        matched_by_name = bool(provs)

    # Eng yaqindan saralab, so'ralган songa qisqartiramiz
    if by_distance and provs:
        provs = sorted(
            provs,
            key=lambda p: _distance_km(user_lat, user_lng, p.lat or 0.0, p.lng or 0.0),
        )[:limit]

    # ── Hech narsa topilmadi: aralash ro'yxat O'RNIGA aniqlashtirish so'raymiz ──
    if not provs:
        return json.dumps({
            "status": "not_found",
            "message": (
                "Mos xizmat/usta topilmadi. Foydalanuvchidan qaysi xizmat turi kerakligini "
                "aniqlashtiring va quyidagi mavjud kategoriyalardan birini taklif qiling."
            ),
            "available_categories": [{"key": c.key, "name": c.title_uz} for c in cats],
        }, ensure_ascii=False), None

    results = []
    seen_ids: set[int] = set()
    for p in provs:
        if p.id in seen_ids:
            continue
        seen_ids.add(p.id)
        pcat = cat_by_id.get(p.category_id)
        row = {
            "id": p.id, "name": p.name, "category_id": p.category_id,
            "category_key": pcat.key if pcat else None,
            "category_name": pcat.title_uz if pcat else None,
            "rating": p.rating, "review_count": p.review_count,
            "address": p.address,
            "lat": p.lat, "lng": p.lng,
        }
        if user_lat is not None and p.lat is not None and p.lng is not None:
            row["distance_km"] = round(_distance_km(user_lat, user_lng, p.lat, p.lng), 1)
        results.append(row)

    payload = {
        "status": "success",
        "count": len(results),
        "providers": results,
        "matched_category": (
            {"id": matched_cat.id, "key": matched_cat.key, "name": matched_cat.title_uz}
            if matched_cat else None
        ),
        "matched_by_name": matched_by_name,
        # AI shu belgilarga qarab javobda "eng yaqin" deyishi yoki joylashuv
        # aniqlanmaganini aytishi mumkin.
        "sorted_by": "distance" if by_distance else "rating",
        "user_location_available": user_lat is not None,
    }
    # Chatда HAR provayder uchun alohida "bron qilish" tugmasi chiqadi.
    # category_key: kategoriya qidiruvida — umumiy; nom qidiruvida — provayderniki.
    action = None
    if results:
        top_key = matched_cat.key if matched_cat else results[0].get("category_key")
        action = {
            "type": "provider_list",
            "category_key": top_key,
            "category_name": matched_cat.title_uz if matched_cat else results[0].get("category_name"),
            "providers": [
                {
                    "id": r["id"],
                    "name": r["name"],
                    "rating": r["rating"],
                    "address": r["address"],
                    "category_key": r["category_key"],
                    "distance_km": r.get("distance_km"),
                }
                for r in results
            ],
        }
    return json.dumps(payload, ensure_ascii=False), action


async def create_booking(db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None) -> tuple[str, dict | None]:
    from app.models.provider import Provider
    from app.models.order import Order, OrderStatus
    from app.services.notification_service import NotificationService

    # ── Usta ──
    try:
        provider_id = int(args.get("provider_id"))
    except (TypeError, ValueError):
        return json.dumps({"status": "error",
            "message": "provider_id kiritilmagan yoki noto'g'ri."}, ensure_ascii=False), None
    prov = (await db.execute(select(Provider).where(Provider.id == provider_id))).scalar_one_or_none()
    if not prov:
        return '{"status": "error", "message": "Usta topilmadi"}', None

    # ── Majburiy maydonlarni tekshirish (indamay default QO'YMAYMIZ) ──
    service_name = (args.get("service_name") or "").strip()
    if not service_name:
        return json.dumps({"status": "error",
            "message": "Xizmat nomi (service_name) kiritilmagan."}, ensure_ascii=False), None

    try:
        price = float(args.get("price"))
    except (TypeError, ValueError):
        return json.dumps({"status": "error",
            "message": "Narx (price) kiritilmagan yoki noto'g'ri."}, ensure_ascii=False), None
    if price <= 0:
        return json.dumps({"status": "error",
            "message": "Narx (price) 0 dan katta bo'lishi kerak."}, ensure_ascii=False), None

    date_raw = (args.get("date") or "").strip()
    if not date_raw:
        return json.dumps({"status": "error",
            "message": "Sana/vaqt (date) kiritilmagan."}, ensure_ascii=False), None
    try:
        booking_date = datetime.fromisoformat(date_raw.replace("Z", "+00:00")).replace(tzinfo=None)
    except Exception:
        return json.dumps({"status": "error",
            "message": "Sana/vaqt (date) formati noto'g'ri — ISO 8601 kutiladi (masalan '2026-07-07T15:00:00Z')."},
            ensure_ascii=False), None

    address = (args.get("address") or "").strip()
    if not address:
        return json.dumps({"status": "error",
            "message": "Manzil (address) kiritilmagan."}, ensure_ascii=False), None

    # ── TASDIQ DARVOZASI: confirm=true bo'lmasa buyurtma YARATILMAYDI ──
    if not args.get("confirm"):
        return json.dumps({
            "status": "needs_confirmation",
            "summary": {
                "provider": prov.name,
                "service": service_name,
                "date": booking_date.isoformat(),
                "price": price,
                "address": address,
            },
            "message": "Bron tafsilotlarini foydalanuvchiga ko'rsatib tasdiqini so'rang, "
                       "so'ng create_booking'ni confirm=true bilan qayta chaqiring.",
        }, ensure_ascii=False), None

    order = Order(
        user_id=user_id,
        category_id=prov.category_id,
        provider_id=prov.id,
        service_name=service_name,
        address=address,
        date=booking_date,
        price=price,
        status=OrderStatus.pending,
        booking_mode="fixed",
    )
    db.add(order)
    await db.commit()
    await db.refresh(order)
    if prov.owner_user_id:
        NotificationService.notify_new_order_for_provider(prov.owner_user_id, order.id)
    action = {"type": "booking_created", "order_id": order.id, "provider_name": prov.name}
    return json.dumps(
        {"status": "success", "message": "Buyurtma yaratildi", "order_id": order.id},
        ensure_ascii=False,
    ), action


HANDLERS = {
    "search_providers": search_providers,
    "create_booking": create_booking,
}
