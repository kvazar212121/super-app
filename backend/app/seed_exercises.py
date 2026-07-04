"""
Exercises datasetni DB ga yuklash (idempotent upsert).

app/data/exercises.json (asl) + app/data/exercises_uz.json (tarjima) fayllarini
o'qib, exercises jadvaliga external_id bo'yicha upsert qiladi.
Tarjimasi yo'q yozuvlar inglizcha nom/ko'rsatmalar bilan kiradi.

Ishga tushirish (backend/ papkasidan):
    python -m app.seed_exercises
"""
import asyncio
import json
import logging
from pathlib import Path

from sqlalchemy import select
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker

from app.core.config import settings
from app.db.base import Base  # noqa: F401
from app.models import *  # noqa: F401,F403 — barcha modellarni ro'yxatga olish
from app.models.exercise import Exercise

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

DATA_DIR = Path(__file__).resolve().parent / "data"
SOURCE_FILE = DATA_DIR / "exercises.json"
UZ_FILE = DATA_DIR / "exercises_uz.json"


async def seed_exercises():
    source = json.loads(SOURCE_FILE.read_text(encoding="utf-8"))
    translations: dict = {}
    if UZ_FILE.exists():
        translations = json.loads(UZ_FILE.read_text(encoding="utf-8"))
    else:
        logger.warning(
            "exercises_uz.json topilmadi — inglizcha fallback bilan yuklanadi. "
            "Avval scripts/translate_exercises.py ni ishga tushirish tavsiya etiladi."
        )

    engine = create_async_engine(settings.database_url, echo=False)
    async_session = async_sessionmaker(engine, expire_on_commit=False)

    created, updated = 0, 0
    async with async_session() as db:
        result = await db.execute(select(Exercise))
        existing = {e.external_id: e for e in result.scalars().all()}

        for item in source:
            ext_id = str(item["id"])
            media_id = item.get("media_id") or ""
            steps_en = (item.get("instruction_steps") or {}).get("en") or []
            tr = translations.get(ext_id) or {}

            values = {
                "external_id": ext_id,
                "media_id": media_id or None,
                "gif_url": f"{settings.exercise_gif_base}/{media_id}.gif" if media_id else None,
                "name_en": item.get("name") or "",
                "name_uz": tr.get("name_uz") or item.get("name") or "",
                "category": item.get("category"),
                "body_part": item.get("body_part"),
                "equipment": item.get("equipment"),
                "target": item.get("target"),
                "muscle_group": item.get("muscle_group"),
                "secondary_muscles": item.get("secondary_muscles") or [],
                "instructions_en": steps_en,
                "instructions_uz": tr.get("instructions_uz") or steps_en,
            }

            exercise = existing.get(ext_id)
            if exercise:
                for key, value in values.items():
                    setattr(exercise, key, value)
                updated += 1
            else:
                db.add(Exercise(**values))
                created += 1

        await db.commit()

    await engine.dispose()
    translated = sum(1 for item in source if str(item["id"]) in translations)
    logger.info(
        "Tayyor: %d ta yangi, %d ta yangilandi (jami %d, tarjimali %d).",
        created, updated, len(source), translated,
    )


if __name__ == "__main__":
    asyncio.run(seed_exercises())
