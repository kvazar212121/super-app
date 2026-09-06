"""
Ikki tomonlama tasdiqlash (Check-in) xizmati.

Xizmat guruhlari:
  A — Mijoz boradi: sartarosh, salon, stomatologiya, oshxona, gameZona, sportMaydon, futbol
  B — Usta keladi: elektrik, santexnik, tozalash, konditsioner, hamshira, ...
  C — Yetkazish: kuryerlik, bozorchi, avtoYordam
  D — Joy bron: futbol, gameZona, sportMaydon, tadbirlar (soatga asoslangan)

Har bir guruh uchun checkin qoidalari farq qiladi.
"""
import logging
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import HTTPException

from app.models.order import Order, OrderStatus
from app.models.order_checkin import OrderCheckin, CheckinSide, CheckinResponse
from app.models.provider_fraud_stats import ProviderFraudStats, FraudFlagLevel
from app.services.notification_service import NotificationService

logger = logging.getLogger(__name__)

# Kategoriya guruhlarni aniqlash (category key bo'yicha)
GROUP_A_KEYS = {
    "sartarosh", "salon", "stomatologiya", "oshxona",
    "gameZona", "sportMaydon", "futbol",
}
GROUP_B_KEYS = {
    "elektrik", "santexnik", "tozalash", "konditsioner",
    "hamshira", "texnikaUstasi", "dezinfeksiya", "massajHijoma",
    "kompUsta", "usta", "ishchi", "enaga", "repetitor",
}
GROUP_C_KEYS = {"kuryerlik", "bozorchi", "avtoYordam"}
GROUP_D_KEYS = {"futbol", "gameZona", "sportMaydon", "tadbirlar"}


def _get_group(category_key: str) -> str:
    """Kategoriya kaliti bo'yicha guruhni aniqlash."""
    if category_key in GROUP_D_KEYS:
        return "D"
    if category_key in GROUP_A_KEYS:
        return "A"
    if category_key in GROUP_C_KEYS:
        return "C"
    if category_key in GROUP_B_KEYS:
        return "B"
    return "B"  # default — usta keladi


