"""Tadbir tashkil etuvchi guruh — ro'yxatdan o'tish."""
from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from app.api.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.provider import ProviderOut
from app.services.event_service import EventOrganizerService
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter(prefix="/provider/event", tags=["event portal"])


class EventRegisterIn(BaseModel):
    name: str = Field(..., min_length=2, max_length=200)
    phone: str = Field(..., min_length=9, max_length=20)
    service_area: str = Field(..., min_length=3, max_length=500)
    address: str | None = None
    team_size: int = Field(default=3, ge=1, le=50)
    organizer_types: list[str] = Field(default_factory=list)
    event_types: list[str] = Field(default_factory=list)
    venue_types: list[str] = Field(default_factory=list)


@router.post("/register", response_model=ProviderOut, status_code=201)
async def register_event_organizer(
    data: EventRegisterIn,
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await EventOrganizerService.register(
        db,
        user,
        name=data.name,
        phone=data.phone,
        service_area=data.service_area,
        address=data.address,
        team_size=data.team_size,
        organizer_types=data.organizer_types or None,
        event_types=data.event_types or None,
        venue_types=data.venue_types or None,
    )
    return ProviderOut.from_provider(provider)
