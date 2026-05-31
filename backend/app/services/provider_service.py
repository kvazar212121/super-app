from math import ceil
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_
from fastapi import HTTPException, status

from app.models.provider import Provider
from app.models.review import Review
from app.models.category import Category
from app.models.order import Order, OrderStatus


class ProviderService:

    @staticmethod
    async def list_providers(
        db: AsyncSession,
        category_id: int | None = None,
        category_key: str | None = None,
        search: str | None = None,
        page: int = 1,
        per_page: int = 20,
        lat: float | None = None,
        lng: float | None = None,
    ) -> tuple[list[Provider], int]:
        from sqlalchemy.orm import selectinload

        base = (
            select(Provider)
            .options(selectinload(Provider.category))
            .where(Provider.is_active == True)
        )
        count_base = select(func.count(Provider.id)).where(Provider.is_active == True)

        if category_id:
            base = base.where(Provider.category_id == category_id)
            count_base = count_base.where(Provider.category_id == category_id)
        elif category_key:
            base = base.join(Category).where(Category.key == category_key)
            count_base = count_base.join(Category).where(Category.key == category_key)

        if search:
            term = f"%{search.strip()}%"
            search_filter = or_(
                Provider.name.ilike(term),
                Provider.address.ilike(term),
                Provider.phone.ilike(term),
            )
            base = base.where(search_filter)
            count_base = count_base.where(search_filter)

        total = (await db.execute(count_base)).scalar() or 0

        query = base.offset((page - 1) * per_page).limit(per_page)
        providers = (await db.execute(query)).scalars().all()

        return list(providers), total

    @staticmethod
    async def get_by_id(db: AsyncSession, provider_id: int) -> Provider:
        result = await db.execute(
            select(Provider).where(
                Provider.id == provider_id, Provider.is_active == True
            )
        )
        p = result.scalar_one_or_none()
        if not p:
            raise HTTPException(status_code=404, detail="Provayder topilmadi")
        return p

    @staticmethod
    async def get_reviews(
        db: AsyncSession, provider_id: int, page: int = 1, per_page: int = 20
    ) -> tuple[list[Review], int]:
        count_q = select(func.count(Review.id)).where(
            Review.provider_id == provider_id
        )
        total = (await db.execute(count_q)).scalar() or 0

        q = (
            select(Review)
            .where(Review.provider_id == provider_id)
            .order_by(Review.created_at.desc())
            .offset((page - 1) * per_page)
            .limit(per_page)
        )
        reviews = (await db.execute(q)).scalars().all()
        return list(reviews), total

    @staticmethod
    async def add_review(
        db: AsyncSession, user_id: int, provider_id: int, rating: int, comment: str | None
    ) -> Review:
        provider = await ProviderService.get_by_id(db, provider_id)

        # Foydalanuvchi allaqachon ushbu provayderga baho berganligini tekshirish
        existing = await db.execute(
            select(Review).where(
                Review.user_id == user_id,
                Review.provider_id == provider_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Siz ushbu provayderga allaqachon baho bergansiz",
            )

        # Foydalanuvchi ushbu provayder bilan yakunlangan buyurtmaga ega bo'lishi kerak
        completed_order = await db.execute(
            select(Order).where(
                Order.user_id == user_id,
                Order.provider_id == provider_id,
                Order.status == OrderStatus.completed,
            ).limit(1)
        )
        if not completed_order.scalar_one_or_none():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Baho berish uchun ushbu provayder bilan yakunlangan buyurtma bo'lishi kerak",
            )

        review = Review(
            user_id=user_id,
            provider_id=provider_id,
            rating=rating,
            comment=comment,
        )
        db.add(review)

        provider.review_count += 1
        count_q = select(func.avg(Review.rating)).where(
            Review.provider_id == provider_id
        )
        avg = (await db.execute(count_q)).scalar() or rating
        provider.rating = round(float(avg), 1)

        await db.flush()
        await db.refresh(review)
        return review