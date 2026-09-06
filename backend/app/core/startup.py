"""Startup migratsiya va seed logikasi.

Ko'p workerда FAQAT bitta worker bajaradi (Redis lock 'startup_init_lock')
— concurrent DDL deadlock oldini olish uchun.
"""
import logging

from sqlalchemy import select, text, func

from app.core.config import settings
from app.core.security import hash_password
from app.db.base import Base
from app.db.session import async_session, engine
from app.models.user import User
from app.models.promo import Promo
from app.models.category import Category, CategoryVariant
from app.categories_data import CATEGORIES_DATA

logger = logging.getLogger(__name__)


async def _should_run_init() -> bool:
    """Redis lock orqali faqat bitta worker startup init bajarishini ta'minlaydi."""
    try:
        from app.core.call_manager import manager as _init_cm
        _init_redis = await _init_cm._get_redis()
        if _init_redis is not None:
            return bool(await _init_redis.set("startup_init_lock", "1", nx=True, ex=120))
    except Exception:
        return True
    return True


async def sync_categories() -> int:
    """`CATEGORIES_DATA` dagi yetishmayotgan kategoriyalarni bazaga qo'shadi.

    Nega kerak: ilgari kategoriyalar FAQAT `seed.py` da, FAQAT butunlay bo'sh
    bazada yaratilardi. Shu sababli `CATEGORIES_DATA` ga qo'shilgan yangi
    xizmat ishlab turgan serverga hech qachon tushmasdi va ilovada o'sha
    bo'lim doim bo'sh ko'rinardi.

    Mavjud kategoriyalar O'ZGARTIRILMAYDI — adminda qo'lda tahrirlangan
    nom/rang saqlanadi. Takroriy chaqirilsa dublikat yaratmaydi.

    Qaytaradi: qo'shilgan kategoriyalar soni.
    """
    async with async_session() as db:
        existing_keys = set(
            (await db.execute(select(Category.key))).scalars().all()
        )

        added = 0
        for cat_info in CATEGORIES_DATA:
            if cat_info["key"] in existing_keys:
                continue
            category = Category(
                key=cat_info["key"],
                title_uz=cat_info["title_uz"],
                subtitle_uz=cat_info.get("subtitle_uz"),
                icon=cat_info["icon"],
                accent_color=cat_info["accent_color"],
            )
            db.add(category)
            await db.flush()
            for var_info in cat_info.get("variants", []):
                db.add(
                    CategoryVariant(
                        category_id=category.id,
                        label_uz=var_info["label_uz"],
                        base_price=var_info["base_price"],
                    )
                )
            added += 1

        if added:
            await db.commit()
            logger.info("Yangi kategoriyalar qo'shildi: %d", added)
        return added


