from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from pydantic import BaseModel
from typing import Optional

from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.services.bozorchi_service import BozorchiService
from app.models.user import User

router = APIRouter()

class BozorchiRegisterIn(BaseModel):
    name: str
    phone: Optional[str] = None
    service_area: str
    vehicle_type: str = "car"

@router.post("/providers/bozorchi/register")
async def register_bozorchi(
    data: BozorchiRegisterIn,
    db: AsyncSession = Depends(get_db),
    user: User = Depends(get_current_user)
):
    provider = await BozorchiService.register(
        db=db,
        user=user,
        name=data.name,
        phone=data.phone or "",
        service_area=data.service_area,
        vehicle_type=data.vehicle_type,
    )
    return {"message": "Bozorchi sifatida ro'yxatdan o'tdingiz", "provider_id": provider.id}
