"""Xaridor qidiruvi: filtr + saralash.

RAG (vektor qidiruv) ATAYLAB ishlatilmaydi — foydalanuvchi qarori.
Asosiy filtrlar aniq (toifa, narx, holat, hudud), buni SQL tezroq va
arzonroq bajaradi. AI esa erkin gapni shu filtrlarga aylantiradi.

BARCHA filtr SQL'da bajariladi. Ilgari kod `LIMIT 200` bilan tartibsiz
to'plam olib, narx va masofani Python'da filtrlardi. 500 ming e'lonli
o'lchovda bu qamrovni 0% ga tushirgan: shartga mos 22 ta e'lon
bo'lganda ham foydalanuvchi bo'sh ekran ko'rardi, chunki tasodifiy
200 talik bo'lakka ular tushmasdi.

Saralash: yaqinlik -> yangilik. Narx bo'yicha saralash `sort` bilan.
"""
from __future__ import annotations

import math
from datetime import datetime, timezone

from sqlalchemy import Float, case, cast, func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.marketplace import Listing, ListingCondition, ListingStatus

from .currency import usd_rate
from .fields import resolve_category

# Chatdagi grid 20 tagacha karta ko'rsatadi (foydalanuvchi talabi).
MAX_RESULTS = 20

# Bir gradus kenglik ~111 km. Bounding box uchun yetarli aniqlik.
_KM_PER_DEG_LAT = 111.0


def _distance_expr(lat: float, lng: float):
    """Haversine masofasi (km) — SQL ifodasi sifatida."""
    return 6371.0 * 2 * func.asin(func.sqrt(
        func.power(func.sin(func.radians(Listing.lat - lat) / 2), 2)
        + func.cos(func.radians(lat))
        * func.cos(func.radians(Listing.lat))
        * func.power(func.sin(func.radians(Listing.lng - lng) / 2), 2)
    ))


async def search_listings(
    db: AsyncSession,
    *,
    query: str | None = None,
    category: str | None = None,
    price_min: float | None = None,
    price_max: float | None = None,
    condition: str | None = None,
    lat: float | None = None,
    lng: float | None = None,
    radius_km: float | None = None,
    sort: str = "relevant",
    limit: int = MAX_RESULTS,
    exclude_user_id: int | None = None,
) -> list[dict]:
    """Xaridor uchun e'lonlar. Har element `Listing.to_dict()` ko'rinishi.

    `price_min/max` — SO'MDA (xaridor so'mda o'ylaydi). Dollarli
    e'lonlar joriy kursga ko'ra SQL ichida taqqoslanadi.
    """
    rate = await usd_rate()

    # Narx so'mda — kurs kunlik o'zgargani uchun ustunda saqlanmaydi,
    # har so'rovda joriy kurs bilan hisoblanadi.
    price_uzs = case(
        (Listing.currency == "USD", Listing.price * rate),
        else_=cast(Listing.price, Float),
    )

    geo_bor = lat is not None and lng is not None
    masofa = _distance_expr(lat, lng) if geo_bor else None

    ustunlar = [Listing, price_uzs.label("price_uzs")]
    if geo_bor:
        ustunlar.append(masofa.label("distance_km"))

    stmt = select(*ustunlar).where(Listing.status == ListingStatus.active)

    if category:
        stmt = stmt.where(Listing.category_key == resolve_category(category))

    if query:
        naqsh = f"%{query.strip()}%"
        stmt = stmt.where(or_(
            Listing.title.ilike(naqsh),
            Listing.description.ilike(naqsh),
        ))

    if condition:
        try:
            stmt = stmt.where(Listing.condition == ListingCondition(condition))
        except ValueError:
            pass  # noma'lum holat filtri e'tiborsiz qoldiriladi

    if exclude_user_id is not None:
        # O'z e'loningni sotib olmaysan — qidiruvda ko'rinishi ortiqcha.
        stmt = stmt.where(Listing.user_id != exclude_user_id)

    # Muddati tugaganini ko'rsatmaymiz (scheduler kechikkan bo'lishi mumkin).
    now = datetime.now(timezone.utc)
    stmt = stmt.where(or_(Listing.expires_at.is_(None),
                          Listing.expires_at > now))

    # Narxi yo'q e'lon ("Kelishamiz") narx filtridan TUSHIB QOLMAYDI —
    # eski Python mantig'i ham shunday edi.
    if price_min is not None:
        stmt = stmt.where(or_(Listing.price.is_(None), price_uzs >= price_min))
    if price_max is not None:
        stmt = stmt.where(or_(Listing.price.is_(None), price_uzs <= price_max))

    if geo_bor and radius_km is not None:
        d_lat = radius_km / _KM_PER_DEG_LAT
        d_lng = radius_km / (_KM_PER_DEG_LAT * max(math.cos(math.radians(lat)), 0.01))
        stmt = stmt.where(or_(
            # Koordinatasiz e'lon YO'QOLMAYDI (eski xatti-harakat saqlanadi).
            Listing.lat.is_(None),
            Listing.lng.is_(None),
            # Avval bounding box — `ix_listings_active_geo` shu yerda ishlaydi,
            # keyingi haversine faqat qolgan oz sondagi qatorga hisoblanadi.
            (Listing.lat.between(lat - d_lat, lat + d_lat)
             & Listing.lng.between(lng - d_lng, lng + d_lng)
             & (masofa <= radius_km)),
        ))

    stmt = stmt.order_by(*_order_by(sort, price_uzs, masofa if geo_bor else None))
    stmt = stmt.limit(max(1, min(limit, MAX_RESULTS)))

    rows = (await db.execute(stmt)).all()
    natija = []
    for row in rows:
        km = getattr(row, "distance_km", None)
        natija.append(row[0].to_dict(
            distance_km=round(km, 1) if km is not None else None,
            price_uzs=row.price_uzs,
        ))
    return natija


def _order_by(sort: str, price_uzs, masofa):
    """SQL saralash tartibi.

    Standart: avval yaqindagilar, keyin yangilari. Masofasi yo'q e'lon
    oxirida turadi (`NULLS LAST`), lekin YO'QOLMAYDI — koordinatasiz
    eski e'lonlar ham sotilishi kerak.

    Narx bo'yicha saralash SO'MGA o'tkazilgan qiymatda — aks holda
    dollarli e'lon so'mli bilan noto'g'ri solishtiriladi.
    """
    if sort == "price_asc":
        return (price_uzs.asc().nullslast(),)
    if sort == "price_desc":
        return (price_uzs.desc().nullslast(),)
    if sort == "new":
        return (Listing.created_at.desc(), Listing.id.desc())
    if masofa is not None:
        return (masofa.asc().nullslast(), Listing.created_at.desc())
    return (Listing.created_at.desc(), Listing.id.desc())
