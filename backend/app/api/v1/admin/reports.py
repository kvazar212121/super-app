import csv
import io
from datetime import datetime, date, timedelta
from enum import Enum
from typing import Optional, List
from fastapi import APIRouter, Depends, Query
from fastapi.responses import PlainTextResponse
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select, and_, desc as sa_desc

from app.db.session import get_db
from app.models.user import User
from app.models.category import Category
from app.models.order import Order, OrderStatus
from app.models.provider import Provider
from app.models.finance_record import FinanceRecord
from app.api.v1.admin.dependencies import require_admin

router = APIRouter()


def _csv_response(filename: str, header: list, rows: list) -> PlainTextResponse:
    buf = io.StringIO()
    w = csv.writer(buf)
    w.writerow(header)
    for r in rows:
        w.writerow(r)
    return PlainTextResponse(
        content=buf.getvalue(),
        media_type="text/csv; charset=utf-8",
        headers={"Content-Disposition": f"attachment; filename={filename}"},
    )


@router.get("/reports/export/orders.csv")
async def export_orders(_admin: User = Depends(require_admin), db: AsyncSession = Depends(get_db)):
    rows = (await db.execute(select(Order).order_by(sa_desc(Order.id)).limit(5000))).scalars().all()
    data = [
        [o.id, o.user_id, o.provider_id, o.service_name, o.price,
         (o.status.value if hasattr(o.status, "value") else o.status),
         o.date.isoformat() if o.date else "",
         o.created_at.isoformat() if o.created_at else ""]
        for o in rows
    ]
    return _csv_response("orders.csv",
        ["id", "user_id", "provider_id", "service_name", "price", "status", "date", "created_at"], data)


@router.get("/reports/export/users.csv")
async def export_users(_admin: User = Depends(require_admin), db: AsyncSession = Depends(get_db)):
    rows = (await db.execute(select(User).order_by(sa_desc(User.id)).limit(10000))).scalars().all()
    data = [
        [u.id, u.name, u.surname, u.phone, u.balance,
         u.is_premium, u.is_admin, u.created_at.isoformat() if u.created_at else ""]
        for u in rows
    ]
    return _csv_response("users.csv",
        ["id", "name", "surname", "phone", "balance", "is_premium", "is_admin", "created_at"], data)


@router.get("/reports/export/finance.csv")
async def export_finance(_admin: User = Depends(require_admin), db: AsyncSession = Depends(get_db)):
    rows = (await db.execute(select(FinanceRecord).order_by(sa_desc(FinanceRecord.id)).limit(10000))).scalars().all()
    data = [
        [f.id, f.user_id, f.type, f.amount, f.category, (f.description or ""),
         f.date.isoformat() if f.date else ""]
        for f in rows
    ]
    return _csv_response("finance.csv",
        ["id", "user_id", "type", "amount", "category", "description", "date"], data)


class ReportPeriod(str, Enum):
    daily = "daily"
    weekly = "weekly"
    monthly = "monthly"
    yearly = "yearly"


class CategoryStat(BaseModel):
    name: str
    orders: int
    lead_fee_total: float


class ProviderStat(BaseModel):
    id: int
    name: str
    balance: float
    orders: int
    lead_fee_total: float


class ChartPoint(BaseModel):
    label: str
    lead_fee: float
    orders: int


class ReportOut(BaseModel):
    period: str
    date_from: str
    date_to: str
    total_orders: int
    completed_orders: int
    cancelled_orders: int
    pending_orders: int
    avg_order_price: float
    total_lead_fee: float
    total_premium: float
    total_topup: float
    total_admin_withdraw: float
    net_profit: float
    total_revenue: float
    total_commission: float
    new_users: int
    new_providers: int
    top_category: Optional[str] = None
    category_stats: List[CategoryStat] = []
    top_providers: List[ProviderStat] = []
    chart_data: List[ChartPoint] = []


