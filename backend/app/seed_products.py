"""
Mahsulotlar katalogini boshlang'ich o'rtacha narxlar bilan to'ldirish (idempotent upsert).

app/data/products_uz.json faylini o'qib, product_catalog jadvaliga NOM bo'yicha upsert qiladi.
Narxlar — O'zbekiston chakana bozori bo'yicha taxminiy o'rtacha qiymatlar (2026);
admin panelidan istalgan vaqtda tahrirlash mumkin.

Ishga tushirish (backend/ papkasidan):
    python -m app.seed_products
"""
import asyncio
import json
import logging
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker

from app.core.config import settings
from app.models import *  # noqa: F401,F403 — barcha modellarni ro'yxatga olish
from app.models.product_catalog import ProductCatalog, ProductPriceEntry

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DATA_FILE = Path(__file__).resolve().parent / "data" / "products_uz.json"


async def seed_products():
    items = json.loads(DATA_FILE.read_text(encoding="utf-8"))

    engine = create_async_engine(settings.database_url, echo=False)
    async_session = async_sessionmaker(engine, expire_on_commit=False)

    created, updated = 0, 0
    async with async_session() as db:
        result = await db.execute(select(ProductCatalog))
        existing = {p.name.lower(): p for p in result.scalars().all()}

        for item in items:
            name = str(item["name"]).strip()
            unit = str(item.get("unit") or "dona")
            price = float(item.get("average_price") or 0.0)

            product = existing.get(name.lower())
            if product:
                product.unit = unit
                product.average_price = price
                updated += 1
            else:
                product = ProductCatalog(name=name, unit=unit, average_price=price)
                db.add(product)
                await db.flush()  # id olish uchun
                # Boshlang'ich narx tarixini yozamiz (manba: 'seed')
                db.add(ProductPriceEntry(product_id=product.id, source_type="seed", price=price))
                created += 1

        await db.commit()

    await engine.dispose()
    logger.info("Tayyor: %d ta yangi, %d ta yangilandi (jami %d).", created, updated, len(items))


if __name__ == "__main__":
    asyncio.run(seed_products())
