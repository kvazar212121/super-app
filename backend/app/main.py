import logging
import time
import traceback
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from sqlalchemy import select
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


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Loggingni sozlash
    setup_logging()
    root_logger = logging.getLogger()
    root_logger.addFilter(request_id_filter)

    # Create tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Seed admin user
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
    yield
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

    @app.get("/")
    async def root():
        return {
            "name": settings.app_name,
            "docs": "/docs",
            "health": f"{settings.api_v1_prefix}/health",
        }

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

    app.include_router(api_router, prefix=settings.api_v1_prefix)
    app.include_router(admin_panel_router)
    return app


app = create_app()