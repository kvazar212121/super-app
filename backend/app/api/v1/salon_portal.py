"""Salon ro'yxatdan o'tish va jamoa boshqaruvi."""
from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.api.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.provider import ProviderOut
from app.services.salon_service import SalonService
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/provider/salon", tags=["salon portal"])


class SalonOwnerIn(BaseModel):
    name: str = Field(..., min_length=2, max_length=300)
    address: str = Field(..., min_length=5, max_length=500)
    phone: str = Field(..., min_length=9, max_length=20)
    lat: float = 41.2995
    lng: float = 69.2401
    also_works_as_stylist: bool = False
    hours: str | None = None


class SalonMobileIn(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    phone: str = Field(..., min_length=9, max_length=20)
    service_area: str = Field(..., min_length=3, max_length=500)
    address: str | None = None


class SalonJoinIn(BaseModel):
    display_name: str = Field(..., min_length=2, max_length=200)
    salon_id: int | None = None
    invite_code: str | None = None


class SalonOut(BaseModel):
    id: int
    name: str
    address: str
    lat: float
    lng: float
    rating: float
    review_count: int


@router.get("/venues", response_model=list[SalonOut])
async def list_salons(db: AsyncSession = Depends(get_db)):
    """Ro'yxatdan o'tishda tanlash uchun salonlar."""
    salons = await SalonService.list_salons(db)
    return [
        SalonOut(
            id=s.id,
            name=s.name,
            address=s.address,
            lat=s.lat,
            lng=s.lng,
            rating=float(s.rating or 0),
            review_count=int(s.review_count or 0),
        )
        for s in salons
    ]


@router.get("/my-status")
async def get_my_salon_status(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await SalonService.get_my_status(db, user)


@router.post("/register/owner", response_model=ProviderOut, status_code=201)
async def register_salon_owner(
    data: SalonOwnerIn,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await SalonService.register_salon_owner(
        db,
        user,
        name=data.name,
        address=data.address,
        phone=data.phone,
        lat=data.lat,
        lng=data.lng,
        also_works_as_stylist=data.also_works_as_stylist,
        hours=data.hours,
    )
    return ProviderOut.from_provider(provider)


@router.post("/register/mobile", response_model=ProviderOut, status_code=201)
async def register_mobile_stylist(
    data: SalonMobileIn,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await SalonService.register_mobile(
        db,
        user,
        name=data.name,
        phone=data.phone,
        service_area=data.service_area,
        address=data.address,
    )
    return ProviderOut.from_provider(provider)


@router.post("/join-request")
async def request_join_salon(
    data: SalonJoinIn,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await SalonService.request_join_salon(
        db,
        user,
        display_name=data.display_name,
        salon_id=data.salon_id,
        invite_code=data.invite_code,
    )


@router.get("/pending-members")
async def list_pending_members(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return {"items": await SalonService.list_pending_members(db, user)}


@router.post("/pending-members/{member_user_id}/approve")
async def approve_member(
    member_user_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await SalonService.approve_member(db, user, member_user_id)


@router.post("/pending-members/{member_user_id}/reject")
async def reject_member(
    member_user_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await SalonService.reject_member(db, user, member_user_id)


@router.post("/regenerate-invite")
async def regenerate_invite(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    code = await SalonService.regenerate_invite(db, user)
    return {"invite_code": code}
