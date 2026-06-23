from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from collections import Counter
from datetime import datetime

from app.db.session import get_db
from app.models.user import User
from app.models.todo import Todo
from app.models.shopping_list import ShoppingList
from app.models.plan import Plan
from app.api.v1.admin.dependencies import require_admin

router = APIRouter()

@router.get("/analytics/user-insights")
async def get_user_insights(
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db)
):
    # 1. Shopping Analytics
    shopping_result = await db.execute(select(ShoppingList))
    shopping_lists = shopping_result.scalars().all()
    
    total_shopping_lists = len(shopping_lists)
    total_estimated_price = sum(sl.total_estimated_price for sl in shopping_lists if sl.total_estimated_price)
    avg_shopping_price = total_estimated_price / total_shopping_lists if total_shopping_lists > 0 else 0
    
    item_counter = Counter()
    for sl in shopping_lists:
        if isinstance(sl.items, list):
            for item in sl.items:
                name = item.get("name", "").strip().lower()
                if name:
                    item_counter[name] += 1
    
    top_items = [{"name": name.capitalize(), "count": count} for name, count in item_counter.most_common(10)]

    # 2. Plans and Todos Analytics (By Hour)
    plans_result = await db.execute(select(Plan))
    plans = plans_result.scalars().all()
    
    todos_result = await db.execute(select(Todo))
    todos = todos_result.scalars().all()
    
    total_plans = len(plans)
    completed_plans = sum(1 for p in plans if p.is_completed)
    
    total_todos = len(todos)
    completed_todos = sum(1 for t in todos if t.is_completed)
    
    hour_counter = {i: 0 for i in range(24)}
    
    for p in plans:
        if p.due_date:
            hour_counter[p.due_date.hour] += 1
            
    for t in todos:
        if t.due_date:
            hour_counter[t.due_date.hour] += 1
            
    popular_hours = [{"hour": f"{h:02d}:00", "count": count} for h, count in hour_counter.items()]

    return {
        "shopping": {
            "total_lists": total_shopping_lists,
            "avg_price": avg_shopping_price,
            "top_items": top_items
        },
        "planning": {
            "total_plans": total_plans,
            "completed_plans": completed_plans,
            "total_todos": total_todos,
            "completed_todos": completed_todos,
            "popular_hours": popular_hours
        }
    }
