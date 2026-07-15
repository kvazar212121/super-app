"""Soha egasi (provider) paneli — buyurtmalar, statistika, hisobotlar."""
from datetime import datetime, date, timedelta
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import select, func, and_
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.api.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.models.provider import Provider
from app.models.order import Order, OrderStatus
from app.models.category import Category
from app.models.review import Review
from app.schemas.provider import ProviderOut, ProviderCreate, ProviderUpdate
from app.schemas.order import OrderStatusUpdate
from app.schemas.common import PaginatedResponse

router = APIRouter(prefix="/provider", tags=["provider portal"])


class ProviderOrderOut(BaseModel):
    id: int
    user_id: int
    user_name: Optional[str] = None
    service_name: str
    address: str
    notes: Optional[str] = None
    date: Optional[str] = None
    price: float
    status: str
    created_at: Optional[str] = None


class ProviderStatsOut(BaseModel):
    orders_today: int
    orders_active: int
    revenue_today: float
    revenue_month: float
    rating: float
    review_count: int


class ProviderReportOut(BaseModel):
    period: str
    total_revenue: float
    total_orders: int
    completed_orders: int
    total_leads: int
    lead_fee_charged: float
    balance: float
    chart: list[dict]
    breakdown: list[dict]


class ProviderCalendarOut(BaseModel):
    date: str
    busy_slots: list[str]
    orders: list[ProviderOrderOut]


async def _get_user_provider(
    db: AsyncSession,
    user: User,
    category_key: str | None = None,
) -> Provider:
    base = (
        select(Provider)
        .options(selectinload(Provider.category))
        # populate_existing: get_current_user provider'ni noload bilan yuklab qo'ygan
        # bo'lishi mumkin — bu category'ni majburan qayta yuklaydi (aks holda category_key null bo'ladi)
        .execution_options(populate_existing=True)
        .where(Provider.owner_user_id == user.id)
    )
    if category_key:
        base = base.join(Category).where(Category.key == category_key)

    result = await db.execute(base.order_by(Provider.id).limit(1))
    provider = result.scalar_one_or_none()

    if not provider:
        phone_q = (
            select(Provider)
            .options(selectinload(Provider.category))
            .execution_options(populate_existing=True)
            .where(Provider.phone == user.phone)
        )
        if category_key:
            phone_q = phone_q.join(Category).where(Category.key == category_key)
        result = await db.execute(phone_q.order_by(Provider.id).limit(1))
        provider = result.scalar_one_or_none()

    if not provider:
        raise HTTPException(status_code=404, detail="Sizga biriktirilgan provider topilmadi")
    return provider


def _order_to_out(order: Order) -> ProviderOrderOut:
    user = getattr(order, "user", None)
    user_name = f"{user.name} {user.surname}".strip() if user else None
    return ProviderOrderOut(
        id=order.id,
        user_id=order.user_id,
        user_name=user_name,
        service_name=order.service_name,
        address=order.address,
        notes=order.notes,
        date=order.date.isoformat() if order.date else None,
        price=float(order.price),
        status=order.status.value if hasattr(order.status, "value") else str(order.status),
        created_at=order.created_at.isoformat() if order.created_at else None,
    )


