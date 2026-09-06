from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select, desc
from sqlalchemy.orm import selectinload

from app.db.session import get_db
from app.models.user import User
from app.models.provider import Provider
from app.models.review import Review
from app.schemas.common import PaginatedResponse
from app.api.v1.admin.dependencies import require_admin

router = APIRouter()


@router.get("/reviews", response_model=PaginatedResponse)
async def list_reviews(
    provider_id: int | None = Query(None),
    user_id: int | None = Query(None),
    min_rating: int | None = Query(None),
    max_rating: int | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    query = select(Review).options(selectinload(Review.provider), selectinload(Review.user))

    if provider_id:
        query = query.where(Review.provider_id == provider_id)
    if user_id:
        query = query.where(Review.user_id == user_id)
    if min_rating:
        query = query.where(Review.rating >= min_rating)
    if max_rating:
        query = query.where(Review.rating <= max_rating)

    count_query = select(func.count()).select_from(Review)
    if provider_id:
        count_query = count_query.where(Review.provider_id == provider_id)
    if user_id:
        count_query = count_query.where(Review.user_id == user_id)

    total = int(await db.scalar(count_query) or 0)

    query = query.order_by(desc(Review.created_at)).offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(query)
    items = result.scalars().all()

    out_items = []
    for r in items:
        d = r.to_dict()
        d["provider_name"] = r.provider.name if r.provider else None
        out_items.append(d)

    pages = (total + per_page - 1) // per_page
    return PaginatedResponse(items=out_items, total=total, page=page, per_page=per_page, pages=pages)


@router.delete("/reviews/{review_id}", status_code=204)
async def delete_review(
    review_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Review).where(Review.id == review_id))
    review = result.scalar_one_or_none()
    if not review:
        raise HTTPException(status_code=404, detail="Sharh topilmadi")
    await db.delete(review)

    avg_result = await db.execute(
        select(func.coalesce(func.avg(Review.rating), 0), func.count(Review.id)).where(
            Review.provider_id == review.provider_id
        )
    )
    avg_row = avg_result.one()
    provider_result = await db.execute(
        select(Provider).where(Provider.id == review.provider_id)
    )
    provider = provider_result.scalar_one()
    provider.rating = float(avg_row[0])
    provider.review_count = int(avg_row[1])
    await db.flush()
