"""Navigatsiya tooli — AI chatда ilova bo'limlariga o'tish TUGMALARINI chiqaradi.

AI javob ostiga bir yoki bir nechta tugma qo'sha oladi (masalan "Rejalarim" va
"Mening moliyam"). Tugma bosilganда ilova ichида o'sha ekran ochiladi.
"""
import json

from sqlalchemy.ext.asyncio import AsyncSession

# route → ilovadagi ekran nomi (Flutter shu kalitlar bo'yicha ekran ochadi).
# Yangi bo'lim qo'shilsa — shu yerга va Flutter'даги _handleNavigate'ga qo'shiladi.
SECTIONS: dict[str, str] = {
    "plans": "Rejalarim",
    "todos": "Vazifalarim",
    "finance": "Mening moliyam",
    "shopping": "Aqlli savdo",
    "orders": "Buyurtmalarim",
    "alarms": "Majburlovchi budilnik",
    "services": "Barcha xizmatlar",
    "calorie": "Kaloriya hisoblagich",
    "fitness": "Fitnes trener",
    "calls": "Aloqa",
    "profile": "Profil",
    "premium": "Premium",
}


async def open_app_section(db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None) -> tuple[str, dict | None]:
    """Bir yoki bir nechta bo'lim uchun chatда tugma chiqaradi."""
    raw = args.get("sections") or args.get("section") or []
    if isinstance(raw, str):
        raw = [raw]
    if not isinstance(raw, list):
        raw = []

    items = []
    invalid = []
    for s in raw[:6]:  # ko'pi bilan 6 ta tugma
        key = str(s).strip().lower()
        if key in SECTIONS:
            if not any(i["route"] == key for i in items):  # takrorlanmasin
                items.append({"route": key, "label": SECTIONS[key]})
        else:
            invalid.append(key)

    if not items:
        return json.dumps({
            "status": "error",
            "message": "Noto'g'ri bo'lim nomi. Quyidagilardan birini tanlang.",
            "invalid": invalid,
            "available_sections": [{"route": k, "label": v} for k, v in SECTIONS.items()],
        }, ensure_ascii=False), None

    action = {"type": "navigate", "items": items}
    return json.dumps({
        "status": "success",
        "message": "Tugma(lar) chatда ko'rsatildi. Javobда qisqa izoh yozing.",
        "shown": items,
    }, ensure_ascii=False), action


HANDLERS = {
    "open_app_section": open_app_section,
}
