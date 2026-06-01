"""Enaga ro'yxatdan o'tish — hujjatlar va admin tasdiqlash."""
from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.api.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.provider import ProviderOut
from app.services.nanny_service import NannyService
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/provider/nanny", tags=["nanny portal"])


class NannyDocumentsIn(BaseModel):
    medical_cert: bool = False
    criminal_record: bool = False
    id_verified: bool = False
    medical_cert_url: str | None = None
    id_url: str | None = None
    criminal_record_url: str | None = None


class NannyRegisterIn(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    phone: str = Field(..., min_length=9, max_length=20)
    service_area: str = Field(..., min_length=3, max_length=500)
    address: str | None = None
    experience_years: int = Field(0, ge=0, le=50)
    age_groups: list[str] = Field(default_factory=list)
    languages: list[str] = Field(default_factory=list)
    service_types: list[str] = Field(default_factory=list)
    documents: NannyDocumentsIn | None = None


@router.post("/register", response_model=ProviderOut, status_code=201)
async def register_nanny(
    data: NannyRegisterIn,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await NannyService.register(
        db,
        user,
        name=data.name,
        phone=data.phone,
        service_area=data.service_area,
        address=data.address,
        experience_years=data.experience_years,
        age_groups=data.age_groups or None,
        languages=data.languages or None,
        service_types=data.service_types or None,
        documents=data.documents.model_dump() if data.documents else None,
    )
    return ProviderOut.from_provider(provider)
