"""Ish e'lonlari: mijoz e'lon beradi, ustalar taklif beradi.

MIJOZ:
  POST   /jobs                      e'lon berish (rasm, summa, muddat)
  GET    /jobs/my                   o'z e'lonlarim
  GET    /jobs/{id}/offers          kelgan takliflar
  POST   /jobs/{id}/offers/{oid}/accept   ustani tanlash
  POST   /jobs/{id}/complete        ishni yakunlash
  DELETE /jobs/{id}                 bekor qilish

USTA (soha egasi paneli):
  GET    /jobs/feed                 ochiq e'lonlar (o'z sohasi bo'yicha)
  POST   /jobs/{id}/offers          taklif berish
  GET    /jobs/offers/my            bergan takliflarim
  DELETE /jobs/offers/{oid}         taklifni qaytarib olish

CHAT: mavjud /messages tizimi ishlatiladi. Taklif javobida
`provider_owner_user_id` bor — mijoz shu foydalanuvchiga yozadi.
RASM: /upload/job-photo orqali yuklanadi, qaytgan URL e'longa qo'shiladi.
"""

from datetime import timezone

from fastapi import APIRouter, Depends, File, Query, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.dependencies import get_current_user
from app.db.session import get_db
from app.models.user import User
from app.schemas.common import UrlResponse
from app.schemas.job import JobCreate, JobOut, MyOfferOut, OfferCreate, OfferOut
from app.services.ai_job.limits import check_can_create_job, expires_at_for
from app.services.job_service import JobService
from app.services.upload_service import UploadService

router = APIRouter(prefix="/jobs", tags=["jobs"])


# ── Rasm yuklash ─────────────────────────────────────────────────────
@router.post("/photo", response_model=UrlResponse)
async def upload_job_photo(
    file: UploadFile = File(...),
    _user: User = Depends(get_current_user),
):
    """Ish joyining rasmini yuklash — URL qaytaradi."""
    url = await UploadService.upload_job_photo(file)
    return UrlResponse(url=url)


# ── Mijoz ────────────────────────────────────────────────────────────
@router.post("", response_model=JobOut, status_code=201)
async def create_job(
    data: JobCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    # Chegaralar AI orqali berilgan e'longa ham, oddiy formaga ham
    # BIR XIL qo'llanadi. Ilgari tekshiruv faqat AI tool'ida edi, ya'ni
    # foydalanuvchi oddiy forma orqali cheklovni chetlab o'ta olardi.
    await check_can_create_job(db, current_user)

    payload = data.model_dump()
    # Muddat: oddiy foydalanuvchiga 5 kun, premiumga cheksiz. Mijoz
    # o'zi qisqaroq muddat bergan bo'lsa — uniki qoladi.
    limit_expires = expires_at_for(current_user)
    if limit_expires is not None:
        given = payload.get("expires_at")
        # Mijoz vaqt mintaqasiz sana yuborishi mumkin — solishtirishda
        # TypeError bo'lmasligi uchun UTC deb qaraymiz.
        if given is not None and given.tzinfo is None:
            given = given.replace(tzinfo=timezone.utc)
        if given is None or given > limit_expires:
            payload["expires_at"] = limit_expires

    job = await JobService.create(db, current_user.id, payload)
    return JobOut(**job.to_dict())


@router.get("/my", response_model=list[JobOut])
async def my_jobs(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await JobService.list_for_client(db, current_user.id)


# ── Usta lentasi ─────────────────────────────────────────────────────
# DIQQAT: bu /{job_id} dan OLDIN turishi kerak, aks holda "feed" so'zi
# job_id sifatida o'qilib 422 qaytadi.
@router.get("/feed", response_model=list[JobOut])
async def jobs_feed(
    category_id: int | None = Query(None, description="Soha bo'yicha filtr"),
    provider_id: int | None = Query(
        None,
        description=(
            "Usta provayderi. Berilsa e'lonlar HUDUD bo'yicha "
            "filtrlanadi — boshqa shahardagi e'lon ko'rinmaydi."
        ),
    ),
    limit: int = Query(50, ge=1, le=200),
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Ustalar ko'radigan ochiq e'lonlar.

    `provider_id` berilsa faqat SHU HUDUDDAGI e'lonlar qaytadi:
    Buxorodagi usta Toshkentdagi e'lonni ko'rib, bekorga taklif
    bermasligi uchun.
    """
    if provider_id is None:
        return await JobService.list_for_providers(db, category_id, limit)

    from app.models.provider import Provider
    from app.services.ai_job.geo import filter_jobs_for_provider

    provider = await db.get(Provider, provider_id)
    if provider is None:
        return await JobService.list_for_providers(db, category_id, limit)

    # Masofa filtri `LIMIT` dan OLDIN, SQL'da qo'llanadi. Keyingi Python
    # bosqichi faqat koordinatasiz e'lonlarni manzil matni bo'yicha saralaydi.
    jobs = await JobService.list_for_providers(db, category_id, limit, provider)
    return filter_jobs_for_provider(jobs, provider)


@router.get("/offers/my", response_model=list[MyOfferOut])
async def my_offers(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Ustaning bergan takliflari."""
    return await JobService.my_offers(db, current_user.id)


@router.delete("/offers/{offer_id}", response_model=OfferOut)
async def withdraw_offer(
    offer_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    offer = await JobService.withdraw_offer(db, offer_id, current_user.id)
    return OfferOut(**offer.to_dict())


@router.get("/{job_id}", response_model=JobOut)
async def get_job(
    job_id: int,
    _user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    job = await JobService.get_by_id(db, job_id)
    return JobOut(**job.to_dict(offers_count=len(job.offers)))


@router.delete("/{job_id}", response_model=JobOut)
async def cancel_job(
    job_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    job = await JobService.cancel(db, job_id, current_user.id)
    return JobOut(**job.to_dict())


@router.post("/{job_id}/complete", response_model=JobOut)
async def complete_job(
    job_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    job = await JobService.complete(db, job_id, current_user.id)
    return JobOut(**job.to_dict())


# ── Takliflar ────────────────────────────────────────────────────────
@router.post("/{job_id}/offers", response_model=OfferOut, status_code=201)
async def make_offer(
    job_id: int,
    data: OfferCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Usta taklif beradi (o'z provayderi nomidan)."""
    offer = await JobService.make_offer(db, job_id, current_user.id, data.model_dump())
    return OfferOut(**offer.to_dict())


@router.get("/{job_id}/offers", response_model=list[OfferOut])
async def list_offers(
    job_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """E'longa kelgan takliflar (faqat e'lon egasi ko'radi)."""
    return await JobService.list_offers(db, job_id, current_user.id)


@router.post("/{job_id}/offers/seen", status_code=204)
async def mark_seen(
    job_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await JobService.mark_offers_seen(db, job_id, current_user.id)


@router.post("/{job_id}/offers/{offer_id}/accept", response_model=JobOut)
async def accept_offer(
    job_id: int,
    offer_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Mijoz ustani tanlaydi. Qolgan takliflar avtomatik rad etiladi."""
    job = await JobService.accept_offer(db, job_id, offer_id, current_user.id)
    return JobOut(**job.to_dict())
