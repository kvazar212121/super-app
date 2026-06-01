"""Stomatologiya — klinika ro'yxatdan o'tish."""
from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.api.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.provider import ProviderOut
from app.services.dental_service import DentalService
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/provider/dental", tags=["dental portal"])


class DentalRegisterIn(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    phone: str = Field(..., min_length=9, max_length=20)
    address: str = Field(..., min_length=5, max_length=500)
    services: list[str] = Field(default_factory=list)


@router.post("/register", response_model=ProviderOut, status_code=201)
async def register_dental(
    data: DentalRegisterIn,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await DentalService.register_clinic(
        db,
        user,
        name=data.name,
        phone=data.phone,
        address=data.address,
        services=data.services or None,
    )
    return ProviderOut.from_provider(provider)
