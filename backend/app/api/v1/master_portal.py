"""Usta chaqirish ro'yxatdan o'tish — yakka usta yoki brigada."""
from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.api.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.provider import ProviderOut
from app.services.master_dispatch_service import MasterDispatchService
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/provider/master", tags=["master portal"])


class MasterSoloIn(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    phone: str = Field(..., min_length=9, max_length=20)
    service_area: str = Field(..., min_length=3, max_length=500)
    address: str | None = None


class MasterBrigadeIn(BaseModel):
    name: str = Field(..., min_length=2, max_length=300)
    phone: str = Field(..., min_length=9, max_length=20)
    address: str = Field(..., min_length=5, max_length=500)
    service_area: str = Field(..., min_length=3, max_length=500)
    team_size: int = Field(..., ge=2, le=50)
    lat: float = 41.2995
    lng: float = 69.2401


@router.post("/register/solo", response_model=ProviderOut, status_code=201)
async def register_solo_master(
    data: MasterSoloIn,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await MasterDispatchService.register_solo(
        db,
        user,
        name=data.name,
        phone=data.phone,
        service_area=data.service_area,
        address=data.address,
    )
    return ProviderOut.from_provider(provider)


@router.post("/register/brigade", response_model=ProviderOut, status_code=201)
async def register_master_brigade(
    data: MasterBrigadeIn,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await MasterDispatchService.register_brigade(
        db,
        user,
        name=data.name,
        phone=data.phone,
        address=data.address,
        service_area=data.service_area,
        team_size=data.team_size,
        lat=data.lat,
        lng=data.lng,
    )
    return ProviderOut.from_provider(provider)
