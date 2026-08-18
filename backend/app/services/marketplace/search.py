"""Xaridor qidiruvi: filtr + saralash.

RAG (vektor qidiruv) ATAYLAB ishlatilmaydi — foydalanuvchi qarori.
Asosiy filtrlar aniq (toifa, narx, holat, hudud), buni SQL tezroq va
arzonroq bajaradi. AI esa erkin gapni shu filtrlarga aylantiradi.

Saralash: yaqinlik -> yangilik. Narx bo'yicha saralash so'ralsa
`sort` parametri bilan.
"""
from __future__ import annotations

from datetime import datetime, timezone

from sqlalchemy import or_, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.marketplace import Listing, ListingCondition, ListingStatus
from app.services.ai_job.geo import distance_km

from .currency import to_uzs, usd_rate
from .fields import resolve_category

# Chatdagi grid 20 tagacha karta ko'rsatadi (foydalanuvchi talabi).
MAX_RESULTS = 20


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
    e'lonlar kursga ko'ra taqqoslanadi.
    """
    stmt = select(Listing).where(Listing.status == ListingStatus.active)

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

    # Ko'proq olib, keyin narx/masofa bo'yicha Python'da saralaymiz:
    # narx solishtiruvi valyuta konvertatsiyasini talab qiladi.
    rows = (await db.execute(stmt.limit(200))).scalars().all()

    rate = await usd_rate()
    natija: list[dict] = []
    for item in rows:
        narx_uzs = to_uzs(item.price, item.currency, rate)
        if price_min is not None and narx_uzs is not None and narx_uzs < price_min:
            continue
        if price_max is not None and narx_uzs is not None and narx_uzs > price_max:
            continue

        masofa = None
        if (lat is not None and lng is not None
                and item.lat is not None and item.lng is not None):
            masofa = round(distance_km(lat, lng, item.lat, item.lng), 1)
            if radius_km is not None and masofa > radius_km:
                continue

        natija.append(item.to_dict(distance_km=masofa, price_uzs=narx_uzs))

    natija.sort(key=lambda d: _sort_key(d, sort))
    return natija[: max(1, min(limit, MAX_RESULTS))]


def _sort_key(d: dict, sort: str):
    """Saralash kaliti.

    Standart: avval yaqindagilar, keyin yangilari. Masofasi yo'q
    e'lon oxirida turadi (lekin YO'QOLMAYDI — koordinatasiz eski
    e'lonlar ham sotilishi kerak).
    """
    yaratilgan = d.get("created_at") or ""
    if sort == "price_asc":
        return (d.get("price_uzs") if d.get("price_uzs") is not None else 1e18,)
    if sort == "price_desc":
        return (-(d.get("price_uzs") or 0),)
    if sort == "new":
        return (_teskari(yaratilgan),)
    masofa = d.get("distance_km")
    return (masofa if masofa is not None else 1e9, _teskari(yaratilgan))


def _teskari(iso: str) -> str:
    """Yangi sana oldin chiqishi uchun teskari tartib kaliti."""
    # ISO satrlarni teskari solishtirish uchun har belgini invert
    # qilish shart emas: manfiy timestamp yetarli.
    try:
        return -datetime.fromisoformat(iso).timestamp()
    except (TypeError, ValueError):
        return 0
