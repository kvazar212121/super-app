from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select

from app.api.v1.router import api_router
from app.api.v1.admin_panel import router as admin_panel_router
from app.core.config import settings
from app.core.security import hash_password
from app.db.base import Base
from app.db.session import async_session, engine
from app.models.user import User


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Create tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    # Seed admin user
    async with async_session() as db:
        result = await db.execute(select(User).where(User.phone == "admin"))
        if not result.scalar_one_or_none():
            admin = User(
                name="Admin",
                surname="SuperApp",
                phone="admin",
                hashed_password=hash_password("admin123"),
                is_admin=True,
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

    @app.get("/")
    async def root():
        return {
            "name": settings.app_name,
            "docs": "/docs",
            "health": f"{settings.api_v1_prefix}/health",
        }

    origins = [o.strip() for o in settings.cors_origins.split(",") if o.strip()]
    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins or ["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(api_router, prefix=settings.api_v1_prefix)
    app.include_router(admin_panel_router)
    return app


app = create_app()