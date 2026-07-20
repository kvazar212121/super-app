from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from sqlalchemy.orm import selectinload
from fastapi import HTTPException

from app.models.order import Order, OrderStatus
from app.models.provider import Provider
from app.models.user import User
from app.schemas.order import OrderCreate, OrderStatusUpdate
from app.core.config import settings


class OrderService:

    @staticmethod
    async def create(db: AsyncSession, user: User, data: OrderCreate) -> Order:
        # category'ni EAGER yuklaymiz — pastda provider.category ishlatiladi.
        # (async'da lazy-load 'MissingGreenlet' xatosi berib 500 qiladi.)
        _pres = await db.execute(
            select(Provider)
            .options(selectinload(Provider.category))
            .where(Provider.id == data.provider_id)
        )
        provider = _pres.scalar_one_or_none()
        if not provider:
            raise HTTPException(status_code=404, detail="Provayder topilmadi")

        if data.date:
            from app.services.provider_service import ProviderService
            availability = await ProviderService.get_availability(db, provider.id, data.date.date())
            slot_str = f"{data.date.hour:02d}:{data.date.minute:02d}"
            if slot_str in availability.get("booked", []):
                raise HTTPException(status_code=400, detail="Tanlangan vaqt band qilingan yoki ruxsat etilmagan")

        cashback_earned = 0.0

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
        await db.flush()

        if provider.owner_user_id:
            owner_user = await db.get(User, provider.owner_user_id)
            if owner_user:
                from app.models.setting import PlatformSetting
                default_fee_setting = await db.scalar(select(PlatformSetting).where(PlatformSetting.key == "default_lead_fee"))
                default_fee = float(default_fee_setting.value) if default_fee_setting else 5000.0
                
                actual_fee = default_fee
                if provider.lead_fee is not None:
                    actual_fee = provider.lead_fee
                elif provider.category and provider.category.lead_fee is not None:
                    actual_fee = provider.category.lead_fee
                
                if actual_fee > 0:
                    # balance null bo'lishi mumkin (hech to'ldirilmagan) — himoya.
                    provider.balance = (provider.balance or 0.0) - actual_fee
                    
                    from app.models.transaction import Transaction
                    tx = Transaction(
                        user_id=owner_user.id,
                        provider_id=provider.id,
                        order_id=order.id,
                        type="lead_fee",
                        amount=-actual_fee,
                        description=f"Mijoz topilganligi uchun komissiya (Buyurtma #{order.id})",
                        status="completed",
                    )
                    db.add(tx)
        
        import traceback
        try:
            from app.models.plan import Plan
            from datetime import timezone
            plan_title = f"{order.service_name}"
            plan_desc = f"Provayder: {provider.name}\nManzil: {order.address}\nNarxi: {int(order.price or 0):,} so'm".replace(",", " ")
            if order.notes:
                plan_desc += f"\nIzoh: {order.notes}"
            
            # Fix naive datetime for asyncpg
            due_date_aware = order.date
            if due_date_aware.tzinfo is None:
                due_date_aware = due_date_aware.replace(tzinfo=timezone.utc)
            
            plan = Plan(
                user_id=user.id,
                title=plan_title,
                description=plan_desc,
                due_date=due_date_aware,
                is_completed=False,
                is_notified=False,
            )
            db.add(plan)
            
            await db.flush()
        except Exception as e:
            print(f"Error creating Plan or Transaction: {e}")
            traceback.print_exc()
            # If creating a plan fails, we don't want to crash the whole order creation
            # Rollback to the savepoint if we were using one, but here we can just ignore or raise.
            # Actually, if db.flush() fails, the session is in a bad state. We must raise.
            raise HTTPException(status_code=500, detail=f"Ichki xatolik: {e}")
        
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

        # Mijoz buyurtmani o'zi YAKUNLAY olmaydi — yakunlash ikki tomonlama tasdiq orqali.
        # Mijozga faqat bekor qilish ruxsat etiladi (yakunlangan holatdan tashqari).
        TERMINAL = {OrderStatus.completed, OrderStatus.cancelled, OrderStatus.no_show}
        if new_status != old_status:
            if old_status in TERMINAL:
                raise HTTPException(status_code=400, detail="Bu buyurtma allaqachon yakunlangan")
            if new_status != OrderStatus.cancelled:
                raise HTTPException(
                    status_code=403,
                    detail="Buyurtma holatini bu tarzda o'zgartirib bo'lmaydi",
                )

        order.status = new_status
        await db.flush()
        await db.refresh(order)

        if old_status != new_status:
            from app.services.notification_service import NotificationService
            status_translations = {
                OrderStatus.pending: "kutilmoqda",
                OrderStatus.confirmed: "qabul qilindi",
                OrderStatus.on_the_way: "yo'lda",
                OrderStatus.arrived: "yetib keldi",
                OrderStatus.preparing: "tayyorlanmoqda",
                OrderStatus.in_progress: "jarayonda",
                OrderStatus.delivered: "yetkazildi",
                OrderStatus.completed: "yakunlandi",
                OrderStatus.cancelled: "bekor qilindi",
                OrderStatus.no_show: "mijoz kelmadi",
                OrderStatus.disputed: "nizoli holat",
            }
            status_str = status_translations.get(new_status, new_status.value)
            NotificationService.notify_order_status(
                user_id=order.user_id,
                order_id=order.id,
                status_label=status_str,
            )
            if new_status == OrderStatus.completed:
                await OrderService.shift_flexible_queue(db, order.provider_id)
                await OrderService.process_commission(db, order)
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

    @staticmethod
    async def shift_flexible_queue(db: AsyncSession, provider_id: int) -> None:
        """
        Smart queue shifting algorithm.
        When an order is completed, shifts subsequent flexible orders forward.
        Stops shifting when a fixed order is encountered.
        """
        from datetime import datetime, time
        from app.models.order import Order, OrderStatus
        
        now = datetime.utcnow()
        today_end = datetime.combine(now.date(), time.max)
        
        # Get all future confirmed or pending/in-progress orders for this provider today
        q = (
            select(Order)
            .where(
                Order.provider_id == provider_id,
                Order.status.in_([OrderStatus.pending, OrderStatus.confirmed, OrderStatus.in_progress]),
                Order.date > now,
                Order.date <= today_end,
            )
            .order_by(Order.date.asc())
        )
        future_orders = list((await db.execute(q)).scalars().all())
        if not future_orders:
            return
            
        # The shift threshold: we shift the first flexible order to 'now'
        first_order = future_orders[0]
        if getattr(first_order, "booking_mode", "fixed") != "flexible":
            # If the first future order is fixed, we cannot shift it or skip past it
            return
            
        delta = first_order.date - now
        if delta.total_seconds() <= 0:
            return
            
        # Shift the first flexible order to now
        first_order.date = now
        db.add(first_order)
        
        # Send notification to the user of the first order
        from app.services.notification_service import NotificationService
        time_str = now.strftime("%H:%M")
        NotificationService.notify_order_shifted(
            user_id=first_order.user_id,
            order_id=first_order.id,
            new_time_label=time_str,
        )
        
        # Shift subsequent flexible orders by the same delta
        for order in future_orders[1:]:
            if getattr(order, "booking_mode", "fixed") == "flexible":
                new_date = order.date - delta
                order.date = new_date
                db.add(order)
                # Notify
                time_str = new_date.strftime("%H:%M")
                NotificationService.notify_order_shifted(
                    user_id=order.user_id,
                    order_id=order.id,
                    new_time_label=time_str,
                )
            else:
                # Stop shifting when we hit a fixed order
                break
        await db.flush()

    @staticmethod
    async def run_completion_checks(db: AsyncSession) -> None:
        from datetime import datetime, timezone, timedelta
        from app.models.order import Order, OrderStatus
        from app.services.notification_service import NotificationService

        now = datetime.now(timezone.utc).replace(tzinfo=None)

        # 1. 2 soat o'tgan bo'lsa eslatish (faqat in_progress yoki confirmed)
        q_remind = select(Order).where(
            Order.status.in_([OrderStatus.confirmed, OrderStatus.in_progress]),
            Order.date <= now - timedelta(hours=2)
        )
        orders_to_remind = (await db.execute(q_remind)).scalars().all()
        for order in orders_to_remind:
            # Ustaga eslatish
            if order.provider and order.provider.owner_user_id:
                NotificationService.notify_order_status(
                    user_id=order.provider.owner_user_id,
                    order_id=order.id,
                    status_label="Vaqti o'tdi! Ishni yakunladingizmi?"
                )
            # Mijozga eslatish
            NotificationService.notify_order_status(
                user_id=order.user_id,
                order_id=order.id,
                status_label="Xizmatdan qoniqdingizmi?"
            )

        # 2. 24 soat o'tgan bo'lsa (awaiting_confirmation -> completed avtomatik)
        q_auto_complete = select(Order).where(
            Order.status == OrderStatus.awaiting_confirmation,
            Order.date <= now - timedelta(hours=24)
        )
        orders_to_complete = (await db.execute(q_auto_complete)).scalars().all()
        for order in orders_to_complete:
            order.status = OrderStatus.completed
            
            # Count increment & commission
            from app.models.provider import Provider
            provider = await db.get(Provider, order.provider_id)
            if provider:
                provider.completed_orders_count += 1
            await OrderService.shift_flexible_queue(db, order.provider_id)
            await OrderService.process_commission(db, order)

        if orders_to_complete:
            await db.flush()
            await db.commit()

    @staticmethod
    async def process_commission(db: AsyncSession, order) -> None:
        """
        Foizlik komissiya ushlab qolish tizimi bekor qilindi.
        Buning o'rniga faqat buyurtma yaratilayotganda qat'iy "Lead fee" olinadi.
        """
        pass