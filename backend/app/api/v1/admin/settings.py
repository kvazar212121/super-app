from typing import Optional
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.user import User
from app.api.v1.admin.dependencies import require_admin
from app.services import settings_service

router = APIRouter()


class SettingsOut(BaseModel):
    # default_lead_fee — provayder balansidan (user.balance) mijoz topilganda
    # yechiladigan qat'iy komissiya (so'm). Provayder yoki kategoriya alohida
    # lead_fee belgilamasa, shu qiymat ishlatiladi.
    default_lead_fee: float
    currency: str
    maintenance_mode: bool
    registration_open: bool
    support_phone: str
    support_telegram: str


class SettingsUpdate(BaseModel):
    default_lead_fee: Optional[float] = None
    currency: Optional[str] = None
    maintenance_mode: Optional[bool] = None
    registration_open: Optional[bool] = None
    support_phone: Optional[str] = None
    support_telegram: Optional[str] = None


# Standart qiymatlar — DB'da sozlanmagan bo'lsa shular qaytadi
_DEFAULTS = {
    "default_lead_fee": 5000.0,
    "currency": "UZS",
    "maintenance_mode": False,
    "registration_open": True,
    "support_phone": "+998 71 200 00 00",
    "support_telegram": "@superapp_support",
}


def _read_settings() -> SettingsOut:
    def _f(key: str) -> float:
        val = settings_service.get(key, None)
        try:
            return float(val) if val is not None else float(_DEFAULTS[key])
        except (TypeError, ValueError):
            return float(_DEFAULTS[key])

    return SettingsOut(
        default_lead_fee=_f("default_lead_fee"),
        currency=(settings_service.get("currency", None) or _DEFAULTS["currency"]),
        maintenance_mode=settings_service.get_bool("maintenance_mode", _DEFAULTS["maintenance_mode"]),
        registration_open=settings_service.get_bool("registration_open", _DEFAULTS["registration_open"]),
        support_phone=(settings_service.get("support_phone", None) or _DEFAULTS["support_phone"]),
        support_telegram=(settings_service.get("support_telegram", None) or _DEFAULTS["support_telegram"]),
    )


@router.get("/settings", response_model=SettingsOut)
async def get_settings(
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    return _read_settings()


@router.patch("/settings", response_model=SettingsOut)
async def update_settings(
    data: SettingsUpdate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    updates: dict[str, str] = {}
    payload = data.model_dump(exclude_unset=True)
    for key, val in payload.items():
        if val is None:
            continue
        if isinstance(val, bool):
            updates[key] = "true" if val else "false"
        else:
            updates[key] = str(val)
    if updates:
        settings_service.set_many(updates)
    return _read_settings()
