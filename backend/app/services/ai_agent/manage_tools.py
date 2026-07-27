"""BEKOR / O'CHIRISH / TAHRIRLASH toollari — xavflilari 2-qadamli confirm bilan."""
import json

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.plan import Plan
from app.models.finance_record import FinanceRecord
from app.models.shopping_list import ShoppingList


async def cancel_order(db: AsyncSession, user_id: int, args: dict) -> tuple[str, dict | None]:
    from app.models.order import Order, OrderStatus
    if not args.get("confirm"):
        return json.dumps({"status": "needs_confirmation",
            "message": "Bekor qilishni tasdiqlashini so'rang."}, ensure_ascii=False), None
    o = (await db.execute(
        select(Order).where(Order.id == int(args.get("order_id")), Order.user_id == user_id)
    )).scalar_one_or_none()
    if not o:
        return '{"status": "error", "message": "Buyurtma topilmadi"}', None
    if o.status in (OrderStatus.completed, OrderStatus.cancelled, OrderStatus.no_show):
        return '{"status": "error", "message": "Bu buyurtmani bekor qilib bo\'lmaydi"}', None
    o.status = OrderStatus.cancelled
    await db.commit()
    return json.dumps({"status": "success", "message": "Buyurtma bekor qilindi", "order_id": o.id},
                      ensure_ascii=False), {"type": "orders_changed"}


async def complete_plan(db: AsyncSession, user_id: int, args: dict) -> tuple[str, dict | None]:
    p = (await db.execute(
        select(Plan).where(Plan.id == int(args.get("plan_id")), Plan.user_id == user_id)
    )).scalar_one_or_none()
    if not p:
        return '{"status": "error", "message": "Reja topilmadi"}', None
    p.is_completed = True
    await db.commit()
    return '{"status": "success", "message": "Reja bajarildi deb belgilandi."}', {"type": "plans_changed"}


async def delete_plan(db: AsyncSession, user_id: int, args: dict) -> tuple[str, dict | None]:
    if not args.get("confirm"):
        return '{"status": "needs_confirmation", "message": "O\'chirishni tasdiqlashini so\'rang."}', None
    p = (await db.execute(
        select(Plan).where(Plan.id == int(args.get("plan_id")), Plan.user_id == user_id)
    )).scalar_one_or_none()
    if not p:
        return '{"status": "error", "message": "Reja topilmadi"}', None
    await db.delete(p)
    await db.commit()
    return '{"status": "success", "message": "Reja o\'chirildi."}', {"type": "plans_changed"}


async def complete_todo(db: AsyncSession, user_id: int, args: dict) -> tuple[str, dict | None]:
    from app.models.todo import Todo
    t = (await db.execute(
        select(Todo).where(Todo.id == int(args.get("todo_id")), Todo.user_id == user_id)
    )).scalar_one_or_none()
    if not t:
        return '{"status": "error", "message": "Vazifa topilmadi"}', None
    t.is_completed = True
    await db.commit()
    return '{"status": "success", "message": "Vazifa bajarildi deb belgilandi."}', {"type": "todos_changed"}


async def delete_todo(db: AsyncSession, user_id: int, args: dict) -> tuple[str, dict | None]:
    from app.models.todo import Todo
    if not args.get("confirm"):
        return '{"status": "needs_confirmation", "message": "O\'chirishni tasdiqlashini so\'rang."}', None
    t = (await db.execute(
        select(Todo).where(Todo.id == int(args.get("todo_id")), Todo.user_id == user_id)
    )).scalar_one_or_none()
    if not t:
        return '{"status": "error", "message": "Vazifa topilmadi"}', None
    await db.delete(t)
    await db.commit()
    return '{"status": "success", "message": "Vazifa o\'chirildi."}', {"type": "todos_changed"}


async def toggle_alarm(db: AsyncSession, user_id: int, args: dict) -> tuple[str, dict | None]:
    from app.models.alarm import Alarm
    a = (await db.execute(
        select(Alarm).where(Alarm.id == int(args.get("alarm_id")), Alarm.user_id == user_id)
    )).scalar_one_or_none()
    if not a:
        return '{"status": "error", "message": "Budilnik topilmadi"}', None
    a.is_enabled = bool(args.get("enabled"))
    await db.commit()
    msg = "Budilnik yoqildi." if a.is_enabled else "Budilnik o'chirildi."
    return json.dumps({"status": "success", "message": msg}, ensure_ascii=False), {"type": "alarms_changed", "alarm_id": a.id, "enabled": a.is_enabled}


async def delete_alarm(db: AsyncSession, user_id: int, args: dict) -> tuple[str, dict | None]:
    from app.models.alarm import Alarm
    if not args.get("confirm"):
        return '{"status": "needs_confirmation", "message": "O\'chirishni tasdiqlashini so\'rang."}', None
    a = (await db.execute(
        select(Alarm).where(Alarm.id == int(args.get("alarm_id")), Alarm.user_id == user_id)
    )).scalar_one_or_none()
    if not a:
        return '{"status": "error", "message": "Budilnik topilmadi"}', None
    aid = a.id
    await db.delete(a)
    await db.commit()
    return '{"status": "success", "message": "Budilnik o\'chirildi."}', {"type": "alarms_changed", "alarm_id": aid, "deleted": True}


async def mark_shopping_bought(db: AsyncSession, user_id: int, args: dict) -> tuple[str, dict | None]:
    result = await db.execute(
        select(ShoppingList).where(ShoppingList.user_id == user_id).order_by(ShoppingList.id.desc()).limit(1)
    )
    s_list = result.scalar_one_or_none()
    if not s_list or not s_list.items:
        return '{"status": "error", "message": "Bozorlik ro\'yxati bo\'sh"}', None
    name_q = (args.get("item_name") or "").strip().lower()
    items = list(s_list.items)
    found = False
    for it in items:
        if (it.get("name") or "").strip().lower() == name_q:
            it["is_bought"] = True
            found = True
            break
    if not found:
        return '{"status": "error", "message": "Mahsulot topilmadi"}', None
    s_list.items = items
    await db.commit()
    return '{"status": "success", "message": "Mahsulot sotib olindi deb belgilandi."}', {"type": "shopping_changed"}


async def delete_finance_record(db: AsyncSession, user_id: int, args: dict) -> tuple[str, dict | None]:
    if not args.get("confirm"):
        return '{"status": "needs_confirmation", "message": "O\'chirishni tasdiqlashini so\'rang."}', None
    r = (await db.execute(
        select(FinanceRecord).where(FinanceRecord.id == int(args.get("record_id")), FinanceRecord.user_id == user_id)
    )).scalar_one_or_none()
    if not r:
        return '{"status": "error", "message": "Yozuv topilmadi"}', None
    await db.delete(r)
    await db.commit()
    return '{"status": "success", "message": "Moliya yozuvi o\'chirildi."}', {"type": "finance_changed"}


HANDLERS = {
    "cancel_order": cancel_order,
    "complete_plan": complete_plan,
    "delete_plan": delete_plan,
    "complete_todo": complete_todo,
    "delete_todo": delete_todo,
    "toggle_alarm": toggle_alarm,
    "delete_alarm": delete_alarm,
    "mark_shopping_bought": mark_shopping_bought,
    "delete_finance_record": delete_finance_record,
}
