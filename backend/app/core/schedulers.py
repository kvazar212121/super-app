"""Fon (background) schedulerlar.

Barcha davriy vazifalar shu yerda. `scheduler_supervisor` Redis-lock 'leader'
saylovi orqali ko'p workerда FAQAT bittasида ishlashini ta'minlaydi.
"""
import asyncio
import logging

from sqlalchemy import select

from app.db.session import async_session

logger = logging.getLogger(__name__)


async def plan_reminder_scheduler():
    logger.info("Plan reminder scheduler starting...")
    while True:
        try:
            await asyncio.sleep(15)  # Check every 15 seconds
            from datetime import datetime, timezone, timedelta
            now = datetime.now(timezone.utc)

            async with async_session() as db:
                from app.models.plan import Plan
                from app.models.user import User
                from app.services.notification_service import NotificationService

                stmt = select(Plan, User).join(User, Plan.user_id == User.id).where(
                    Plan.is_completed == False,
                    Plan.is_notified == False
                )
                result = await db.execute(stmt)
                rows = result.all()

                if rows:
                    for plan, user in rows:
                        offset = getattr(user, "reminder_offset_minutes", 10)
                        reminder_time = plan.due_date - timedelta(minutes=offset)
                        if reminder_time <= now:
                            NotificationService.send_notification(
                                user_id=plan.user_id,
                                ntype="plan_reminder",
                                title="Reja eslatmasi ⏰",
                                message=f"Siz shu soatda shuni qilishingiz kerak edi: {plan.title}",
                            )
                            plan.is_notified = True
                    await db.commit()
        except asyncio.CancelledError:
            logger.info("Plan reminder scheduler cancelled.")
            break
        except Exception as e:
            logger.error(f"Error in plan reminder scheduler: {e}")


async def finance_reminder_scheduler():
    logger.info("Finance reminder and AI advisor scheduler starting...")
    while True:
        try:
            await asyncio.sleep(30)  # Check every 30 seconds
            from datetime import datetime, timezone, timedelta
            now = datetime.now(timezone.utc)
            tomorrow = now + timedelta(days=1)

            async with async_session() as db:
                from app.models.planned_payment import PlannedPayment
                from app.models.finance_record import FinanceRecord
                from app.services.notification_service import NotificationService
                from app.models.user import User

                # 1. Planned Payment Reminders
                stmt = select(PlannedPayment).where(
                    PlannedPayment.is_paid == False,
                    PlannedPayment.is_notified == False,
                    PlannedPayment.due_date <= tomorrow
                )
                result = await db.execute(stmt)
                payments = result.scalars().all()

                if payments:
                    logger.info(f"Finance scheduler found {len(payments)} planned payments to notify.")
                    for p in payments:
                        due_time_str = p.due_date.astimezone().strftime("%d-%B %H:%M")
                        amt_str = f"{int(p.amount):,}".replace(",", " ")

                        NotificationService.send_notification(
                            user_id=p.user_id,
                            ntype="planned_payment_reminder",
                            title="To'lov eslatmasi 💸",
                            message=f"Siz yaqin orada (muddat: {due_time_str}) '{p.title}' to'lovini amalga oshirishingiz kerak. Summa: {amt_str} UZS.",
                        )
                        p.is_notified = True
                    await db.commit()

                # 2. AI Spending Advice
                user_stmt = select(User).where(User.is_active == True)
                user_res = await db.execute(user_stmt)
                users = user_res.scalars().all()

                from app.models.notification import Notification as NotificationModel
                from datetime import timedelta
                week_ago = now - timedelta(days=7)
                for u in users:
                    recent_res = await db.execute(
                        select(NotificationModel.id).where(
                            NotificationModel.user_id == u.id,
                            NotificationModel.type == "ai_spending_advice",
                            NotificationModel.created_at >= week_ago,
                        ).limit(1)
                    )
                    has_recent = recent_res.first() is not None

                    if not has_recent:
                        start_of_month = datetime(now.year, now.month, 1, tzinfo=timezone.utc)
                        records_stmt = select(FinanceRecord).where(
                            FinanceRecord.user_id == u.id,
                            FinanceRecord.date >= start_of_month
                        )
                        records_res = await db.execute(records_stmt)
                        records = records_res.scalars().all()

                        total_income = 0.0
                        total_expense = 0.0
                        category_totals = {}

                        for r in records:
                            if r.type == "income":
                                total_income += r.amount
                            elif r.type == "expense":
                                total_expense += r.amount
                                category_totals[r.category] = category_totals.get(r.category, 0.0) + r.amount

                        if total_expense > 50000:
                            advice_msg = None

                            if total_expense > total_income and total_income > 0:
                                advice_msg = (
                                    f"Diqqat! Ushbu oyda xarajatlaringiz daromadingizdan oshib ketdi. "
                                    f"Tejashni boshlash tavsiya etiladi. Jami xarajat: {int(total_expense):,} UZS, "
                                    f"Daromad: {int(total_income):,} UZS."
                                ).replace(",", " ")
                            elif total_income > 0 and (total_expense / total_income) > 0.8:
                                advice_msg = (
                                    f"Ehtiyot bo'ling! Xarajatlaringiz daromadingizning 80% idan oshib ketdi. "
                                    f"Budjetingizni qayta ko'rib chiqing. Jami xarajat: {int(total_expense):,} UZS."
                                ).replace(",", " ")
                            elif category_totals:
                                max_cat = max(category_totals, key=category_totals.get)
                                max_amt = category_totals[max_cat]
                                pct = (max_amt / total_expense) * 100
                                if pct > 40:
                                    advice_msg = (
                                        f"Siz eng ko'p mablag'ni '{max_cat}' toifasiga sarflayapsiz. "
                                        f"Bu oylik xarajatlaringizning {pct:.1f}% qismini tashkil qilmoqda. "
                                        f"Kafe va restoranlar yoki shaxsiy xaridlarni biroz qisqartirishni maslahat beramiz."
                                    )

                            if advice_msg:
                                NotificationService.send_notification(
                                    user_id=u.id,
                                    ntype="ai_spending_advice",
                                    title="Aqlli AI Maslahatchi 🧠",
                                    message=advice_msg,
                                )
                                logger.info(f"Sent AI spending advice to user {u.id}")

        except asyncio.CancelledError:
            logger.info("Finance reminder scheduler cancelled.")
            break
        except Exception as e:
            logger.error(f"Error in finance reminder scheduler: {e}")


