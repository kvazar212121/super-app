from fastapi import APIRouter
import random
import httpx

router = APIRouter(prefix="/utilities", tags=["utilities"])

@router.get("/weather")
async def get_weather(city: str = "Tashkent"):
    # Mocking weather since we don't have an API key. 
    # In real app, we would use OpenWeatherMap or similar.
    return {
        "city": city,
        "temperature_celsius": random.randint(10, 35),
        "condition": random.choice(["Quyoshli", "Bulutli", "Yomg'ir", "Shamol"]),
        "humidity": random.randint(30, 80)
    }

@router.get("/currency")
async def get_currency():
    # Calling CBU API for real currency rates
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get("https://cbu.uz/uz/arkhiv-kursov-valyut/json/")
            response.raise_for_status()
            data = response.json()
            # Filter USD, EUR, RUB
            rates = [item for item in data if item["Ccy"] in ["USD", "EUR", "RUB"]]
            return {"rates": rates}
    except Exception as e:
        return {"error": "Could not fetch currency", "details": str(e)}

@router.get("/prayer-times")
async def get_prayer_times(city: str = "Tashkent"):
    # Calling Aladhan API
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"https://api.aladhan.com/v1/timingsByCity?city={city}&country=Uzbekistan&method=3")
            response.raise_for_status()
            data = response.json()
            return {"timings": data["data"]["timings"], "date": data["data"]["date"]["gregorian"]["date"]}
    except Exception as e:
        return {"error": "Could not fetch prayer times", "details": str(e)}
