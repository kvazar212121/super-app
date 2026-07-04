from datetime import datetime
from sqlalchemy import DateTime, Integer, String, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Exercise(Base):
    """Global mashqlar katalogi (exercises-dataset'dan seed qilinadi)."""

    __tablename__ = "exercises"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    external_id: Mapped[str] = mapped_column(String(20), unique=True, index=True)
    media_id: Mapped[str | None] = mapped_column(String(64), nullable=True)
    gif_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    name_en: Mapped[str] = mapped_column(String(255), nullable=False)
    name_uz: Mapped[str] = mapped_column(String(255), nullable=False, index=True)
    category: Mapped[str | None] = mapped_column(String(50), nullable=True, index=True)
    body_part: Mapped[str | None] = mapped_column(String(50), nullable=True, index=True)
    equipment: Mapped[str | None] = mapped_column(String(50), nullable=True, index=True)
    target: Mapped[str | None] = mapped_column(String(100), nullable=True, index=True)
    muscle_group: Mapped[str | None] = mapped_column(String(100), nullable=True)
    secondary_muscles: Mapped[list | dict] = mapped_column(JSONB, default=list)
    instructions_en: Mapped[list | dict] = mapped_column(JSONB, default=list)
    instructions_uz: Mapped[list | dict] = mapped_column(JSONB, default=list)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