async def checkin_scheduler():
    """Checkin eslatmalari va auto-noshow uchun cron scheduler."""
    logger.info("Checkin scheduler starting...")
    while True:
        try:
            await asyncio.sleep(15)  # Har 15 sekundda tekshirish

            async with async_session() as db:
                from app.services.checkin_service import CheckinService, CheckinScheduler

                # 1. Checkin so'rovlari yuborish (vaqti yaqinlashganlarga)
                prompt_count = await CheckinScheduler.send_checkin_prompts(db)

                # 2. Auto no-show tekshiruvi (20 daqiqa o'tganlarga)
                noshow_count = await CheckinService.auto_noshow_check(db)

                await db.commit()

                if prompt_count > 0 or noshow_count > 0:
                    logger.info(
                        "Checkin scheduler: %d prompts, %d auto-noshow",
                        prompt_count, noshow_count,
                    )
        except asyncio.CancelledError:
            logger.info("Checkin scheduler cancelled.")
            break
        except Exception as e:
            logger.error(f"Error in checkin scheduler: {e}")


async def order_completion_scheduler():
    """Ikki tomonlama tasdiqlash uchun eslatmalar va avto-yakunlash"""
    logger.info("Order completion scheduler starting...")
    while True:
        try:
            await asyncio.sleep(60 * 5)  # Har 5 daqiqada tekshiradi

            async with async_session() as db:
                from app.services.order_service import OrderService
                await OrderService.run_completion_checks(db)
        except asyncio.CancelledError:
            logger.info("Order completion scheduler cancelled.")
            break
        except Exception as e:
            logger.error(f"Error in order completion scheduler: {e}")


async def market_scraper_scheduler():
    """Bozor narxlarini har haftada avtomatik yangilash"""
    logger.info("Market scraper scheduler starting...")
    while True:
        try:
            # Haftada bir marta Dushanba kuni soat 03:00 da ishlash
            from datetime import datetime, timezone, timedelta
            now = datetime.now(timezone.utc)
            # Find next Monday 03:00 UTC
            days_ahead = 0 - now.weekday()
            if days_ahead <= 0:  # Target day already happened this week
                days_ahead += 7
            next_run = now + timedelta(days=days_ahead)
            next_run = next_run.replace(hour=3, minute=0, second=0, microsecond=0)

            # Agar hozirgi vaqt 03:00 dan oldin va dushanba bo'lsa, bugun ishlaydi
            if now.weekday() == 0 and now.hour < 3:
                next_run = now.replace(hour=3, minute=0, second=0, microsecond=0)

            sleep_seconds = (next_run - now).total_seconds()
            logger.info(f"Next market scraping scheduled in {sleep_seconds} seconds (at {next_run})")

            await asyncio.sleep(sleep_seconds)

            logger.info("Running scheduled market scraper...")
            async with async_session() as db:
                from app.services.scraper_service import ScraperService
                await ScraperService.run_scraper(db)

        except asyncio.CancelledError:
            logger.info("Market scraper scheduler cancelled.")
            break
        except Exception as e:
            logger.error(f"Error in market scraper scheduler: {e}")
            await asyncio.sleep(3600)  # xato bo'lsa 1 soat kutish


