from datetime import datetime
from typing import Literal, Optional
from pydantic import BaseModel, Field


class FoodAnalyzeOut(BaseModel):
    is_food: bool
    dish_name_uz: str
    portion_grams: Optional[float] = None
    calories: float
    protein_g: float
    fat_g: float
    carbs_g: float
    confidence: Optional[float] = None
    photo_url: Optional[str] = None


class MealLogCreate(BaseModel):
    meal_type: Literal["breakfast", "lunch", "dinner", "snack"] = "snack"
    dish_name: str
    portion_grams: Optional[float] = None
    calories: float = 0.0
    protein_g: float = 0.0
    fat_g: float = 0.0
    carbs_g: float = 0.0
    photo_url: Optional[str] = None
    ai_confidence: Optional[float] = None
    logged_at: Optional[datetime] = None


class MealLogOut(BaseModel):
    id: int
    user_id: int
    meal_type: str
    dish_name: str
    portion_grams: Optional[float] = None
    calories: float
    protein_g: float
    fat_g: float
    carbs_g: float
    photo_url: Optional[str] = None
    ai_confidence: Optional[float] = None
    logged_at: datetime
    created_at: datetime

    class Config:
        from_attributes = True


class DailySummaryOut(BaseModel):
    date: str
    total_calories: float
    protein_g: float
    fat_g: float
    carbs_g: float
    goal_calories: Optional[float] = None
    remaining: Optional[float] = None
    meals_count: int


class NutritionProfileIn(BaseModel):
    sex: Literal["male", "female"]
    age: int = Field(ge=10, le=100)
    height_cm: float = Field(gt=50, lt=260)
    weight_kg: float = Field(gt=20, lt=400)
    activity_level: Literal["sedentary", "light", "moderate", "active", "very_active"] = "light"
    goal: Literal["lose", "maintain", "gain"] = "maintain"
    manual_calorie_goal: Optional[float] = None


class NutritionProfileOut(NutritionProfileIn):
    id: int
    user_id: int
    daily_calorie_goal: float

    class Config:
        from_attributes = True
