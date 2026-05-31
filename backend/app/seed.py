"""To'liq demo ma'lumotlarni DB ga yuklash yoki o'chirish."""
import argparse
import asyncio
import logging
from datetime import datetime, timedelta, timezone

from sqlalchemy import select, func, delete
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker

from app.core.config import settings
from app.core.security import hash_password
from app.models.category import Category, CategoryVariant
from app.models.provider import Provider
from app.models.user import User
from app.models.order import Order, OrderStatus
from app.models.review import Review
from app.models.payment import PaymentCard
from app.models.setting import PlatformSetting
from app.models.notification import Notification
from app.seed_data import (
    USERS,
    PROVIDERS,
    ORDERS,
    REVIEWS,
    PLATFORM_SETTINGS,
    PAYMENT_CARDS,
    NOTIFICATIONS,
)
from app.categories_data import CATEGORIES_DATA

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DEMO_PHONES = {u["phone"] for u in USERS}


async def clear_demo():
    """Seed qilingan demo ma'lumotlarni o'chirish (kategoriyalar va admin qoladi)."""
    engine = create_async_engine(settings.database_url, echo=False)
    async_session = async_sessionmaker(engine, expire_on_commit=False)

    async with async_session() as db:
        result = await db.execute(select(User).where(User.phone.in_(DEMO_PHONES)))
        demo_users = list(result.scalars().all())
        demo_user_ids = [u.id for u in demo_users]

        if demo_user_ids:
            await db.execute(
                delete(Notification).where(Notification.user_id.in_(demo_user_ids))
            )
            await db.execute(
                delete(PaymentCard).where(PaymentCard.user_id.in_(demo_user_ids))
            )
            for u in demo_users:
                await db.delete(u)
            logger.info("Demo foydalanuvchilar o'chirildi: %d", len(demo_users))

        await db.execute(delete(Review))
        await db.execute(delete(Order))
        await db.execute(delete(Provider))
        await db.commit()
        logger.info("Buyurtmalar, sharhlar va provayderlar o'chirildi")

    logger.info("Demo ma'lumotlar tozalandi. Kategoriyalar va admin saqlanadi.")
    await engine.dispose()


