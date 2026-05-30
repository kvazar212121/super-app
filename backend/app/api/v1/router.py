from fastapi import APIRouter

from app.api.v1 import health, auth, users, categories, providers, orders, admin, admin_panel, upload, notifications

api_router = APIRouter()
api_router.include_router(health.router, tags=["health"])
api_router.include_router(auth.router)
api_router.include_router(users.router)
api_router.include_router(categories.router)
api_router.include_router(providers.router)
api_router.include_router(orders.router)
api_router.include_router(admin.router)
api_router.include_router(admin_panel.router)
api_router.include_router(upload.router)
api_router.include_router(notifications.router)
