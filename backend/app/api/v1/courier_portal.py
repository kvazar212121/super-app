"""Kuryer ro'yxatdan o'tish — yakka kuryer."""
from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.api.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.provider import ProviderOut
from app.services.courier_service import CourierService
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/provider/courier", tags=["courier portal"])


class CourierSoloIn(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    phone: str = Field(..., min_length=9, max_length=20)
    service_area: str = Field(..., min_length=3, max_length=500)
    vehicle_type: str = Field(default="bike", pattern="^(bike|car|van)$")
    address: str | None = None


@router.post("/register/solo", response_model=ProviderOut, status_code=201)
async def register_solo_courier(
    data: CourierSoloIn,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await CourierService.register_solo(
        db,
        user,
        name=data.name,
        phone=data.phone,
        service_area=data.service_area,
        vehicle_type=data.vehicle_type,
        address=data.address,
    )
    return ProviderOut.from_provider(provider)
