"""Sartarosh — xona egasi, xona ustasi, mobil sartarosh."""
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


def is_barber_shop(provider: Provider) -> bool:
    meta = provider.metadata_json or {}
    role = meta.get("barber_role")
    if role == "shop_owner":
        return True
    if role in ("shop_employee", "mobile"):
        return False
    return meta.get("type") == "barber_shop"


class BarberService:

    @staticmethod
    async def _category_id(db: AsyncSession) -> int:
        result = await db.execute(select(Category).where(Category.key == "sartarosh"))
        cat = result.scalar_one_or_none()
        if not cat:
            raise HTTPException(status_code=404, detail="Sartarosh kategoriyasi topilmadi")
        return cat.id

    @staticmethod
    async def list_shops(db: AsyncSession) -> list[Provider]:
        cat_id = await BarberService._category_id(db)
        result = await db.execute(
            select(Provider)
            .options(selectinload(Provider.category))
            .where(Provider.category_id == cat_id, Provider.is_active == True)
            .order_by(Provider.name)
        )
        shops = [p for p in result.scalars().all() if is_barber_shop(p)]
        return shops

    @staticmethod
    async def _find_shop_by_invite(db: AsyncSession, code: str) -> Provider | None:
        cat_id = await BarberService._category_id(db)
        result = await db.execute(
            select(Provider).where(Provider.category_id == cat_id)
        )
        code_upper = code.strip().upper()
        for p in result.scalars().all():
            if not is_barber_shop(p):
                continue
            meta = p.metadata_json or {}
            if meta.get("invite_code", "").upper() == code_upper:
                return p
        return None

    @staticmethod
    async def _user_shop_provider(db: AsyncSession, user_id: int) -> Provider | None:
        cat_id = await BarberService._category_id(db)
        result = await db.execute(
            select(Provider)
            .options(selectinload(Provider.category))
            .where(Provider.owner_user_id == user_id, Provider.category_id == cat_id)
        )
        for p in result.scalars().all():
            meta = p.metadata_json or {}
            role = meta.get("barber_role")
            if role == "shop_employee":
                continue
            if role == "mobile":
                continue
            if role == "shop_owner" or is_barber_shop(p):
                return p
        return None

    @staticmethod
    async def get_my_status(db: AsyncSession, user: User) -> dict:
        cat_id = await BarberService._category_id(db)
        result = await db.execute(
            select(Provider)
            .options(selectinload(Provider.category))
            .where(Provider.owner_user_id == user.id, Provider.category_id == cat_id)
        )
        owned = list(result.scalars().all())

        for p in owned:
            meta = p.metadata_json or {}
            role = meta.get("barber_role")
            if role == "shop_employee":
                status = meta.get("member_status", "approved")
                shop_id = meta.get("shop_provider_id")
                shop_name = None
                if shop_id:
                    shop = await db.get(Provider, shop_id)
                    shop_name = shop.name if shop else None
                return {
                    "role": "shop_employee",
                    "status": status,
                    "provider_id": p.id,
                    "shop_provider_id": shop_id,
                    "shop_name": shop_name,
                    "display_name": meta.get("display_name") or p.name,
                }
            if role == "mobile":
                return {
                    "role": "mobile",
                    "status": "active" if p.is_active else "pending",
                    "provider_id": p.id,
                    "display_name": p.name,
                }
            if role == "shop_owner" or is_barber_shop(p):
                return {
                    "role": "shop_owner",
                    "status": "active" if p.is_active else "pending",
                    "provider_id": p.id,
                    "shop_name": p.name,
                    "invite_code": (meta or {}).get("invite_code"),
                    "also_works_as_barber": (meta or {}).get("also_works_as_barber", False),
                }

        pending = await BarberService._find_pending_join(db, user.id)
        if pending:
            return pending

        return {"role": None, "status": "none"}

    @staticmethod
    async def _find_pending_join(db: AsyncSession, user_id: int) -> dict | None:
        cat_id = await BarberService._category_id(db)
        result = await db.execute(select(Provider).where(Provider.category_id == cat_id))
        for shop in result.scalars().all():
            if not is_barber_shop(shop):
                continue
            meta = shop.metadata_json or {}
            for m in meta.get("pending_members", []):
                if m.get("user_id") == user_id:
                    return {
                        "role": "shop_employee",
                        "status": "pending",
                        "shop_provider_id": shop.id,
                        "shop_name": shop.name,
                        "display_name": m.get("name"),
                        "requested_at": m.get("requested_at"),
                    }
        return None

    @staticmethod
    async def register_shop_owner(
        db: AsyncSession,
        user: User,
        *,
        name: str,
        address: str,
        phone: str,
        lat: float,
        lng: float,
        also_works_as_barber: bool,
        hours: str | None = None,
    ) -> Provider:
        cat_id = await BarberService._category_id(db)
        existing = await db.execute(
            select(Provider).where(
                Provider.owner_user_id == user.id,
                Provider.category_id == cat_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Sartarosh sifatida allaqachon ro'yxatdan o'tgansiz")

        code = _invite_code()
        barbers = []
        if also_works_as_barber:
            owner_name = f"{user.name} {user.surname}".strip() or name
            barbers.append({"name": owner_name, "rating": 5.0, "is_owner": True})

        meta = {
            "type": "barber_shop",
            "barber_role": "shop_owner",
            "also_works_as_barber": also_works_as_barber,
            "invite_code": code,
            "pending_members": [],
            "approved_members": [],
            "services": ["Erkaklar kesimi", "Soqol olish"],
            "prices": {"Erkaklar kesimi": 25000, "Soqol olish": 15000},
            "time_slots": ["09:00", "10:00", "11:00", "12:00", "14:00", "15:00", "16:00", "17:00", "18:00"],
            "barbers": barbers,
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
            is_active=True,
            owner_user_id=user.id,
        )
        db.add(provider)
        await db.flush()

        if also_works_as_barber:
            meta = dict(provider.metadata_json)
            barbers = list(meta.get("barbers", []))
            for b in barbers:
                if b.get("is_owner"):
                    b["provider_id"] = provider.id
            meta["barbers"] = barbers
            provider.metadata_json = meta
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
        cat_id = await BarberService._category_id(db)
        existing = await db.execute(
            select(Provider).where(
                Provider.owner_user_id == user.id,
                Provider.category_id == cat_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Sartarosh sifatida allaqachon ro'yxatdan o'tgansiz")

        meta = {
            "barber_role": "mobile",
            "service_area": service_area,
            "is_mobile": True,
            "services": ["Erkaklar kesimi", "Soqol olish"],
            "prices": {"Erkaklar kesimi": 30000, "Soqol olish": 18000},
            "time_slots": ["09:00", "10:00", "11:00", "12:00", "14:00", "15:00", "16:00", "17:00", "18:00"],
            "barbers": [{"name": name, "rating": 5.0}],
        }

        provider = Provider(
            category_id=cat_id,
            name=name,
            address=address or service_area,
            phone=phone or user.phone,
            lat=41.2995,
            lng=69.2401,
            metadata_json=meta,
            is_active=True,
            owner_user_id=user.id,
        )
        db.add(provider)
        await db.flush()

        meta = dict(provider.metadata_json)
        barbers = list(meta.get("barbers", []))
        for b in barbers:
            b["provider_id"] = provider.id
        meta["barbers"] = barbers
        provider.metadata_json = meta
        await db.flush()

        await db.refresh(provider, attribute_names=["category"])
        return provider

    @staticmethod
    async def request_join_shop(
        db: AsyncSession,
        user: User,
        *,
        display_name: str,
        shop_id: int | None = None,
        invite_code: str | None = None,
    ) -> dict:
        cat_id = await BarberService._category_id(db)

        existing = await db.execute(
            select(Provider).where(
                Provider.owner_user_id == user.id,
                Provider.category_id == cat_id,
            )
        )
        if existing.scalar_one_or_none():
            raise HTTPException(status_code=400, detail="Allaqachon sartarosh sifatida ro'yxatdan o'tgansiz")

        pending = await BarberService._find_pending_join(db, user.id)
        if pending:
            raise HTTPException(status_code=400, detail="So'rovingiz allaqachon yuborilgan")

        shop: Provider | None = None
        if shop_id:
            shop = await db.get(Provider, shop_id)
            if not shop or not is_barber_shop(shop):
                raise HTTPException(status_code=404, detail="Sartaroshxona topilmadi")
        elif invite_code:
            shop = await BarberService._find_shop_by_invite(db, invite_code)
            if not shop:
                raise HTTPException(status_code=404, detail="Taklif kodi noto'g'ri")
        else:
            raise HTTPException(status_code=400, detail="Xona yoki taklif kodi kerak")

        meta = dict(shop.metadata_json or {})
        pending_list = list(meta.get("pending_members", []))
        pending_list.append({
            "id": uuid.uuid4().hex[:12],
            "user_id": user.id,
            "name": display_name,
            "phone": user.phone,
            "requested_at": _now_iso(),
        })
        meta["pending_members"] = pending_list
        shop.metadata_json = meta
        await db.flush()

        from app.services.notification_service import NotificationService
        if shop.owner_user_id:
            NotificationService.send_notification(
                user_id=shop.owner_user_id,
                ntype="barber_join_request",
                title="Yangi usta so'rovi",
                message=f"{display_name} sizning xonangizga qo'shilishni so'radi.",
            )

        return {
            "shop_id": shop.id,
            "shop_name": shop.name,
            "status": "pending",
            "message": "So'rov yuborildi. Xona egasi tasdiqlashi kerak.",
        }

    @staticmethod
    async def list_pending_members(db: AsyncSession, owner: User) -> list[dict]:
        shop = await BarberService._user_shop_provider(db, owner.id)
        if not shop:
            raise HTTPException(status_code=404, detail="Sartaroshxonangiz topilmadi")
        meta = shop.metadata_json or {}
        return meta.get("pending_members", [])

    @staticmethod
    async def approve_member(db: AsyncSession, owner: User, member_user_id: int) -> dict:
        shop = await BarberService._user_shop_provider(db, owner.id)
        if not shop:
            raise HTTPException(status_code=404, detail="Sartaroshxonangiz topilmadi")

        meta = dict(shop.metadata_json or {})
        pending = list(meta.get("pending_members", []))
        member_req = next((m for m in pending if m.get("user_id") == member_user_id), None)
        if not member_req:
            raise HTTPException(status_code=404, detail="So'rov topilmadi")

        # Ismni SO'ROVDAN olamiz. Ilgari bu yerda `display_name`
        # ishlatilardi, lekin u faqat join_shop() parametri edi va bu
        # funksiyaga umuman uzatilmasdi -> NameError, ya'ni xodim qabul
        # qilish BUTUNLAY ishlamasdi (pyflakes bilan aniqlandi).
        member_user_pre = await db.get(User, member_user_id)
        display_name = (
            member_req.get("name")
            or (f"{member_user_pre.name} {member_user_pre.surname}".strip()
                if member_user_pre else None)
            or "Usta"
        )

        pending = [m for m in pending if m.get("user_id") != member_user_id]
        meta["pending_members"] = pending

        approved = list(meta.get("approved_members", []))
        approved.append({
            "user_id": member_user_id,
            "name": display_name,
            "approved_at": _now_iso(),
        })
        meta["approved_members"] = approved
        # shop.metadata_json is updated later

        member_user = await db.get(User, member_user_id)
        if not member_user:
            raise HTTPException(status_code=404, detail="Foydalanuvchi topilmadi")

        employee = Provider(
            category_id=shop.category_id,
            name=display_name,
            address=shop.address,
            phone=member_user.phone,
            lat=shop.lat,
            lng=shop.lng,
            metadata_json={
                "barber_role": "shop_employee",
                "shop_provider_id": shop.id,
                "member_status": "approved",
                "display_name": display_name,
            },
            is_active=True,
            owner_user_id=member_user_id,
        )
        db.add(employee)
        await db.flush()

        # Update barbers list with new provider ID
        barbers = list(meta.get("barbers", []))
        barbers.append({
            "name": display_name, 
            "rating": 5.0, 
            "user_id": member_user_id,
            "provider_id": employee.id
        })
        meta["barbers"] = barbers
        shop.metadata_json = meta
        await db.flush()

        from app.services.notification_service import NotificationService
        NotificationService.send_notification(
            user_id=member_user_id,
            ntype="barber_join_approved",
            title="Qo'shilish tasdiqlandi",
            message=f"{shop.name} xonasiga muvaffaqiyatli qo'shildingiz!",
        )

        return {"message": "Usta qabul qilindi", "member_user_id": member_user_id}

    @staticmethod
    async def reject_member(db: AsyncSession, owner: User, member_user_id: int) -> dict:
        shop = await BarberService._user_shop_provider(db, owner.id)
        if not shop:
            raise HTTPException(status_code=404, detail="Sartaroshxonangiz topilmadi")

        meta = dict(shop.metadata_json or {})
        pending = list(meta.get("pending_members", []))
        member_req = next((m for m in pending if m.get("user_id") == member_user_id), None)
        if not member_req:
            raise HTTPException(status_code=404, detail="So'rov topilmadi")

        meta["pending_members"] = [m for m in pending if m.get("user_id") != member_user_id]
        shop.metadata_json = meta
        await db.flush()

        from app.services.notification_service import NotificationService
        NotificationService.send_notification(
            user_id=member_user_id,
            ntype="barber_join_rejected",
            title="So'rov rad etildi",
            message=f"{shop.name} xonasi so'rovingizni rad etdi.",
        )
        return {"message": "So'rov rad etildi"}

    @staticmethod
    async def regenerate_invite(db: AsyncSession, owner: User) -> str:
        shop = await BarberService._user_shop_provider(db, owner.id)
        if not shop:
            raise HTTPException(status_code=404, detail="Sartaroshxonangiz topilmadi")
        meta = dict(shop.metadata_json or {})
        code = _invite_code()
        meta["invite_code"] = code
        shop.metadata_json = meta
        await db.flush()
        return code
