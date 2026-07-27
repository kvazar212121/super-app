"""Xizmat provayderlari toollari: qidiruv (QAT'IY filtrli) va bron yaratish.

QAT'IY QOIDA: kategoriya yoki nom bo'yicha ANIQ moslik topilmasa — hech narsa
qaytarilmaydi (barcha providerlarni aralashtirib "to'kib tashlash" YO'Q).
AI natija topilmaganda foydalanuvchidan xizmat turini aniqlashtiradi.
"""
import json
import logging
from datetime import datetime

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

logger = logging.getLogger(__name__)


async def search_providers(db: AsyncSession, user_id: int, args: dict) -> tuple[str, dict | None]:
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

    provs = []
    matched_by_name = False
    if matched_cat:
        # FAQAT shu kategoriya — boshqa kategoriyalar ARALASHMAYDI
        pstmt = select(Provider).where(*base_filter, Provider.category_id == matched_cat.id)
        if location:
            pstmt = pstmt.where(Provider.address.ilike(f"%{location}%"))
        pstmt = pstmt.order_by(Provider.rating.desc()).limit(limit)
        provs = (await db.execute(pstmt)).scalars().all()
    elif query:
        # Kategoriya aniqlanmadi — provider NOMI bo'yicha maqsadli qidiruv
        pstmt = select(Provider).where(*base_filter, Provider.name.ilike(f"%{query}%"))
        if location:
            pstmt = pstmt.where(Provider.address.ilike(f"%{location}%"))
        pstmt = pstmt.order_by(Provider.rating.desc()).limit(limit)
        provs = (await db.execute(pstmt)).scalars().all()
        matched_by_name = bool(provs)

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
        results.append({
            "id": p.id, "name": p.name, "category_id": p.category_id,
            "category_key": pcat.key if pcat else None,
            "category_name": pcat.title_uz if pcat else None,
            "rating": p.rating, "review_count": p.review_count,
            "address": p.address,
            "lat": p.lat, "lng": p.lng,
        })

    payload = {
        "status": "success",
        "count": len(results),
        "providers": results,
        "matched_category": (
            {"id": matched_cat.id, "key": matched_cat.key, "name": matched_cat.title_uz}
            if matched_cat else None
        ),
        "matched_by_name": matched_by_name,
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
                }
                for r in results
            ],
        }
    return json.dumps(payload, ensure_ascii=False), action


async def create_booking(db: AsyncSession, user_id: int, args: dict) -> tuple[str, dict | None]:
    from app.models.provider import Provider
    from app.models.order import Order, OrderStatus
    from app.services.notification_service import NotificationService
    provider_id = int(args.get("provider_id"))
    prov = (await db.execute(select(Provider).where(Provider.id == provider_id))).scalar_one_or_none()
    if not prov:
        return '{"status": "error", "message": "Usta topilmadi"}', None
    price = float(args.get("price") or 0)
    if price <= 0:
        price = 50000.0
    try:
        booking_date = datetime.fromisoformat(
            (args.get("date") or "").replace("Z", "+00:00")
        ).replace(tzinfo=None)
    except Exception:
        booking_date = datetime.now()
    order = Order(
        user_id=user_id,
        category_id=prov.category_id,
        provider_id=prov.id,
        service_name=args.get("service_name") or "Xizmat",
        address=args.get("address") or "Manzil kiritilmagan",
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
