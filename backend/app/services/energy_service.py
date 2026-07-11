"""Energiya balansi hisob-kitoblari — fitnes ↔ kaloriya integratsiyasi.

Yagona joy: mashg'ulotdan va yurishdan yoqilgan kaloriyani foydalanuvchi vazniga
qarab hisoblaydi. Barcha baholar TAXMINIY (MET-ga asoslangan).
"""
from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.user import User
from app.models.nutrition import NutritionProfile

DEFAULT_WEIGHT_KG = 70.0

# Maqsadga qarab MET (metabolik ekvivalent) — kuch mashqlari
GOAL_MET = {
    "weight_loss": 6.0,   # doiraviy / yuqori temp
    "muscle_gain": 5.0,
    "general_fit": 5.0,
}
DEFAULT_MET = 5.0

# Bir yondashuv (set) taxminan shuncha soniya ish
SECONDS_PER_SET = 40


async def get_user_weight(db: AsyncSession, user_id: int) -> float:
    """Foydalanuvchi vazni (NutritionProfile'dan). Profil yo'q bo'lsa 70 kg."""
    profile = (
        await db.execute(
            select(NutritionProfile).where(NutritionProfile.user_id == user_id)
        )
    ).scalar_one_or_none()
    if profile and profile.weight_kg:
        return float(profile.weight_kg)
    return DEFAULT_WEIGHT_KG


def _day_exercises(plan_days: list | None, day_index: int) -> list[dict]:
    if not isinstance(plan_days, list):
        return []
    for d in plan_days:
        if isinstance(d, dict) and d.get("day_index") == day_index:
            return d.get("exercises") or []
    return []


def estimate_workout(
    plan_days: list | None,
    day_index: int,
    completed_ids: list | None,
    weight_kg: float,
    goal: str | None,
) -> tuple[int, float]:
    """Mashg'ulot davomiyligi (daqiqa) va yoqilgan kaloriyani baholaydi.

    Davomiylik = har bajarilgan mashq uchun `sets × (40s ish + rest_sec)` yig'indisi.
    calories = MET × weight_kg × (daqiqa/60).
    """
    exercises = _day_exercises(plan_days, day_index)
    done = set(completed_ids or [])
    total_seconds = 0
    for ex in exercises:
        if not isinstance(ex, dict):
            continue
        # completed_ids berilgan bo'lsa faqat belgilanganlarni, aks holda hammasini
        if done and ex.get("exercise_id") not in done:
            continue
        sets = ex.get("sets") or 3
        rest = ex.get("rest_sec") or 60
        try:
            total_seconds += int(sets) * (SECONDS_PER_SET + int(rest))
        except (TypeError, ValueError):
            total_seconds += 3 * (SECONDS_PER_SET + 60)

    duration_min = max(1, round(total_seconds / 60)) if total_seconds else 0
    if duration_min == 0:
        return 0, 0.0
    met = GOAL_MET.get((goal or "").lower(), DEFAULT_MET)
    calories = met * weight_kg * (duration_min / 60.0)
    return duration_min, round(calories, 1)


def steps_to_calories(steps: int, weight_kg: float) -> float:
    """Qadamlardan yoqilgan kaloriya. ~70 kg da 10 000 qadam ≈ 350 kkal."""
    if steps <= 0:
        return 0.0
    return round(steps * weight_kg * 0.0005, 1)