async def run_startup_init():
    """DB jadvallari, yangi ustunlar (DDL) va boshlang'ich ma'lumotlar (seed)."""
    if not await _should_run_init():
        logger.info("Startup init boshqa workerда bajarilmoqda — o'tkazib yuborildi.")
        return

    # Create tables + yangi ustunlar
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
        await conn.execute(text(
            "ALTER TABLE providers ADD COLUMN IF NOT EXISTS owner_user_id INTEGER REFERENCES users(id)"
        ))
        await conn.execute(text(
            "CREATE INDEX IF NOT EXISTS ix_providers_owner_user_id ON providers (owner_user_id)"
        ))
        await conn.execute(text(
            "ALTER TABLE plans ADD COLUMN IF NOT EXISTS is_notified BOOLEAN DEFAULT FALSE"
        ))
        # `suspended` -> `review`. Nomi yolg'on edi: bu daraja hech qachon
        # provayderni bloklamagan. Migratsiya ham bor (dc44c41514df), lekin
        # jadvallarini `create_all` dan olgan bazalar migratsiyani
        # o'tkazmaydi — shuning uchun bu yerda ham qo'llanadi.
        await conn.execute(text("""
            DO $$ BEGIN
              IF EXISTS (
                SELECT 1 FROM pg_enum e JOIN pg_type t ON t.oid = e.enumtypid
                WHERE t.typname = 'fraudflaglevel' AND e.enumlabel = 'suspended'
              ) THEN
                ALTER TYPE fraudflaglevel RENAME VALUE 'suspended' TO 'review';
              END IF;
            END $$;
        """))
        await conn.execute(text(
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS reminder_offset_minutes INTEGER DEFAULT 10"
        ))
        await conn.execute(text(
            "ALTER TABLE orders ADD COLUMN IF NOT EXISTS booking_mode VARCHAR(50) DEFAULT 'fixed'"
        ))
        # Xabar qaysi ish e'loni bo'yicha yozilgani. create_all MAVJUD
        # jadvalga ustun qo'sha olmaydi, shuning uchun ALTER kerak.
        await conn.execute(text(
            "ALTER TABLE direct_messages ADD COLUMN IF NOT EXISTS job_id INTEGER"
        ))
        await conn.execute(text(
            "CREATE INDEX IF NOT EXISTS ix_direct_messages_job_id "
            "ON direct_messages (job_id)"
        ))
        # Shopping list new columns
        await conn.execute(text(
            "ALTER TABLE shopping_lists ADD COLUMN IF NOT EXISTS name VARCHAR(255) DEFAULT 'Bozorlik'"
        ))
        await conn.execute(text(
            "ALTER TABLE shopping_lists ADD COLUMN IF NOT EXISTS total_actual_price FLOAT DEFAULT 0.0"
        ))
        await conn.execute(text(
            "ALTER TABLE shopping_lists ADD COLUMN IF NOT EXISTS is_completed BOOLEAN DEFAULT FALSE"
        ))
        # Provider yangi ustunlari
        await conn.execute(text(
            "ALTER TABLE providers ADD COLUMN IF NOT EXISTS is_paused BOOLEAN DEFAULT FALSE"
        ))
        # RBAC: admin rol ustunlari
        await conn.execute(text(
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS is_super_admin BOOLEAN DEFAULT FALSE"
        ))
        await conn.execute(text(
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS admin_role_id INTEGER REFERENCES admin_roles(id)"
        ))
        # Birinchi migratsiya: hali super admin yo'q bo'lsa, mavjud adminlarni super qilamiz
        _sa = (await conn.execute(text("SELECT COUNT(*) FROM users WHERE is_super_admin = TRUE"))).scalar()
        if not _sa:
            await conn.execute(text("UPDATE users SET is_super_admin = TRUE WHERE is_admin = TRUE"))
        # Premium obuna ustuni
        await conn.execute(text(
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS premium_until TIMESTAMPTZ"
        ))
        # Provayder moderatsiyasi ustunlari
        await conn.execute(text(
            "ALTER TABLE providers ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE"
        ))
        await conn.execute(text(
            "ALTER TABLE providers ADD COLUMN IF NOT EXISTS is_blocked BOOLEAN DEFAULT FALSE"
        ))

        # ── Performance index'lari (tez-tez ishlaydigan scheduler/qidiruv filtrlari) ──
        # plan_reminder_scheduler har 15s: is_completed=false AND is_notified=false
        await conn.execute(text(
            "CREATE INDEX IF NOT EXISTS ix_plans_pending "
            "ON plans (due_date) WHERE is_completed = false AND is_notified = false"
        ))
        # finance_reminder_scheduler har 30s: is_paid=false AND is_notified=false
        await conn.execute(text(
            "CREATE INDEX IF NOT EXISTS ix_planned_payments_pending "
            "ON planned_payments (due_date) WHERE is_paid = false AND is_notified = false"
        ))
        # Provayder ro'yxati/AI qidiruvi: ORDER BY rating DESC
        await conn.execute(text(
            "CREATE INDEX IF NOT EXISTS ix_providers_rating ON providers (rating)"
        ))
        # Oilaviy moliya: foydalanuvchini umumiy byudjet guruhiga bog'lovchi ustun
        await conn.execute(text(
            "ALTER TABLE users ADD COLUMN IF NOT EXISTS finance_group_id INTEGER "
            "REFERENCES finance_groups(id) ON DELETE SET NULL"
        ))
        await conn.execute(text(
            "CREATE INDEX IF NOT EXISTS ix_users_finance_group_id ON users (finance_group_id)"
        ))
        # Energiya balansi integratsiyasi: mashg'ulot logiga yoqilgan kaloriya ustunlari
        await conn.execute(text(
            "ALTER TABLE workout_logs ADD COLUMN IF NOT EXISTS duration_min INTEGER"
        ))
        await conn.execute(text(
            "ALTER TABLE workout_logs ADD COLUMN IF NOT EXISTS calories_burned FLOAT DEFAULT 0"
        ))
        # ── Saqlash limiti: eski bildirishnomalarni serverdan tozalash (1 oy) ──
        # Bildirishnomalar mijoz qurilmasida ko'rinadi; serverда 30 kundan ortiq
        # saqlanmaydi (ma'lumotlar bazasi shishmasligi uchun). Eski xabarlar lokal
        # qurilmada qoladi.
        try:
            deleted = await conn.execute(text(
                "DELETE FROM notifications WHERE created_at < NOW() - INTERVAL '30 days'"
            ))
            if deleted.rowcount:
                logger.info("Retention: %s ta eski bildirishnoma tozalandi (>30 kun)", deleted.rowcount)
        except Exception as e:
            logger.warning("Bildirishnoma retention xatosi: %s", e)

    # Yangi xizmat kategoriyalarini bazaga qo'shamiz (deploy paytida).
    await sync_categories()

    # Seed admin user & default promos
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

        # Seed default promos if empty
        promo_count = (await db.execute(select(func.count(Promo.id)))).scalar() or 0
        if promo_count == 0:
            default_promos = [
                Promo(
                    title="Sartarosh — 25% chegirma",
                    subtitle="Dushanba–chorshanba, barcha xizmatlar",
                    badge="-25%",
                    colors="#6366F1,#A855F7"
                ),
                Promo(
                    title="Tozalash — birinchi buyurtma",
                    subtitle="30% gacha chegirma, kod: TOZA30",
                    badge="AKSIYA",
                    colors="#0D9488,#06B6D4"
                ),
                Promo(
                    title="Avto-yordam tungi tarif",
                    subtitle="Evakuator 20% arzonroq 22:00 dan keyin",
                    badge="-20%",
                    colors="#EA580C,#F59E0B"
                )
            ]
            db.add_all(default_promos)
            await db.commit()