@router.post("/register", response_model=ProviderOut, status_code=201)
async def register_as_provider(
    data: ProviderCreate,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Foydalanuvchini soha egasi sifatida ro'yxatdan o'tkazish."""
    existing = await db.execute(
        select(Provider).where(
            Provider.owner_user_id == user.id,
            Provider.category_id == data.category_id,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Bu kategoriyada allaqachon ro'yxatdan o'tgansiz")

    provider = Provider(
        category_id=data.category_id,
        name=data.name,
        address=data.address,
        phone=data.phone or user.phone,
        lat=data.lat,
        lng=data.lng,
        cover_image=data.cover_image,
        metadata_json=data.metadata_json,
        is_active=False,
        owner_user_id=user.id,
    )
    db.add(provider)
    await db.flush()
    await db.refresh(provider, attribute_names=["category"])
    return ProviderOut.from_provider(provider)


@router.get("/mine", response_model=list[ProviderOut])
async def list_my_providers(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Foydalanuvchiga biriktirilgan barcha providerlar."""
    result = await db.execute(
        select(Provider)
        .options(selectinload(Provider.category))
        .execution_options(populate_existing=True)
        .where(Provider.owner_user_id == user.id)
        .order_by(Provider.id)
    )
    providers = list(result.scalars().all())

    if not providers:
        phone_result = await db.execute(
            select(Provider)
            .options(selectinload(Provider.category))
            .execution_options(populate_existing=True)
            .where(Provider.phone == user.phone)
            .order_by(Provider.id)
        )
        providers = list(phone_result.scalars().all())

    # Kategoriyasi yo'q (orphaned — kategoriya o'chirilgan/qayta seed qilingan)
    # providerlarni chiqarib tashlaymiz — ular panelni ocholmaydi, faqat
    # "kategoriya mos kelmadi" xatosini beradi. Bunday holatда foydalanuvchi
    # qaytadan ro'yxatdan o'tadi.
    providers = [p for p in providers if p.category is not None]

    return [ProviderOut.from_provider(p) for p in providers]


@router.get("/me", response_model=ProviderOut)
async def get_my_provider(
    category_key: str | None = Query(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await _get_user_provider(db, user, category_key)
    return ProviderOut.from_provider(provider)


@router.patch("/me", response_model=ProviderOut)
async def update_my_provider(
    data: ProviderUpdate,
    category_key: str | None = Query(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await _get_user_provider(db, user, category_key)
    for key, val in data.model_dump(exclude_unset=True).items():
        setattr(provider, key, val)
    await db.flush()
    await db.refresh(provider, attribute_names=["category"])
    return ProviderOut.from_provider(provider)


@router.get("/stats", response_model=ProviderStatsOut)
async def get_my_stats(
    category_key: str | None = Query(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await _get_user_provider(db, user, category_key)
    today = datetime.utcnow().date()
    month_start = today.replace(day=1)

    orders_today = await db.scalar(
        select(func.count(Order.id)).where(
            Order.provider_id == provider.id,
            func.date(Order.date) == today,
        )
    ) or 0

    orders_active = await db.scalar(
        select(func.count(Order.id)).where(
            Order.provider_id == provider.id,
            Order.status.in_([
                OrderStatus.pending,
                OrderStatus.confirmed,
                OrderStatus.in_progress,
            ]),
        )
    ) or 0

    revenue_today = float(
        await db.scalar(
            select(func.coalesce(func.sum(Order.price), 0)).where(
                Order.provider_id == provider.id,
                Order.status == OrderStatus.completed,
                func.date(Order.date) == today,
            )
        ) or 0
    )

    revenue_month = float(
        await db.scalar(
            select(func.coalesce(func.sum(Order.price), 0)).where(
                Order.provider_id == provider.id,
                Order.status == OrderStatus.completed,
                func.date(Order.date) >= month_start,
            )
        ) or 0
    )

    return ProviderStatsOut(
        orders_today=orders_today,
        orders_active=orders_active,
        revenue_today=revenue_today,
        revenue_month=revenue_month,
        rating=float(provider.rating or 0),
        review_count=int(provider.review_count or 0),
    )


@router.get("/orders", response_model=PaginatedResponse)
async def list_my_orders(
    category_key: str | None = Query(None),
    status: str | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await _get_user_provider(db, user, category_key)
    base = (
        select(Order)
        .options(selectinload(Order.user))
        .where(Order.provider_id == provider.id)
        .order_by(Order.date.desc())
    )
    count_base = select(func.count(Order.id)).where(Order.provider_id == provider.id)

    if status:
        base = base.where(Order.status == OrderStatus(status))
        count_base = count_base.where(Order.status == OrderStatus(status))

    total = (await db.execute(count_base)).scalar() or 0
    orders = (
        await db.execute(base.offset((page - 1) * per_page).limit(per_page))
    ).scalars().all()

    pages = (total + per_page - 1) // per_page
    return PaginatedResponse(
        items=[_order_to_out(o) for o in orders],
        total=total,
        page=page,
        per_page=per_page,
        pages=pages,
    )


@router.patch("/orders/{order_id}/status")
async def update_order_status(
    order_id: int,
    data: OrderStatusUpdate,
    category_key: str | None = Query(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await _get_user_provider(db, user, category_key)
    result = await db.execute(
        select(Order).where(Order.id == order_id, Order.provider_id == provider.id)
    )
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Buyurtma topilmadi")
    old_status = order.status
    
    # Ikki tomonlama tasdiqlash mantig'i: 
    # Usta "completed" deb belgilasa, avval mijoz tasdig'i kutiladi
    from app.models.order import OrderStatus as OS
    if data.status == "completed" and old_status not in (OS.completed, OS.awaiting_confirmation):
        # 30 minut qoidasi: buyurtma vaqtidan 30 daqiqa oldin yakunlab bo'lmaydi
        if order.date:
            from datetime import datetime, timezone
            now = datetime.now(timezone.utc).replace(tzinfo=None)
            if (order.date - now).total_seconds() > 1800:
                raise HTTPException(status_code=400, detail="Buyurtmani belgilangan vaqtdan 30 daqiqadan erta yakunlash mumkin emas")
        data.status = "awaiting_confirmation"

    order.status = OS(data.status)
    await db.flush()

    if old_status != order.status:
        from app.services.notification_service import NotificationService
        labels = {
            OS.pending: "kutilmoqda",
            OS.confirmed: "qabul qilindi",
            OS.in_progress: "jarayonda",
            OS.completed: "yakunlandi",
            OS.awaiting_confirmation: "mijoz tasdig'ini kutmoqda",
            OS.cancelled: "bekor qilindi",
        }
        label = labels.get(order.status, order.status.value)
        NotificationService.notify_order_status(
            user_id=order.user_id,
            order_id=order.id,
            status_label=label,
        )
        if order.status == OS.completed:
            provider.completed_orders_count += 1
            from app.services.order_service import OrderService
            await OrderService.shift_flexible_queue(db, order.provider_id)
            await OrderService.process_commission(db, order)
        elif order.status == OS.cancelled:
            if not data.notified_client:
                provider.cancelled_orders_count += 1

    return {"message": "Status yangilandi", "status": data.status}


@router.get("/calendar", response_model=ProviderCalendarOut)
async def get_calendar(
    day: date | None = Query(None),
    category_key: str | None = Query(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    target_day = day or date.today()
    provider = await _get_user_provider(db, user, category_key)
    
    from app.services.provider_service import ProviderService
    availability = await ProviderService.get_availability(db, provider.id, target_day, allow_inactive=True)
    
    result = await db.execute(
        select(Order)
        .options(selectinload(Order.user))
        .where(
            Order.provider_id == provider.id,
            func.date(Order.date) == target_day,
            Order.status != OrderStatus.cancelled,
        )
        .order_by(Order.date)
    )
    orders = list(result.scalars().all())

    return ProviderCalendarOut(
        date=target_day.isoformat(),
        busy_slots=availability.get("booked", []),
        orders=[_order_to_out(o) for o in orders],
    )


@router.get("/reports", response_model=ProviderReportOut)
async def get_reports(
    period: str = Query("monthly", pattern="^(daily|monthly|yearly|all_time)$"),
    category_key: str | None = Query(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await _get_user_provider(db, user, category_key)
    today = datetime.utcnow().date()

    if period == "daily":
        start = today
    elif period == "yearly":
        start = today.replace(month=1, day=1)
    elif period == "all_time":
        start = today.replace(year=2000, month=1, day=1)
    else:
        start = today.replace(day=1)

    result = await db.execute(
        select(Order)
        .where(
            Order.provider_id == provider.id,
            Order.status == OrderStatus.completed,
            func.date(Order.date) >= start,
            func.date(Order.date) <= today,
        )
        .order_by(Order.date)
    )
    orders = list(result.scalars().all())
    total_revenue = sum(float(o.price) for o in orders)

    chart_map: dict[str, float] = {}
    breakdown_map: dict[str, float] = {}
    for o in orders:
        key = o.date.strftime("%Y-%m-%d") if o.date else "unknown"
        chart_map[key] = chart_map.get(key, 0) + float(o.price)
        breakdown_map[o.service_name] = breakdown_map.get(o.service_name, 0) + float(o.price)

    chart = [{"label": k, "value": v} for k, v in sorted(chart_map.items())]
    breakdown = [
        {"title": k, "amount": v, "count": sum(1 for o in orders if o.service_name == k)}
        for k, v in sorted(breakdown_map.items(), key=lambda x: -x[1])
    ]

    total_leads = await db.scalar(
        select(func.count(Order.id)).where(
            Order.provider_id == provider.id,
            func.date(Order.date) >= start,
            func.date(Order.date) <= today,
        )
    ) or 0

    completed_orders = len(orders)

    from app.models.transaction import Transaction
    lead_fee_charged = float(
        await db.scalar(
            select(func.coalesce(func.sum(func.abs(Transaction.amount)), 0)).where(
                Transaction.user_id == user.id,
                Transaction.type == "lead_fee",
                Transaction.status == "completed",
                func.date(Transaction.created_at) >= start,
                func.date(Transaction.created_at) <= today,
            )
        ) or 0
    )

    balance = float(user.balance)

    return ProviderReportOut(
        period=period,
        total_revenue=total_revenue,
        total_orders=len(orders),
        completed_orders=completed_orders,
        total_leads=total_leads,
        lead_fee_charged=lead_fee_charged,
        balance=balance,
        chart=chart,
        breakdown=breakdown,
    )


@router.get("/reviews", response_model=PaginatedResponse)
async def list_my_reviews(
    category_key: str | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from app.schemas.provider import ReviewOut

    provider = await _get_user_provider(db, user, category_key)
    total = await db.scalar(
        select(func.count(Review.id)).where(Review.provider_id == provider.id)
    ) or 0
    result = await db.execute(
        select(Review)
        .options(selectinload(Review.user))
        .where(Review.provider_id == provider.id)
        .order_by(Review.created_at.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
    )
    reviews = list(result.scalars().all())
    pages = (total + per_page - 1) // per_page
    return PaginatedResponse(
        items=[ReviewOut.from_review(r) for r in reviews],
        total=total,
        page=page,
        per_page=per_page,
        pages=pages,
    )


@router.put("/pause", response_model=ProviderOut)
async def toggle_provider_pause(
    is_paused: bool = Query(...),
    category_key: str | None = Query(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await _get_user_provider(db, user, category_key)
    provider.is_paused = is_paused
    await db.commit()
    await db.refresh(provider)
    return ProviderOut.from_provider(provider)


@router.get("/blocked-times")
async def list_blocked_times(
    category_key: str | None = Query(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from app.schemas.provider import ProviderBlockedTimeOut
    from app.models.provider_blocked_time import ProviderBlockedTime
    provider = await _get_user_provider(db, user, category_key)
    result = await db.execute(
        select(ProviderBlockedTime)
        .where(ProviderBlockedTime.provider_id == provider.id)
        .order_by(ProviderBlockedTime.start_time)
    )
    blocks = result.scalars().all()
    return [ProviderBlockedTimeOut.model_validate(b) for b in blocks]


@router.post("/blocked-times")
async def add_blocked_time(
    data: dict,  # Using dict directly to avoid circular imports or redefining schemas if import fails
    category_key: str | None = Query(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from app.schemas.provider import ProviderBlockedTimeCreate, ProviderBlockedTimeOut
    from app.models.provider_blocked_time import ProviderBlockedTime
    parsed_data = ProviderBlockedTimeCreate(**data)
    provider = await _get_user_provider(db, user, category_key)

    if parsed_data.start_time >= parsed_data.end_time:
        raise HTTPException(status_code=400, detail="Start time must be before end time")

    new_block = ProviderBlockedTime(
        provider_id=provider.id,
        start_time=parsed_data.start_time.replace(tzinfo=None),
        end_time=parsed_data.end_time.replace(tzinfo=None),
        reason=parsed_data.reason,
    )
    db.add(new_block)
    await db.commit()
    await db.refresh(new_block)
    return ProviderBlockedTimeOut.model_validate(new_block)


@router.delete("/blocked-times/{blocked_time_id}")
async def remove_blocked_time(
    blocked_time_id: int,
    category_key: str | None = Query(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from app.models.provider_blocked_time import ProviderBlockedTime
    provider = await _get_user_provider(db, user, category_key)
    result = await db.execute(
        select(ProviderBlockedTime).where(
            ProviderBlockedTime.id == blocked_time_id,
            ProviderBlockedTime.provider_id == provider.id
        )
    )
    block = result.scalar_one_or_none()
    if not block:
        raise HTTPException(status_code=404, detail="Blocked time not found")

    await db.delete(block)
    await db.commit()
    return {"detail": "Muvaffaqiyatli o'chirildi"}


@router.get("/call-history")
async def get_call_history(
    category_key: str | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from app.models.call_history import CallHistory
    provider = await _get_user_provider(db, user, category_key)
    
    total = await db.scalar(
        select(func.count(CallHistory.id)).where(CallHistory.provider_id == provider.id)
    ) or 0
    
    result = await db.execute(
        select(CallHistory)
        .options(selectinload(CallHistory.caller), selectinload(CallHistory.receiver))
        .where(CallHistory.provider_id == provider.id)
        .order_by(CallHistory.created_at.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
    )
    calls = result.scalars().all()
    pages = (total + per_page - 1) // per_page
    
    return PaginatedResponse(
        items=[c.to_dict() for c in calls],
        total=total,
        page=page,
        per_page=per_page,
        pages=pages,
    )


@router.post("/block-user")
async def block_user(
    user_id: int = Query(...),
    category_key: str | None = Query(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from app.models.blocked_user import BlockedUser
    provider = await _get_user_provider(db, user, category_key)
    
    # Check if already blocked
    existing = await db.scalar(
        select(BlockedUser).where(BlockedUser.provider_id == provider.id, BlockedUser.user_id == user_id)
    )
    if existing:
        return {"detail": "Foydalanuvchi allaqachon bloklangan"}
        
    blocked = BlockedUser(provider_id=provider.id, user_id=user_id)
    db.add(blocked)
    await db.commit()
    return {"detail": "Foydalanuvchi bloklandi"}


@router.get("/blocked-users")
async def get_blocked_users(
    category_key: str | None = Query(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from app.models.blocked_user import BlockedUser
    provider = await _get_user_provider(db, user, category_key)
    
    result = await db.execute(
        select(BlockedUser)
        .options(selectinload(BlockedUser.user))
        .where(BlockedUser.provider_id == provider.id)
        .order_by(BlockedUser.created_at.desc())
    )
    blocked = result.scalars().all()
    return [b.to_dict() for b in blocked]


@router.delete("/block-user/{blocked_user_id}")
async def unblock_user(
    blocked_user_id: int,
    category_key: str | None = Query(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from app.models.blocked_user import BlockedUser
    provider = await _get_user_provider(db, user, category_key)
    
    result = await db.execute(
        select(BlockedUser).where(
            BlockedUser.user_id == blocked_user_id,
            BlockedUser.provider_id == provider.id
        )
    )
    block = result.scalar_one_or_none()
    if not block:
        raise HTTPException(status_code=404, detail="Bloklangan foydalanuvchi topilmadi")

    await db.delete(block)
    await db.commit()
    return {"detail": "Muvaffaqiyatli o'chirildi (unblocked)"}



class ManualCallOrderIn(BaseModel):
    user_id: int
    service_name: str
    date: datetime
    price: float
    address: str | None = None
    notes: str | None = "Telefon orqali kelishildi"
    staff_provider_id: int | None = None

@router.post("/orders/manual_after_call")
async def create_manual_order(
    parsed_data: ManualCallOrderIn,
    category_key: str | None = Query(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from app.models.order import Order, OrderStatus
    provider = await _get_user_provider(db, user, category_key)
    
    # Verify the user exists
    user_query = await db.execute(select(User).where(User.id == parsed_data.user_id))
    target_user = user_query.scalar_one_or_none()
    if not target_user:
        raise HTTPException(status_code=404, detail="Foydalanuvchi topilmadi")
        
    actual_provider_id = parsed_data.staff_provider_id if parsed_data.staff_provider_id else provider.id
    new_order = Order(
        user_id=target_user.id,
        category_id=provider.category_id,
        provider_id=actual_provider_id,
        service_name=parsed_data.service_name,
        date=parsed_data.date.replace(tzinfo=None),
        price=parsed_data.price,
        address=parsed_data.address or provider.address or "",
        notes=parsed_data.notes,
        status=OrderStatus.confirmed,
        booking_mode="manual_call"
    )
    db.add(new_order)
    await db.commit()
    await db.refresh(new_order)
    
    return {"detail": "Buyurtma muvaffaqiyatli qo'shildi", "order_id": new_order.id}

@router.get("/my-staff")
async def get_my_staff(
    category_key: str | None = Query(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await _get_user_provider(db, user, category_key)
    
    # Staff are providers with salon_role='salon_employee' and salon_provider_id=provider.id
    from app.models.provider import Provider
    result = await db.execute(
        select(Provider).where(
            Provider.is_active == True,
            Provider.category_id == provider.category_id
        )
    )
    staff_list = []
    for p in result.scalars().all():
        meta = p.metadata_json or {}
        is_salon_staff = meta.get("salon_role") == "salon_employee" and meta.get("salon_provider_id") == provider.id
        is_massage_staff = meta.get("massage_role") == "center_employee" and meta.get("center_provider_id") == provider.id
        is_dental_staff = meta.get("clinic_role") == "clinic_employee" and meta.get("clinic_provider_id") == provider.id
        
        if is_salon_staff or is_massage_staff or is_dental_staff:
            staff_list.append({
                "id": p.id,
                "name": meta.get("display_name") or p.name,
                "user_id": p.owner_user_id
            })
            
    return {"staff": staff_list}
