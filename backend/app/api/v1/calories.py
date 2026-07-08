"""Kaloriya hisoblagich mini-ilovasi API: rasm tahlili, ovqat jurnali, kunlik xulosalar."""
from datetime import date, datetime

from fastapi import APIRouter, Depends, HTTPException, Query, UploadFile, File
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from starlette.requests import Request

from app.core.limiter import limiter
from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.nutrition import NutritionProfile, MealLog
from app.schemas.calories import (
    FoodAnalyzeOut,
    MealLogCreate,
    MealLogOut,
    DailySummaryOut,
    NutritionProfileIn,
    NutritionProfileOut,
)
from app.services.upload_service import UploadService
from app.services.vision_service import analyze_food

router = APIRouter(prefix="/calories", tags=["calories"])

ACTIVITY_FACTORS = {
    "sedentary": 1.2,
    "light": 1.375,
    "moderate": 1.55,
    "active": 1.725,
    "very_active": 1.9,
}


def compute_daily_goal(profile: NutritionProfile) -> float:
    """Mifflin-St Jeor bo'yicha kunlik kaloriya maqsadi."""
    if profile.manual_calorie_goal:
        return profile.manual_calorie_goal
    bmr = (
        10 * profile.weight_kg
        + 6.25 * profile.height_cm
        - 5 * profile.age
        + (5 if profile.sex == "male" else -161)
    )
    tdee = bmr * ACTIVITY_FACTORS.get(profile.activity_level, 1.375)
    if profile.goal == "lose":
        tdee -= 500
    elif profile.goal == "gain":
        tdee += 300
    return float(round(max(tdee, 1200)))


def _profile_out(profile: NutritionProfile) -> dict:
    return {
        "id": profile.id,
        "user_id": profile.user_id,
        "sex": profile.sex,
        "age": profile.age,
        "height_cm": profile.height_cm,
        "weight_kg": profile.weight_kg,
        "activity_level": profile.activity_level,
        "goal": profile.goal,
        "manual_calorie_goal": profile.manual_calorie_goal,
        "daily_calorie_goal": compute_daily_goal(profile),
    }


def _parse_date(date_str: str | None) -> date:
    if not date_str:
        return datetime.now().date()
    try:
        return date.fromisoformat(date_str)
    except ValueError:
        raise HTTPException(status_code=400, detail="Sana formati noto'g'ri. YYYY-MM-DD ishlating.")


@router.post("/analyze", response_model=FoodAnalyzeOut)
@limiter.limit("10/minute")
async def analyze_food_photo(
    request: Request,
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
):
    # Rasm diskka YOZILMAYDI — xotirada siqilib to'g'ridan-to'g'ri AI'ga jo'natiladi
    UploadService._validate_file(file)
    contents = await file.read()
    compressed = UploadService._compress_to_jpeg(contents, 1024, 70)

    result = await analyze_food(compressed, "image/jpeg")
    result["photo_url"] = None
    return result


@router.post("/log", response_model=MealLogOut, status_code=201)
async def create_meal_log(
    data: MealLogCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    payload = data.model_dump()
    if payload.get("logged_at") is None:
        payload.pop("logged_at", None)

    new_log = MealLog(**payload, user_id=current_user.id)
    db.add(new_log)
    await db.commit()
    await db.refresh(new_log)
    return new_log


@router.get("/log", response_model=list[MealLogOut])
async def get_meal_logs(
    date_str: str | None = Query(None, alias="date"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    target_date = _parse_date(date_str)
    result = await db.execute(
        select(MealLog)
        .where(MealLog.user_id == current_user.id, func.date(MealLog.logged_at) == target_date)
        .order_by(MealLog.logged_at.asc())
    )
    return result.scalars().all()


@router.delete("/log/{log_id}", status_code=204)
async def delete_meal_log(
    log_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(MealLog).where(MealLog.id == log_id, MealLog.user_id == current_user.id)
    )
    log = result.scalar_one_or_none()
    if not log:
        raise HTTPException(status_code=404, detail="Yozuv topilmadi")
    await db.delete(log)
    await db.commit()


@router.get("/summary", response_model=DailySummaryOut)
async def get_daily_summary(
    date_str: str | None = Query(None, alias="date"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    target_date = _parse_date(date_str)
    result = await db.execute(
        select(
            func.coalesce(func.sum(MealLog.calories), 0.0),
            func.coalesce(func.sum(MealLog.protein_g), 0.0),
            func.coalesce(func.sum(MealLog.fat_g), 0.0),
            func.coalesce(func.sum(MealLog.carbs_g), 0.0),
            func.count(MealLog.id),
        ).where(MealLog.user_id == current_user.id, func.date(MealLog.logged_at) == target_date)
    )
    total_calories, protein_g, fat_g, carbs_g, meals_count = result.one()

    profile_result = await db.execute(
        select(NutritionProfile).where(NutritionProfile.user_id == current_user.id)
    )
    profile = profile_result.scalar_one_or_none()
    goal = compute_daily_goal(profile) if profile else None

    return DailySummaryOut(
        date=target_date.isoformat(),
        total_calories=float(total_calories),
        protein_g=float(protein_g),
        fat_g=float(fat_g),
        carbs_g=float(carbs_g),
        goal_calories=goal,
        remaining=(goal - float(total_calories)) if goal is not None else None,
        meals_count=int(meals_count),
    )


@router.get("/profile", response_model=NutritionProfileOut)
async def get_nutrition_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(NutritionProfile).where(NutritionProfile.user_id == current_user.id)
    )
    profile = result.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=404, detail="Profil hali to'ldirilmagan")
    return _profile_out(profile)


@router.put("/profile", response_model=NutritionProfileOut)
async def upsert_nutrition_profile(
    data: NutritionProfileIn,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(NutritionProfile).where(NutritionProfile.user_id == current_user.id)
    )
    profile = result.scalar_one_or_none()

    if profile:
        for key, value in data.model_dump().items():
            setattr(profile, key, value)
    else:
        profile = NutritionProfile(**data.model_dump(), user_id=current_user.id)
        db.add(profile)

    await db.commit()
    await db.refresh(profile)
    return _profile_out(profile)
