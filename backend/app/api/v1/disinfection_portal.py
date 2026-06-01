"""Dezinfeksiya — ro'yxatdan o'tish."""
from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.api.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.provider import ProviderOut
from app.services.disinfection_service import DisinfectionService
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/provider/disinfection", tags=["disinfection portal"])


class DisinfectionRegisterIn(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    phone: str = Field(..., min_length=9, max_length=20)
    service_area: str = Field(..., min_length=3, max_length=500)
    address: str | None = None
    area_types: list[str] = Field(default_factory=list)
    is_certified: bool = False


@router.post("/register", response_model=ProviderOut, status_code=201)
async def register_disinfection(
    data: DisinfectionRegisterIn,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await DisinfectionService.register(
        db,
        user,
        name=data.name,
        phone=data.phone,
        service_area=data.service_area,
        address=data.address,
        area_types=data.area_types or None,
        is_certified=data.is_certified,
    )
    return ProviderOut.from_provider(provider)
