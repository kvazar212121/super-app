import asyncio
import logging
import time
import traceback
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from sqlalchemy import select, text, func
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.responses import Response

from app.api.v1.router import api_router
from app.api.v1.admin_panel import router as admin_panel_router
from app.core.config import settings
from app.core.limiter import limiter
from app.core.logging_config import (
    setup_logging,
    request_id_filter,
    get_request_id,
)
from app.core.security import hash_password
from app.db.base import Base
from app.db.session import async_session, engine
from app.models.user import User
from app.models.promo import Promo

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Rate-limit oshib ketganda qaytariladigan javob
# ---------------------------------------------------------------------------
async def _rate_limit_exceeded_handler(request: Request, exc: RateLimitExceeded) -> JSONResponse:
    """Rate-limit oshib ketganda JSON javob qaytaradi."""
    logger.warning(
        "Rate-limit oshib ketdi: IP=%s path=%s",
        request.client.host if request.client else "unknown",
        request.url.path,
    )
    return JSONResponse(
        status_code=429,
        content={
            "detail": "Rate-limit oshib ketdi. Biroz kuting va qayta urinib ko'ring.",
        },
        headers={
            "Retry-After": str(exc.retry_after) if exc.retry_after else "60",
        },
    )


# ---------------------------------------------------------------------------
# So'rovlarni loglash middleware
# ---------------------------------------------------------------------------
class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """Har bir HTTP so'rovni log qiladi va request ID qo'shadi."""

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        # Request ID yaratish yoki mavjudini olish
        request_id = request.headers.get("X-Request-ID", get_request_id())
        request_id_filter.set_request_id(request_id)

        # Boshlash vaqti
        start_time = time.perf_counter()

        # So'rovni log qilish
        logger.info(
            "So'rov boshlandi: %s %s",
            request.method,
            request.url.path,
        )

        try:
            # Javobni olish
            response = await call_next(request)

            # Vaqtni hisoblash
            duration_ms = (time.perf_counter() - start_time) * 1000

            # Javobda request ID qo'shish
            response.headers["X-Request-ID"] = request_id

            # Rate-limit headerlarini qo'shish (agar mavjud bo'lsa)
            if hasattr(request.state, "view_rate_limit"):
                limit_info = request.state.view_rate_limit
                if isinstance(limit_info, dict):
                    response.headers["X-RateLimit-Limit"] = str(limit_info.get("limit", ""))
                    response.headers["X-RateLimit-Remaining"] = str(limit_info.get("remaining", ""))
                    response.headers["X-RateLimit-Reset"] = str(limit_info.get("reset", ""))

            # Javobni log qilish
            logger.info(
                "Javob: %s %s -> %d | %.1fms",
                request.method,
                request.url.path,
                response.status_code,
                duration_ms,
            )

            return response

        except Exception as exc:
            # Xatolikni log qilish
            duration_ms = (time.perf_counter() - start_time) * 1000
            logger.error(
                "Xatolik: %s %s -> 500 | %.1fms | %s\n%s",
                request.method,
                request.url.path,
                duration_ms,
                str(exc),
                traceback.format_exc(),
            )
            return JSONResponse(
                status_code=500,
                content={"detail": "Ichki server xatoligi."},
                headers={"X-Request-ID": request_id},
            )


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
                
                for u in users:
                    from app.services.notification_service import _notification_store
                    user_notifs = _notification_store.get(u.id, [])
                    recent_ai_notifs = [
                        n for n in user_notifs 
                        if n.type == "ai_spending_advice" and (now - n.created_at).days < 7
                    ]
                    
                    if not recent_ai_notifs:
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
            if days_ahead <= 0: # Target day already happened this week
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
            await asyncio.sleep(3600) # xato bo'lsa 1 soat kutish


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Loggingni sozlash
    setup_logging()
    root_logger = logging.getLogger()
    root_logger.addFilter(request_id_filter)

    # Create tables + yangi ustunlar
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        await conn.execute(text(
            "ALTER TABLE providers ADD COLUMN IF NOT EXISTS owner_user_id INTEGER REFERENCES users(id)"
        ))
        await conn.execute(text(
            "CREATE INDEX IF NOT EXISTS ix_providers_owner_user_id ON providers (owner_user_id)"
        ))
        await conn.execute(text(
            "ALTER TABLE plans ADD COLUMN IF NOT EXISTS is_notified BOOLEAN DEFAULT FALSE"
        ))
        await conn.execute(text(
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS reminder_offset_minutes INTEGER DEFAULT 10"
        ))
        await conn.execute(text(
            "ALTER TABLE orders ADD COLUMN IF NOT EXISTS booking_mode VARCHAR(50) DEFAULT 'fixed'"
        ))
        # Shopping list new columns
        await conn.execute(text(
            "ALTER TABLE shopping_lists ADD COLUMN IF NOT EXISTS name VARCHAR(255) DEFAULT 'Bozorlik'"
        ))
        await conn.execute(text(
            "ALTER TABLE shopping_lists ADD COLUMN IF NOT EXISTS total_actual_price FLOAT DEFAULT 0.0"
        ))
        await conn.execute(text(
            "ALTER TABLE shopping_lists ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT FALSE"
        ))
        # Provider yangi ustunlari
        await conn.execute(text(
            "ALTER TABLE providers ADD COLUMN IF NOT EXISTS is_paused BOOLEAN DEFAULT FALSE"
        ))

    # Seed admin user & default promos
    async with async_session() as db:
        result = await db.execute(
            select(User).where(User.phone == settings.admin_default_phone)
        )
        if not result.scalar_one_or_none():
            admin = User(
                name="Admin",
                surname="SuperApp",
                phone=settings.admin_default_phone,
                hashed_password=hash_password(settings.admin_default_password),
                is_admin=True,
                is_active=True,
            )
            db.add(admin)
            await db.commit()

        # Seed default promos if empty
        promo_count = (await db.execute(select(func.count(Promo.id)))).scalar() or 0
        if promo_count == 0:
            default_promos = [
                Promo(
                    title="Sartarosh — 25% chegirma",
                    subtitle="Dushanba–chorshanba, barcha xizmatlar",
                    badge="-25%",
                    colors="#6366F1,#A855F7"
                ),
                Promo(
                    title="Tozalash — birinchi buyurtma",
                    subtitle="30% gacha chegirma, kod: TOZA30",
                    badge="AKSIYA",
                    colors="#0D9488,#06B6D4"
                ),
                Promo(
                    title="Avto-yordam tungi tarif",
                    subtitle="Evakuator 20% arzonroq 22:00 dan keyin",
                    badge="-20%",
                    colors="#EA580C,#F59E0B"
                )
            ]
            db.add_all(default_promos)
            await db.commit()
            
    # Start the background tasks
    reminder_task = asyncio.create_task(plan_reminder_scheduler())
    finance_task = asyncio.create_task(finance_reminder_scheduler())
    checkin_task = asyncio.create_task(checkin_scheduler())
    completion_task = asyncio.create_task(order_completion_scheduler())
    scraper_task = asyncio.create_task(market_scraper_scheduler())
    
    yield
    
    # Cancel the background tasks
    reminder_task.cancel()
    finance_task.cancel()
    checkin_task.cancel()
    completion_task.cancel()
    scraper_task.cancel()
    try:
        await reminder_task
    except asyncio.CancelledError:
        pass
    try:
        await finance_task
    except asyncio.CancelledError:
        pass
    try:
        await checkin_task
    except asyncio.CancelledError:
        pass
    try:
        await completion_task
    except asyncio.CancelledError:
        pass
    try:
        await scraper_task
    except asyncio.CancelledError:
        pass
        
    await engine.dispose()


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        openapi_url=f"{settings.api_v1_prefix}/openapi.json",
        lifespan=lifespan,
    )

    # Rate-limiter
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
    app.add_middleware(SlowAPIMiddleware)

    # So'rovlarni loglash middleware
    app.add_middleware(RequestLoggingMiddleware)

    LANDING_HTML = Path(__file__).resolve().parent / "static" / "landing" / "index.html"
    PRIVACY_HTML = Path(__file__).resolve().parent / "static" / "landing" / "privacy.html"

    @app.get("/")
    async def root():
        if LANDING_HTML.is_file():
            return FileResponse(LANDING_HTML, media_type="text/html")
        return {
            "name": settings.app_name,
            "docs": "/docs",
            "health": f"{settings.api_v1_prefix}/health",
        }

    @app.get("/privacy", include_in_schema=False)
    async def privacy_policy():
        """Maxfiylik siyosati (Google Play uchun ham talab qilinadi)."""
        if PRIVACY_HTML.is_file():
            return FileResponse(PRIVACY_HTML, media_type="text/html")
        return JSONResponse(status_code=404, content={"detail": "Sahifa topilmadi"})

    # CORS
    if settings.cors_allow_all:
        origins = ["*"]
    else:
        origins = [o.strip() for o in settings.cors_origins.split(",") if o.strip()]
        if not origins:
            origins = ["http://localhost:3000"]

    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Static files for uploads
    upload_dir = Path(settings.upload_dir)
    upload_dir.mkdir(exist_ok=True)
    app.mount(
        "/uploads",
        StaticFiles(directory=str(upload_dir)),
        name="uploads",
    )

    # Static files for admin panel
    admin_static_dir = Path(__file__).resolve().parent / "static" / "admin"
    app.mount(
        "/admin-assets",
        StaticFiles(directory=str(admin_static_dir)),
        name="admin_static",
    )

    # General static files (favicon etc.)
    static_dir = Path(__file__).resolve().parent / "static"
    if static_dir.is_dir():
        app.mount(
            "/static",
            StaticFiles(directory=str(static_dir)),
            name="static_root",
        )

    # Favicon routes
    @app.get("/favicon.ico", include_in_schema=False)
    async def favicon_ico():
        ico = static_dir / "favicon.ico"
        png = static_dir / "favicon.png"
        if ico.is_file():
            return FileResponse(ico, media_type="image/x-icon")
        if png.is_file():
            return FileResponse(png, media_type="image/png")
        return JSONResponse({"detail": "not found"}, status_code=404)

    @app.get("/favicon.png", include_in_schema=False)
    async def favicon_png():
        png = static_dir / "favicon.png"
        if png.is_file():
            return FileResponse(png, media_type="image/png")
        return JSONResponse({"detail": "not found"}, status_code=404)

    app.include_router(api_router, prefix=settings.api_v1_prefix)
    app.include_router(admin_panel_router)
    return app


app = create_app()