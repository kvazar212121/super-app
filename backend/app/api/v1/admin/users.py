from typing import Optional
from fastapi import APIRouter, Depends, Query, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select, or_, desc

from app.db.session import get_db
from app.models.user import User
from app.schemas.common import PaginatedResponse
from app.api.v1.admin.dependencies import require_admin

router = APIRouter()


class UserOut(BaseModel):
    id: int
    name: str
    surname: str
    phone: str
    avatar_url: Optional[str] = None
    telegram_username: Optional[str] = None
    balance: float
    is_premium: bool
    is_admin: bool
    is_active: bool
    is_blocked: bool
    created_at: Optional[str] = None

    @classmethod
    def from_user(cls, u: User) -> "UserOut":
        created = u.created_at.isoformat() if getattr(u, "created_at", None) else None
        return cls(
            id=u.id,
            name=u.name,
            surname=u.surname,
            phone=u.phone,
            avatar_url=u.avatar_url,
            telegram_username=u.telegram_username,
            balance=u.balance,
            is_premium=u.is_premium,
            is_admin=u.is_admin,
            is_active=u.is_active,
            is_blocked=not u.is_active,
            created_at=created,
        )


class UserUpdate(BaseModel):
    name: Optional[str] = None
    surname: Optional[str] = None
    telegram_username: Optional[str] = None
    balance: Optional[float] = None
    is_premium: Optional[bool] = None


class UserBlockUpdate(BaseModel):
    is_blocked: bool


@router.get("/users", response_model=PaginatedResponse)
async def list_users(
    search: str | None = Query(None),
    is_premium: bool | None = Query(None),
    sort_by: str = Query("created_at"),
    sort_order: str = Query("desc", regex="^(asc|desc)$"),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    query = select(User)

    if search:
        query = query.where(
            or_(
                User.name.ilike(f"%{search}%"),
                User.surname.ilike(f"%{search}%"),
                User.phone.ilike(f"%{search}%"),
            )
        )
    if is_premium is not None:
        query = query.where(User.is_premium == is_premium)

    count_query = select(func.count()).select_from(User)
    if search:
        count_query = count_query.where(
            or_(
                User.name.ilike(f"%{search}%"),
                User.surname.ilike(f"%{search}%"),
                User.phone.ilike(f"%{search}%"),
            )
        )
    total = int(await db.scalar(count_query) or 0)

    if hasattr(User, sort_by):
        sort_col = getattr(User, sort_by)
        if sort_order == "desc":
            query = query.order_by(desc(sort_col))
        else:
            query = query.order_by(sort_col)

    query = query.offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(query)
    items = result.scalars().all()

    pages = (total + per_page - 1) // per_page
    return PaginatedResponse(
        items=[UserOut.from_user(u) for u in items],
        total=total, page=page, per_page=per_page, pages=pages,
    )


@router.get("/users/{user_id}", response_model=UserOut)
async def get_user(
    user_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Foydalanuvchi topilmadi")
    return UserOut.from_user(user)


@router.patch("/users/{user_id}", response_model=UserOut)
async def update_user(
    user_id: int,
    data: UserUpdate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Foydalanuvchi topilmadi")

    update_data = data.model_dump(exclude_unset=True)
    for key, val in update_data.items():
        setattr(user, key, val)

    await db.flush()
    await db.refresh(user)
    return UserOut.from_user(user)


@router.patch("/users/{user_id}/block", response_model=UserOut)
async def block_user(
    user_id: int,
    data: UserBlockUpdate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Foydalanuvchi topilmadi")
    if user.is_admin:
        raise HTTPException(status_code=400, detail="Adminni bloklab bo'lmaydi")
    user.is_active = not data.is_blocked
    await db.flush()
    await db.refresh(user)
    return UserOut.from_user(user)


@router.delete("/users/{user_id}", status_code=204)
async def delete_user(
    user_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=404, detail="Foydalanuvchi topilmadi")
    if user.is_admin:
        raise HTTPException(status_code=400, detail="Adminni o'chirib bo'lmaydi")
    await db.delete(user)
