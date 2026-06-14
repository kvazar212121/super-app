from datetime import date
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.plan import Plan
from app.schemas.plan import PlanOut, PlanCreate, PlanUpdate

router = APIRouter(prefix="/plans", tags=["plans"])


@router.get("/", response_model=list[PlanOut])
async def get_plans(
    date_str: str | None = Query(None, alias="date"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = select(Plan).where(Plan.user_id == current_user.id)
    if date_str:
        try:
            target_date = date.fromisoformat(date_str)
            query = query.where(func.date(Plan.due_date) == target_date)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid date format. Use YYYY-MM-DD.")

    result = await db.execute(query.order_by(Plan.due_date.asc()))
    return result.scalars().all()


@router.post("/", response_model=PlanOut, status_code=201)
async def create_plan(
    data: PlanCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    new_plan = Plan(**data.model_dump(), user_id=current_user.id)
    db.add(new_plan)
    await db.commit()
    await db.refresh(new_plan)
    return new_plan


@router.patch("/{plan_id}", response_model=PlanOut)
async def update_plan(
    plan_id: int,
    data: PlanUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Plan).where(Plan.id == plan_id, Plan.user_id == current_user.id))
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")

    update_data = data.model_dump(exclude_unset=True)
    if "due_date" in update_data:
        plan.is_notified = False
    for key, value in update_data.items():
        setattr(plan, key, value)

    await db.commit()
    await db.refresh(plan)
    return plan


@router.delete("/{plan_id}", status_code=204)
async def delete_plan(
    plan_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Plan).where(Plan.id == plan_id, Plan.user_id == current_user.id))
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="Plan not found")

    await db.delete(plan)
    await db.commit()
