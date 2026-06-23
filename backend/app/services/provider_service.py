from math import ceil
from datetime import date, datetime, time

from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, or_
from fastapi import HTTPException, status

from app.models.provider import Provider
from app.models.review import Review
from app.models.category import Category
from app.models.order import Order, OrderStatus


DEFAULT_TIME_SLOTS = [
    "09:00", "10:00", "11:00", "12:00",
    "14:00", "15:00", "16:00", "17:00", "18:00",
]


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
            .where(Provider.is_active == True, Provider.is_paused == False)
        )
        count_base = select(func.count(Provider.id)).where(Provider.is_active == True, Provider.is_paused == False)

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
        filtered = [
            p for p in providers
            if (p.metadata_json or {}).get("barber_role") != "shop_employee"
            and not (p.metadata_json or {}).get("is_suspended")
        ]
        return filtered, total

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

    @staticmethod
    async def get_availability(
        db: AsyncSession, provider_id: int, day: date
    ) -> dict:
        """Kunlik band/bo'sh vaqt slotlari (buyurtmalar va metadata asosida)."""
        provider = await ProviderService.get_by_id(db, provider_id)
        meta = provider.metadata_json or {}
        slots: list[str] = meta.get("time_slots") or DEFAULT_TIME_SLOTS

        blocked_dates = meta.get("blocked_dates") or []
        if meta.get("is_suspended") == True or day.isoformat() in blocked_dates or getattr(provider, "is_paused", False):
            return {
                "date": day.isoformat(),
                "slots": slots,
                "booked": list(slots),
            }

        day_start = datetime.combine(day, time.min)
        day_end = datetime.combine(day, time.max)

        result = await db.execute(
            select(Order).where(
                Order.provider_id == provider_id,
                Order.date >= day_start,
                Order.date <= day_end,
                Order.status != OrderStatus.cancelled,
            )
        )
        orders = result.scalars().all()

        from app.models.provider_blocked_time import ProviderBlockedTime
        block_result = await db.execute(
            select(ProviderBlockedTime).where(
                ProviderBlockedTime.provider_id == provider_id,
                ProviderBlockedTime.end_time > day_start,
                ProviderBlockedTime.start_time < day_end
            )
        )
        blocks = block_result.scalars().all()

        capacity = int(meta.get("concurrent_capacity", 1))

        # Count orders per time slot
        from collections import Counter
        order_counts = Counter(
            f"{o.date.hour:02d}:{o.date.minute:02d}"
            for o in orders
            if o.date is not None
        )

        booked_times = set()
        for t_str, count in order_counts.items():
            if count >= capacity:
                booked_times.add(t_str)

        # Check slots against blocks
        for slot in slots:
            slot_h, slot_m = map(int, slot.split(':'))
            slot_dt = datetime.combine(day, time(slot_h, slot_m))
            for b in blocks:
                # slot duration assumed 1 hr for simplicity, or just check point overlap
                slot_end_dt = slot_dt + __import__('datetime').timedelta(minutes=59)
                if b.start_time <= slot_end_dt and b.end_time > slot_dt:
                    booked_times.add(slot)

        booked = [s for s in slots if s in booked_times]

        return {
            "date": day.isoformat(),
            "slots": slots,
            "booked": booked,
        }