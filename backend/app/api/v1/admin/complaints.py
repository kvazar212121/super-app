"""Admin: foydalanuvchi shikoyatlari.

Bu endpoint SHART: shikoyat yig'ilib, hech kim ko'rmaydigan jadvalda
yotib qolsa, `flag_level` bilan bo'lgan xato takrorlanadi (bayroq
qo'yilardi, lekin uni hech narsa o'qimasdi).
"""
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.admin.dependencies import require_admin
from app.db.session import get_db
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.services import complaint_service

router = APIRouter()


class ResolveIn(BaseModel):
    # `new` yo'q: qaytarib "yangi" qilib bo'lmaydi — qaror tarixi saqlanadi.
    status: str = Field(..., pattern="^(reviewing|upheld|rejected)$")
    note: str | None = Field(None, max_length=2000)


@router.get("/complaints", response_model=PaginatedResponse)
async def list_complaints(
    status: str | None = Query(None, pattern="^(new|reviewing|upheld|rejected)$"),
    provider_id: int | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    items, total = await complaint_service.list_for_admin(
        db, status=status, provider_id=provider_id, page=page, per_page=per_page
    )
    pages = (total + per_page - 1) // per_page
    return PaginatedResponse(
        items=[c.to_dict() for c in items],
        total=total, page=page, per_page=per_page, pages=pages,
    )


@router.patch("/complaints/{complaint_id}")
async def resolve_complaint(
    complaint_id: int,
    body: ResolveIn,
    admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Admin qarori. Shikoyat MATNI va dalili o'zgarmaydi — faqat holat."""
    row = await complaint_service.resolve(
        db, complaint_id, status=body.status,
        admin_user_id=admin.id, note=body.note,
    )
    if row is None:
        raise HTTPException(status_code=404, detail="Shikoyat topilmadi")
    await db.commit()
    return row.to_dict()
