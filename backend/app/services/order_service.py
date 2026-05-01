from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from fastapi import HTTPException

from app.models.order import Order, OrderStatus
from app.models.provider import Provider
from app.models.user import User
from app.schemas.order import OrderCreate, OrderStatusUpdate


class OrderService:

    @staticmethod
    async def create(db: AsyncSession, user: User, data: OrderCreate) -> Order:
        provider = await db.get(Provider, data.provider_id)
        if not provider:
            raise HTTPException(status_code=404, detail="Provayder topilmadi")

        cashback_earned = round(data.price * 0.01, 2)

        order = Order(
            user_id=user.id,
            category_id=data.category_id,
            provider_id=data.provider_id,
            variant_id=data.variant_id,
            service_name=data.service_name,
            service_icon=data.service_icon,
            address=data.address,
            notes=data.notes,
            date=data.date,
            price=data.price,
            cashback_earned=cashback_earned,
            status=OrderStatus.pending,
        )
        db.add(order)
        user.cashback += cashback_earned
        await db.flush()
        await db.refresh(order)
        return order

    @staticmethod
    async def list_by_user(
        db: AsyncSession, user_id: int, page: int = 1, per_page: int = 20
    ) -> tuple[list[Order], int]:
        count_q = select(func.count(Order.id)).where(Order.user_id == user_id)
        total = (await db.execute(count_q)).scalar() or 0

        q = (
            select(Order)
            .where(Order.user_id == user_id)
            .order_by(Order.created_at.desc())
            .offset((page - 1) * per_page)
            .limit(per_page)
        )
        orders = (await db.execute(q)).scalars().all()
        return list(orders), total

    @staticmethod
    async def get_by_id(db: AsyncSession, user_id: int, order_id: int) -> Order:
        result = await db.execute(
            select(Order).where(Order.id == order_id, Order.user_id == user_id)
        )
        order = result.scalar_one_or_none()
        if not order:
            raise HTTPException(status_code=404, detail="Buyurtma topilmadi")
        return order

    @staticmethod
    async def update_status(
        db: AsyncSession, user_id: int, order_id: int, data: OrderStatusUpdate
    ) -> Order:
        order = await OrderService.get_by_id(db, user_id, order_id)
        order.status = OrderStatus(data.status)
        await db.flush()
        await db.refresh(order)
        return order

    @staticmethod
    async def list_all(
        db: AsyncSession,
        status: str | None = None,
        category_id: int | None = None,
        page: int = 1,
        per_page: int = 20,
    ) -> tuple[list[Order], int]:
        base = select(Order)
        count_base = select(func.count(Order.id))

        if status:
            base = base.where(Order.status == OrderStatus(status))
            count_base = count_base.where(Order.status == OrderStatus(status))
        if category_id:
            base = base.where(Order.category_id == category_id)
            count_base = count_base.where(Order.category_id == category_id)

        total = (await db.execute(count_base)).scalar() or 0
        q = base.order_by(Order.created_at.desc()).offset(
            (page - 1) * per_page
        ).limit(per_page)
        orders = (await db.execute(q)).scalars().all()
        return list(orders), total