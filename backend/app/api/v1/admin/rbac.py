"""Admin RBAC API — /admin/me, rollar, adminlar boshqaruvi, audit jurnali."""
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import select, desc
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.core.security import hash_password
from app.models.user import User
from app.models.admin_role import AdminRole, AuditLog
from app.api.v1.admin.dependencies import require_admin
from app.api.v1.admin.permissions import SECTIONS, SECTION_KEYS, ACTIONS, load_permissions

# /admin/me va sxema — har admin uchun (ruxsat tekshirilmaydi, faqat admin bo'lishi kifoya)
me_router = APIRouter()
# rollar/adminlar/audit — section_guard("admins") bilan o'raladi (include vaqtида)
router = APIRouter()


class AdminMeOut(BaseModel):
    id: int
    name: str
    surname: str
    phone: str
    is_super_admin: bool
    role_id: Optional[int] = None
    role_name: Optional[str] = None
    permissions: dict


@me_router.get("/me", response_model=AdminMeOut)
async def admin_me(current: User = Depends(require_admin), db: AsyncSession = Depends(get_db)):
    perms = await load_permissions(db, current)
    role_name = None
    if current.admin_role_id:
        role = await db.get(AdminRole, current.admin_role_id)
        role_name = role.name if role else None
    return AdminMeOut(
        id=current.id, name=current.name, surname=current.surname, phone=current.phone,
        is_super_admin=current.is_super_admin, role_id=current.admin_role_id,
        role_name=role_name, permissions=perms,
    )


@me_router.get("/permission-schema")
async def permission_schema(_: User = Depends(require_admin)):
    return {
        "sections": [{"key": k, "label": lbl} for k, lbl in SECTIONS],
        "actions": ACTIONS,
    }


# ─────────────────────────── ROLLAR ───────────────────────────

class RoleIn(BaseModel):
    name: str = Field(..., min_length=2, max_length=100)
    permissions: dict = Field(default_factory=dict)


class RoleOut(BaseModel):
    id: int
    name: str
    permissions: dict

    class Config:
        from_attributes = True


def _clean_permissions(perms: dict) -> dict:
    """Faqat ma'lum bo'lim va amallarni saqlaydi."""
    out = {}
    for section, actions in (perms or {}).items():
        if section in SECTION_KEYS and isinstance(actions, list):
            allowed = [a for a in actions if a in ACTIONS]
            if allowed:
                out[section] = allowed
    return out


@router.get("/roles", response_model=list[RoleOut])
async def list_roles(db: AsyncSession = Depends(get_db)):
    res = await db.execute(select(AdminRole).order_by(AdminRole.id))
    return res.scalars().all()


@router.post("/roles", response_model=RoleOut, status_code=201)
async def create_role(data: RoleIn, db: AsyncSession = Depends(get_db)):
    exists = (await db.execute(select(AdminRole).where(AdminRole.name == data.name))).scalar_one_or_none()
    if exists:
        raise HTTPException(status_code=400, detail="Bunday nomli rol allaqachon bor")
    role = AdminRole(name=data.name, permissions=_clean_permissions(data.permissions))
    db.add(role)
    await db.commit()
    await db.refresh(role)
    return role


@router.put("/roles/{role_id}", response_model=RoleOut)
async def update_role(role_id: int, data: RoleIn, db: AsyncSession = Depends(get_db)):
    role = await db.get(AdminRole, role_id)
    if not role:
        raise HTTPException(status_code=404, detail="Rol topilmadi")
    role.name = data.name
    role.permissions = _clean_permissions(data.permissions)
    await db.commit()
    await db.refresh(role)
    return role


@router.delete("/roles/{role_id}", status_code=204)
async def delete_role(role_id: int, db: AsyncSession = Depends(get_db)):
    role = await db.get(AdminRole, role_id)
    if not role:
        raise HTTPException(status_code=404, detail="Rol topilmadi")
    await db.delete(role)
    await db.commit()


# ─────────────────────────── ADMINLAR ───────────────────────────

class AdminOut(BaseModel):
    id: int
    name: str
    surname: str
    phone: str
    is_super_admin: bool
    is_active: bool
    role_id: Optional[int] = None
    role_name: Optional[str] = None


class AdminCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    surname: str = Field(default="", max_length=100)
    phone: str = Field(..., min_length=3, max_length=20)
    password: str = Field(..., min_length=4, max_length=100)
    role_id: Optional[int] = None


