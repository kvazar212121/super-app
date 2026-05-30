"""Platform sozlamalari — bazada saqlanadi, restart'dan keyin ham saqlanib qoladi."""
from datetime import datetime, timezone

from sqlalchemy import Column, Integer, String, Text, DateTime
from app.db.base import Base


class PlatformSetting(Base):
    __tablename__ = "platform_settings"

    id = Column(Integer, primary_key=True, index=True)
    key = Column(String(100), unique=True, nullable=False, index=True)
    value = Column(Text, nullable=False, default="")
    description = Column(String(300), nullable=True)
    updated_at = Column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    # Default settings
    DEFAULTS = {
        "commission_rate": {"value": "15", "description": "Komissiya foizi (%)"},
        "cashback_rate": {"value": "2", "description": "Cashback foizi (%)"},
        "currency": {"value": "UZS", "description": "Asosiy valyuta"},
        "min_order_amount": {"value": "10000", "description": "Minimal buyurtma summasi"},
        "max_order_amount": {"value": "50000000", "description": "Maksimal buyurtma summasi"},
        "support_phone": {"value": "+998712001234", "description": "Qo'llab-quvvatlash telefoni"},
        "support_email": {"value": "support@superapp.uz", "description": "Qo'llab-quvvatlash email"},
        "app_version": {"value": "1.0.0", "description": "Ilova versiyasi"},
        "maintenance_mode": {"value": "false", "description": "Texnik xizmat rejimi"},
    }
