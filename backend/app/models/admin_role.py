"""Admin rollari va audit jurnali (RBAC).

AdminRole — nomlangan rol + ruxsatlar (JSON: {bo'lim: [view/edit]}).
AuditLog — kim, qachon, qaysi bo'limда qanday o'zgarish qildi.
"""
from datetime import datetime

from sqlalchemy import DateTime, Integer, String, ForeignKey, JSON, func
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class AdminRole(Base):
    __tablename__ = "admin_roles"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(100), unique=True, index=True)
    # {"orders": ["view", "edit"], "finance": ["view"], ...}
    permissions: Mapped[dict] = mapped_column(JSON, default=dict)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    admin_user_id: Mapped[int | None] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True, index=True
    )
    admin_name: Mapped[str | None] = mapped_column(String(150), nullable=True)
    section: Mapped[str] = mapped_column(String(50), index=True)
    action: Mapped[str] = mapped_column(String(20))   # HTTP metodi: POST/PUT/PATCH/DELETE
    path: Mapped[str] = mapped_column(String(300))
    detail: Mapped[str | None] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), index=True)
