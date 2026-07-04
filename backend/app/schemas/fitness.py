from datetime import datetime
from typing import List, Literal, Optional
from pydantic import BaseModel, Field


class ExerciseOut(BaseModel):
    id: int
    external_id: str
    name_en: str
    name_uz: str
    category: Optional[str] = None
    body_part: Optional[str] = None
    body_part_uz: Optional[str] = None
    equipment: Optional[str] = None
    equipment_uz: Optional[str] = None
    target: Optional[str] = None
    target_uz: Optional[str] = None
    muscle_group: Optional[str] = None
    secondary_muscles: List[str] = []
    gif_url: Optional[str] = None
    instructions_uz: List[str] = []
    instructions_en: List[str] = []

    class Config:
        from_attributes = True


class ExercisePage(BaseModel):
    items: List[ExerciseOut]
    total: int
    page: int
    page_size: int


class MetaItem(BaseModel):
    value: str
    label_uz: str


class ExerciseMetaOut(BaseModel):
    body_parts: List[MetaItem]
    equipment: List[MetaItem]
    targets: List[MetaItem]


class PlanGenerateRequest(BaseModel):
    goal: Literal["weight_loss", "muscle_gain", "general_fit"]
    level: Literal["beginner", "intermediate", "advanced"]
    days_per_week: int = Field(ge=2, le=6)
    equipment_mode: Literal["home", "gym"]


class WorkoutPlanOut(BaseModel):
    id: int
    user_id: int
    name: str
    goal: str
    level: str
    days_per_week: int
    equipment_mode: str
    days: List[dict]
    is_active: bool
    reminder_time: Optional[str] = None
    reminder_weekdays: Optional[List[int]] = None
    created_at: datetime

    class Config:
        from_attributes = True


class WorkoutPlanUpdate(BaseModel):
    name: Optional[str] = None
    reminder_time: Optional[str] = None
    reminder_weekdays: Optional[List[int]] = None
    is_active: Optional[bool] = None


class WorkoutLogCreate(BaseModel):
    plan_id: Optional[int] = None
    day_index: int
    date: datetime
    completed_exercises: Optional[List[int]] = None
    note: Optional[str] = None


class WorkoutLogOut(WorkoutLogCreate):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True
