from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.services.provider_service import ProviderService
from app.schemas.provider import ProviderOut, ReviewOut, ReviewCreate
from app.schemas.common import PaginatedResponse

router = APIRouter(prefix="/providers", tags=["providers"])


@router.get("", response_model=PaginatedResponse)
async def list_providers(
    category_id: int | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    lat: float | None = Query(None),
    lng: float | None = Query(None),
    db: AsyncSession = Depends(get_db),
):
    items, total = await ProviderService.list_providers(
        db, category_id, page, per_page, lat, lng
    )
    pages = (total + per_page - 1) // per_page
    return PaginatedResponse(
        items=[ProviderOut.model_validate(p) for p in items],
        total=total,
        page=page,
        per_page=per_page,
        pages=pages,
    )


@router.get("/{provider_id}", response_model=ProviderOut)
async def get_provider(provider_id: int, db: AsyncSession = Depends(get_db)):
    p = await ProviderService.get_by_id(db, provider_id)
    return p


@router.get("/{provider_id}/reviews", response_model=PaginatedResponse)
async def get_reviews(
    provider_id: int,
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    db: AsyncSession = Depends(get_db),
):
    items, total = await ProviderService.get_reviews(db, provider_id, page, per_page)
    pages = (total + per_page - 1) // per_page
    return PaginatedResponse(
        items=[ReviewOut.model_validate(r) for r in items],
        total=total,
        page=page,
        per_page=per_page,
        pages=pages,
    )


@router.post("/reviews", response_model=ReviewOut, status_code=201)
async def add_review(
    data: ReviewCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    review = await ProviderService.add_review(
        db, current_user.id, data.provider_id, data.rating, data.comment
    )
    return review