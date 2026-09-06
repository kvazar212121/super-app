from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import func, select, or_, desc
from sqlalchemy.orm import selectinload

from app.db.session import get_db
from app.models.user import User
from app.models.provider import Provider
from app.schemas.provider import ProviderCreate, ProviderUpdate, ProviderOut
from app.schemas.common import PaginatedResponse
from app.api.v1.admin.dependencies import require_admin

router = APIRouter()


@router.get("/providers", response_model=PaginatedResponse)
async def list_providers(
    search: str | None = Query(None),
    category_id: int | None = Query(None),
    is_active: bool | None = Query(None),
    min_rating: float | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    query = select(Provider).options(
        selectinload(Provider.category),
        selectinload(Provider.owner)
    )

    if search:
        query = query.where(
            or_(
                Provider.name.ilike(f"%{search}%"),
                Provider.address.ilike(f"%{search}%"),
                Provider.phone.ilike(f"%{search}%"),
            )
        )
    if category_id is not None:
        query = query.where(Provider.category_id == category_id)
    if is_active is not None:
        query = query.where(Provider.is_active == is_active)
    if min_rating is not None:
        query = query.where(Provider.rating >= min_rating)

    count_query = select(func.count()).select_from(Provider)
    if search:
        count_query = count_query.where(
            or_(
                Provider.name.ilike(f"%{search}%"),
                Provider.address.ilike(f"%{search}%"),
            )
        )
    if category_id is not None:
        count_query = count_query.where(Provider.category_id == category_id)
    if is_active is not None:
        count_query = count_query.where(Provider.is_active == is_active)
    if min_rating is not None:
        count_query = count_query.where(Provider.rating >= min_rating)

    total = int(await db.scalar(count_query) or 0)

    query = query.order_by(desc(Provider.rating)).offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(query)
    items = result.scalars().all()

    out_items = []
    for p in items:
        d = p.to_dict()
        d["category_title"] = p.category.title_uz if p.category else None
        d["owner_balance"] = p.owner.balance if p.owner else None
        d["owner_phone"] = p.owner.phone if p.owner else None
        out_items.append(d)

    pages = (total + per_page - 1) // per_page
    return PaginatedResponse(items=out_items, total=total, page=page, per_page=per_page, pages=pages)


@router.patch("/providers/{provider_id}/approve")
async def approve_provider(
    provider_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Provider).where(Provider.id == provider_id))
    p = result.scalar_one_or_none()
    if not p:
        raise HTTPException(status_code=404, detail="Provayder topilmadi")
    p.is_active = True
    meta = dict(p.metadata_json or {})
    if meta.get("type") == "nanny":
        meta["verification_status"] = "verified"
        meta["nanny_role"] = "verified"
        docs = dict(meta.get("documents") or {})
        if docs.get("medical_cert_url"):
            docs["medical_cert"] = True
        if docs.get("id_url"):
            docs["id_verified"] = True
        if docs.get("criminal_record_url"):
            docs["criminal_record"] = True
        meta["documents"] = docs
        p.metadata_json = meta
    elif meta.get("type") in ("tutor", "education_center"):
        meta["verification_status"] = "verified"
        p.metadata_json = meta
    elif meta.get("type") == "disinfection":
        meta["verification_status"] = "verified"
        p.metadata_json = meta
    elif meta.get("type") == "massage":
        meta["verification_status"] = "verified"
        p.metadata_json = meta
    elif meta.get("type") in ("nurse", "dental_clinic", "event_organizer"):
        meta["verification_status"] = "verified"
        p.metadata_json = meta
    await db.flush()
    return {"message": "Provayder tasdiqlandi", "provider_id": provider_id}


@router.patch("/providers/{provider_id}/reject")
async def reject_provider(
    provider_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Provider).where(Provider.id == provider_id))
    p = result.scalar_one_or_none()
    if not p:
        raise HTTPException(status_code=404, detail="Provayder topilmadi")
    p.is_active = False
    meta = dict(p.metadata_json or {})
    if meta.get("type") == "nanny":
        meta["verification_status"] = "rejected"
        meta["nanny_role"] = "rejected"
        p.metadata_json = meta
    elif meta.get("type") in ("tutor", "education_center"):
        meta["verification_status"] = "rejected"
        p.metadata_json = meta
    elif meta.get("type") == "disinfection":
        meta["verification_status"] = "rejected"
        p.metadata_json = meta
    elif meta.get("type") == "massage":
        meta["verification_status"] = "rejected"
        p.metadata_json = meta
    elif meta.get("type") in ("nurse", "dental_clinic", "event_organizer"):
        meta["verification_status"] = "rejected"
        p.metadata_json = meta
    await db.flush()
    return {"message": "Provayder rad etildi", "provider_id": provider_id}


