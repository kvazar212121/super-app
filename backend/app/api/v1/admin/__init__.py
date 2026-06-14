from fastapi import APIRouter
from app.api.v1.admin import (
    dashboard,
    users,
    providers,
    orders,
    categories,
    reviews,
    finance,
    settings,
    promos,
    notifications,
    reports
)

router = APIRouter(prefix="/admin", tags=["admin"])

router.include_router(dashboard.router)
router.include_router(users.router)
router.include_router(providers.router)
router.include_router(orders.router)
router.include_router(categories.router)
router.include_router(reviews.router)
router.include_router(finance.router)
router.include_router(settings.router)
router.include_router(promos.router)
router.include_router(notifications.router)
router.include_router(reports.router)
