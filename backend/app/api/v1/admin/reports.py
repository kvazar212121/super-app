from datetime import datetime, date, timedelta
from enum import Enum
from typing import Optional
from fastapi import APIRouter, Depends, Query
from fastapi.responses import PlainTextResponse
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select, and_

from app.db.session import get_db
from app.models.user import User
from app.models.category import Category
from app.models.order import Order, OrderStatus
from app.api.v1.admin.dependencies import require_admin

router = APIRouter()


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
