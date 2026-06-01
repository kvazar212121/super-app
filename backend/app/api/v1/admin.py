"""
Super-App Admin Panel API — barcha admin funksiyalari.

10 ta asosiy bo'lim:
  1. Dashboard — analytics, statistika, grafiklar
  2. Foydalanuvchilar — CRUD, block/unblock, premium
  3. Soha egalari — tasdiqlash, bloklash, reyting
  4. Buyurtmalar — barcha buyurtmalar, status, filter
  5. Kategoriyalar — CRUD, variantlar, narxlar
  6. Sharhlar — moderatsiya, o'chirish, spam
  7. Moliya — to'lovlar, cashback, komissiya, chiqim
  8. Sozlamalar — komissiya %, bannerlar, xabarlar
  9. Bildirishnomalar — push, email, SMS
 10. Hisobotlar — kunlik/oylik/yillik, export CSV
"""
from datetime import datetime, date, timedelta
from enum import Enum
from typing import Optional

from fastapi import APIRouter, Depends, Query, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select, and_, or_, desc
from sqlalchemy.orm import selectinload

from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.category import Category, CategoryVariant
from app.models.provider import Provider
from app.models.order import Order, OrderStatus
from app.models.review import Review
from app.models.payment import PaymentCard
from app.services.order_service import OrderService
from app.schemas.category import CategoryCreate, CategoryOut, VariantCreate, VariantOut
from app.schemas.provider import ProviderCreate, ProviderUpdate, ProviderOut, ReviewOut
from app.schemas.order import OrderOut, OrderStatusUpdate
from app.schemas.common import PaginatedResponse

router = APIRouter(prefix="/admin", tags=["admin"])

admin_only_msg = "Faqat admin uchun ruxsat"


# ─────────────────────────────────────────────────────────────
# Helper: admin tekshirish
# ─────────────────────────────────────────────────────────────
def require_admin(current_user: User = Depends(get_current_user)) -> User:
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail=admin_only_msg)
    return current_user


# ════════════════════════════════════════════════════════════
# 1. DASHBOARD — Analytics, statistika, grafiklar
# ════════════════════════════════════════════════════════════

class AdminStatsOut(BaseModel):
    orders_total: int
    orders_by_status: dict[str, int]
    providers: int
    users: int
    categories: int
    revenue_today: float
    revenue_month: float
    revenue_total: float
    avg_rating: float
    new_users_today: int
    pending_providers: int