class CheckinService:

    @staticmethod
    async def process_checkin(
        db: AsyncSession,
        order_id: int,
        side: str,
        response: str,
    ) -> dict:
        """
        Ikki tomonlama checkin ni qayta ishlash.

        side:     'user' | 'provider'
        response: 'arrived' | 'delayed' | 'cant_come' | 'no_show'
        """
        from sqlalchemy.orm import selectinload
        order = (
            await db.execute(
                select(Order)
                .options(selectinload(Order.category), selectinload(Order.provider))
                .where(Order.id == order_id)
            )
        ).scalar_one_or_none()

        if not order:
            raise HTTPException(status_code=404, detail="Buyurtma topilmadi")

        checkin_side = CheckinSide(side)
        checkin_response = CheckinResponse(response)

        # Mavjud checkin bormi tekshirish (bir tomon ikki marta bosmaydi)
        existing = (
            await db.execute(
                select(OrderCheckin).where(
                    OrderCheckin.order_id == order_id,
                    OrderCheckin.side == checkin_side,
                )
            )
        ).scalar_one_or_none()

        if existing:
            raise HTTPException(
                status_code=400,
                detail=f"Siz allaqachon javob bergansiz: {existing.response.value}",
            )

        # Checkin yozuvini saqlash
        checkin = OrderCheckin(
            order_id=order_id,
            side=checkin_side,
            response=checkin_response,
        )
        db.add(checkin)
        await db.flush()

        # ----- Maxsus holatlar -----

        # Agar mijoz "Bora olmayman" desa → darhol cancelled
        if checkin_side == CheckinSide.user and checkin_response == CheckinResponse.cant_come:
            order.status = OrderStatus.cancelled
            await db.flush()
            # Provider ga xabar
            if order.provider and order.provider.owner_user_id:
                NotificationService.send_notification(
                    user_id=order.provider.owner_user_id,
                    ntype="checkin_cancelled",
                    title="Mijoz bekor qildi ❌",
                    message=f"#{order.id} buyurtma: mijoz bora olmasligini bildirdi.",
                )
            return {"action": "cancelled", "status": order.status.value}

        # Agar mijoz "Kechikaman" desa → timer uzayadi (status o'zgarmaydi)
        if checkin_side == CheckinSide.user and checkin_response == CheckinResponse.delayed:
            if order.provider and order.provider.owner_user_id:
                NotificationService.send_notification(
                    user_id=order.provider.owner_user_id,
                    ntype="checkin_delayed",
                    title="Mijoz kechikadi ⏳",
                    message=f"#{order.id} buyurtma: mijoz kechikishini bildirdi. +10 daqiqa kutiladi.",
                )
            return {"action": "delayed", "status": order.status.value, "extra_minutes": 10}

        # Endi ikkala tomon ham javob berganmi tekshiramiz
        all_checkins = (
            await db.execute(
                select(OrderCheckin).where(OrderCheckin.order_id == order_id)
            )
        ).scalars().all()

        user_checkin = next((c for c in all_checkins if c.side == CheckinSide.user), None)
        provider_checkin = next((c for c in all_checkins if c.side == CheckinSide.provider), None)

        result = {"action": "waiting", "status": order.status.value}

        if user_checkin and provider_checkin:
            result = await CheckinService._resolve_checkins(
                db, order, user_checkin, provider_checkin
            )

        return result

    @staticmethod
    async def _resolve_checkins(
        db: AsyncSession,
        order: Order,
        user_checkin: OrderCheckin,
        provider_checkin: OrderCheckin,
    ) -> dict:
        """Ikkala tomon javob bergandan keyin qaror qabul qilish."""

        user_resp = user_checkin.response
        prov_resp = provider_checkin.response

        # ✅ Ikkalasi ham "arrived"
        if user_resp == CheckinResponse.arrived and prov_resp == CheckinResponse.arrived:
            order.status = OrderStatus.arrived
            await db.flush()
            return {"action": "arrived", "status": "arrived"}

        # ⚠️ Mijoz "arrived" + Usta "no_show" → DISPUTED
        if user_resp == CheckinResponse.arrived and prov_resp == CheckinResponse.no_show:
            order.status = OrderStatus.disputed
            await db.flush()

            # Fraud stats ni yangilash
            await CheckinService._increment_fraud_stat(
                db, order.provider_id, "disputed"
            )

            # Admin ga xabar
            NotificationService.send_notification(
                user_id=1,  # Admin user
                ntype="disputed_order",
                title="⚠️ Nizoli buyurtma",
                message=(
                    f"#{order.id} buyurtma: mijoz 'keldim' dedi, lekin usta "
                    f"'kelmadi' dedi. Tekshirish kerak!"
                ),
            )
            return {"action": "disputed", "status": "disputed"}

        # Usta "arrived" + Mijoz javob bermagan → auto arrived (B guruh uchun)
        if prov_resp == CheckinResponse.arrived and user_resp is None:
            order.status = OrderStatus.arrived
            await db.flush()
            return {"action": "arrived", "status": "arrived"}

        # Usta "no_show" + Mijoz javob bermagan → no_show
        if prov_resp == CheckinResponse.no_show and (
            user_resp is None or user_resp == CheckinResponse.no_show
        ):
            order.status = OrderStatus.no_show
            await db.flush()

            await CheckinService._increment_fraud_stat(
                db, order.provider_id, "no_show"
            )

            # Mijozga xabar
            NotificationService.send_notification(
                user_id=order.user_id,
                ntype="order_noshow",
                title="Buyurtma bekor qilindi 🚫",
                message=f"#{order.id} buyurtma: belgilangan vaqtda kelmaganingiz uchun bekor qilindi.",
            )

            # Navbatni surish (tezkor navbat uchun)
            from app.services.order_service import OrderService
            await OrderService.shift_flexible_queue(db, order.provider_id)

            return {"action": "no_show", "status": "no_show"}

        return {"action": "waiting", "status": order.status.value}

    @staticmethod
    async def get_checkin_status(db: AsyncSession, order_id: int) -> dict:
        """Buyurtmaning checkin holatini qaytarish."""
        checkins = (
            await db.execute(
                select(OrderCheckin).where(OrderCheckin.order_id == order_id)
            )
        ).scalars().all()

        user_checkin = next(
            (c for c in checkins if c.side == CheckinSide.user), None
        )
        provider_checkin = next(
            (c for c in checkins if c.side == CheckinSide.provider), None
        )

        return {
            "order_id": order_id,
            "user": user_checkin.to_dict() if user_checkin else None,
            "provider": provider_checkin.to_dict() if provider_checkin else None,
            "resolved": user_checkin is not None and provider_checkin is not None,
        }

    @staticmethod
    async def auto_noshow_check(db: AsyncSession) -> int:
        """
        Cron: Vaqti o'tgan va hech kim javob bermagan buyurtmalarni no_show qilish.
        20 daqiqadan keyin avtomatik ishga tushadi.
        """
        from datetime import timedelta

        # Order.date ustuni tz-siz (naive) saqlanadi — solishtirish uchun naive UTC ishlatamiz
        now = datetime.now(timezone.utc).replace(tzinfo=None)
        cutoff = now - timedelta(minutes=20)

        # Tasdiqlangan lekin vaqti o'tgan buyurtmalar
        q = (
            select(Order)
            .where(
                Order.status == OrderStatus.confirmed,
                Order.date <= cutoff,
            )
        )
        overdue_orders = (await db.execute(q)).scalars().all()

        count = 0
        for order in overdue_orders:
            # Allaqachon checkin bormi?
            checkins = (
                await db.execute(
                    select(OrderCheckin).where(OrderCheckin.order_id == order.id)
                )
            ).scalars().all()

            user_arrived = any(
                c.side == CheckinSide.user and c.response == CheckinResponse.arrived
                for c in checkins
            )
            provider_arrived = any(
                c.side == CheckinSide.provider and c.response == CheckinResponse.arrived
                for c in checkins
            )

            # Agar birontasi arrived degan bo'lsa — auto noshow qilmaymiz
            if user_arrived or provider_arrived:
                continue

            # Delayed bo'lsa — +10 daqiqa kutamiz
            user_delayed = any(
                c.side == CheckinSide.user and c.response == CheckinResponse.delayed
                for c in checkins
            )
            if user_delayed:
                extended_cutoff = now - timedelta(minutes=30)
                if order.date > extended_cutoff:
                    continue

            order.status = OrderStatus.no_show
            count += 1

            await CheckinService._increment_fraud_stat(
                db, order.provider_id, "no_show"
            )

            NotificationService.send_notification(
                user_id=order.user_id,
                ntype="auto_noshow",
                title="Buyurtma avtomatik bekor qilindi 🚫",
                message=(
                    f"#{order.id} buyurtma: belgilangan vaqtdan 20 daqiqa "
                    f"o'tdi, hech kim javob bermadi."
                ),
            )

            from app.services.order_service import OrderService
            await OrderService.shift_flexible_queue(db, order.provider_id)

        if count > 0:
            await db.flush()
            logger.info("Auto no-show: %d ta buyurtma bekor qilindi", count)

        return count

    @staticmethod
    async def _increment_fraud_stat(
        db: AsyncSession,
        provider_id: int,
        stat_type: str,  # "no_show" | "disputed"
    ) -> None:
        """Provider fraud statistikasini yangilash."""
        now = datetime.now(timezone.utc)
        month_key = now.strftime("%Y-%m")

        stat = (
            await db.execute(
                select(ProviderFraudStats).where(
                    ProviderFraudStats.provider_id == provider_id,
                    ProviderFraudStats.month == month_key,
                )
            )
        ).scalar_one_or_none()

        if not stat:
            stat = ProviderFraudStats(
                provider_id=provider_id,
                month=month_key,
                total_orders=0,
                no_show_count=0,
                disputed_count=0,
                flexible_skip_pattern=0,
                flag_level=FraudFlagLevel.normal,
            )
            db.add(stat)
            await db.flush()

        if stat_type == "no_show":
            stat.no_show_count += 1
        elif stat_type == "disputed":
            stat.disputed_count += 1

        # Flag level ni yangilash
        if stat.disputed_count >= 3:
            stat.flag_level = FraudFlagLevel.review
            from app.models.provider import Provider
            provider = await db.get(Provider, provider_id)
            # Xabar HAQIQATNI aytadi: profil to'xtatilmaydi, tekshiruvga
            # olinadi. Ilgari "Faoliyat to'xtatildi" deb yozilardi, lekin
            # hech narsa to'xtamasdi — provayder ishlab yuraverardi.
            if provider and provider.owner_user_id:
                NotificationService.send_notification(
                    user_id=provider.owner_user_id,
                    ntype="fraud_review",
                    title="⚠️ Profilingiz tekshiruvga olindi",
                    message=(
                        f"Ushbu oyda {stat.disputed_count} ta nizoli holat aniqlandi "
                        f"(mijoz va siz turlicha javob bergansiz). Administrator "
                        f"tekshirib chiqadi. Hozircha ishlashda davom etishingiz mumkin."
                    ),
                )
            # Admin HAM xabardor bo'lishi kerak — aks holda "tekshiruv"
            # hech kim ko'rmaydigan bayroq bo'lib qolardi.
            NotificationService.send_notification(
                user_id=1,
                ntype="fraud_review",
                title="⚠️ Provayder tekshiruvga olindi",
                message=(
                    f"Provider #{provider_id}: oyda {stat.disputed_count} ta "
                    f"nizoli holat. Ko'rib chiqing."
                ),
            )
        elif stat.no_show_count >= 10:
            stat.flag_level = FraudFlagLevel.alert
            NotificationService.send_notification(
                user_id=1,  # Admin
                ntype="fraud_alert",
                title="🔴 Fraud Alert",
                message=f"Provider #{provider_id}: oyda {stat.no_show_count} ta no_show.",
            )
        elif stat.no_show_count >= 5:
            stat.flag_level = FraudFlagLevel.warning
            from app.models.provider import Provider
            provider = await db.get(Provider, provider_id)
            if provider and provider.owner_user_id:
                NotificationService.send_notification(
                    user_id=provider.owner_user_id,
                    ntype="fraud_warning",
                    title="⚠️ Ogohlantirish",
                    message=(
                        f"Ushbu oyda {stat.no_show_count} ta mijoz kelmadi deb belgilangandi. "
                        f"Ko'p takrorlansa profilingiz tekshiruvga tushadi."
                    ),
                )

        stat.updated_at = now
        await db.flush()