class AdminUpdate(BaseModel):
    role_id: Optional[int] = None
    is_active: Optional[bool] = None
    is_super_admin: Optional[bool] = None
    password: Optional[str] = Field(default=None, min_length=4, max_length=100)


async def _admin_out(db: AsyncSession, u: User) -> AdminOut:
    role_name = None
    if u.admin_role_id:
        role = await db.get(AdminRole, u.admin_role_id)
        role_name = role.name if role else None
    return AdminOut(
        id=u.id, name=u.name, surname=u.surname, phone=u.phone,
        is_super_admin=u.is_super_admin, is_active=u.is_active,
        role_id=u.admin_role_id, role_name=role_name,
    )


@router.get("/admins", response_model=list[AdminOut])
async def list_admins(db: AsyncSession = Depends(get_db)):
    res = await db.execute(select(User).where(User.is_admin == True).order_by(User.id))
    return [await _admin_out(db, u) for u in res.scalars().all()]


@router.post("/admins", response_model=AdminOut, status_code=201)
async def create_admin(data: AdminCreate, db: AsyncSession = Depends(get_db)):
    exists = (await db.execute(select(User).where(User.phone == data.phone))).scalar_one_or_none()
    if exists:
        raise HTTPException(status_code=400, detail="Bu telefon raqami allaqachon ro'yxatda")
    if data.role_id is not None and not await db.get(AdminRole, data.role_id):
        raise HTTPException(status_code=400, detail="Rol topilmadi")
    admin = User(
        name=data.name, surname=data.surname, phone=data.phone,
        hashed_password=hash_password(data.password),
        is_admin=True, is_active=True, is_super_admin=False,
        admin_role_id=data.role_id,
    )
    db.add(admin)
    await db.commit()
    await db.refresh(admin)
    return await _admin_out(db, admin)


@router.put("/admins/{admin_id}", response_model=AdminOut)
async def update_admin(
    admin_id: int,
    data: AdminUpdate,
    db: AsyncSession = Depends(get_db),
    current: User = Depends(require_admin),
):
    admin = await db.get(User, admin_id)
    if not admin or not admin.is_admin:
        raise HTTPException(status_code=404, detail="Admin topilmadi")

    if data.role_id is not None:
        if data.role_id and not await db.get(AdminRole, data.role_id):
            raise HTTPException(status_code=400, detail="Rol topilmadi")
        admin.admin_role_id = data.role_id or None
    if data.is_active is not None:
        admin.is_active = data.is_active
    if data.password:
        admin.hashed_password = hash_password(data.password)
    # super_admin darajasini faqat super_admin o'zgartira oladi
    if data.is_super_admin is not None:
        if not current.is_super_admin:
            raise HTTPException(status_code=403, detail="Super admin darajasini faqat super admin o'zgartiradi")
        admin.is_super_admin = data.is_super_admin

    await db.commit()
    await db.refresh(admin)
    return await _admin_out(db, admin)


@router.delete("/admins/{admin_id}", status_code=204)
async def revoke_admin(admin_id: int, db: AsyncSession = Depends(get_db), current: User = Depends(require_admin)):
    admin = await db.get(User, admin_id)
    if not admin or not admin.is_admin:
        raise HTTPException(status_code=404, detail="Admin topilmadi")
    if admin.id == current.id:
        raise HTTPException(status_code=400, detail="O'zingizni o'chira olmaysiz")
    if admin.is_super_admin and not current.is_super_admin:
        raise HTTPException(status_code=403, detail="Super adminni faqat super admin o'chiradi")
    # Admin huquqini olib tashlaymiz (foydalanuvchi hisobi qoladi)
    admin.is_admin = False
    admin.is_super_admin = False
    admin.admin_role_id = None
    await db.commit()


# ─────────────────────────── AUDIT ───────────────────────────

class AuditOut(BaseModel):
    id: int
    admin_user_id: Optional[int]
    admin_name: Optional[str]
    section: str
    action: str
    path: str
    created_at: object

    class Config:
        from_attributes = True


@router.get("/audit-logs", response_model=list[AuditOut])
async def audit_logs(limit: int = 100, db: AsyncSession = Depends(get_db)):
    res = await db.execute(select(AuditLog).order_by(desc(AuditLog.created_at)).limit(min(limit, 300)))
    return res.scalars().all()
