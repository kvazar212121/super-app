import asyncio
from sqlalchemy import select
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from app.models.category import Category
from app.core.config import settings

engine = create_async_engine(settings.database_url)

MISSING = [
    {"key": "bozorchi", "title_uz": "Bozorchi", "icon": "shoppingCart", "accent_color": "#FF9800"},
    {"key": "oshxona", "title_uz": "Restoran va Kafe", "icon": "utensils", "accent_color": "#F44336"},
    {"key": "game_zona", "title_uz": "Game Zona", "icon": "gamepad2", "accent_color": "#673AB7"},
    {"key": "sport_maydon", "title_uz": "Sport Maydonlari", "icon": "sports_soccer", "accent_color": "#4CAF50"},
    {"key": "kompyuter_usta", "title_uz": "Kompyuter Ustasi", "icon": "monitor", "accent_color": "#607D8B"},
    {"key": "boshqa_xizmatlar", "title_uz": "Boshqa Xizmatlar", "icon": "layoutGrid", "accent_color": "#9E9E9E"}
]

async def main():
    async with AsyncSession(engine) as session:
        for m in MISSING:
            existing = await session.execute(select(Category).where(Category.key == m["key"]))
            if not existing.scalar_one_or_none():
                c = Category(key=m["key"], title_uz=m["title_uz"], icon=m["icon"], accent_color=m["accent_color"])
                session.add(c)
                print(f"Added {m['key']}")
        await session.commit()

asyncio.run(main())
