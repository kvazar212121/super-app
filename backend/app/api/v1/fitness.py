"""Fitnes trener mini-ilovasi API: mashqlar katalogi, reja generatori, mashg'ulot loglari."""
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select, func, or_, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.exercise import Exercise
from app.models.workout import WorkoutPlan, WorkoutLog
from app.schemas.fitness import (
    ExerciseOut,
    ExercisePage,
    ExerciseMetaOut,
    MetaItem,
    PlanGenerateRequest,
    WorkoutPlanOut,
    WorkoutPlanUpdate,
    WorkoutLogCreate,
    WorkoutLogOut,
)
from app.services.workout_generator import generate_plan
from app.data.exercises_vocab_uz import BODY_PART_UZ, EQUIPMENT_UZ, TARGET_UZ

router = APIRouter(prefix="/fitness", tags=["fitness"])


def _exercise_out(ex: Exercise) -> dict:
    return {
        "id": ex.id,
        "external_id": ex.external_id,
        "name_en": ex.name_en,
        "name_uz": ex.name_uz,
        "category": ex.category,
        "body_part": ex.body_part,
        "body_part_uz": BODY_PART_UZ.get(ex.body_part or "", ex.body_part),
        "equipment": ex.equipment,
        "equipment_uz": EQUIPMENT_UZ.get(ex.equipment or "", ex.equipment),
        "target": ex.target,
        "target_uz": TARGET_UZ.get(ex.target or "", ex.target),
        "muscle_group": ex.muscle_group,
        "secondary_muscles": ex.secondary_muscles or [],
        "gif_url": ex.gif_url,
        "instructions_uz": ex.instructions_uz or [],
        "instructions_en": ex.instructions_en or [],
    }


@router.get("/exercises", response_model=ExercisePage)
async def get_exercises(
    body_part: str | None = Query(None),
    equipment: str | None = Query(None),
    target: str | None = Query(None),
    search: str | None = Query(None),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    query = select(Exercise)
    if body_part:
        query = query.where(Exercise.body_part == body_part)
    if equipment:
        query = query.where(Exercise.equipment == equipment)
    if target:
        query = query.where(Exercise.target == target)
    if search:
        pattern = f"%{search.strip()}%"
        query = query.where(or_(Exercise.name_uz.ilike(pattern), Exercise.name_en.ilike(pattern)))

    total = (await db.execute(select(func.count()).select_from(query.subquery()))).scalar() or 0
    result = await db.execute(
        query.order_by(Exercise.id.asc()).offset((page - 1) * page_size).limit(page_size)
    )
    items = [_exercise_out(e) for e in result.scalars().all()]
    return {"items": items, "total": total, "page": page, "page_size": page_size}


@router.get("/exercises/meta", response_model=ExerciseMetaOut)
async def get_exercises_meta(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    async def distinct_of(column):
        result = await db.execute(select(column).distinct().where(column.isnot(None)))
        return sorted(v for v in result.scalars().all() if v)

    body_parts = await distinct_of(Exercise.body_part)
    equipment = await distinct_of(Exercise.equipment)
    targets = await distinct_of(Exercise.target)

    return ExerciseMetaOut(
        body_parts=[MetaItem(value=v, label_uz=BODY_PART_UZ.get(v, v)) for v in body_parts],
        equipment=[MetaItem(value=v, label_uz=EQUIPMENT_UZ.get(v, v)) for v in equipment],
        targets=[MetaItem(value=v, label_uz=TARGET_UZ.get(v, v)) for v in targets],
    )


@router.get("/exercises/{exercise_id}", response_model=ExerciseOut)
async def get_exercise(
    exercise_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Exercise).where(Exercise.id == exercise_id))
    exercise = result.scalar_one_or_none()
    if not exercise:
        raise HTTPException(status_code=404, detail="Mashq topilmadi")
    return _exercise_out(exercise)


@router.post("/plans/generate", response_model=WorkoutPlanOut, status_code=201)
async def generate_workout_plan(
    data: PlanGenerateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    generated = await generate_plan(db, data)
    if not any(day["exercises"] for day in generated["days"]):
        raise HTTPException(
            status_code=503,
            detail="Mashqlar bazasi hali yuklanmagan. Administratorga murojaat qiling.",
        )

    # Oldingi aktiv rejalarni o'chirish
    await db.execute(
        update(WorkoutPlan)
        .where(WorkoutPlan.user_id == current_user.id, WorkoutPlan.is_active.is_(True))
        .values(is_active=False)
    )

    new_plan = WorkoutPlan(
        user_id=current_user.id,
        name=generated["name"],
        goal=data.goal,
        level=data.level,
        days_per_week=data.days_per_week,
        equipment_mode=data.equipment_mode,
        days=generated["days"],
        is_active=True,
    )
    db.add(new_plan)
    await db.commit()
    await db.refresh(new_plan)
    return new_plan


@router.get("/plans/active", response_model=WorkoutPlanOut)
async def get_active_plan(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(WorkoutPlan)
        .where(WorkoutPlan.user_id == current_user.id, WorkoutPlan.is_active.is_(True))
        .order_by(WorkoutPlan.created_at.desc())
        .limit(1)
    )
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="Aktiv reja topilmadi")
    return plan


@router.patch("/plans/{plan_id}", response_model=WorkoutPlanOut)
async def update_workout_plan(
    plan_id: int,
    data: WorkoutPlanUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(WorkoutPlan).where(WorkoutPlan.id == plan_id, WorkoutPlan.user_id == current_user.id)
    )
    plan = result.scalar_one_or_none()
    if not plan:
        raise HTTPException(status_code=404, detail="Reja topilmadi")

    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(plan, key, value)

    await db.commit()
    await db.refresh(plan)
    return plan


@router.post("/logs", response_model=WorkoutLogOut, status_code=201)
async def create_workout_log(
    data: WorkoutLogCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    new_log = WorkoutLog(**data.model_dump(), user_id=current_user.id)
    db.add(new_log)
    await db.commit()
    await db.refresh(new_log)
    return new_log


@router.get("/logs", response_model=list[WorkoutLogOut])
async def get_workout_logs(
    from_date: str | None = Query(None, alias="from"),
    to_date: str | None = Query(None, alias="to"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    query = select(WorkoutLog).where(WorkoutLog.user_id == current_user.id)
    try:
        if from_date:
            query = query.where(WorkoutLog.date >= datetime.fromisoformat(from_date))
        if to_date:
            query = query.where(WorkoutLog.date <= datetime.fromisoformat(to_date))
    except ValueError:
        raise HTTPException(status_code=400, detail="Sana formati noto'g'ri. ISO 8601 ishlating.")

    result = await db.execute(query.order_by(WorkoutLog.date.desc()).limit(200))
    return result.scalars().all()
