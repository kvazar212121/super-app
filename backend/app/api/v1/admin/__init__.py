from fastapi import APIRouter, Depends
from app.api.v1.admin import (
    dashboard,
    users,
    providers,
    orders,
    categories,
    reviews,
    complaints,
    finance,
    settings,
    promos,
    campaigns,
    monitoring,
    notifications,
    reports,
    products,
    analytics,
    ai_settings,
    rbac,
    premium,
    support,
)
from app.api.v1.admin.permissions import section_guard

router = APIRouter(prefix="/admin", tags=["admin"])


def _g(section: str):
    return [Depends(section_guard(section))]


# /admin/me va permission-schema — har admin uchun (ruxsat cheklovsiz)
router.include_router(rbac.me_router)

# Har bo'lim o'z ruxsati bilan himoyalanadi (view=GET, edit=yozuv)
router.include_router(dashboard.router, dependencies=_g("dashboard"))
router.include_router(users.router, dependencies=_g("users"))
router.include_router(providers.router, dependencies=_g("providers"))
router.include_router(orders.router, dependencies=_g("orders"))
router.include_router(categories.router, dependencies=_g("categories"))
router.include_router(reviews.router, dependencies=_g("reviews"))
# Shikoyatlar «reviews» huquqi ostida: ikkalasi ham foydalanuvchi
# fikri bilan ishlaydi, alohida rol yaratish ortiqcha.
router.include_router(complaints.router, dependencies=_g("reviews"))
router.include_router(finance.router, dependencies=_g("finance"))
router.include_router(settings.router, dependencies=_g("settings"))
router.include_router(promos.router, dependencies=_g("promos"))
# Sovrinli sezonli reyting — "promos" ruxsati ostida (ikkalasi ham aksiya)
router.include_router(campaigns.router, dependencies=_g("promos"))
# Monitoring: firibgarlik, ish e'lonlari, push qamrovi, faollik
router.include_router(monitoring.router, dependencies=_g("reports"))
router.include_router(notifications.router, dependencies=_g("notifications"))
router.include_router(reports.router, dependencies=_g("reports"))
router.include_router(products.router, dependencies=_g("products"))
router.include_router(analytics.router, dependencies=_g("reports"))
router.include_router(ai_settings.router, dependencies=_g("settings"))
router.include_router(premium.router, dependencies=_g("premium"))
router.include_router(support.router, dependencies=_g("support"))
router.include_router(rbac.router, dependencies=_g("admins"))
