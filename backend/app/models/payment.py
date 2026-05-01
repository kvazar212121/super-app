from sqlalchemy import Integer, String, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base


class PaymentCard(Base):
    __tablename__ = "payment_cards"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(
        Integer, ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    masked_number: Mapped[str] = mapped_column(String(19))
    bank: Mapped[str] = mapped_column(String(100))
    card_type: Mapped[str] = mapped_column(String(20), default="uzcard")
    exp_month: Mapped[int] = mapped_column(Integer)
    exp_year: Mapped[int] = mapped_column(Integer)
    is_default: Mapped[bool] = mapped_column(default=False)

    user = relationship("User", back_populates="payment_cards")

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "user_id": self.user_id,
            "masked_number": self.masked_number,
            "bank": self.bank,
            "card_type": self.card_type,
            "exp_month": self.exp_month,
            "exp_year": self.exp_year,
            "is_default": self.is_default,
        }