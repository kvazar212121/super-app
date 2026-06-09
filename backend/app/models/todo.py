from datetime import datetime
from sqlalchemy import DateTime, Integer, String, Boolean, ForeignKey, func, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base

class Todo(Base):
    __tablename__ = "todos"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id", ondelete="CASCADE"), index=True)
    title: Mapped[str] = mapped_column(String(255))
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    is_completed: Mapped[bool] = mapped_column(Boolean, default=False)
    due_date: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    
    user = relationship("User", back_populates="todos")
