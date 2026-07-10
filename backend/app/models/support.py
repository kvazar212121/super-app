"""Qo'llab-quvvatlash chati (foydalanuvchi ↔ operator/admin).

Har foydalanuvchida bitta ochiq ticket bo'ladi. Foydalanuvchi va admin shu ticket
ichida yozishadi. `unread_admin` — admin o'qimagan xabarlar soni (inbox badge uchun),
`unread_user` — foydalanuvchi o'qimaganlar soni.
"""
from datetime import datetime

from sqlalchemy import DateTime, Integer, String, Text, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class SupportTicket(Base):
    __tablename__ = "support_tickets"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    status: Mapped[str] = mapped_column(String(20), default="open", index=True)  # open | closed
    subject: Mapped[str | None] = mapped_column(String(200), nullable=True)
    last_message: Mapped[str | None] = mapped_column(String(300), nullable=True)
    unread_admin: Mapped[int] = mapped_column(Integer, default=0)
    unread_user: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), index=True
    )
    last_message_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), index=True
    )

    messages: Mapped[list["SupportMessage"]] = relationship(
        back_populates="ticket", cascade="all, delete-orphan"
    )


class SupportMessage(Base):
    __tablename__ = "support_messages"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    ticket_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("support_tickets.id", ondelete="CASCADE"), index=True
    )
    sender: Mapped[str] = mapped_column(String(10), default="user")  # user | admin
    admin_name: Mapped[str | None] = mapped_column(String(100), nullable=True)
    text: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), index=True
    )

    ticket: Mapped["SupportTicket"] = relationship(back_populates="messages")
