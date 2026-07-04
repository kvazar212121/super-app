"""
Rule-based haftalik mashg'ulot rejasi generatori.

Maqsad, daraja, haftadagi kunlar soni va uskuna rejimiga qarab
exercises jadvalidan mashqlar tanlab, WorkoutPlan.days JSONB
formatidagi haftalik reja qaytaradi.
"""
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.exercise import Exercise
from app.schemas.fitness import PlanGenerateRequest

# Uy sharoitida mavjud deb hisoblanadigan uskunalar
HOME_EQUIPMENT = ["body weight", "band", "dumbbell"]

# Kun shablonlari: (sarlavha_uz, body_part slotlari)
FULL_BODY = ("Butun tana", ["chest", "back", "upper legs", "shoulders", "waist"])
PUSH = ("Ko'krak, yelka va triseps", ["chest", "shoulders", "upper arms"])
PULL = ("Orqa va biseps", ["back", "upper arms", "waist"])
LEGS = ("Oyoqlar va press", ["upper legs", "lower legs", "waist"])
UPPER = ("Yuqori tana", ["chest", "back", "shoulders", "upper arms"])
LOWER = ("Pastki tana va press", ["upper legs", "lower legs", "waist"])

PLAN_NAMES = {
    "weight_loss": "Vazn yo'qotish rejasi",
    "muscle_gain": "Mushak o'stirish rejasi",
    "general_fit": "Umumiy fitnes rejasi",
}

# Maqsadga qarab sets/reps/dam
GOAL_PARAMS = {
    "weight_loss": {"sets": 3, "reps": "15", "rest_sec": 45},
    "muscle_gain": {"sets": 4, "reps": "8-12", "rest_sec": 90},
    "general_fit": {"sets": 3, "reps": "12", "rest_sec": 60},
}

# Darajaga qarab kuniga mashqlar soni
LEVEL_EXERCISE_COUNT = {"beginner": 5, "intermediate": 6, "advanced": 7}


def _split_for(days_per_week: int, level: str) -> list[tuple[str, list[str]]]:
    if days_per_week == 2:
        return [FULL_BODY, FULL_BODY]
    if days_per_week == 3:
        if level == "beginner":
            return [FULL_BODY, FULL_BODY, FULL_BODY]
        return [PUSH, PULL, LEGS]
    if days_per_week == 4:
        return [UPPER, LOWER, UPPER, LOWER]
    if days_per_week == 5:
        return [PUSH, PULL, LEGS, UPPER, LOWER]
    return [PUSH, PULL, LEGS, PUSH, PULL, LEGS]


async def _pick_exercises(
    db: AsyncSession, body_part: str, count: int, equipment_mode: str, exclude_ids: set[int]
) -> list[Exercise]:
    query = select(Exercise).where(Exercise.body_part == body_part)
    if equipment_mode == "home":
        query = query.where(Exercise.equipment.in_(HOME_EQUIPMENT))
    if exclude_ids:
        query = query.where(Exercise.id.notin_(exclude_ids))
    result = await db.execute(query.order_by(func.random()).limit(count))
    return list(result.scalars().all())


async def generate_plan(db: AsyncSession, req: PlanGenerateRequest) -> dict:
    """Haftalik reja tuzadi: {"name": ..., "days": [...]}."""
    split = _split_for(req.days_per_week, req.level)
    per_day = LEVEL_EXERCISE_COUNT[req.level]
    params = GOAL_PARAMS[req.goal]

    days = []
    for day_index, (title, body_parts) in enumerate(split, start=1):
        # Slotlar bo'yicha mashqlar sonini teng taqsimlash
        base = per_day // len(body_parts)
        extra = per_day % len(body_parts)

        picked: list[Exercise] = []
        used_ids: set[int] = set()
        for slot_i, bp in enumerate(body_parts):
            need = base + (1 if slot_i < extra else 0)
            if need == 0:
                continue
            found = await _pick_exercises(db, bp, need, req.equipment_mode, used_ids)
            picked.extend(found)
            used_ids.update(e.id for e in found)

        # Ba'zi body_part'larda uy rejimida mashq kam bo'lsa, umumiy zaxiradan to'ldirish
        if len(picked) < per_day:
            filler = await _pick_exercises(
                db, body_parts[0], per_day - len(picked), "gym", used_ids
            )
            picked.extend(filler)

        days.append(
            {
                "day_index": day_index,
                "title": title,
                "exercises": [
                    {
                        "exercise_id": e.id,
                        "name_uz": e.name_uz,
                        "gif_url": e.gif_url,
                        "body_part": e.body_part,
                        "sets": params["sets"],
                        "reps": params["reps"],
                        "rest_sec": params["rest_sec"],
                    }
                    for e in picked
                ],
            }
        )

    return {"name": PLAN_NAMES[req.goal], "days": days}