async def seed():
    engine = create_async_engine(settings.database_url, echo=False)
    async_session = async_sessionmaker(engine, expire_on_commit=False)

    async with async_session() as db:
        # Kategoriyalar bo'sh bo'lsa yuklash
        cat_count = (await db.execute(select(func.count(Category.id)))).scalar() or 0
        if cat_count == 0:
            logger.info("Kategoriyalar yuklanmoqda...")
            for cat_info in CATEGORIES_DATA:
                category = Category(
                    key=cat_info["key"],
                    title_uz=cat_info["title_uz"],
                    subtitle_uz=cat_info["subtitle_uz"],
                    icon=cat_info["icon"],
                    accent_color=cat_info["accent_color"],
                )
                db.add(category)
                await db.flush()
                for var_info in cat_info["variants"]:
                    db.add(
                        CategoryVariant(
                            category_id=category.id,
                            label_uz=var_info["label_uz"],
                            base_price=var_info["base_price"],
                        )
                    )
            await db.commit()
            logger.info("Kategoriyalar yuklandi: %d", len(CATEGORIES_DATA))
        else:
            logger.info("Kategoriyalar allaqachon mavjud: %d", cat_count)

        # Kategoriya map
        result = await db.execute(select(Category))
        categories = {c.key: c for c in result.scalars().all()}

        # Foydalanuvchilar
        user_map: dict[str, User] = {}
        for u in USERS:
            res = await db.execute(select(User).where(User.phone == u["phone"]))
            existing = res.scalar_one_or_none()
            if existing:
                user_map[u["phone"]] = existing
                continue
            user = User(
                name=u["name"],
                surname=u["surname"],
                phone=u["phone"],
                hashed_password=hash_password(u["password"]),
                balance=u.get("balance", 0),
                cashback=u.get("cashback", 0),
                is_premium=u.get("is_premium", False),
                is_active=True,
            )
            db.add(user)
            await db.flush()
            user_map[u["phone"]] = user
        await db.commit()
        logger.info("Foydalanuvchilar: %d", len(user_map))

        # Provayderlar
        provider_map: dict[str, Provider] = {}
        prov_count = (await db.execute(select(func.count(Provider.id)))).scalar() or 0
        if prov_count == 0:
            for p in PROVIDERS:
                cat = categories.get(p["category_key"])
                if not cat:
                    logger.warning("Kategoriya topilmadi: %s", p["category_key"])
                    continue
                provider = Provider(
                    category_id=cat.id,
                    name=p["name"],
                    address=p["address"],
                    phone=p["phone"],
                    lat=p["lat"],
                    lng=p["lng"],
                    rating=p["rating"],
                    review_count=p["review_count"],
                    metadata_json=p.get("metadata"),
                    is_active=True,
                )
                db.add(provider)
                await db.flush()
                provider_map[p["name"]] = provider
            await db.commit()
            logger.info("Provayderlar yuklandi: %d", len(provider_map))
        else:
            result = await db.execute(select(Provider))
            for p in result.scalars().all():
                provider_map[p.name] = p
            logger.info("Provayderlar allaqachon mavjud: %d", prov_count)

        # Buyurtmalar
        order_count = (await db.execute(select(func.count(Order.id)))).scalar() or 0
        if order_count == 0:
            now = datetime.utcnow()
            for o in ORDERS:
                user = user_map.get(o["user_phone"])
                provider = provider_map.get(o["provider_name"])
                cat = categories.get(o["category_key"])
                if not user or not provider or not cat:
                    continue
                db.add(
                    Order(
                        user_id=user.id,
                        category_id=cat.id,
                        provider_id=provider.id,
                        service_name=o["service_name"],
                        service_icon=cat.icon,
                        address="Toshkent",
                        date=now + timedelta(days=1),
                        price=o["price"],
                        cashback_earned=round(o["price"] * 0.01, 2),
                        status=OrderStatus(o["status"]),
                        created_at=now - timedelta(days=o["days_ago"]),
                    )
                )
            await db.commit()
            logger.info("Buyurtmalar yuklandi: %d", len(ORDERS))

        # Sharhlar
        review_count = (await db.execute(select(func.count(Review.id)))).scalar() or 0
        if review_count == 0:
            for r in REVIEWS:
                user = user_map.get(r["user_phone"])
                provider = provider_map.get(r["provider_name"])
                if not user or not provider:
                    continue
                db.add(
                    Review(
                        user_id=user.id,
                        provider_id=provider.id,
                        rating=r["rating"],
                        comment=r["comment"],
                    )
                )
            await db.commit()
            logger.info("Sharhlar yuklandi: %d", len(REVIEWS))

        # Sozlamalar
        for s in PLATFORM_SETTINGS:
            res = await db.execute(
                select(PlatformSetting).where(PlatformSetting.key == s["key"])
            )
            if not res.scalar_one_or_none():
                db.add(
                    PlatformSetting(
                        key=s["key"],
                        value=s["value"],
                        description=s.get("description"),
                    )
                )
        await db.commit()

        # Kartalar
        for c in PAYMENT_CARDS:
            user = user_map.get(c["user_phone"])
            if not user:
                continue
            res = await db.execute(
                select(PaymentCard).where(
                    PaymentCard.user_id == user.id,
                    PaymentCard.masked_number == c["masked_number"],
                )
            )
            if res.scalar_one_or_none():
                continue
            db.add(
                PaymentCard(
                    user_id=user.id,
                    masked_number=c["masked_number"],
                    bank=c["bank"],
                    card_type=c["card_type"],
                    exp_month=c["exp_month"],
                    exp_year=c["exp_year"],
                    is_default=c.get("is_default", False),
                )
            )
        await db.commit()

        # Provider egalari — foydalanuvchilar bilan bog'lash
        result = await db.execute(select(Provider))
        phone_to_user = {u.phone: u for u in user_map.values()}
        for p in result.scalars().all():
            if p.owner_user_id is None and p.phone in phone_to_user:
                p.owner_user_id = phone_to_user[p.phone].id
        demo = user_map.get("+998901112233")
        if demo:
            res = await db.execute(
                select(Provider)
                .join(Category)
                .where(Category.key == "sartarosh")
                .order_by(Provider.id)
                .limit(1)
            )
            barber = res.scalar_one_or_none()
            if barber:
                barber.owner_user_id = demo.id
        await db.commit()

        # Bildirishnomalar (takrorlanmasin)
        for n in NOTIFICATIONS:
            user = user_map.get(n["user_phone"])
            if not user:
                continue
            existing = await db.execute(
                select(Notification).where(
                    Notification.user_id == user.id,
                    Notification.title == n["title"],
                )
            )
            if existing.scalar_one_or_none():
                continue
            db.add(
                Notification(
                    user_id=user.id,
                    type=n["type"],
                    title=n["title"],
                    message=n["message"],
                    is_read=False,
                )
            )
        await db.commit()

    logger.info("Seed muvaffaqiyatli yakunlandi!")
    await engine.dispose()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Demo ma'lumotlarni yuklash yoki o'chirish")
    parser.add_argument(
        "--clear",
        action="store_true",
        help="Demo foydalanuvchilar, provayderlar, buyurtmalar va sharhlarni o'chirish",
    )
    args = parser.parse_args()
    if args.clear:
        asyncio.run(clear_demo())
    else:
        asyncio.run(seed())
