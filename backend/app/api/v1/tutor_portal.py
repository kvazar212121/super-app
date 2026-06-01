"""Repetitor ro'yxatdan o'tish — yakka o'qituvchi yoki o'quv markazi."""
from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.api.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.provider import ProviderOut
from app.services.tutor_service import TutorService
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/provider/tutor", tags=["tutor portal"])


class TutorSoloIn(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    phone: str = Field(..., min_length=9, max_length=20)
    service_area: str = Field(..., min_length=3, max_length=500)
    address: str | None = None
    subjects: list[str] = Field(default_factory=list)
    lesson_modes: list[str] = Field(default_factory=list)
    experience_years: int = Field(0, ge=0, le=50)


class TutorCenterIn(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    phone: str = Field(..., min_length=9, max_length=20)
    address: str = Field(..., min_length=5, max_length=500)
    courses: list[str] = Field(default_factory=list)


@router.post("/register/solo", response_model=ProviderOut, status_code=201)
async def register_solo_tutor(
    data: TutorSoloIn,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await TutorService.register_solo(
        db,
        user,
        name=data.name,
        phone=data.phone,
        service_area=data.service_area,
        address=data.address,
        subjects=data.subjects or None,
        lesson_modes=data.lesson_modes or None,
        experience_years=data.experience_years,
    )
    return ProviderOut.from_provider(provider)


@router.post("/register/center", response_model=ProviderOut, status_code=201)
async def register_tutor_center(
    data: TutorCenterIn,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await TutorService.register_center(
        db,
        user,
        name=data.name,
        phone=data.phone,
        address=data.address,
        courses=data.courses or None,
    )
    return ProviderOut.from_provider(provider)
