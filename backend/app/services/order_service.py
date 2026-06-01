from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from fastapi import HTTPException

from app.models.order import Order, OrderStatus
from app.models.provider import Provider
from app.models.user import User
from app.schemas.order import OrderCreate, OrderStatusUpdate
from app.core.config import settings


class OrderService:

    @staticmethod
    async def create(db: AsyncSession, user: User, data: OrderCreate) -> Order:
        provider = await db.get(Provider, data.provider_id)
        if not provider:
            raise HTTPException(status_code=404, detail="Provayder topilmadi")

        cashback_earned = round(data.price * (settings.cashback_rate / 100), 2)

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
        from sqlalchemy.orm import selectinload
        q = (
            select(Order)
            .options(selectinload(Order.category), selectinload(Order.provider))
            .where(Order.id == order.id)
        )
        order = (await db.execute(q)).scalar_one()

        from app.services.notification_service import NotificationService
        owner_id = provider.owner_user_id
        if owner_id:
            NotificationService.notify_new_order_for_provider(owner_id, order.id)

        return order

    @staticmethod
    async def list_by_user(
        db: AsyncSession, user_id: int, page: int = 1, per_page: int = 20
    ) -> tuple[list[Order], int]:
        count_q = select(func.count(Order.id)).where(Order.user_id == user_id)
        total = (await db.execute(count_q)).scalar() or 0

        from sqlalchemy.orm import selectinload
        q = (
            select(Order)
            .options(selectinload(Order.category), selectinload(Order.provider))
            .where(Order.user_id == user_id)
            .order_by(Order.created_at.desc())
            .offset((page - 1) * per_page)
            .limit(per_page)
        )
        orders = (await db.execute(q)).scalars().all()
        return list(orders), total

    @staticmethod
    async def get_by_id(db: AsyncSession, user_id: int, order_id: int) -> Order:
        from sqlalchemy.orm import selectinload
        result = await db.execute(
            select(Order)
            .options(selectinload(Order.category), selectinload(Order.provider))
            .where(Order.id == order_id, Order.user_id == user_id)
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
        old_status = order.status
        new_status = OrderStatus(data.status)
        order.status = new_status
        await db.flush()
        await db.refresh(order)

        if old_status != new_status:
            from app.services.notification_service import NotificationService
            status_translations = {
                OrderStatus.pending: "kutilmoqda",
                OrderStatus.confirmed: "qabul qilindi",
                OrderStatus.in_progress: "jarayonda",
                OrderStatus.completed: "yakunlandi",
                OrderStatus.cancelled: "bekor qilindi",
            }
            status_str = status_translations.get(new_status, new_status.value)
            NotificationService.notify_order_status(
                user_id=order.user_id,
                order_id=order.id,
                status_label=status_str,
            )
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