"""RBAC — bo'lim darajasidagi ruxsatlar va audit.

Har admin bo'limга (users, orders, finance...) `view`/`edit` ruxsatiga ega bo'lishi mumkin.
super_admin barcha ruxsatga ega. section_guard(section) — router-darajali dependency:
ruxsatни tekshiradi va yozuv (edit) amallarini audit jurnaliga yozadi.
"""
from fastapi import Depends, HTTPException, Request
from sqlalchemy.ext.asyncio import AsyncSession

import logging

from app.api.dependencies import get_current_user
from app.db.session import get_db, async_session
from app.models.user import User
from app.models.admin_role import AdminRole, AuditLog

logger = logging.getLogger(__name__)

# Boshqarilishi mumkin bo'lgan bo'limlar (rol tahrirlagichда ko'rsatiladi)
SECTIONS = [
    ("dashboard", "Bosh sahifa"),
    ("users", "Foydalanuvchilar"),
    ("providers", "Provayderlar"),
    ("orders", "Buyurtmalar"),
    ("finance", "Moliya"),
    ("categories", "Kategoriyalar"),
    ("reviews", "Sharhlar"),
    ("promos", "Aksiyalar"),
    ("products", "Mahsulotlar"),
    ("notifications", "Bildirishnomalar"),
    ("support", "Qo'llab-quvvatlash"),
    ("reports", "Hisobotlar"),
    ("settings", "Sozlamalar (AI, bo'limlar, shartlar)"),
    ("premium", "Premium obuna"),
    ("admins", "Adminlar va rollar"),
]
SECTION_KEYS = [s for s, _ in SECTIONS]
ACTIONS = ["view", "edit"]


async def load_permissions(db: AsyncSession, user: User) -> dict:
    """Adminning amaldagi ruxsatlari (super_admin — hammasi)."""
    if user.is_super_admin:
        return {s: list(ACTIONS) for s in SECTION_KEYS}
    if not user.admin_role_id:
        return {}
    role = await db.get(AdminRole, user.admin_role_id)
    return (role.permissions if role and role.permissions else {})


def _method_action(method: str) -> str:
    return "view" if method.upper() in ("GET", "HEAD", "OPTIONS") else "edit"


def section_guard(section: str):
    """Berilgan bo'lim uchun ruxsatни tekshiruvchi router dependency.

    Ruxsat endpointдан OLDIN tekshiriladi. Yozuv (edit) amallari audit jurnaliga
    faqat endpoint MUVAFFAQIYATLI tugagach yoziladi. Buning uchun bu dependency
    `yield` bilan ishlaydi: FastAPI endpoint xatosini generatorga qaytaradi, shунда
    biz muvaffaqiyat/xatolikni ajratamiz. Audit alohida (mustaqil) sessiyada yoziladi,
    shунday qilib u endpointning ichki commit/rollback'iга bog'lanmaydi.
    """

    async def _guard(
        request: Request,
        current_user: User = Depends(get_current_user),
        db: AsyncSession = Depends(get_db),
    ):
        if not current_user.is_admin:
            raise HTTPException(status_code=403, detail="Faqat admin uchun ruxsat")

        action = _method_action(request.method)

        if not current_user.is_super_admin:
            perms = await load_permissions(db, current_user)
            if action not in perms.get(section, []):
                raise HTTPException(
                    status_code=403,
                    detail=f"Ruxsat yo'q: '{section}' bo'limi uchun {action} huquqi berilmagan",
                )

        # View (GET/HEAD/OPTIONS) audit qilinmaydi — teardown'siz qaytamiz
        if action != "edit":
            yield current_user
            return

        admin_id = current_user.id
        admin_name = f"{current_user.name} {current_user.surname}".strip()
        http_method = request.method.upper()
        path = str(request.url.path)

        endpoint_failed = False
        try:
            # Endpoint shu yerда ishga tushadi. Xato bo'lsa FastAPI uni bu generatorга qaytaradi.
            yield current_user
        except Exception:
            endpoint_failed = True
            raise
        finally:
            # Faqat endpoint xatosiz tugaganda audit yozuvини saqlaymiz.
            if not endpoint_failed:
                try:
                    async with async_session() as audit_db:
                        audit_db.add(AuditLog(
                            admin_user_id=admin_id,
                            admin_name=admin_name,
                            section=section,
                            action=http_method,
                            path=path,
                        ))
                        await audit_db.commit()
                except Exception as exc:
                    logger.error("Audit yozuvида xatolik: %s", exc)

    return _guard
