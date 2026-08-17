"""E'lon qaysi ustalarga ko'rinishi — HUDUD bo'yicha filtr.

Foydalanuvchi talabi:
    "bu elani bir huddagi odamlar yani ustalar kora olishi kerak
     masalan toshkent shaxardan bo'lsa shuni ichidan"

MUAMMO: hozir usta lentasi faqat KATEGORIYA bo'yicha filtrlaydi,
ya'ni Buxorodagi elektrik Toshkentdagi e'lonni ko'radi va bekorga
taklif beradi. Mijoz esa kela olmaydigan ustadan taklif oladi.

YECHIM (uch bosqichli, chunki ma'lumot har doim to'liq emas):
    1. E'londa ham, ustada ham koordinata bor -> masofa hisoblanadi
    2. Koordinata yo'q -> manzil matnidan shahar solishtiriladi
    3. Ikkalasi ham noaniq -> e'lon KO'RSATILADI

3-qoida ataylab: e'lon ko'rinmay qolgandan ko'ra, ortiqcha ko'ringani
yaxshi. Aks holda eski provayderlar (koordinatasiz) hech qachon
e'lon ko'rmay qoladi.
"""
from __future__ import annotations

import math

# Standart radius. Toshkent shahri diametri ~30 km, shuning uchun
# 50 km butun shaharni va yaqin tumanlarni qamraydi.
DEFAULT_RADIUS_KM = 50.0

# Yirik shaharlar/viloyatlar — manzil matnidan taniш uchun.
# Koordinata bo'lmaganda ishlatiladi.
_REGIONS = {
    "toshkent": {"toshkent", "тошкент", "ташкент", "tashkent"},
    "samarqand": {"samarqand", "самарканд", "самарқанд", "samarkand"},
    "buxoro": {"buxoro", "бухара", "бухоро", "bukhara"},
    "andijon": {"andijon", "андижан", "андижон", "andijan"},
    "farg'ona": {"farg'ona", "fargona", "фергана", "фарғона", "fergana"},
    "namangan": {"namangan", "наманган"},
    "qashqadaryo": {"qashqadaryo", "кашкадарья", "qarshi", "карши"},
    "surxondaryo": {"surxondaryo", "сурхандарья", "termiz", "термез"},
    "jizzax": {"jizzax", "джизак", "жиззах"},
    "sirdaryo": {"sirdaryo", "сырдарья", "guliston", "гулистан"},
    "navoiy": {"navoiy", "навои", "навоий"},
    "xorazm": {"xorazm", "хорезм", "urganch", "ургенч"},
    "qoraqalpogiston": {"qoraqalpog", "каракалпак", "nukus", "нукус"},
}


def distance_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Ikki nuqta orasidagi masofa (km) — haversine formulasi.

    provider_tools.py dagi bilan bir xil. U yerda ichki funksiya
    bo'lgani uchun bu yerga ko'chirildi (import halqasi bo'lmasin).
    """
    r = 6371.0  # Yer radiusi (km)
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lng2 - lng1)
    a = (
        math.sin(dp / 2) ** 2
        + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    )
    return 2 * r * math.asin(math.sqrt(a))


def region_of(address: str | None) -> str | None:
    """Manzil matnidan hudud nomini topadi. Topilmasa None."""
    if not address:
        return None
    text = address.lower()
    for region, aliases in _REGIONS.items():
        for alias in aliases:
            if alias in text:
                return region
    return None


def radius_km() -> float:
    """Qidiruv radiusi — admin panelidan sozlanadi.

    Toshkent ichida 50 km ko'p bo'lishi, viloyatlarda esa kam
    bo'lishi mumkin, shuning uchun qat'iy raqam qoldirilmadi.
    """
    try:
        from app.services import settings_service
        raw = settings_service.get("jobs_radius_km", "")
        return float(raw) if raw else DEFAULT_RADIUS_KM
    except Exception:
        return DEFAULT_RADIUS_KM


def is_visible_to_provider(
    job_lat: float | None,
    job_lng: float | None,
    job_address: str | None,
    prov_lat: float | None,
    prov_lng: float | None,
    prov_address: str | None,
    max_km: float | None = None,
) -> bool:
    """Shu e'lon shu ustaga ko'rinadimi.

    Yuqoridagi uch bosqichli qoida bo'yicha.
    """
    limit = max_km if max_km is not None else radius_km()

    # 1) Ikkalasida ham koordinata bor — aniq masofa
    if (
        job_lat is not None and job_lng is not None
        and prov_lat is not None and prov_lng is not None
    ):
        return distance_km(job_lat, job_lng, prov_lat, prov_lng) <= limit

    # 2) Koordinata yo'q — manzil matnidan hudud
    job_region = region_of(job_address)
    prov_region = region_of(prov_address)
    if job_region and prov_region:
        return job_region == prov_region

    # 3) Aniqlab bo'lmadi — ko'rsatamiz (e'lon yo'qolib qolmasin)
    return True


def filter_jobs_for_provider(jobs: list[dict], provider) -> list[dict]:
    """E'lonlar ro'yxatidan shu ustaga tegishlilarini qoldiradi.

    `jobs` — JobPost.to_dict() natijalari.
    """
    limit = radius_km()
    prov_lat = getattr(provider, "lat", None)
    prov_lng = getattr(provider, "lng", None)
    prov_address = getattr(provider, "address", None)

    out = []
    for job in jobs:
        if is_visible_to_provider(
            job.get("lat"), job.get("lng"), job.get("address"),
            prov_lat, prov_lng, prov_address,
            max_km=limit,
        ):
            # Usta uchun foydali: qancha uzoqligini ko'rsatamiz
            if (
                job.get("lat") is not None and job.get("lng") is not None
                and prov_lat is not None and prov_lng is not None
            ):
                job = dict(job)
                job["distance_km"] = round(
                    distance_km(job["lat"], job["lng"], prov_lat, prov_lng), 1
                )
            out.append(job)
    return out
