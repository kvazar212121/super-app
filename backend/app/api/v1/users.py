from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.services.user_service import UserService
from app.schemas.user import UserOut, UserUpdate, CardOut, CardCreate, TopUpRequest

router = APIRouter(prefix="/users", tags=["users"])


@router.get("/me", response_model=UserOut)
async def get_me(current_user: User = Depends(get_current_user)):
    return current_user


@router.delete("/me", status_code=204)
async def delete_me(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await UserService.delete(db, current_user)


@router.patch("/me", response_model=UserOut)
async def update_me(
    data: UserUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    updated = await UserService.update(db, current_user, data)
    return updated


@router.post("/top-up", response_model=UserOut)
async def top_up_balance(
    data: TopUpRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    updated = await UserService.top_up(db, current_user, data.amount)
    return updated


@router.get("/cards", response_model=list[CardOut])
async def get_cards(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await UserService.get_cards(db, current_user.id)


@router.post("/cards", response_model=CardOut, status_code=201)
async def add_card(
    data: CardCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await UserService.add_card(db, current_user.id, data)


@router.delete("/cards/{card_id}", status_code=204)
async def remove_card(
    card_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await UserService.remove_card(db, current_user.id, card_id)


@router.get("/call-history")
async def get_my_call_history(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from sqlalchemy import select, func, or_
    from sqlalchemy.orm import selectinload
    from app.models.call_history import CallHistory
    from app.schemas.common import PaginatedResponse
    
    total = await db.scalar(
        select(func.count(CallHistory.id)).where(
            or_(
                CallHistory.caller_id == current_user.id,
                CallHistory.receiver_id == current_user.id
            )
        )
    ) or 0
    
    result = await db.execute(
        select(CallHistory)
        .options(selectinload(CallHistory.caller), selectinload(CallHistory.receiver), selectinload(CallHistory.provider))
        .where(
            or_(
                CallHistory.caller_id == current_user.id,
                CallHistory.receiver_id == current_user.id
            )
        )
        .order_by(CallHistory.created_at.desc())
        .offset((page - 1) * per_page)
        .limit(per_page)
    )
    calls = result.scalars().all()
    pages = (total + per_page - 1) // per_page
    
    return PaginatedResponse(
        items=[c.to_dict() for c in calls],
        total=total,
        page=page,
        per_page=per_page,
        pages=pages,
    )