from fastapi import APIRouter, Depends
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