"""Sartarosh ro'yxatdan o'tish va jamoa boshqaruvi."""
from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.api.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.provider import ProviderOut
from app.services.barber_service import BarberService
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/provider/barber", tags=["barber portal"])


class BarberShopOwnerIn(BaseModel):
    name: str = Field(..., min_length=2, max_length=300)
    address: str = Field(..., min_length=5, max_length=500)
    phone: str = Field(..., min_length=9, max_length=20)
    lat: float = 41.2995
    lng: float = 69.2401
    also_works_as_barber: bool = False
    hours: str | None = None


class BarberMobileIn(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    phone: str = Field(..., min_length=9, max_length=20)
    service_area: str = Field(..., min_length=3, max_length=500)
    address: str | None = None


class BarberJoinIn(BaseModel):
    display_name: str = Field(..., min_length=2, max_length=200)
    shop_id: int | None = None
    invite_code: str | None = None


class BarberShopOut(BaseModel):
    id: int
    name: str
    address: str
    lat: float
    lng: float
    rating: float
    review_count: int


@router.get("/shops", response_model=list[BarberShopOut])
async def list_barber_shops(db: AsyncSession = Depends(get_db)):
    """Ro'yxatdan o'tishda tanlash uchun sartaroshxonalar."""
    shops = await BarberService.list_shops(db)
    return [
        BarberShopOut(
            id=s.id,
            name=s.name,
            address=s.address,
            lat=s.lat,
            lng=s.lng,
            rating=float(s.rating or 0),
            review_count=int(s.review_count or 0),
        )
        for s in shops
    ]


@router.get("/my-status")
async def get_my_barber_status(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await BarberService.get_my_status(db, user)


@router.post("/register/shop-owner", response_model=ProviderOut, status_code=201)
async def register_shop_owner(
    data: BarberShopOwnerIn,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await BarberService.register_shop_owner(
        db,
        user,
        name=data.name,
        address=data.address,
        phone=data.phone,
        lat=data.lat,
        lng=data.lng,
        also_works_as_barber=data.also_works_as_barber,
        hours=data.hours,
    )
    return ProviderOut.from_provider(provider)


@router.post("/register/mobile", response_model=ProviderOut, status_code=201)
async def register_mobile_barber(
    data: BarberMobileIn,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await BarberService.register_mobile(
        db,
        user,
        name=data.name,
        phone=data.phone,
        service_area=data.service_area,
        address=data.address,
    )
    return ProviderOut.from_provider(provider)


@router.post("/join-request")
async def request_join_shop(
    data: BarberJoinIn,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await BarberService.request_join_shop(
        db,
        user,
        display_name=data.display_name,
        shop_id=data.shop_id,
        invite_code=data.invite_code,
    )


@router.get("/pending-members")
async def list_pending_members(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return {"items": await BarberService.list_pending_members(db, user)}


@router.post("/pending-members/{member_user_id}/approve")
async def approve_member(
    member_user_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await BarberService.approve_member(db, user, member_user_id)


@router.post("/pending-members/{member_user_id}/reject")
async def reject_member(
    member_user_id: int,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await BarberService.reject_member(db, user, member_user_id)


@router.post("/regenerate-invite")
async def regenerate_invite(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    code = await BarberService.regenerate_invite(db, user)
    return {"invite_code": code}


@router.post("/cancel-join")
async def cancel_join_request(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await BarberService.cancel_join_request(db, user)


@router.post("/leave")
async def leave_shop(
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await BarberService.leave_shop(db, user)