def _get_date_range(period: ReportPeriod, date_from, date_to):
    today = datetime.utcnow().date()
    if date_from and date_to:
        return date.fromisoformat(date_from), date.fromisoformat(date_to)
    if period == ReportPeriod.daily:
        return today, today
    if period == ReportPeriod.weekly:
        return today - timedelta(days=7), today
    if period == ReportPeriod.monthly:
        return today.replace(day=1), today
    return today.replace(month=1, day=1), today


@router.get("/reports", response_model=ReportOut)
async def get_report(
    period: ReportPeriod = Query(ReportPeriod.monthly),
    date_from: str | None = Query(None),
    date_to: str | None = Query(None),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    d_from, d_to = _get_date_range(period, date_from, date_to)
    from app.models.transaction import Transaction

    def df(col):
        return and_(func.date(col) >= d_from, func.date(col) <= d_to)

    total_orders = int(await db.scalar(select(func.count(Order.id)).where(df(Order.created_at))) or 0)
    completed_orders = int(await db.scalar(select(func.count(Order.id)).where(Order.status == OrderStatus.completed, df(Order.created_at))) or 0)
    cancelled_orders = int(await db.scalar(select(func.count(Order.id)).where(Order.status == OrderStatus.cancelled, df(Order.created_at))) or 0)
    pending_orders = int(await db.scalar(select(func.count(Order.id)).where(Order.status == OrderStatus.pending, df(Order.created_at))) or 0)
    total_revenue = float(await db.scalar(select(func.coalesce(func.sum(Order.price), 0)).where(Order.status == OrderStatus.completed, df(Order.created_at))) or 0)
    avg_order_price = round(total_revenue / completed_orders, 0) if completed_orders > 0 else 0

    total_lead_fee = float(await db.scalar(
        select(func.coalesce(func.sum(func.abs(Transaction.amount)), 0)).where(
            Transaction.type == "lead_fee", Transaction.status == "completed", df(Transaction.created_at)
        )
    ) or 0)

    total_premium = float(await db.scalar(
        select(func.coalesce(func.sum(Transaction.amount), 0)).where(
            Transaction.type == "premium_subscription", Transaction.status == "completed", df(Transaction.created_at)
        )
    ) or 0)

    total_topup = float(await db.scalar(
        select(func.coalesce(func.sum(Transaction.amount), 0)).where(
            Transaction.type == "topup", Transaction.status == "completed", df(Transaction.created_at)
        )
    ) or 0)

    total_admin_withdraw = float(await db.scalar(
        select(func.coalesce(func.sum(func.abs(Transaction.amount)), 0)).where(
            Transaction.type == "admin_withdraw", Transaction.status == "completed", df(Transaction.created_at)
        )
    ) or 0)

    net_profit = round(total_lead_fee + total_premium - total_admin_withdraw, 2)

    new_users = int(await db.scalar(select(func.count(User.id)).where(df(User.created_at))) or 0)
    new_providers = int(await db.scalar(select(func.count(Provider.id)).where(df(Provider.created_at))) or 0)

    cat_rows = (await db.execute(
        select(Category.title_uz, func.count(Order.id), func.coalesce(func.sum(func.abs(Transaction.amount)), 0))
        .join(Order, Order.category_id == Category.id)
        .outerjoin(Transaction, and_(Transaction.order_id == Order.id, Transaction.type == "lead_fee"))
        .where(df(Order.created_at))
        .group_by(Category.title_uz)
        .order_by(func.count(Order.id).desc())
        .limit(8)
    )).all()
    category_stats = [CategoryStat(name=r[0], orders=int(r[1]), lead_fee_total=float(r[2])) for r in cat_rows]
    top_category = category_stats[0].name if category_stats else None

    prov_rows = (await db.execute(
        select(Provider.id, Provider.name, Provider.balance, func.count(Order.id), func.coalesce(func.sum(func.abs(Transaction.amount)), 0))
        .outerjoin(Order, and_(Order.provider_id == Provider.id, df(Order.created_at)))
        .outerjoin(Transaction, and_(Transaction.provider_id == Provider.id, Transaction.type == "lead_fee", df(Transaction.created_at)))
        .group_by(Provider.id, Provider.name, Provider.balance)
        .order_by(func.count(Order.id).desc())
        .limit(8)
    )).all()
    top_providers = [ProviderStat(id=r[0], name=r[1], balance=float(r[2] or 0), orders=int(r[3] or 0), lead_fee_total=float(r[4] or 0)) for r in prov_rows]

    delta = (d_to - d_from).days
    chart_points = []
    if delta <= 31:
        for i in range(delta + 1):
            day = d_from + timedelta(days=i)
            day_orders = int(await db.scalar(select(func.count(Order.id)).where(func.date(Order.created_at) == day)) or 0)
            day_fee = float(await db.scalar(
                select(func.coalesce(func.sum(func.abs(Transaction.amount)), 0)).where(
                    Transaction.type == "lead_fee", func.date(Transaction.created_at) == day
                )
            ) or 0)
            chart_points.append(ChartPoint(label=day.strftime("%-d %b"), lead_fee=day_fee, orders=day_orders))
    else:
        cur = d_from
        while cur <= d_to:
            week_end = min(cur + timedelta(days=6), d_to)
            week_fee = float(await db.scalar(
                select(func.coalesce(func.sum(func.abs(Transaction.amount)), 0)).where(
                    Transaction.type == "lead_fee",
                    func.date(Transaction.created_at) >= cur,
                    func.date(Transaction.created_at) <= week_end
                )
            ) or 0)
            week_orders = int(await db.scalar(
                select(func.count(Order.id)).where(
                    func.date(Order.created_at) >= cur,
                    func.date(Order.created_at) <= week_end
                )
            ) or 0)
            chart_points.append(ChartPoint(label=cur.strftime("%-d %b"), lead_fee=week_fee, orders=week_orders))
            cur = week_end + timedelta(days=1)

    return ReportOut(
        period=period.value,
        date_from=str(d_from),
        date_to=str(d_to),
        total_orders=total_orders,
        completed_orders=completed_orders,
        cancelled_orders=cancelled_orders,
        pending_orders=pending_orders,
        avg_order_price=avg_order_price,
        total_lead_fee=round(total_lead_fee, 2),
        total_premium=round(total_premium, 2),
        total_topup=round(total_topup, 2),
        total_admin_withdraw=round(total_admin_withdraw, 2),
        net_profit=net_profit,
        total_revenue=total_revenue,
        total_commission=round(total_lead_fee, 2),
        new_users=new_users,
        new_providers=new_providers,
        top_category=top_category,
        category_stats=category_stats,
        top_providers=top_providers,
        chart_data=chart_points,
    )


@router.get("/reports/export/csv")
async def export_report_csv(
    period: ReportPeriod = Query(ReportPeriod.monthly),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    report = await get_report(period, None, None, _admin, db)
    lines = [
        "Hisobot", f"Davr,{report.period}", f"Sana,{report.date_from} - {report.date_to}", "",
        "Buyurtmalar",
        f"Jami,{report.total_orders}",
        f"Tugallangan,{report.completed_orders}",
        f"Bekor qilingan,{report.cancelled_orders}",
        f"Kutilmoqda,{report.pending_orders}",
        f"O'rtacha narx,{report.avg_order_price}", "",
        "Moliya (Yangi Tizim)",
        f"Lead Fee (Komissiya),{report.total_lead_fee}",
        f"Premium Tushum,{report.total_premium}",
        f"Jami Top-up,{report.total_topup}",
        f"Platforma Xarajati,{report.total_admin_withdraw}",
        f"Sof Foyda,{report.net_profit}", "",
        "Foydalanuvchilar",
        f"Yangi foydalanuvchilar,{report.new_users}",
        f"Yangi soha egalari,{report.new_providers}", "",
        "Eng faol kategoriyalar",
    ] + [f"{c.name},{c.orders} buyurtma,{c.lead_fee_total} so'm" for c in report.category_stats]
    return PlainTextResponse(
        content="\n".join(lines),
        media_type="text/csv",
        headers={"Content-Disposition": f"attachment; filename=report_{report.period}.csv"},
    )
