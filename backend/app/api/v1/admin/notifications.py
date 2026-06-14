from typing import Optional
from fastapi import APIRouter, Depends, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.user import User
from app.api.v1.admin.dependencies import require_admin

router = APIRouter()


class NotificationSend(BaseModel):
    type: str = Field(..., pattern="^(push|email|sms|in_app)$")
    title: str = Field(..., min_length=1, max_length=200)
    message: str = Field(..., min_length=1, max_length=1000)
    target: str = Field(..., pattern="^(all|users|providers|user|provider)$")
    target_id: Optional[int] = None


@router.post("/notifications/send")
async def send_notification(
    data: NotificationSend,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    return {
        "message": "Bildirishnoma yuborildi",
        "type": data.type,
        "title": data.title,
        "target": data.target,
    }


@router.get("/notifications")
async def list_notifications(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    return {"items": [], "total": 0, "page": page, "per_page": per_page, "pages": 1}
