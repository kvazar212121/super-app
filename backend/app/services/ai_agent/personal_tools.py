"""QO'SHISH toollari: reja, moliya yozuvi, bozorlik mahsuloti, budilnik."""
import json
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.plan import Plan
from app.models.finance_record import FinanceRecord
from app.models.shopping_list import ShoppingList


def _build_alarm_mission_config(mission_type: str) -> dict:
    if mission_type == "photo":
        return {"target_uz": "kran (yuvinish joyi)", "target_en": "bathroom sink or faucet"}
    if mission_type == "speech":
        return {"random": True}
    return {"difficulty": "medium", "count": 1}


async def add_plan(db: AsyncSession, user_id: int, args: dict) -> tuple[str, dict | None]:
    plan = Plan(
        user_id=user_id,
        title=args.get("title"),
        description=args.get("description", ""),
        due_date=datetime.fromisoformat(args.get("due_date").replace('Z', '+00:00'))
    )
    db.add(plan)
    await db.commit()
    return '{"status": "success", "message": "Reja muvaffaqiyatli qo\'shildi."}', None


async def add_finance_record(db: AsyncSession, user_id: int, args: dict) -> tuple[str, dict | None]:
    record = FinanceRecord(
        user_id=user_id,
        type=args.get("type"),
        amount=float(args.get("amount")),
        category=args.get("category"),
        description=args.get("description", ""),
        date=datetime.now(timezone.utc)
    )
    db.add(record)
    await db.commit()
    return '{"status": "success", "message": "Moliya yozuvi muvaffaqiyatli qo\'shildi."}', None


async def add_shopping_item(db: AsyncSession, user_id: int, args: dict) -> tuple[str, dict | None]:
    # Active shopping list ni topish yoki yaratish
    result = await db.execute(
        select(ShoppingList).where(ShoppingList.user_id == user_id, ShoppingList.total_estimated_price >= 0).order_by(ShoppingList.id.desc()).limit(1)
    )
    s_list = result.scalar_one_or_none()
    if not s_list:
        s_list = ShoppingList(user_id=user_id, name="Bozorlik (AI orqali)")
        db.add(s_list)
        await db.flush()

    items = list(s_list.items) if s_list.items else []
    items.append({
        "name": args.get("name"),
        "qty": float(args.get("qty")),
        "unit": args.get("unit"),
        "estimated_price": float(args.get("estimated_price", 0)),
        "actual_price": None,
        "is_bought": False
    })
    s_list.items = items

    # Recalculate total estimated price safely
    total_est = 0.0
    for item in items:
        est = item.get("estimated_price")
        if est is not None:
            try:
                total_est += float(est)
            except ValueError:
                pass
    s_list.total_estimated_price = total_est

    await db.commit()
    return '{"status": "success", "message": "Mahsulot bozorlik ro\'yxatiga muvaffaqiyatli qo\'shildi."}', None


async def set_alarm(db: AsyncSession, user_id: int, args: dict) -> tuple[str, dict | None]:
    from app.models.alarm import Alarm
    hour = max(0, min(23, int(args.get("hour"))))
    minute = max(0, min(59, int(args.get("minute"))))
    mission_type = args.get("mission_type") or "math"
    if mission_type not in ("math", "photo", "speech"):
        mission_type = "math"
    mission_config = _build_alarm_mission_config(mission_type)
    alarm = Alarm(
        user_id=user_id,
        label=args.get("label") or "Budilnik",
        hour=hour,
        minute=minute,
        repeat_days=args.get("repeat_days") or "",
        mission_type=mission_type,
        mission_config=mission_config,
    )
    db.add(alarm)
    await db.commit()
    await db.refresh(alarm)
    # Mobil ilova buni olib, budilnikni QURILMADA lokal rejalashtiradi
    action = {
        "type": "schedule_alarm",
        "alarm": {
            "id": alarm.id,
            "label": alarm.label,
            "hour": alarm.hour,
            "minute": alarm.minute,
            "repeat_days": alarm.repeat_days,
            "ringtone": alarm.ringtone,
            "mission_type": alarm.mission_type,
            "mission_config": alarm.mission_config,
            "snooze_enabled": alarm.snooze_enabled,
            "snooze_minutes": alarm.snooze_minutes,
            "is_enabled": alarm.is_enabled,
        },
    }
    return '{"status": "success", "message": "Budilnik qo\'shildi va rejalashtirildi."}', action


HANDLERS = {
    "add_plan": add_plan,
    "add_finance_record": add_finance_record,
    "add_shopping_item": add_shopping_item,
    "set_alarm": set_alarm,
}
