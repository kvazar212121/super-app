from fastapi import APIRouter
import httpx
from datetime import datetime

router = APIRouter(prefix="/utilities", tags=["utilities"])

WEATHER_CODES = {
    0: "Ochiq havo",
    1: "Asosan ochiq",
    2: "Qisman bulutli",
    3: "Bulutli",
    45: "Tumanli",
    48: "Quyuq tuman",
    51: "Yengil shabada",
    53: "O'rtacha shabada",
    55: "Kuchli shabada",
    61: "Yengil yomg'ir",
    63: "O'rtacha yomg'ir",
    65: "Kuchli yomg'ir",
    71: "Yengil qor",
    73: "O'rtacha qor",
    75: "Kuchli qor",
    95: "Momaqaldiroq",
    96: "Momaqaldiroq",
    99: "Momaqaldiroq"
}

@router.get("/weather")
async def get_weather(lat: float = 41.2995, lng: float = 69.2401, city: str = "Tashkent"):
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(
                f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lng}&current_weather=true"
            )
            response.raise_for_status()
            data = response.json()
            current = data.get("current_weather", {})
            temp = current.get("temperature", 0)
            code = current.get("weathercode", 0)
            condition = WEATHER_CODES.get(code, "O'zgaruvchan")
            
            return {
                "city": city,
                "temperature": temp,
                "condition": condition,
                "windspeed": current.get("windspeed", 0)
            }
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=f"Could not fetch weather: {str(e)}")

@router.get("/currency")
async def get_currency():
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get("https://cbu.uz/uz/arkhiv-kursov-valyut/json/")
            response.raise_for_status()
            data = response.json()
            target_currencies = ["USD", "EUR", "RUB", "GBP", "KZT"]
            rates = [item for item in data if item["Ccy"] in target_currencies]
            # Optional: sort them so they always appear in a predictable order
            rates.sort(key=lambda x: target_currencies.index(x["Ccy"]))
            return {"rates": rates}
    except Exception as e:
        from fastapi import HTTPException
        raise HTTPException(status_code=500, detail=f"Could not fetch currency: {str(e)}")

@router.get("/prayer-times")
async def get_prayer_times(city: str = "Tashkent"):
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(f"https://api.aladhan.com/v1/timingsByCity?city={city}&country=Uzbekistan&method=3")
            response.raise_for_status()
            data = response.json()
            return {"timings": data["data"]["timings"], "date": data["data"]["date"]["gregorian"]["date"]}
    except Exception as e:
        return {"error": "Could not fetch prayer times", "details": str(e)}