async def _get_provider(db, provider_id):
    p = (await db.execute(select(Provider).where(Provider.id == provider_id))).scalar_one_or_none()
    if not p:
        raise HTTPException(status_code=404, detail="Provayder topilmadi")
    return p


@router.patch("/providers/{provider_id}/verify")
async def verify_provider(provider_id: int, _admin: User = Depends(require_admin), db: AsyncSession = Depends(get_db)):
    p = await _get_provider(db, provider_id)
    p.is_verified = True
    meta = dict(p.metadata_json or {})
    meta["verification_status"] = "verified"
    p.metadata_json = meta
    await db.flush()
    return {"message": "Provayder tasdiqlandi (verified)", "provider_id": provider_id}


@router.patch("/providers/{provider_id}/block")
async def block_provider(provider_id: int, _admin: User = Depends(require_admin), db: AsyncSession = Depends(get_db)):
    p = await _get_provider(db, provider_id)
    p.is_blocked = True
    p.is_active = False
    await db.flush()
    return {"message": "Provayder bloklandi", "provider_id": provider_id}


@router.patch("/providers/{provider_id}/unblock")
async def unblock_provider(provider_id: int, _admin: User = Depends(require_admin), db: AsyncSession = Depends(get_db)):
    p = await _get_provider(db, provider_id)
    p.is_blocked = False
    p.is_active = True
    await db.flush()
    return {"message": "Blok olindi", "provider_id": provider_id}


@router.get("/providers/{provider_id}/kyc")
async def provider_kyc(provider_id: int, _admin: User = Depends(require_admin), db: AsyncSession = Depends(get_db)):
    p = await _get_provider(db, provider_id)
    meta = p.metadata_json or {}
    return {
        "provider_id": provider_id,
        "name": p.name,
        "is_verified": p.is_verified,
        "is_blocked": p.is_blocked,
        "verification_status": meta.get("verification_status"),
        "documents": meta.get("documents") or {},
        "metadata": meta,
    }


@router.patch("/providers/{provider_id}/rating")
async def update_provider_rating(
    provider_id: int,
    rating: float = Query(..., ge=0, le=5),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Provider).where(Provider.id == provider_id))
    p = result.scalar_one_or_none()
    if not p:
        raise HTTPException(status_code=404, detail="Provayder topilmadi")
    p.rating = rating
    await db.flush()
    return {"message": "Reyting yangilandi", "provider_id": provider_id, "rating": rating}


@router.post("/providers", response_model=ProviderOut, status_code=201)
async def create_provider(
    data: ProviderCreate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    p = Provider(**data.model_dump(exclude={"metadata_json"}))
    if data.metadata_json:
        p.metadata_json = data.metadata_json
    db.add(p)
    await db.flush()
    await db.refresh(p)
    return p


@router.patch("/providers/{provider_id}", response_model=ProviderOut)
async def update_provider(
    provider_id: int,
    data: ProviderUpdate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Provider).where(Provider.id == provider_id))
    p = result.scalar_one_or_none()
    if not p:
        raise HTTPException(status_code=404, detail="Provayder topilmadi")
    update_data = data.model_dump(exclude_unset=True, exclude={"metadata_json"})
    for key, val in update_data.items():
        setattr(p, key, val)
    if data.metadata_json is not None:
        p.metadata_json = data.metadata_json
    await db.flush()
    await db.refresh(p)
    return p


@router.delete("/providers/{provider_id}", status_code=204)
async def delete_provider(
    provider_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Provider).where(Provider.id == provider_id))
    p = result.scalar_one_or_none()
    if not p:
        raise HTTPException(status_code=404, detail="Provayder topilmadi")
    await db.delete(p)