class CheckinScheduler:
    """Checkin eslatmalari uchun cron scheduler."""

    @staticmethod
    async def send_checkin_prompts(db: AsyncSession) -> int:
        """
        Vaqti yaqinlashgan buyurtmalarga checkin so'rovi yuborish.
        5 daqiqadan keyin checkin so'rovi, 15 daqiqadan keyin ogohlantirish.
        """
        from datetime import timedelta
        from sqlalchemy.orm import selectinload

        # Order.date ustuni tz-siz (naive) saqlanadi — solishtirish uchun naive UTC ishlatamiz
        now = datetime.now(timezone.utc).replace(tzinfo=None)

        # Vaqti 5 daqiqa oldin o'tgan va hali checkin qilinmagan buyurtmalar
        window_start = now - timedelta(minutes=6)
        window_end = now - timedelta(minutes=4)

        q = (
            select(Order)
            .options(selectinload(Order.provider))
            .where(
                Order.status == OrderStatus.confirmed,
                Order.date >= window_start,
                Order.date <= window_end,
            )
        )
        orders_needing_prompt = (await db.execute(q)).scalars().all()
        count = 0

        for order in orders_needing_prompt:
            # Allaqachon checkin bormi?
            checkins = (
                await db.execute(
                    select(OrderCheckin).where(OrderCheckin.order_id == order.id)
                )
            ).scalars().all()

            if checkins:
                continue  # Allaqachon javob berilgan

            # Mijozga so'rov
            NotificationService.send_notification(
                user_id=order.user_id,
                ntype="checkin_prompt",
                title="Yetib keldingizmi? 📍",
                message=(
                    f"#{order.id} buyurtma vaqti keldi. "
                    f"Yetib keldingizmi? Ilovadan javob bering."
                ),
            )

            # Provider ga so'rov
            if order.provider and order.provider.owner_user_id:
                category_key = order.category_key if hasattr(order, "category_key") else ""
                group = _get_group(category_key)

                if group == "A":
                    msg = f"#{order.id} buyurtma: Mijoz keldimi? Ilovadan javob bering."
                else:
                    msg = f"#{order.id} buyurtma: Yetib keldingizmi? Ilovadan javob bering."

                NotificationService.send_notification(
                    user_id=order.provider.owner_user_id,
                    ntype="checkin_prompt",
                    title="Tasdiqlash kerak 📍",
                    message=msg,
                )

            count += 1

        # 15 daqiqa o'tgan — ogohlantirish
        warn_start = now - timedelta(minutes=16)
        warn_end = now - timedelta(minutes=14)

        q_warn = (
            select(Order)
            .where(
                Order.status == OrderStatus.confirmed,
                Order.date >= warn_start,
                Order.date <= warn_end,
            )
        )
        warn_orders = (await db.execute(q_warn)).scalars().all()

        for order in warn_orders:
            checkins = (
                await db.execute(
                    select(OrderCheckin).where(OrderCheckin.order_id == order.id)
                )
            ).scalars().all()

            user_arrived = any(
                c.side == CheckinSide.user and c.response == CheckinResponse.arrived
                for c in checkins
            )
            if user_arrived:
                continue

            NotificationService.send_notification(
                user_id=order.user_id,
                ntype="noshow_warning",
                title="⚠️ Navbat bekor bo'lish arafasida!",
                message=(
                    f"#{order.id} buyurtma: 5 daqiqa ichida javob bermasangiz, "
                    f"navbatingiz avtomatik bekor qilinadi."
                ),
            )
            count += 1

        return count
