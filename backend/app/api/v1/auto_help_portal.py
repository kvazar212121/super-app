"""Mobil avto-yordam ro'yxatdan o'tish."""
from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.api.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.provider import ProviderOut
from app.services.auto_help_service import AutoHelpService
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/provider/auto-help", tags=["auto help portal"])


class AutoMobileIn(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    phone: str = Field(..., min_length=9, max_length=20)
    service_area: str = Field(..., min_length=3, max_length=500)
    vehicle_type: str = Field(default="combo", pattern="^(evakuator|service_van|fuel_truck|combo)$")
    address: str | None = None


@router.post("/register/mobile", response_model=ProviderOut, status_code=201)
async def register_mobile_auto_help(
    data: AutoMobileIn,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await AutoHelpService.register_mobile(
        db,
        user,
        name=data.name,
        phone=data.phone,
        service_area=data.service_area,
        vehicle_type=data.vehicle_type,
        address=data.address,
    )
    return ProviderOut.from_provider(provider)


class AutoWorkshopIn(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    phone: str = Field(..., min_length=9, max_length=20)
    address: str = Field(..., min_length=5, max_length=500)
    specializations: list[str] = Field(default_factory=list)


@router.post("/register/workshop", response_model=ProviderOut, status_code=201)
async def register_workshop_auto_help(
    data: AutoWorkshopIn,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await AutoHelpService.register_workshop(
        db,
        user,
        name=data.name,
        phone=data.phone,
        address=data.address,
        specializations=data.specializations or None,
    )
    return ProviderOut.from_provider(provider)
