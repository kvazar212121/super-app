"""Hamshira — ro'yxatdan o'tish."""
from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.api.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.provider import ProviderOut
from app.services.nurse_service import NurseService
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/provider/nurse", tags=["nurse portal"])


class NurseRegisterIn(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    phone: str = Field(..., min_length=9, max_length=20)
    service_area: str = Field(..., min_length=3, max_length=500)
    address: str | None = None
    medical_types: list[str] = Field(default_factory=list)
    qualifications: str | None = None


@router.post("/register", response_model=ProviderOut, status_code=201)
async def register_nurse(
    data: NurseRegisterIn,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await NurseService.register(
        db,
        user,
        name=data.name,
        phone=data.phone,
        service_area=data.service_area,
        address=data.address,
        medical_types=data.medical_types or None,
        qualifications=data.qualifications,
    )
    return ProviderOut.from_provider(provider)
