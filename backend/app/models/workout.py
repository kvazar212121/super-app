from datetime import datetime
from sqlalchemy import DateTime, Integer, String, Boolean, ForeignKey, func, Text, Float
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class WorkoutPlan(Base):
    __tablename__ = "workout_plans"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    goal: Mapped[str] = mapped_column(String(30), nullable=False)  # weight_loss | muscle_gain | general_fit
    level: Mapped[str] = mapped_column(String(20), nullable=False)  # beginner | intermediate | advanced
    days_per_week: Mapped[int] = mapped_column(Integer, nullable=False)
    equipment_mode: Mapped[str] = mapped_column(String(20), nullable=False)  # home | gym
    days: Mapped[list | dict] = mapped_column(JSONB, default=list)
    # days format: [{"day_index": 1, "title": "Ko'krak va triseps",
    #   "exercises": [{"exercise_id": 12, "name_uz": "...", "gif_url": "...", "sets": 3, "reps": "10-12", "rest_sec": 60}]}]
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    reminder_time: Mapped[str | None] = mapped_column(String(5), nullable=True)  # "19:00"
    reminder_weekdays: Mapped[list | dict | None] = mapped_column(JSONB, nullable=True)  # [1, 3, 5] (ISO weekday)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="workout_plans")


class WorkoutLog(Base):
    __tablename__ = "workout_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    plan_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("workout_plans.id", ondelete="SET NULL"), nullable=True)
    day_index: Mapped[int] = mapped_column(Integer, nullable=False)
    date: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False, index=True)
    completed_exercises: Mapped[list | dict | None] = mapped_column(JSONB, nullable=True)
    # Energiya balansi integratsiyasi: server-side hisoblanadi (davomiylik va yoqilgan kaloriya)
    duration_min: Mapped[int | None] = mapped_column(Integer, nullable=True)
    calories_burned: Mapped[float] = mapped_column(Float, default=0.0)
    note: Mapped[str | None] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="workout_logs")
