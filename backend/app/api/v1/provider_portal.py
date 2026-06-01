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
        .where(Provider.owner_user_id == user.id)
        .order_by(Provider.id)
    )
    providers = list(result.scalars().all())

    if not providers:
        phone_result = await db.execute(
            select(Provider)
            .options(selectinload(Provider.category))
            .where(Provider.phone == user.phone)
            .order_by(Provider.id)
        )
        providers = list(phone_result.scalars().all())

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
    order.status = OrderStatus(data.status)
    await db.flush()

    if old_status != order.status:
        from app.models.order import OrderStatus as OS
        from app.services.notification_service import NotificationService
        labels = {
            OS.pending: "kutilmoqda",
            OS.confirmed: "qabul qilindi",
            OS.in_progress: "jarayonda",
            OS.completed: "yakunlandi",
            OS.cancelled: "bekor qilindi",
        }
        label = labels.get(order.status, order.status.value)
        NotificationService.notify_order_status(
            user_id=order.user_id,
            order_id=order.id,
            status_label=label,
        )

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
    busy = []
    for o in orders:
        if o.date:
            busy.append(o.date.strftime("%H:%M"))

    return ProviderCalendarOut(
        date=target_day.isoformat(),
        busy_slots=busy,
        orders=[_order_to_out(o) for o in orders],
    )


@router.get("/reports", response_model=ProviderReportOut)
async def get_reports(
    period: str = Query("monthly", pattern="^(daily|monthly|yearly)$"),
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

    return ProviderReportOut(
        period=period,
        total_revenue=total_revenue,
        total_orders=len(orders),
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
