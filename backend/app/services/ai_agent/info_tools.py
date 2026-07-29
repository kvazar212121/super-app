"""FOYDALI MA'LUMOT toollari — tashqi API'lar (ob-havo, valyuta, namoz vaqtlari)."""
import json

import httpx
from sqlalchemy.ext.asyncio import AsyncSession


# Qo'llab-quvvatlanadigan shaharlar: normalizatsiya kaliti → (ko'rsatiladigan nom, lat, lng).
# So'ralган shahar shu yerда bo'lsagina o'sha shahar koordinatasi ishlatiladi —
# Tashkent ma'lumotini boshqa shahar nomi bilan YORLIQLAMAYMIZ.
_WEATHER_CITIES = {
    "toshkent": ("Toshkent", 41.2995, 69.2401),
    "tashkent": ("Toshkent", 41.2995, 69.2401),
    "samarqand": ("Samarqand", 39.6270, 66.9750),
    "samarkand": ("Samarqand", 39.6270, 66.9750),
    "buxoro": ("Buxoro", 39.7680, 64.4210),
    "bukhara": ("Buxoro", 39.7680, 64.4210),
    "andijon": ("Andijon", 40.7830, 72.3440),
    "andijan": ("Andijon", 40.7830, 72.3440),
    "namangan": ("Namangan", 41.0011, 71.6725),
    "farg'ona": ("Farg'ona", 40.3860, 71.7870),
    "fargona": ("Farg'ona", 40.3860, 71.7870),
    "fergana": ("Farg'ona", 40.3860, 71.7870),
    "nukus": ("Nukus", 42.4600, 59.6170),
    "qarshi": ("Qarshi", 38.8600, 65.7990),
    "termiz": ("Termiz", 37.2240, 67.2780),
}
_WEATHER_SUPPORTED = [
    "Toshkent", "Samarqand", "Buxoro", "Andijon",
    "Namangan", "Farg'ona", "Nukus", "Qarshi", "Termiz",
]


async def get_weather(db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None) -> tuple[str, dict | None]:
    raw = (args.get("city") or "Toshkent").strip()
    key = raw.lower().replace("‘", "'").replace("’", "'")
    entry = _WEATHER_CITIES.get(key)
    if entry is None:
        # Bilib turib noto'g'ri yorliq bermaymiz — shahar qo'llab-quvvatlanmasligini rostini aytamiz.
        return json.dumps({
            "status": "unsupported_city",
            "message": f"'{raw}' shahri uchun ob-havo ma'lumoti hozircha mavjud emas.",
            "supported_cities": _WEATHER_SUPPORTED,
        }, ensure_ascii=False), None
    label, lat, lng = entry
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(
                f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lng}&current_weather=true"
            )
            resp.raise_for_status()
            cur = resp.json().get("current_weather", {})
            return json.dumps({"status": "success", "city": label,
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
