"""Savdo (marketplace): buyum e'lonlari.

XARIDOR:
  GET    /marketplace/categories        toifalar va maydonlar
  GET    /marketplace/search            qidiruv (filtr + saralash)
  GET    /marketplace/{id}              bitta e'lon (modal uchun)
  GET    /marketplace/{id}/safety       aloqadan oldingi ogohlantirish
  POST   /marketplace/{id}/report       shikoyat (support'ga tushadi)

SOTUVCHI:
  POST   /marketplace/photo             rasm yuklash
  POST   /marketplace                   e'lon berish
  GET    /marketplace/my/list           mening e'lonlarim
  POST   /marketplace/{id}/sold         sotildi
  POST   /marketplace/{id}/hide         yashirish
  POST   /marketplace/{id}/reopen       qayta e'lon
  POST   /marketplace/{id}/extend       muddatni uzaytirish (to'lov/premium)

DIQQAT: hech bir javobda sotuvchining TELEFON RAQAMI yo'q. Aloqa
faqat ilova ichida (chat/WebRTC) — bu loyihaning qat'iy qoidasi.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.common import UrlResponse
from app.services.marketplace import (
    ListingDraft, category_list, close_listing, create_listing, get_public,
    mark_sold, my_listings, reopen_listing, resolve_category, search_listings,
)
from app.services.marketplace.currency import to_uzs, usd_rate
from app.services.marketplace.draft import parse_condition
from app.services.marketplace.extend import extend_info, extend_listing
from app.services.marketplace.fields import field_checklist, optional_checklist
from app.services.marketplace.limits import (
    disabled_message, marketplace_enabled, max_photos, min_photos,
)
from app.services.marketplace.safety import report_listing, warning_payload
from app.services.upload_service import UploadService

router = APIRouter(prefix="/marketplace", tags=["marketplace"])


def _guard() -> None:
    """Bo'lim adminkadan o'chirilgan bo'lsa hech narsa ishlamaydi."""
    if not marketplace_enabled():
        raise HTTPException(status_code=403, detail=disabled_message())


class ListingCreate(BaseModel):
    category: str | None = None
    title: str = Field(min_length=3, max_length=200)
    description: str = ""
    price: float | None = None
    currency: str = "UZS"
    is_negotiable: bool = False
    condition: str | None = None
    address: str = Field(min_length=3, max_length=500)
    lat: float | None = None
    lng: float | None = None
    attributes: dict = Field(default_factory=dict)
    photos: list[str] = Field(default_factory=list)


class ReportIn(BaseModel):
    reason: str = ""


# ── Ma'lumot ─────────────────────────────────────────────────────────
@router.get("/categories")
async def categories(lang: str = "uz"):
    """Toifalar + har biriga kerak bo'ladigan maydonlar (ilova formasi uchun)."""
    _guard()
    return {
        "categories": [
            {**c,
             "required_fields": field_checklist(c["key"], lang),
             "optional_fields": optional_checklist(c["key"], lang)}
            for c in category_list(lang)
        ],
        "min_photos": min_photos(),
        "max_photos": max_photos(),
    }


@router.get("/search")
async def search(
    query: str | None = None,
    category: str | None = None,
    price_min: float | None = None,
    price_max: float | None = None,
    condition: str | None = None,
    lat: float | None = None,
    lng: float | None = None,
    radius_km: float | None = None,
    sort: str = "relevant",
    limit: int = Query(20, ge=1, le=20),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Xaridor qidiruvi. Narxlar SO'MDA (`price_uzs`) qaytadi."""
    _guard()
    return await search_listings(
        db, query=query, category=category, price_min=price_min,
        price_max=price_max, condition=condition, lat=lat, lng=lng,
        radius_km=radius_km, sort=sort, limit=limit,
        exclude_user_id=current_user.id,
    )


# ── Sotuvchi ─────────────────────────────────────────────────────────
# DIQQAT: aniq yo'llar /{listing_id} dan OLDIN turishi kerak, aks
# holda "my" so'zi listing_id sifatida o'qilib 422 qaytadi.
@router.post("/photo", response_model=UrlResponse)
async def upload_photo(
    file: UploadFile = File(...),
    _user: User = Depends(get_current_user),
):
    _guard()
    return UrlResponse(url=await UploadService.upload_listing_photo(file))


@router.get("/my/list")
async def my_list(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """«Mening e'lonlarim» — uzaytirish narxi bilan."""
    _guard()
    rows = await my_listings(db, current_user.id)
    rate = await usd_rate()
    return {
        "listings": [r.to_dict(price_uzs=to_uzs(r.price, r.currency, rate))
                     for r in rows],
        "extend": extend_info(current_user),
    }


@router.post("", status_code=201)
async def create(
    data: ListingCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """E'lon berish (oddiy forma orqali).

    Chegaralar AI oqimi bilan BIR XIL: formadan chetlab o'tib
    bo'lmaydi.
    """
    _guard()
    draft = ListingDraft(
        category_key=resolve_category(data.category or data.title),
        title=data.title,
        description=data.description or data.title,
        price=data.price,
        currency=(data.currency or "UZS").upper(),
        is_negotiable=data.is_negotiable,
        condition=parse_condition(data.condition),
        address=data.address,
        lat=data.lat,
        lng=data.lng,
        attributes=data.attributes or {},
        photos=list(data.photos or []),
    )
    listing = await create_listing(db, current_user, draft)
    rate = await usd_rate()
    return listing.to_dict(
        price_uzs=to_uzs(listing.price, listing.currency, rate))


@router.get("/{listing_id}")
async def detail(
    listing_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Bitta e'lon. Ko'rishlar soni oshadi (egasiniki sanalmaydi)."""
    _guard()
    return await get_public(db, listing_id, viewer_id=current_user.id)


@router.get("/{listing_id}/safety")
async def safety(listing_id: int, lang: str = "uz",
                 _user: User = Depends(get_current_user)):
    """Sotuvchi bilan aloqadan OLDIN ko'rsatiladigan ogohlantirish."""
    _guard()
    return warning_payload(listing_id, lang)


@router.post("/{listing_id}/report")
async def report(
    listing_id: int,
    data: ReportIn,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Shikoyat — mavjud support tizimiga tushadi."""
    _guard()
    ticket_id = await report_listing(db, current_user.id, listing_id,
                                     data.reason)
    return {"status": "ok", "ticket_id": ticket_id}


@router.post("/{listing_id}/sold")
async def sold(
    listing_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    _guard()
    listing = await mark_sold(db, current_user.id, listing_id)
    return listing.to_dict()


@router.post("/{listing_id}/hide")
async def hide(
    listing_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    _guard()
    listing = await close_listing(db, current_user.id, listing_id)
    return listing.to_dict()


@router.post("/{listing_id}/reopen")
async def reopen(
    listing_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    _guard()
    listing = await reopen_listing(db, current_user, listing_id)
    return listing.to_dict()


@router.post("/{listing_id}/extend")
async def extend(
    listing_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Muddatni uzaytirish. Premium bepul, boshqasi balansdan."""
    _guard()
    listing = await extend_listing(db, current_user, listing_id)
    return listing.to_dict()