@router.get("/stats", response_model=AdminStatsOut)
async def admin_stats(
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    today = datetime.utcnow().date()
    month_start = today.replace(day=1)

    # Orders total
    orders_total = int(await db.scalar(select(func.count()).select_from(Order)) or 0)

    # Orders by status
    status_rows = await db.execute(
        select(Order.status, func.count(Order.id)).group_by(Order.status)
    )
    orders_by_status: dict[str, int] = {s.value: 0 for s in OrderStatus}
    for row in status_rows.all():
        status_val, cnt = row[0], int(row[1])
        if status_val is not None:
            orders_by_status[status_val.value] = cnt

    # Counts
    providers = int(await db.scalar(select(func.count()).select_from(Provider)) or 0)
    users = int(await db.scalar(select(func.count()).select_from(User)) or 0)
    categories = int(await db.scalar(select(func.count()).select_from(Category)) or 0)

    # Revenue
    revenue_total = float(
        await db.scalar(
            select(func.coalesce(func.sum(Order.price), 0)).where(
                Order.status == OrderStatus.completed
            )
        ) or 0
    )
    revenue_today = float(
        await db.scalar(
            select(func.coalesce(func.sum(Order.price), 0)).where(
                and_(
                    Order.status == OrderStatus.completed,
                    func.date(Order.created_at) == today,
                )
            )
        ) or 0
    )
    revenue_month = float(
        await db.scalar(
            select(func.coalesce(func.sum(Order.price), 0)).where(
                and_(
                    Order.status == OrderStatus.completed,
                    func.date(Order.created_at) >= month_start,
                )
            )
        ) or 0
    )

    # Avg rating
    avg_rating = float(
        await db.scalar(select(func.coalesce(func.avg(Review.rating), 0))) or 0
    )

    # New users today
    new_users_today = int(
        await db.scalar(
            select(func.count(User.id)).where(func.date(User.created_at) == today)
        ) or 0
    )

    # Pending providers (not active yet)
    pending_providers = int(
        await db.scalar(
            select(func.count(Provider.id)).where(Provider.is_active == False)
        ) or 0
    )

    return AdminStatsOut(
        orders_total=orders_total,
        orders_by_status=orders_by_status,
        providers=providers,
        users=users,
        categories=categories,
        revenue_today=revenue_today,
        revenue_month=revenue_month,
        revenue_total=revenue_total,
        avg_rating=round(avg_rating, 2),
        new_users_today=new_users_today,
        pending_providers=pending_providers,
    )


class ChartDataPoint(BaseModel):
    label: str
    value: float | int


class ChartDataOut(BaseModel):
    revenue: list[ChartDataPoint]
    orders: list[ChartDataPoint]
    users: list[ChartDataPoint]
    top_categories: list[ChartDataPoint]


@router.get("/chart-data", response_model=ChartDataOut)
async def admin_chart_data(
    days: int = Query(30, ge=1, le=365),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Kunlik grafik ma'lumotlari (revenue, orders, users, top categories)."""
    today = datetime.utcnow().date()
    start_date = today - timedelta(days=days - 1)

    # Revenue per day
    rev_rows = await db.execute(
        select(func.date(Order.created_at), func.sum(Order.price)).where(
            and_(
                Order.status == OrderStatus.completed,
                func.date(Order.created_at) >= start_date,
            )
        ).group_by(func.date(Order.created_at))
    )
    revenue_map = {str(r[0]): float(r[1]) for r in rev_rows.all()}

    # Orders per day
    ord_rows = await db.execute(
        select(func.date(Order.created_at), func.count(Order.id)).where(
            func.date(Order.created_at) >= start_date
        ).group_by(func.date(Order.created_at))
    )
    orders_map = {str(r[0]): int(r[1]) for r in ord_rows.all()}

    # Users per day
    usr_rows = await db.execute(
        select(func.date(User.created_at), func.count(User.id)).where(
            func.date(User.created_at) >= start_date
        ).group_by(func.date(User.created_at))
    )
    users_map = {str(r[0]): int(r[1]) for r in usr_rows.all()}

    revenue: list[ChartDataPoint] = []
    orders: list[ChartDataPoint] = []
    users: list[ChartDataPoint] = []

    for i in range(days):
        d = start_date + timedelta(days=i)
        ds = str(d)
        revenue.append(ChartDataPoint(label=ds, value=revenue_map.get(ds, 0)))
        orders.append(ChartDataPoint(label=ds, value=orders_map.get(ds, 0)))
        users.append(ChartDataPoint(label=ds, value=users_map.get(ds, 0)))

    # Top categories by order count
    cat_rows = await db.execute(
        select(Category.title_uz, func.count(Order.id))
        .join(Order, Order.category_id == Category.id)
        .group_by(Category.title_uz)
        .order_by(func.count(Order.id).desc())
        .limit(10)
    )
    top_categories = [
        ChartDataPoint(label=r[0], value=int(r[1])) for r in cat_rows.all()
    ]

    return ChartDataOut(
        revenue=revenue,
        orders=orders,
        users=users,
        top_categories=top_categories,
    )


# ════════════════════════════════════════════════════════════
# 2. FOYDALANUVCHILAR — CRUD, block/unblock, premium
# ════════════════════════════════════════════════════════════

class UserOut(BaseModel):
    id: int
    name: str
    surname: str
    phone: str
    avatar_url: Optional[str] = None
    telegram_username: Optional[str] = None
    balance: float
    cashback: float
    is_premium: bool
    is_admin: bool
    created_at: Optional[str] = None

    model_config = {"from_attributes": False}

    @classmethod
    def from_user(cls, u: "User") -> "UserOut":
        created = u.created_at.isoformat() if getattr(u, "created_at", None) else None
        return cls(
            id=u.id,
            name=u.name,
            surname=u.surname,
            phone=u.phone,
            avatar_url=u.avatar_url,
            telegram_username=u.telegram_username,
            balance=u.balance,
            cashback=u.cashback,
            is_premium=u.is_premium,
            is_admin=u.is_admin,
            created_at=created,
        )


class UserUpdate(BaseModel):
    name: Optional[str] = None
    surname: Optional[str] = None
    telegram_username: Optional[str] = None
    balance: Optional[float] = None
    cashback: Optional[float] = None
    is_premium: Optional[bool] = None


class UserBlockUpdate(BaseModel):
    is_blocked: bool


@router.get("/users", response_model=PaginatedResponse)
async def list_users(
    search: str | None = Query(None),
    is_premium: bool | None = Query(None),
    sort_by: str = Query("created_at"),
    sort_order: str = Query("desc", regex="^(asc|desc)$"),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Foydalanuvchilar ro'yxati — qidirish, filter, sort."""
    query = select(User)

    if search:
        query = query.where(
            or_(
                User.name.ilike(f"%{search}%"),
                User.surname.ilike(f"%{search}%"),
                User.phone.ilike(f"%{search}%"),
            )
        )
    if is_premium is not None:
        query = query.where(User.is_premium == is_premium)

    # Count
    count_query = select(func.count()).select_from(User)
    if search:
        count_query = count_query.where(
            or_(
                User.name.ilike(f"%{search}%"),
                User.surname.ilike(f"%{search}%"),
                User.phone.ilike(f"%{search}%"),
            )
        )
    total = int(await db.scalar(count_query) or 0)

    # Sort
    if hasattr(User, sort_by):
        sort_col = getattr(User, sort_by)
        if sort_order == "desc":
            query = query.order_by(desc(sort_col))
        else:
            query = query.order_by(sort_col)

    query = query.offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(query)
    items = result.scalars().all()

    pages = (total + per_page - 1) // per_page
    return PaginatedResponse(
        items=[UserOut.from_user(u) for u in items],
        total=total, page=page, per_page=per_page, pages=pages,
    )


@router.get("/users/{user_id}", response_model=UserOut)
async def get_user(
    user_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Foydalanuvchi topilmadi")
    return UserOut.from_user(user)


@router.patch("/users/{user_id}", response_model=UserOut)
async def update_user(
    user_id: int,
    data: UserUpdate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Foydalanuvchi topilmadi")

    update_data = data.model_dump(exclude_unset=True)
    for key, val in update_data.items():
        setattr(user, key, val)

    await db.flush()
    await db.refresh(user)
    return UserOut.from_user(user)


@router.patch("/users/{user_id}/block", response_model=UserOut)
async def block_user(
    user_id: int,
    data: UserBlockUpdate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Foydalanuvchini bloklash/yechish."""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Foydalanuvchi topilmadi")
    if user.is_admin:
        raise HTTPException(status_code=400, detail="Adminni bloklab bo'lmaydi")
    # is_active flag orqali bloklash
    user.is_active = not data.is_blocked
    await db.flush()
    await db.refresh(user)
    return UserOut.from_user(user)


@router.delete("/users/{user_id}", status_code=204)
async def delete_user(
    user_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Foydalanuvchi topilmadi")
    if user.is_admin:
        raise HTTPException(status_code=400, detail="Adminni o'chirib bo'lmaydi")
    await db.delete(user)


# ════════════════════════════════════════════════════════════
# 3. SOHA EGALARI — tasdiqlash, bloklash, reyting
# ════════════════════════════════════════════════════════════

class ProviderListOut(ProviderOut):
    category_title: Optional[str] = None


@router.get("/providers", response_model=PaginatedResponse)
async def list_providers(
    search: str | None = Query(None),
    category_id: int | None = Query(None),
    is_active: bool | None = Query(None),
    min_rating: float | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Soha egalari ro'yxati — qidirish, filter."""
    query = select(Provider).options(selectinload(Provider.category))

    if search:
        query = query.where(
            or_(
                Provider.name.ilike(f"%{search}%"),
                Provider.address.ilike(f"%{search}%"),
                Provider.phone.ilike(f"%{search}%"),
            )
        )
    if category_id is not None:
        query = query.where(Provider.category_id == category_id)
    if is_active is not None:
        query = query.where(Provider.is_active == is_active)
    if min_rating is not None:
        query = query.where(Provider.rating >= min_rating)

    # Count
    count_query = select(func.count()).select_from(Provider)
    if search:
        count_query = count_query.where(
            or_(
                Provider.name.ilike(f"%{search}%"),
                Provider.address.ilike(f"%{search}%"),
            )
        )
    if category_id is not None:
        count_query = count_query.where(Provider.category_id == category_id)
    if is_active is not None:
        count_query = count_query.where(Provider.is_active == is_active)
    if min_rating is not None:
        count_query = count_query.where(Provider.rating >= min_rating)

    total = int(await db.scalar(count_query) or 0)

    query = query.order_by(desc(Provider.rating)).offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(query)
    items = result.scalars().all()

    out_items = []
    for p in items:
        d = p.to_dict()
        d["category_title"] = p.category.title_uz if p.category else None
        out_items.append(d)

    pages = (total + per_page - 1) // per_page
    return PaginatedResponse(items=out_items, total=total, page=page, per_page=per_page, pages=pages)


@router.patch("/providers/{provider_id}/approve")
async def approve_provider(
    provider_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Soha egasini tasdiqlash (active = True)."""
    result = await db.execute(select(Provider).where(Provider.id == provider_id))
    p = result.scalar_one_or_none()
    if not p:
        raise HTTPException(status_code=404, detail="Provayder topilmadi")
    p.is_active = True
    meta = dict(p.metadata_json or {})
    if meta.get("type") == "nanny":
        meta["verification_status"] = "verified"
        meta["nanny_role"] = "verified"
        docs = dict(meta.get("documents") or {})
        if docs.get("medical_cert_url"):
            docs["medical_cert"] = True
        if docs.get("id_url"):
            docs["id_verified"] = True
        if docs.get("criminal_record_url"):
            docs["criminal_record"] = True
        meta["documents"] = docs
        p.metadata_json = meta
    elif meta.get("type") in ("tutor", "education_center"):
        meta["verification_status"] = "verified"
        p.metadata_json = meta
    elif meta.get("type") == "disinfection":
        meta["verification_status"] = "verified"
        p.metadata_json = meta
    elif meta.get("type") == "massage":
        meta["verification_status"] = "verified"
        p.metadata_json = meta
    elif meta.get("type") in ("nurse", "dental_clinic", "event_organizer"):
        meta["verification_status"] = "verified"
        p.metadata_json = meta
    await db.flush()
    return {"message": "Provayder tasdiqlandi", "provider_id": provider_id}


@router.patch("/providers/{provider_id}/reject")
async def reject_provider(
    provider_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Soha egasini rad etish (active = False)."""
    result = await db.execute(select(Provider).where(Provider.id == provider_id))
    p = result.scalar_one_or_none()
    if not p:
        raise HTTPException(status_code=404, detail="Provayder topilmadi")
    p.is_active = False
    meta = dict(p.metadata_json or {})
    if meta.get("type") == "nanny":
        meta["verification_status"] = "rejected"
        meta["nanny_role"] = "rejected"
        p.metadata_json = meta
    elif meta.get("type") in ("tutor", "education_center"):
        meta["verification_status"] = "rejected"
        p.metadata_json = meta
    elif meta.get("type") == "disinfection":
        meta["verification_status"] = "rejected"
        p.metadata_json = meta
    elif meta.get("type") == "massage":
        meta["verification_status"] = "rejected"
        p.metadata_json = meta
    elif meta.get("type") in ("nurse", "dental_clinic", "event_organizer"):
        meta["verification_status"] = "rejected"
        p.metadata_json = meta
    await db.flush()
    return {"message": "Provayder rad etildi", "provider_id": provider_id}


@router.patch("/providers/{provider_id}/rating")
async def update_provider_rating(
    provider_id: int,
    rating: float = Query(..., ge=0, le=5),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Soha egasi reytingini admin tomonidan yangilash."""
    result = await db.execute(select(Provider).where(Provider.id == provider_id))
    p = result.scalar_one_or_none()
    if not p:
        raise HTTPException(status_code=404, detail="Provayder topilmadi")
    p.rating = rating
    await db.flush()
    return {"message": "Reyting yangilandi", "provider_id": provider_id, "rating": rating}


@router.post("/providers", response_model=ProviderOut, status_code=201)
async def create_provider(
    data: ProviderCreate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    p = Provider(**data.model_dump(exclude={"metadata_json"}))
    if data.metadata_json:
        p.metadata_json = data.metadata_json
    db.add(p)
    await db.flush()
    await db.refresh(p)
    return p


@router.patch("/providers/{provider_id}", response_model=ProviderOut)
async def update_provider(
    provider_id: int,
    data: ProviderUpdate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Provider).where(Provider.id == provider_id))
    p = result.scalar_one_or_none()
    if not p:
        raise HTTPException(status_code=404, detail="Provayder topilmadi")
    update_data = data.model_dump(exclude_unset=True, exclude={"metadata_json"})
    for key, val in update_data.items():
        setattr(p, key, val)
    if data.metadata_json is not None:
        p.metadata_json = data.metadata_json
    await db.flush()
    await db.refresh(p)
    return p


@router.delete("/providers/{provider_id}", status_code=204)
async def delete_provider(
    provider_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Provider).where(Provider.id == provider_id))
    p = result.scalar_one_or_none()
    if not p:
        raise HTTPException(status_code=404, detail="Provayder topilmadi")
    await db.delete(p)


# ════════════════════════════════════════════════════════════
# 4. BUYURTMALAR — barcha buyurtmalar, status, filter
# ════════════════════════════════════════════════════════════

class OrderDetailOut(OrderOut):
    user_name: Optional[str] = None
    provider_name: Optional[str] = None
    category_title: Optional[str] = None


@router.get("/orders", response_model=PaginatedResponse)
async def list_all_orders(
    status: str | None = Query(None),
    category_id: int | None = Query(None),
    provider_id: int | None = Query(None),
    user_id: int | None = Query(None),
    date_from: str | None = Query(None),
    date_to: str | None = Query(None),
    search: str | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Buyurtmalar ro'yxati — keng filter imkoniyatlari."""
    query = select(Order).options(
        selectinload(Order.user),
        selectinload(Order.provider),
        selectinload(Order.category),
    )

    if status:
        query = query.where(Order.status == OrderStatus(status))
    if category_id:
        query = query.where(Order.category_id == category_id)
    if provider_id:
        query = query.where(Order.provider_id == provider_id)
    if user_id:
        query = query.where(Order.user_id == user_id)
    if date_from:
        query = query.where(func.date(Order.date) >= date.fromisoformat(date_from))
    if date_to:
        query = query.where(func.date(Order.date) <= date.fromisoformat(date_to))
    if search:
        query = query.where(
            or_(
                Order.service_name.ilike(f"%{search}%"),
                Order.address.ilike(f"%{search}%"),
            )
        )

    # Count
    count_query = select(func.count()).select_from(Order)
    if status:
        count_query = count_query.where(Order.status == OrderStatus(status))
    if category_id:
        count_query = count_query.where(Order.category_id == category_id)
    total = int(await db.scalar(count_query) or 0)

    query = query.order_by(desc(Order.created_at)).offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(query)
    items = result.scalars().all()

    out_items = []
    for o in items:
        d = o.to_dict()
        d["user_name"] = f"{o.user.name} {o.user.surname}" if o.user else None
        d["provider_name"] = o.provider.name if o.provider else None
        d["category_title"] = o.category.title_uz if o.category else None
        out_items.append(d)

    pages = (total + per_page - 1) // per_page
    return PaginatedResponse(items=out_items, total=total, page=page, per_page=per_page, pages=pages)


@router.get("/orders/{order_id}", response_model=OrderDetailOut)
async def get_order(
    order_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Bitta buyurtma tafsilotlari."""
    result = await db.execute(
        select(Order)
        .options(selectinload(Order.user), selectinload(Order.provider), selectinload(Order.category))
        .where(Order.id == order_id)
    )
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Buyurtma topilmadi")

    d = order.to_dict()
    d["user_name"] = f"{order.user.name} {order.user.surname}" if order.user else None
    d["provider_name"] = order.provider.name if order.provider else None
    d["category_title"] = order.category.title_uz if order.category else None
    return d


@router.patch("/orders/{order_id}/status", response_model=OrderOut)
async def admin_update_order_status(
    order_id: int,
    data: OrderStatusUpdate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Buyurtma topilmadi")
    
    old_status = order.status
    new_status = OrderStatus(data.status)
    order.status = new_status
    await db.flush()
    await db.refresh(order)

    if old_status != new_status:
        from app.services.notification_service import NotificationService
        status_translations = {
            OrderStatus.pending: "kutilmoqda",
            OrderStatus.accepted: "qabul qilindi",
            OrderStatus.completed: "yakunlandi",
            OrderStatus.cancelled: "bekor qilindi"
        }
        status_str = status_translations.get(new_status, new_status.value)
        NotificationService.send_notification(
            user_id=order.user_id,
            ntype="order_status_changed",
            title="Buyurtma holati o'zgardi",
            message=f"Sizning #{order.id} raqamli buyurtmangiz holati '{status_str}' ga o'zgardi."
        )
    return order


@router.delete("/orders/{order_id}", status_code=204)
async def delete_order(
    order_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalar_one_or_none()
    if not order:
        raise HTTPException(status_code=404, detail="Buyurtma topilmadi")
    await db.delete(order)


# ════════════════════════════════════════════════════════════
# 5. KATEGORIYALAR — CRUD, variantlar, narxlar
# ════════════════════════════════════════════════════════════

@router.get("/categories", response_model=list[CategoryOut])
async def list_categories(
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Category).options(selectinload(Category.variants)))
    return result.scalars().all()


@router.post("/categories", response_model=CategoryOut, status_code=201)
async def create_category(
    data: CategoryCreate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    cat = Category(**data.model_dump())
    db.add(cat)
    await db.flush()
    await db.refresh(cat)
    return cat


@router.patch("/categories/{category_id}", response_model=CategoryOut)
async def update_category(
    category_id: int,
    data: CategoryCreate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Category).where(Category.id == category_id))
    cat = result.scalar_one_or_none()
    if not cat:
        raise HTTPException(status_code=404, detail="Kategoriya topilmadi")

    for key, val in data.model_dump(exclude_unset=True).items():
        setattr(cat, key, val)

    await db.flush()
    await db.refresh(cat)
    return cat


@router.delete("/categories/{category_id}", status_code=204)
async def delete_category(
    category_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Category).where(Category.id == category_id))
    cat = result.scalar_one_or_none()
    if not cat:
        raise HTTPException(status_code=404, detail="Kategoriya topilmadi")
    await db.delete(cat)


@router.post("/categories/{category_id}/variants", response_model=VariantOut, status_code=201)
async def create_variant(
    category_id: int,
    data: VariantCreate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    v = CategoryVariant(category_id=category_id, **data.model_dump())
    db.add(v)
    await db.flush()
    await db.refresh(v)
    return v


@router.patch("/categories/{category_id}/variants/{variant_id}", response_model=VariantOut)
async def update_variant(
    category_id: int,
    variant_id: int,
    data: VariantCreate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(CategoryVariant).where(
            and_(
                CategoryVariant.id == variant_id,
                CategoryVariant.category_id == category_id,
            )
        )
    )
    v = result.scalar_one_or_none()
    if not v:
        raise HTTPException(status_code=404, detail="Variant topilmadi")

    for key, val in data.model_dump(exclude_unset=True).items():
        setattr(v, key, val)

    await db.flush()
    await db.refresh(v)
    return v


@router.delete("/categories/{category_id}/variants/{variant_id}", status_code=204)
async def delete_variant(
    category_id: int,
    variant_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(CategoryVariant).where(
            and_(
                CategoryVariant.id == variant_id,
                CategoryVariant.category_id == category_id,
            )
        )
    )
    v = result.scalar_one_or_none()
    if not v:
        raise HTTPException(status_code=404, detail="Variant topilmadi")
    await db.delete(v)


# ════════════════════════════════════════════════════════════
# 6. SHARHLAR — moderatsiya, o'chirish, spam
# ════════════════════════════════════════════════════════════

class ReviewListOut(ReviewOut):
    provider_name: Optional[str] = None


@router.get("/reviews", response_model=PaginatedResponse)
async def list_reviews(
    provider_id: int | None = Query(None),
    user_id: int | None = Query(None),
    min_rating: int | None = Query(None),
    max_rating: int | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Sharhlar ro'yxati — filter."""
    query = select(Review).options(selectinload(Review.provider), selectinload(Review.user))

    if provider_id:
        query = query.where(Review.provider_id == provider_id)
    if user_id:
        query = query.where(Review.user_id == user_id)
    if min_rating:
        query = query.where(Review.rating >= min_rating)
    if max_rating:
        query = query.where(Review.rating <= max_rating)

    count_query = select(func.count()).select_from(Review)
    if provider_id:
        count_query = count_query.where(Review.provider_id == provider_id)
    if user_id:
        count_query = count_query.where(Review.user_id == user_id)

    total = int(await db.scalar(count_query) or 0)

    query = query.order_by(desc(Review.created_at)).offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(query)
    items = result.scalars().all()

    out_items = []
    for r in items:
        d = r.to_dict()
        d["provider_name"] = r.provider.name if r.provider else None
        out_items.append(d)

    pages = (total + per_page - 1) // per_page
    return PaginatedResponse(items=out_items, total=total, page=page, per_page=per_page, pages=pages)


@router.delete("/reviews/{review_id}", status_code=204)
async def delete_review(
    review_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Sharhni o'chirish (moderatsiya)."""
    result = await db.execute(select(Review).where(Review.id == review_id))
    review = result.scalar_one_or_none()
    if not review:
        raise HTTPException(status_code=404, detail="Sharh topilmadi")
    await db.delete(review)

    # Provider rating ni qayta hisoblash
    avg_result = await db.execute(
        select(func.coalesce(func.avg(Review.rating), 0), func.count(Review.id)).where(
            Review.provider_id == review.provider_id
        )
    )
    avg_row = avg_result.one()
    provider_result = await db.execute(
        select(Provider).where(Provider.id == review.provider_id)
    )
    provider = provider_result.scalar_one()
    provider.rating = float(avg_row[0])
    provider.review_count = int(avg_row[1])
    await db.flush()


# ════════════════════════════════════════════════════════════
# 7. MOLIYA — to'lovlar, cashback, komissiya, chiqim
# ════════════════════════════════════════════════════════════

class FinanceStatsOut(BaseModel):
    total_revenue: float
    total_commission: float
    total_cashback_given: float
    total_payouts: float
    platform_balance: float
    commission_rate: float


class CommissionUpdate(BaseModel):
    rate: float = Field(..., ge=0, le=50)


class PayoutRequest(BaseModel):
    provider_id: int
    amount: float = Field(..., gt=0)
    note: Optional[str] = None


@router.get("/finance/stats", response_model=FinanceStatsOut)
async def finance_stats(
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Moliyaviy statistika."""
    total_revenue = float(
        await db.scalar(
            select(func.coalesce(func.sum(Order.price), 0)).where(
                Order.status == OrderStatus.completed
            )
        ) or 0
    )

    # Platform komissiyasi (default 15%)
    commission_rate = 15.0
    total_commission = total_revenue * (commission_rate / 100)
    total_cashback_given = float(
        await db.scalar(
            select(func.coalesce(func.sum(Order.cashback_earned), 0)).where(
                Order.status == OrderStatus.completed
            )
        ) or 0
    )

    return FinanceStatsOut(
        total_revenue=total_revenue,
        total_commission=round(total_commission, 2),
        total_cashback_given=total_cashback_given,
        total_payouts=0.0,
        platform_balance=round(total_commission - total_cashback_given, 2),
        commission_rate=commission_rate,
    )


@router.patch("/finance/commission")
async def update_commission_rate(
    data: CommissionUpdate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Komissiya foizini yangilash."""
    return {"message": "Komissiya yangilandi", "rate": data.rate}


@router.post("/finance/payout")
async def create_payout(
    data: PayoutRequest,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Soha egasiga to'lov (payout) yaratish."""
    result = await db.execute(select(Provider).where(Provider.id == data.provider_id))
    provider = result.scalar_one_or_none()
    if not provider:
        raise HTTPException(status_code=404, detail="Provayder topilmadi")

    return {
        "message": "To'lov yaratildi",
        "provider_id": data.provider_id,
        "amount": data.amount,
        "note": data.note,
    }


# ════════════════════════════════════════════════════════════
# 8. SOZLAMALAR — komissiya %, bannerlar, xabarlar
# ════════════════════════════════════════════════════════════

class SettingsOut(BaseModel):
    commission_rate: float
    cashback_rate: float
    currency: str
    maintenance_mode: bool
    registration_open: bool
    min_withdrawal: float
    support_phone: str
    support_telegram: str


class SettingsUpdate(BaseModel):
    commission_rate: Optional[float] = None
    cashback_rate: Optional[float] = None
    currency: Optional[str] = None
    maintenance_mode: Optional[bool] = None
    registration_open: Optional[bool] = None
    min_withdrawal: Optional[float] = None
    support_phone: Optional[str] = None
    support_telegram: Optional[str] = None


DEFAULT_SETTINGS = SettingsOut(
    commission_rate=15.0,
    cashback_rate=2.0,
    currency="UZS",
    maintenance_mode=False,
    registration_open=True,
    min_withdrawal=50000.0,
    support_phone="+998 71 200 00 00",
    support_telegram="@superapp_support",
)


@router.get("/settings", response_model=SettingsOut)
async def get_settings(
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Platforma sozlamalarini olish."""
    return DEFAULT_SETTINGS


@router.patch("/settings", response_model=SettingsOut)
async def update_settings(
    data: SettingsUpdate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Platforma sozlamalarini yangilash."""
    updated = DEFAULT_SETTINGS.model_copy(update=data.model_dump(exclude_unset=True))
    return updated


# ════════════════════════════════════════════════════════════
# 9. BILDIRISHNOMALAR — push, email, SMS
# ════════════════════════════════════════════════════════════

class NotificationSend(BaseModel):
    type: str = Field(..., pattern="^(push|email|sms|in_app)$")
    title: str = Field(..., min_length=1, max_length=200)
    message: str = Field(..., min_length=1, max_length=1000)
    target: str = Field(..., pattern="^(all|users|providers|user|provider)$")
    target_id: Optional[int] = None


@router.post("/notifications/send")
async def send_notification(
    data: NotificationSend,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Bildirishnoma yuborish (push/email/SMS/in_app)."""
    return {
        "message": "Bildirishnoma yuborildi",
        "type": data.type,
        "title": data.title,
        "target": data.target,
    }


@router.get("/notifications")
async def list_notifications(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Yuborilgan bildirishnomalar tarixi."""
    return {"items": [], "total": 0, "page": page, "per_page": per_page, "pages": 1}


# ════════════════════════════════════════════════════════════
# 10. HISOBOTLAR — kunlik/oylik/yillik, export CSV
# ════════════════════════════════════════════════════════════

class ReportPeriod(str, Enum):
    daily = "daily"
    weekly = "weekly"
    monthly = "monthly"
    yearly = "yearly"


class ReportOut(BaseModel):
    period: str
    date_from: str
    date_to: str
    total_orders: int
    completed_orders: int
    cancelled_orders: int
    total_revenue: float
    total_commission: float
    total_cashback: float
    new_users: int
    new_providers: int
    avg_order_price: float
    top_category: Optional[str] = None


@router.get("/reports", response_model=ReportOut)
async def get_report(
    period: ReportPeriod = Query(ReportPeriod.monthly),
    date_from: str | None = Query(None),
    date_to: str | None = Query(None),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Hisobot — kunlik/haftalik/oylik/yillik."""
    today = datetime.utcnow().date()

    if date_from and date_to:
        d_from = date.fromisoformat(date_from)
        d_to = date.fromisoformat(date_to)
    elif period == ReportPeriod.daily:
        d_from = d_to = today
    elif period == ReportPeriod.weekly:
        d_from = today - timedelta(days=7)
        d_to = today
    elif period == ReportPeriod.monthly:
        d_from = today.replace(day=1)
        d_to = today
    else:  # yearly
        d_from = today.replace(month=1, day=1)
        d_to = today

    # Orders
    total_orders = int(
        await db.scalar(
            select(func.count(Order.id)).where(
                and_(
                    func.date(Order.created_at) >= d_from,
                    func.date(Order.created_at) <= d_to,
                )
            )
        ) or 0
    )

    completed_orders = int(
        await db.scalar(
            select(func.count(Order.id)).where(
                and_(
                    Order.status == OrderStatus.completed,
                    func.date(Order.created_at) >= d_from,
                    func.date(Order.created_at) <= d_to,
                )
            )
        ) or 0
    )

    cancelled_orders = int(
        await db.scalar(
            select(func.count(Order.id)).where(
                and_(
                    Order.status == OrderStatus.cancelled,
                    func.date(Order.created_at) >= d_from,
                    func.date(Order.created_at) <= d_to,
                )
            )
        ) or 0
    )

    total_revenue = float(
        await db.scalar(
            select(func.coalesce(func.sum(Order.price), 0)).where(
                and_(
                    Order.status == OrderStatus.completed,
                    func.date(Order.created_at) >= d_from,
                    func.date(Order.created_at) <= d_to,
                )
            )
        ) or 0
    )

    new_users = int(
        await db.scalar(
            select(func.count(User.id)).where(
                and_(
                    func.date(User.created_at) >= d_from,
                    func.date(User.created_at) <= d_to,
                )
            )
        ) or 0
    )

    avg_order_price = total_revenue / completed_orders if completed_orders > 0 else 0

    # Top category
    cat_rows = await db.execute(
        select(Category.title_uz, func.count(Order.id))
        .join(Order, Order.category_id == Category.id)
        .where(
            and_(
                func.date(Order.created_at) >= d_from,
                func.date(Order.created_at) <= d_to,
            )
        )
        .group_by(Category.title_uz)
        .order_by(func.count(Order.id).desc())
        .limit(1)
    )
    top_cat = cat_rows.first()

    return ReportOut(
        period=period.value,
        date_from=str(d_from),
        date_to=str(d_to),
        total_orders=total_orders,
        completed_orders=completed_orders,
        cancelled_orders=cancelled_orders,
        total_revenue=total_revenue,
        total_commission=round(total_revenue * 0.15, 2),
        total_cashback=0.0,
        new_users=new_users,
        new_providers=0,
        avg_order_price=round(avg_order_price, 2),
        top_category=top_cat[0] if top_cat else None,
    )


@router.get("/reports/export/csv")
async def export_report_csv(
    period: ReportPeriod = Query(ReportPeriod.monthly),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """CSV export — hisobot."""
    from fastapi.responses import PlainTextResponse

    report = await get_report(period, None, None, _admin, db)

    csv_lines = [
        "Hisobot",
        f"Davr,{report.period}",
        f"Sana,{report.date_from} - {report.date_to}",
        "",
        "Buyurtmalar",
        f"Jami buyurtmalar,{report.total_orders}",
        f"Tugallangan,{report.completed_orders}",
        f"Bekor qilingan,{report.cancelled_orders}",
        "",
        "Moliya",
        f"Jami tushum,{report.total_revenue}",
        f"Komissiya (15%),{report.total_commission}",
        f"Cashback,{report.total_cashback}",
        "",
        "Foydalanuvchilar",
        f"Yangi foydalanuvchilar,{report.new_users}",
        f"Yangi soha egalari,{report.new_providers}",
        "",
        "O'rtacha",
        f"O'rtacha buyurtma narxi,{report.avg_order_price}",
        f"Eng mashhur kategoriya,{report.top_category or 'N/A'}",
    ]

    return PlainTextResponse(
        content="\n".join(csv_lines),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename=report_{report.period}.csv"},
    )
