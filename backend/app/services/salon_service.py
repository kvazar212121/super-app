"""Salon — salon egasi, xodim, mobil kosmetolog."""
import secrets
import uuid
from datetime import datetime, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload
from fastapi import HTTPException

from app.models.provider import Provider
from app.models.category import Category
from app.models.user import User


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _invite_code() -> str:
    return secrets.token_hex(4).upper()


def is_salon_venue(provider: Provider) -> bool:
    meta = provider.metadata_json or {}
    role = meta.get("salon_role")
    if role == "salon_owner":
        return True
    if role in ("salon_employee", "mobile"):
        return False
    return meta.get("type") == "beauty_salon"


class SalonService:

    @staticmethod
    async def _category_id(db: AsyncSession) -> int:
        result = await db.execute(select(Category).where(Category.key == "salon"))
        cat = result.scalar_one_or_none()
        if not cat:
            raise HTTPException(status_code=404, detail="Salon kategoriyasi topilmadi")
        return cat.id

    @staticmethod
    async def list_salons(db: AsyncSession) -> list[Provider]:
        cat_id = await SalonService._category_id(db)
        result = await db.execute(
            select(Provider)
            .options(selectinload(Provider.category))
            .where(Provider.category_id == cat_id, Provider.is_active == True)
            .order_by(Provider.name)
        )
        return [p for p in result.scalars().all() if is_salon_venue(p)]

    @staticmethod
    async def _find_salon_by_invite(db: AsyncSession, code: str) -> Provider | None:
        cat_id = await SalonService._category_id(db)
        result = await db.execute(select(Provider).where(Provider.category_id == cat_id))
        code_upper = code.strip().upper()
        for p in result.scalars().all():
            if not is_salon_venue(p):
                continue
            meta = p.metadata_json or {}
            if meta.get("invite_code", "").upper() == code_upper:
                return p
        return None

    @staticmethod
    async def _user_salon_provider(db: AsyncSession, user_id: int) -> Provider | None:
        cat_id = await SalonService._category_id(db)
        result = await db.execute(
            select(Provider)
            .options(selectinload(Provider.category))
            .where(Provider.owner_user_id == user_id, Provider.category_id == cat_id)
        )
        for p in result.scalars().all():
            meta = p.metadata_json or {}
            role = meta.get("salon_role")
            if role in ("salon_employee", "mobile"):
                continue
            if role == "salon_owner" or is_salon_venue(p):
                return p
        return None

    @staticmethod
    async def get_my_status(db: AsyncSession, user: User) -> dict:
        cat_id = await SalonService._category_id(db)
        result = await db.execute(
            select(Provider)
            .options(selectinload(Provider.category))
            .where(Provider.owner_user_id == user.id, Provider.category_id == cat_id)
        )
        owned = list(result.scalars().all())

        for p in owned:
            meta = p.metadata_json or {}
            role = meta.get("salon_role")
            if role == "salon_employee":
                status = meta.get("member_status", "approved")
                salon_id = meta.get("salon_provider_id")
                salon_name = None
                if salon_id:
                    salon = await db.get(Provider, salon_id)
                    salon_name = salon.name if salon else None
                return {
                    "role": "salon_employee",
                    "status": status,
                    "provider_id": p.id,
                    "salon_provider_id": salon_id,
                    "salon_name": salon_name,
                    "display_name": meta.get("display_name") or p.name,
                }
            if role == "mobile":
                return {
                    "role": "mobile",
                    "status": "active" if p.is_active else "pending",
                    "provider_id": p.id,
                    "display_name": p.name,
                }
            if role == "salon_owner" or is_salon_venue(p):
                return {
                    "role": "salon_owner",
                    "status": "active" if p.is_active else "pending",
                    "provider_id": p.id,
                    "salon_name": p.name,
                    "invite_code": (meta or {}).get("invite_code"),
                    "also_works_as_stylist": (meta or {}).get("also_works_as_stylist", False),
                }

        pending = await SalonService._find_pending_join(db, user.id)
        if pending:
            return pending

        return {"role": None, "status": "none"}

    @staticmethod
    async def _find_pending_join(db: AsyncSession, user_id: int) -> dict | None:
        cat_id = await SalonService._category_id(db)
        result = await db.execute(select(Provider).where(Provider.category_id == cat_id))
        for salon in result.scalars().all():
            if not is_salon_venue(salon):
                continue
            meta = salon.metadata_json or {}
            for m in meta.get("pending_members", []):
                if m.get("user_id") == user_id:
                    return {
                        "role": "salon_employee",
                        "status": "pending",
                        "salon_provider_id": salon.id,
                        "salon_name": salon.name,
                        "display_name": m.get("name"),
                        "requested_at": m.get("requested_at"),
                    }
        return None

    @staticmethod
    async def register_salon_owner(
        db: AsyncSession,
        user: User,
        *,
        name: str,
        address: str,
        phone: str,
        lat: float,
        lng: float,
        also_works_as_stylist: bool,
        hours: str | None = None,
    ) -> Provider:
        cat_id = await SalonService._category_id(db)
        existing = await db.execute(
            select(Provider).where(
                Provider.owner_user_id == user.id,
                Provider.category_id == cat_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Salon sifatida allaqachon ro'yxatdan o'tgansiz")

        code = _invite_code()
        staff = []
        if also_works_as_stylist:
            owner_name = f"{user.name} {user.surname}".strip() or name
            staff.append({"name": owner_name, "rating": 5.0, "is_owner": True})

        meta = {
            "type": "beauty_salon",
            "salon_role": "salon_owner",
            "also_works_as_stylist": also_works_as_stylist,
            "invite_code": code,
            "pending_members": [],
            "approved_members": [],
            "services": ["Fen", "Manikyur", "Makiyaj"],
            "prices": {"Fen": 45000, "Manikyur": 60000, "Makiyaj": 80000},
            "time_slots": ["10:00", "11:00", "12:00", "13:00", "14:00", "15:00", "16:00", "17:00", "18:00", "19:00"],
            "staff": staff,
        }
        if hours:
            meta["hours"] = hours

        provider = Provider(
            category_id=cat_id,
            name=name,
            address=address,
            phone=phone or user.phone,
            lat=lat,
            lng=lng,
            metadata_json=meta,
            is_active=False,
            owner_user_id=user.id,
        )
        db.add(provider)
        await db.flush()
        await db.refresh(provider, attribute_names=["category"])
        return provider

    @staticmethod
    async def register_mobile(
        db: AsyncSession,
        user: User,
        *,
        name: str,
        phone: str,
        service_area: str,
        address: str | None = None,
    ) -> Provider:
        cat_id = await SalonService._category_id(db)
        existing = await db.execute(
            select(Provider).where(
                Provider.owner_user_id == user.id,
                Provider.category_id == cat_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Salon sifatida allaqachon ro'yxatdan o'tgansiz")

        meta = {
            "salon_role": "mobile",
            "service_area": service_area,
            "is_mobile": True,
            "services": ["Fen", "Manikyur", "Makiyaj"],
            "prices": {"Fen": 55000, "Manikyur": 70000, "Makiyaj": 90000},
            "time_slots": ["10:00", "11:00", "12:00", "14:00", "15:00", "16:00", "17:00", "18:00"],
            "staff": [{"name": name, "rating": 5.0}],
        }

        provider = Provider(
            category_id=cat_id,
            name=name,
            address=address or service_area,
            phone=phone or user.phone,
            lat=41.2995,
            lng=69.2401,
            metadata_json=meta,
            is_active=False,
            owner_user_id=user.id,
        )
        db.add(provider)
        await db.flush()
        await db.refresh(provider, attribute_names=["category"])
        return provider

    @staticmethod
    async def request_join_salon(
        db: AsyncSession,
        user: User,
        *,
        display_name: str,
        salon_id: int | None = None,
        invite_code: str | None = None,
    ) -> dict:
        cat_id = await SalonService._category_id(db)

        existing = await db.execute(
            select(Provider).where(
                Provider.owner_user_id == user.id,
                Provider.category_id == cat_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Allaqachon salon sifatida ro'yxatdan o'tgansiz")

        pending = await SalonService._find_pending_join(db, user.id)
        if pending:
            raise HTTPException(status_code=400, detail="So'rovingiz allaqachon yuborilgan")

        salon: Provider | None = None
        if salon_id:
            salon = await db.get(Provider, salon_id)
            if not salon or not is_salon_venue(salon):
                raise HTTPException(status_code=404, detail="Salon topilmadi")
        elif invite_code:
            salon = await SalonService._find_salon_by_invite(db, invite_code)
            if not salon:
                raise HTTPException(status_code=404, detail="Taklif kodi noto'g'ri")
        else:
            raise HTTPException(status_code=400, detail="Salon yoki taklif kodi kerak")

        meta = dict(salon.metadata_json or {})
        pending_list = list(meta.get("pending_members", []))
        pending_list.append({
            "id": uuid.uuid4().hex[:12],
            "user_id": user.id,
            "name": display_name,
            "phone": user.phone,
            "requested_at": _now_iso(),
        })
        meta["pending_members"] = pending_list
        salon.metadata_json = meta
        await db.flush()

        from app.services.notification_service import NotificationService
        if salon.owner_user_id:
            NotificationService.send_notification(
                user_id=salon.owner_user_id,
                ntype="salon_join_request",
                title="Yangi xodim so'rovi",
                message=f"{display_name} saloningizga qo'shilishni so'radi.",
            )

        return {
            "salon_id": salon.id,
            "salon_name": salon.name,
            "status": "pending",
            "message": "So'rov yuborildi. Salon egasi tasdiqlashi kerak.",
        }

    @staticmethod
    async def list_pending_members(db: AsyncSession, owner: User) -> list[dict]:
        salon = await SalonService._user_salon_provider(db, owner.id)
        if not salon:
            raise HTTPException(status_code=404, detail="Saloningiz topilmadi")
        meta = salon.metadata_json or {}
        return meta.get("pending_members", [])

    @staticmethod
    async def approve_member(db: AsyncSession, owner: User, member_user_id: int) -> dict:
        salon = await SalonService._user_salon_provider(db, owner.id)
        if not salon:
            raise HTTPException(status_code=404, detail="Saloningiz topilmadi")

        meta = dict(salon.metadata_json or {})
        pending = list(meta.get("pending_members", []))
        member_req = next((m for m in pending if m.get("user_id") == member_user_id), None)
        if not member_req:
            raise HTTPException(status_code=404, detail="So'rov topilmadi")

        pending = [m for m in pending if m.get("user_id") != member_user_id]
        meta["pending_members"] = pending

        display_name = member_req.get("name", "Mutaxassis")
        staff = list(meta.get("staff", []))
        staff.append({"name": display_name, "rating": 5.0, "user_id": member_user_id})
        meta["staff"] = staff

        approved = list(meta.get("approved_members", []))
        approved.append({
            "user_id": member_user_id,
            "name": display_name,
            "approved_at": _now_iso(),
        })
        meta["approved_members"] = approved
        salon.metadata_json = meta

        member_user = await db.get(User, member_user_id)
        if not member_user:
            raise HTTPException(status_code=404, detail="Foydalanuvchi topilmadi")

        employee = Provider(
            category_id=salon.category_id,
            name=display_name,
            address=salon.address,
            phone=member_user.phone,
            lat=salon.lat,
            lng=salon.lng,
            metadata_json={
                "salon_role": "salon_employee",
                "salon_provider_id": salon.id,
                "member_status": "approved",
                "display_name": display_name,
            },
            is_active=True,
            owner_user_id=member_user_id,
        )
        db.add(employee)
        await db.flush()

        from app.services.notification_service import NotificationService
        NotificationService.send_notification(
            user_id=member_user_id,
            ntype="salon_join_approved",
            title="Qo'shilish tasdiqlandi",
            message=f"{salon.name} saloniga muvaffaqiyatli qo'shildingiz!",
        )

        return {"message": "Xodim qabul qilindi", "member_user_id": member_user_id}

    @staticmethod
    async def reject_member(db: AsyncSession, owner: User, member_user_id: int) -> dict:
        salon = await SalonService._user_salon_provider(db, owner.id)
        if not salon:
            raise HTTPException(status_code=404, detail="Saloningiz topilmadi")

        meta = dict(salon.metadata_json or {})
        pending = list(meta.get("pending_members", []))
        member_req = next((m for m in pending if m.get("user_id") == member_user_id), None)
        if not member_req:
            raise HTTPException(status_code=404, detail="So'rov topilmadi")

        meta["pending_members"] = [m for m in pending if m.get("user_id") != member_user_id]
        salon.metadata_json = meta
        await db.flush()

        from app.services.notification_service import NotificationService
        NotificationService.send_notification(
            user_id=member_user_id,
            ntype="salon_join_rejected",
            title="So'rov rad etildi",
            message=f"{salon.name} saloni so'rovingizni rad etdi.",
        )
        return {"message": "So'rov rad etildi"}

    @staticmethod
    async def regenerate_invite(db: AsyncSession, owner: User) -> str:
        salon = await SalonService._user_salon_provider(db, owner.id)
        if not salon:
            raise HTTPException(status_code=404, detail="Saloningiz topilmadi")
        meta = dict(salon.metadata_json or {})
        code = _invite_code()
        meta["invite_code"] = code
        salon.metadata_json = meta
        await db.flush()
        return code
