from datetime import datetime
from sqlalchemy import DateTime, Integer, String, Boolean, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class CallHistory(Base):
    __tablename__ = "call_history"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    caller_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), index=True)
    receiver_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), index=True)
    provider_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("providers.id"), nullable=True, index=True)
    duration_seconds: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[str] = mapped_column(String(50), default="missed") # missed, completed, rejected
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    caller = relationship("User", foreign_keys=[caller_id], lazy="selectin")
    receiver = relationship("User", foreign_keys=[receiver_id], lazy="selectin")
    provider = relationship("Provider", foreign_keys=[provider_id], lazy="selectin")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "caller_id": self.caller_id,
            "receiver_id": self.receiver_id,
            "provider_id": self.provider_id,
            "duration_seconds": self.duration_seconds,
            "status": self.status,
            "created_at": self.created_at,
            "caller": {"name": self.caller.name, "surname": self.caller.surname, "phone": self.caller.phone} if self.caller else None,
            "receiver": {"name": self.receiver.name, "surname": self.receiver.surname, "phone": self.receiver.phone} if self.receiver else None,
        }
