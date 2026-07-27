"""FOYDALI MA'LUMOT toollari — tashqi API'lar (ob-havo, valyuta, namoz vaqtlari)."""
import json

import httpx
from sqlalchemy.ext.asyncio import AsyncSession


async def get_weather(db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None) -> tuple[str, dict | None]:
    city = args.get("city") or "Tashkent"
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(
                "https://api.open-meteo.com/v1/forecast?latitude=41.2995&longitude=69.2401&current_weather=true"
            )
            resp.raise_for_status()
            cur = resp.json().get("current_weather", {})
            return json.dumps({"status": "success", "city": city,
                "temperature": cur.get("temperature"), "windspeed": cur.get("windspeed")},
                ensure_ascii=False), None
    except Exception:
        return '{"status": "error", "message": "Ob-havo olinmadi"}', None


async def get_currency(db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None) -> tuple[str, dict | None]:
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get("https://cbu.uz/uz/arkhiv-kursov-valyut/json/")
            resp.raise_for_status()
            data = resp.json()
            want = ["USD", "EUR", "RUB", "GBP", "KZT"]
            rates = {i["Ccy"]: i["Rate"] for i in data if i["Ccy"] in want}
            return json.dumps({"status": "success", "rates": rates}, ensure_ascii=False), None
    except Exception:
        return '{"status": "error", "message": "Valyuta kurslari olinmadi"}', None


async def get_prayer_times(db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None) -> tuple[str, dict | None]:
    city = args.get("city") or "Tashkent"
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(
                f"https://api.aladhan.com/v1/timingsByCity?city={city}&country=Uzbekistan&method=3"
            )
            resp.raise_for_status()
            t = resp.json()["data"]["timings"]
            return json.dumps({"status": "success", "timings": {
                "Bomdod": t.get("Fajr"), "Quyosh": t.get("Sunrise"), "Peshin": t.get("Dhuhr"),
                "Asr": t.get("Asr"), "Shom": t.get("Maghrib"), "Xufton": t.get("Isha"),
            }}, ensure_ascii=False), None
    except Exception:
        return '{"status": "error", "message": "Namoz vaqtlari olinmadi"}', None


HANDLERS = {
    "get_weather": get_weather,
    "get_currency": get_currency,
    "get_prayer_times": get_prayer_times,
}
