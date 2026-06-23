"""Massaj va hijoma — ro'yxatdan o'tish."""
from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.api.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.provider import ProviderOut
from app.services.massage_service import MassageService
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/provider/massage", tags=["massage portal"])


class MassageRegisterIn(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    phone: str = Field(..., min_length=9, max_length=20)
    service_area: str = Field(..., min_length=3, max_length=500)
    address: str | None = None
    massage_role: str = "solo"
    visit_modes: list[str] = Field(default_factory=list)
    service_types: list[str] = Field(default_factory=list)
    gender: str = "both"
    concurrent_capacity: int = 1


@router.post("/register", response_model=ProviderOut, status_code=201)
async def register_massage(
    data: MassageRegisterIn,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await MassageService.register(
        db,
        user,
        name=data.name,
        phone=data.phone,
        service_area=data.service_area,
        address=data.address,
        massage_role=data.massage_role,
        visit_modes=data.visit_modes or None,
        service_types=data.service_types or None,
        gender=data.gender,
        concurrent_capacity=data.concurrent_capacity,
    )
    return ProviderOut.from_provider(provider)
