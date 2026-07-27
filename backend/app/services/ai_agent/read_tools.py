"""KO'RISH (read-only) toollari: buyurtmalar, rejalar, vazifalar, budilniklar,
bozorlik, moliya xulosasi, hisob ma'lumoti, qadamlar."""
import json
from datetime import datetime, timezone

from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.plan import Plan
from app.models.finance_record import FinanceRecord
from app.models.shopping_list import ShoppingList


async def list_orders(db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None) -> tuple[str, dict | None]:
    from app.models.order import Order, OrderStatus
    from app.models.provider import Provider
    only_active = args.get("only_active", True)
    stmt = select(Order).where(Order.user_id == user_id)
    if only_active:
        stmt = stmt.where(Order.status.notin_([OrderStatus.completed, OrderStatus.cancelled, OrderStatus.no_show]))
    stmt = stmt.order_by(Order.created_at.desc()).limit(15)
    orders = (await db.execute(stmt)).scalars().all()
    out = []
    for o in orders:
        prov = await db.get(Provider, o.provider_id)
        out.append({
            "order_id": o.id,
            "service_name": o.service_name,
            "provider": prov.name if prov else None,
            "status": o.status.value,
            "date": o.date.isoformat() if o.date else None,
            "price": o.price,
        })
    return json.dumps({"status": "success", "orders": out, "count": len(out)}, ensure_ascii=False), None


async def list_plans(db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None) -> tuple[str, dict | None]:
    only_pending = args.get("only_pending", True)
    stmt = select(Plan).where(Plan.user_id == user_id)
    if only_pending:
        stmt = stmt.where(Plan.is_completed == False)
    stmt = stmt.order_by(Plan.due_date.asc()).limit(20)
    plans = (await db.execute(stmt)).scalars().all()
    out = [{"plan_id": p.id, "title": p.title, "due_date": p.due_date.isoformat() if p.due_date else None,
            "is_completed": p.is_completed} for p in plans]
    return json.dumps({"status": "success", "plans": out, "count": len(out)}, ensure_ascii=False), None


async def list_todos(db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None) -> tuple[str, dict | None]:
    from app.models.todo import Todo
    only_pending = args.get("only_pending", True)
    stmt = select(Todo).where(Todo.user_id == user_id)
    if only_pending:
        stmt = stmt.where(Todo.is_completed == False)
    stmt = stmt.order_by(Todo.created_at.desc()).limit(20)
    todos = (await db.execute(stmt)).scalars().all()
    out = [{"todo_id": t.id, "title": t.title, "is_completed": t.is_completed} for t in todos]
    return json.dumps({"status": "success", "todos": out, "count": len(out)}, ensure_ascii=False), None


async def list_alarms(db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None) -> tuple[str, dict | None]:
    from app.models.alarm import Alarm
    alarms = (await db.execute(
        select(Alarm).where(Alarm.user_id == user_id).order_by(Alarm.hour, Alarm.minute)
    )).scalars().all()
    out = [{"alarm_id": a.id, "label": a.label, "time": f"{a.hour:02d}:{a.minute:02d}",
            "is_enabled": a.is_enabled, "repeat_days": a.repeat_days} for a in alarms]
    return json.dumps({"status": "success", "alarms": out, "count": len(out)}, ensure_ascii=False), None


async def list_shopping(db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None) -> tuple[str, dict | None]:
    result = await db.execute(
        select(ShoppingList).where(ShoppingList.user_id == user_id).order_by(ShoppingList.id.desc()).limit(1)
    )
    s_list = result.scalar_one_or_none()
    items = (s_list.items if s_list and s_list.items else [])
    out = [{"name": it.get("name"), "qty": it.get("qty"), "unit": it.get("unit"),
            "is_bought": it.get("is_bought", False)} for it in items]
    return json.dumps({"status": "success", "items": out, "count": len(out)}, ensure_ascii=False), None


async def get_finance_summary(db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None) -> tuple[str, dict | None]:
    income = float(await db.scalar(
        select(func.coalesce(func.sum(FinanceRecord.amount), 0)).where(
            FinanceRecord.user_id == user_id, FinanceRecord.type == "income",
            func.extract("month", FinanceRecord.date) == datetime.now(timezone.utc).month,
            func.extract("year", FinanceRecord.date) == datetime.now(timezone.utc).year,
        )
    ) or 0)
    expense = float(await db.scalar(
        select(func.coalesce(func.sum(FinanceRecord.amount), 0)).where(
            FinanceRecord.user_id == user_id, FinanceRecord.type == "expense",
            func.extract("month", FinanceRecord.date) == datetime.now(timezone.utc).month,
            func.extract("year", FinanceRecord.date) == datetime.now(timezone.utc).year,
        )
    ) or 0)
    return json.dumps({
        "status": "success", "month_income": income, "month_expense": expense,
        "balance": income - expense,
    }, ensure_ascii=False), None


async def get_account_info(db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None) -> tuple[str, dict | None]:
    from app.models.user import User as _U
    u = await db.get(_U, user_id)
    if not u:
        return '{"status": "error", "message": "Foydalanuvchi topilmadi"}', None
    from app.services import premium_service
    return json.dumps({
        "status": "success", "name": u.name,
        "balance": float(u.balance or 0),
        "is_premium": premium_service.is_active(u),
        "premium_until": u.premium_until.isoformat() if u.premium_until else None,
    }, ensure_ascii=False), None


async def get_steps_today(db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None) -> tuple[str, dict | None]:
    from app.models.daily_activity import DailyActivity
    from datetime import date as _date
    row = (await db.execute(
        select(DailyActivity).where(
            DailyActivity.user_id == user_id, DailyActivity.date == _date.today()
        )
    )).scalar_one_or_none()
    return json.dumps({
        "status": "success",
        "steps": (row.steps if row else 0),
        "calories": (round(row.calories, 1) if row else 0),
    }, ensure_ascii=False), None


HANDLERS = {
    "list_orders": list_orders,
    "list_plans": list_plans,
    "list_todos": list_todos,
    "list_alarms": list_alarms,
    "list_shopping": list_shopping,
    "get_finance_summary": get_finance_summary,
    "get_account_info": get_account_info,
    "get_steps_today": get_steps_today,
}
