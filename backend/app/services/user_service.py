from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from fastapi import HTTPException, status

from app.models.user import User
from app.models.payment import PaymentCard
from app.schemas.user import UserUpdate, CardCreate


class UserService:

    @staticmethod
    async def get_by_id(db: AsyncSession, user_id: int) -> User:
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise HTTPException(status_code=404, detail="Foydalanuvchi topilmadi")
        return user

    @staticmethod
    async def update(db: AsyncSession, user: User, data: UserUpdate) -> User:
        for key, val in data.model_dump(exclude_unset=True).items():
            setattr(user, key, val)
        await db.flush()
        await db.refresh(user)
        return user

    @staticmethod
    async def top_up(db: AsyncSession, user: User, amount: float) -> User:
        user.balance += amount
        await db.flush()
        await db.refresh(user)
        return user

    @staticmethod
    async def get_cards(db: AsyncSession, user_id: int) -> list[PaymentCard]:
        result = await db.execute(
            select(PaymentCard).where(PaymentCard.user_id == user_id)
        )
        return list(result.scalars().all())

    @staticmethod
    async def add_card(db: AsyncSession, user_id: int, data: CardCreate) -> PaymentCard:
        card = PaymentCard(user_id=user_id, **data.model_dump())
        db.add(card)
        await db.flush()
        await db.refresh(card)
        return card

    @staticmethod
    async def remove_card(db: AsyncSession, user_id: int, card_id: int) -> None:
        result = await db.execute(
            select(PaymentCard).where(
                PaymentCard.id == card_id,
                PaymentCard.user_id == user_id,
            )
        )
        card = result.scalar_one_or_none()
        if not card:
            raise HTTPException(status_code=404, detail="Karta topilmadi")
        await db.delete(card)