async def retention_scheduler():
    """Saqlash limiti: eski bildirishnomalarni serverdan tozalash (1 oy).

    Bildirishnomalar mijoz qurilmasida ko'rinadi; serverда 30 kundan ortiq
    saqlanmaydi. Har 24 soatda bir marta ishlaydi.
    """
    from sqlalchemy import text
    logger.info("Retention scheduler starting...")
    while True:
        try:
            async with async_session() as db:
                res = await db.execute(text(
                    "DELETE FROM notifications WHERE created_at < NOW() - INTERVAL '30 days'"
                ))
                # Foydalanuvchilararo xabarlar ham serverда 30 kun saqlanadi
                res2 = await db.execute(text(
                    "DELETE FROM direct_messages WHERE created_at < NOW() - INTERVAL '30 days'"
                ))
                await db.commit()
                if res.rowcount:
                    logger.info(f"Retention: {res.rowcount} ta eski bildirishnoma tozalandi (>30 kun)")
                if res2.rowcount:
                    logger.info(f"Retention: {res2.rowcount} ta eski xabar tozalandi (>30 kun)")
            await asyncio.sleep(60 * 60 * 24)  # kuniga bir marta
        except asyncio.CancelledError:
            logger.info("Retention scheduler cancelled.")
            break
        except Exception as e:
            logger.error(f"Error in retention scheduler: {e}")
            await asyncio.sleep(60 * 60)  # xato bo'lsa 1 soat kutib qayta urinadi


async def listing_expiry_scheduler():
    """Muddati tugagan savdo e'lonlarini `expired` qiladi.

    E'lon O'CHIRILMAYDI: egasi "Mening e'lonlarim" dan uzaytirishi
    kerak. Qidiruv baribir muddatni tekshiradi — bu scheduler faqat
    holatni to'g'rilaydi ("Mening e'lonlarim" da kulrang ko'rinsin).
    """
    logger.info("Listing expiry scheduler starting...")
    while True:
        try:
            await asyncio.sleep(60 * 30)  # har yarim soatda
            async with async_session() as db:
                from app.services.marketplace import expire_old
                soni = await expire_old(db)
                if soni:
                    logger.info("Savdo: %d e'lon muddati tugadi", soni)
        except asyncio.CancelledError:
            logger.info("Listing expiry scheduler cancelled.")
            break
        except Exception as e:
            logger.error(f"Error in listing expiry scheduler: {e}")


def _start_scheduler_children():
    """Barcha fon schedulerlarини ishga tushiradi va tasklar ro'yxatini qaytaradi."""
    return [
        asyncio.create_task(plan_reminder_scheduler()),
        asyncio.create_task(finance_reminder_scheduler()),
        asyncio.create_task(checkin_scheduler()),
        asyncio.create_task(order_completion_scheduler()),
        asyncio.create_task(market_scraper_scheduler()),
        asyncio.create_task(retention_scheduler()),
        asyncio.create_task(listing_expiry_scheduler()),
    ]


async def scheduler_supervisor():
    """Redis-lock 'leader' saylovi — ko'p workerда schedulerlar FAQAT bittasида ishlaydi.

    Leader vafot etsa (TTL tugasa), boshqa worker leaderlikni oladi va schedulerlarни boshlaydi.
    Redis bo'lmasa — shu protsessда ishga tushadi (bitta worker deb faraz qilinadi).
    """
    import uuid
    from app.core.call_manager import manager as call_manager

    KEY = "scheduler_leader"
    children = []
    try:
        redis = await call_manager._get_redis()
        if redis is None:
            logger.warning("Schedulers: Redis yo'q — leader saylovsiz shu protsessда ishga tushdi.")
            children = _start_scheduler_children()
            while True:
                await asyncio.sleep(3600)

        me = uuid.uuid4().hex
        # Leaderlikni olguncha kutamiz (30s'da bir urinib)
        while True:
            try:
                got = await redis.set(KEY, me, nx=True, ex=60)
            except Exception:
                got = None
            if got:
                break
            await asyncio.sleep(30)

        logger.info("Scheduler leader saylandi — fon schedulerlari ishga tushdi.")
        children = _start_scheduler_children()

        # Leaderlikni ushlab turish (har 20s'da TTL yangilanadi)
        while True:
            await asyncio.sleep(20)
            try:
                if await redis.get(KEY) == me:
                    await redis.expire(KEY, 60)
                else:
                    await redis.set(KEY, me, ex=60)  # qayta egallaymiz
            except Exception:
                pass
    except asyncio.CancelledError:
        for t in children:
            t.cancel()
        for t in children:
            try:
                await t
            except asyncio.CancelledError:
                pass
        raise
