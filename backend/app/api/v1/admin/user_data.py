from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, desc
from sqlalchemy.orm import joinedload

from app.db.session import get_db
from app.models.user import User
from app.models.todo import Todo
from app.models.shopping_list import ShoppingList
from app.models.finance_record import FinanceRecord
from app.models.plan import Plan
from app.api.v1.admin.dependencies import require_admin

router = APIRouter()

@router.get("/user-data/todos")
async def get_all_todos(
    skip: int = 0,
    limit: int = Query(50, le=100),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Todo).options(joinedload(Todo.user)).order_by(desc(Todo.created_at)).offset(skip).limit(limit)
    )
    todos = result.scalars().all()
    return [{
        "id": t.id,
        "title": t.title,
        "is_completed": t.is_completed,
        "due_date": t.due_date.isoformat() if t.due_date else None,
        "created_at": t.created_at.isoformat() if t.created_at else None,
        "user_id": t.user_id,
        "user_name": f"{t.user.name} {t.user.surname}" if t.user else "Noma'lum"
    } for t in todos]

@router.get("/user-data/shopping")
async def get_all_shopping_lists(
    skip: int = 0,
    limit: int = Query(50, le=100),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(ShoppingList).options(joinedload(ShoppingList.user)).order_by(desc(ShoppingList.created_at)).offset(skip).limit(limit)
    )
    lists = result.scalars().all()
    return [{
        "id": l.id,
        "name": l.name,
        "total_estimated_price": l.total_estimated_price,
        "total_actual_price": l.total_actual_price,
        "is_completed": l.is_completed,
        "created_at": l.created_at.isoformat() if l.created_at else None,
        "item_count": len(l.items) if l.items else 0,
        "user_id": l.user_id,
        "user_name": f"{l.user.name} {l.user.surname}" if l.user else "Noma'lum"
    } for l in lists]

@router.get("/user-data/finance")
async def get_all_finance_records(
    skip: int = 0,
    limit: int = Query(50, le=100),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(FinanceRecord).options(joinedload(FinanceRecord.user)).order_by(desc(FinanceRecord.date)).offset(skip).limit(limit)
    )
    records = result.scalars().all()
    return [{
        "id": r.id,
        "type": r.type.value if hasattr(r.type, 'value') else str(r.type),
        "amount": r.amount,
        "category": r.category,
        "note": r.note,
        "date": r.date.isoformat() if r.date else None,
        "user_id": r.user_id,
        "user_name": f"{r.user.name} {r.user.surname}" if r.user else "Noma'lum"
    } for r in records]

@router.get("/user-data/plans")
async def get_all_plans(
    skip: int = 0,
    limit: int = Query(50, le=100),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(Plan).options(joinedload(Plan.user)).order_by(desc(Plan.date)).offset(skip).limit(limit)
    )
    plans = result.scalars().all()
    return [{
        "id": p.id,
        "title": p.title,
        "description": p.description,
        "date": p.date.isoformat() if p.date else None,
        "time": p.time.isoformat() if p.time else None,
        "is_completed": p.is_completed,
        "user_id": p.user_id,
        "user_name": f"{p.user.name} {p.user.surname}" if p.user else "Noma'lum"
    } for p in plans]
