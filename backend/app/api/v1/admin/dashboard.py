from datetime import datetime, date, timedelta
from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select, and_, desc

from app.db.session import get_db
from app.models.user import User
from app.models.category import Category
from app.models.provider import Provider
from app.models.order import Order, OrderStatus
from app.models.review import Review
from app.api.v1.admin.dependencies import require_admin

router = APIRouter()


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

    orders_total = int(await db.scalar(select(func.count()).select_from(Order)) or 0)

    status_rows = await db.execute(
        select(Order.status, func.count(Order.id)).group_by(Order.status)
    )
    orders_by_status: dict[str, int] = {s.value: 0 for s in OrderStatus}
    for row in status_rows.all():
        status_val, cnt = row[0], int(row[1])
        if status_val is not None:
            orders_by_status[status_val.value] = cnt

    providers = int(await db.scalar(select(func.count()).select_from(Provider)) or 0)
    users = int(await db.scalar(select(func.count()).select_from(User)) or 0)
    categories = int(await db.scalar(select(func.count()).select_from(Category)) or 0)

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

    avg_rating = float(
        await db.scalar(select(func.coalesce(func.avg(Review.rating), 0))) or 0
    )

    new_users_today = int(
        await db.scalar(
            select(func.count(User.id)).where(func.date(User.created_at) == today)
        ) or 0
    )

    pending_providers = int(
        await db.scalar(
            select(func.count(Provider.id)).where(
                Provider.is_active == False,
                Provider.is_blocked == False,
            )
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
    today = datetime.utcnow().date()
    start_date = today - timedelta(days=days - 1)

    rev_rows = await db.execute(
        select(func.date(Order.created_at), func.sum(Order.price)).where(
            and_(
                Order.status == OrderStatus.completed,
                func.date(Order.created_at) >= start_date,
            )
        ).group_by(func.date(Order.created_at))
    )
    revenue_map = {str(r[0]): float(r[1]) for r in rev_rows.all()}

    ord_rows = await db.execute(
        select(func.date(Order.created_at), func.count(Order.id)).where(
            func.date(Order.created_at) >= start_date
        ).group_by(func.date(Order.created_at))
    )
    orders_map = {str(r[0]): int(r[1]) for r in ord_rows.all()}

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
