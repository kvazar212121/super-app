"""Ish e'lonlari xizmati: barcha biznes qoidalari shu yerda.

QOIDALAR:
  - E'lonni faqat egasi tahrirlaydi/bekor qiladi
  - Taklifni faqat PROVAYDER EGASI beradi (o'z provayderi nomidan)
  - Usta o'z e'loniga taklif bera olmaydi
  - Bitta usta bitta e'longa bitta taklif (DB UNIQUE)
  - Taklif faqat OCHIQ va muddati o'tmagan e'longa beriladi
  - Provayder kategoriyasi e'lon kategoriyasiga mos bo'lishi kerak
  - Taklif qabul qilinsa: qolganlar avtomatik rad etiladi
  - Har bir muhim qadamda ikkala tomonga bildirishnoma boradi
"""

from datetime import datetime, timezone

from fastapi import HTTPException
from sqlalchemy import func, select, update as sa_update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.job import JobOffer, JobPost, JobStatus, OfferStatus
from app.models.provider import Provider


def _now() -> datetime:
    return datetime.now(timezone.utc)


async def _notify(user_id: int | None, ntype: str, title: str, message: str) -> None:
    """Bildirishnoma yuborish. Xato bo'lsa asosiy oqim buzilmaydi."""
    if not user_id:
        return
    try:
        import asyncio

        from app.services.notification_service import NotificationService

        await asyncio.to_thread(
            NotificationService.send_notification, user_id, ntype, title, message
        )
    except Exception:
        pass


class JobService:

    # ── E'lon (mijoz tomoni) ──────────────────────────────────────────
    @staticmethod
    async def get_by_id(db: AsyncSession, job_id: int) -> JobPost:
        job = (await db.execute(
            select(JobPost)
            .options(selectinload(JobPost.offers))
            .where(JobPost.id == job_id)
        )).scalar_one_or_none()
        if not job:
            raise HTTPException(status_code=404, detail="E'lon topilmadi")
        return job

    @staticmethod
    async def create(db: AsyncSession, user_id: int, data: dict) -> JobPost:
        photos = data.pop("photos", None)
        if isinstance(photos, list):
            data["photos"] = ",".join(p for p in photos if p)

        if data.get("budget") is not None and data["budget"] < 0:
            raise HTTPException(status_code=400, detail="Summa manfiy bo'lishi mumkin emas")

        expires = data.get("expires_at")
        if expires and expires <= _now():
            raise HTTPException(
                status_code=400,
                detail="E'lon muddati kelajakda bo'lishi kerak",
            )

        job = JobPost(user_id=user_id, **data)
        db.add(job)
        await db.commit()
        await db.refresh(job)
        return job

    @staticmethod
    async def list_for_client(db: AsyncSession, user_id: int) -> list[dict]:
        """Mijozning o'z e'lonlari + har biriga nechta taklif kelgani."""
        rows = (await db.execute(
            select(JobPost, func.count(JobOffer.id))
            # Qaytarib olingan taklif SANALMAYDI: aks holda mijoz
            # "3 taklif" ko'rib, ochganda 2 tasini topadi.
            .outerjoin(
                JobOffer,
                (JobOffer.job_id == JobPost.id)
                & (JobOffer.status != OfferStatus.withdrawn),
            )
            .where(JobPost.user_id == user_id)
            .group_by(JobPost.id)
            .order_by(JobPost.created_at.desc())
        )).all()
        return [job.to_dict(offers_count=cnt) for job, cnt in rows]

    @staticmethod
    async def list_for_providers(
        db: AsyncSession,
        category_id: int | None = None,
        limit: int = 50,
    ) -> list[dict]:
        """Ustalar ko'radigan OCHIQ e'lonlar."""
        now = _now()
        q = (
            select(JobPost, func.count(JobOffer.id))
            # Usta lentasida ham haqiqiy raqib soni ko'rinsin
            .outerjoin(
                JobOffer,
                (JobOffer.job_id == JobPost.id)
                & (JobOffer.status != OfferStatus.withdrawn),
            )
            .where(JobPost.status == JobStatus.open)
            .where((JobPost.expires_at.is_(None)) | (JobPost.expires_at >= now))
            .group_by(JobPost.id)
            .order_by(JobPost.created_at.desc())
            .limit(limit)
        )
        if category_id is not None:
            q = q.where(JobPost.category_id == category_id)
        rows = (await db.execute(q)).all()
        return [job.to_dict(offers_count=cnt) for job, cnt in rows]

    @staticmethod
    async def cancel(db: AsyncSession, job_id: int, user_id: int) -> JobPost:
        job = await JobService.get_by_id(db, job_id)
        if job.user_id != user_id:
            raise HTTPException(status_code=403, detail="Bu e'lon sizniki emas")
        if job.status == JobStatus.completed:
            raise HTTPException(status_code=400, detail="Yakunlangan e'lonni bekor qilib bo'lmaydi")
        job.status = JobStatus.cancelled
        await db.commit()
        await db.refresh(job)
        return job

    @staticmethod
    async def complete(db: AsyncSession, job_id: int, user_id: int) -> JobPost:
        """Mijoz ishni yakunlangan deb belgilaydi."""
        job = await JobService.get_by_id(db, job_id)
        if job.user_id != user_id:
            raise HTTPException(status_code=403, detail="Bu e'lon sizniki emas")
        if job.status != JobStatus.assigned:
            raise HTTPException(
                status_code=400,
                detail="Faqat usta tanlangan ishni yakunlash mumkin",
            )
        job.status = JobStatus.completed
        job.completed_at = _now()
        await db.commit()
        await db.refresh(job)

        owner_id = await JobService._provider_owner(db, job.assigned_provider_id)
        await _notify(
            owner_id, "job_completed", "Ish yakunlandi",
            f"'{job.title}' ishi mijoz tomonidan yakunlandi.",
        )
        return job

    # ── Taklif (usta tomoni) ──────────────────────────────────────────
    @staticmethod
    async def _provider_owner(db: AsyncSession, provider_id: int | None) -> int | None:
        if not provider_id:
            return None
        return (await db.execute(
            select(Provider.owner_user_id).where(Provider.id == provider_id)
        )).scalar_one_or_none()

    @staticmethod
    async def _owned_provider(
        db: AsyncSession, provider_id: int, user_id: int
    ) -> Provider:
        """Foydalanuvchi shu provayder egasimi?"""
        provider = (await db.execute(
            select(Provider).where(Provider.id == provider_id)
        )).scalar_one_or_none()
        if not provider:
            raise HTTPException(status_code=404, detail="Provayder topilmadi")
        if provider.owner_user_id != user_id:
            raise HTTPException(
                status_code=403,
                detail="Bu provayder sizga tegishli emas",
            )
        return provider

    @staticmethod
    async def make_offer(
        db: AsyncSession, job_id: int, user_id: int, data: dict
    ) -> JobOffer:
        job = await JobService.get_by_id(db, job_id)
        provider = await JobService._owned_provider(db, data["provider_id"], user_id)

        if job.user_id == user_id:
            raise HTTPException(
                status_code=400,
                detail="O'z e'loningizga taklif bera olmaysiz",
            )
        if not job.is_open(_now()):
            raise HTTPException(
                status_code=400,
                detail="Bu e'lon yopilgan yoki muddati o'tgan",
            )
        if provider.category_id != job.category_id:
            raise HTTPException(
                status_code=400,
                detail="Bu e'lon sizning sohangizga tegishli emas",
            )
        if data["price"] <= 0:
            raise HTTPException(status_code=400, detail="Narx musbat bo'lishi kerak")

        offer = JobOffer(job_id=job_id, **data)
        db.add(offer)
        try:
            await db.commit()
        except IntegrityError:
            await db.rollback()
            raise HTTPException(
                status_code=409,
                detail="Siz bu e'longa allaqachon taklif bergansiz",
            )
        await db.refresh(offer)

        await _notify(
            job.user_id, "job_offer", "Yangi taklif",
            f"'{job.title}' e'loningizga {provider.name} taklif berdi: "
            f"{int(offer.price):,} so'm".replace(",", " "),
        )
        return offer

    @staticmethod
    async def withdraw_offer(
        db: AsyncSession, offer_id: int, user_id: int
    ) -> JobOffer:
        offer = (await db.execute(
            select(JobOffer).where(JobOffer.id == offer_id)
        )).scalar_one_or_none()
        if not offer:
            raise HTTPException(status_code=404, detail="Taklif topilmadi")
        await JobService._owned_provider(db, offer.provider_id, user_id)
        if offer.status == OfferStatus.accepted:
            raise HTTPException(
                status_code=400,
                detail="Qabul qilingan taklifni qaytarib olib bo'lmaydi",
            )
        offer.status = OfferStatus.withdrawn
        await db.commit()
        await db.refresh(offer)
        return offer

    @staticmethod
    async def list_offers(
        db: AsyncSession, job_id: int, user_id: int
    ) -> list[dict]:
        """E'lon takliflari. Faqat e'lon egasi ko'radi."""
        job = await JobService.get_by_id(db, job_id)
        if job.user_id != user_id:
            raise HTTPException(status_code=403, detail="Bu e'lon sizniki emas")

        # Usta qaytarib olgan taklif mijozga KO'RSATILMAYDI: aks holda
        # mijoz voz kechilgan taklifni tanlashga urinadi va 400 oladi
        # ("Taklif qaytarib olingan"), ya'ni ishonchsiz his qiladi.
        rows = (await db.execute(
            select(JobOffer, Provider)
            .join(Provider, Provider.id == JobOffer.provider_id)
            .where(
                JobOffer.job_id == job_id,
                JobOffer.status != OfferStatus.withdrawn,
            )
            .order_by(JobOffer.created_at.asc())
        )).all()
        return [offer.to_dict(provider=p) for offer, p in rows]

    @staticmethod
    async def my_offers(db: AsyncSession, user_id: int) -> list[dict]:
        """Ustaning bergan takliflari (o'z provayderlari bo'yicha)."""
        rows = (await db.execute(
            select(JobOffer, JobPost)
            .join(JobPost, JobPost.id == JobOffer.job_id)
            .join(Provider, Provider.id == JobOffer.provider_id)
            .where(Provider.owner_user_id == user_id)
            .order_by(JobOffer.created_at.desc())
        )).all()
        out = []
        for offer, job in rows:
            d = offer.to_dict()
            d["job"] = job.to_dict()
            out.append(d)
        return out

    # ── Taklifni qabul qilish (mijoz) ─────────────────────────────────
    @staticmethod
    async def accept_offer(
        db: AsyncSession, job_id: int, offer_id: int, user_id: int
    ) -> JobPost:
        job = await JobService.get_by_id(db, job_id)
        if job.user_id != user_id:
            raise HTTPException(status_code=403, detail="Bu e'lon sizniki emas")
        if job.status != JobStatus.open:
            raise HTTPException(
                status_code=400,
                detail="Bu e'lon bo'yicha allaqachon usta tanlangan",
            )

        offer = (await db.execute(
            select(JobOffer).where(
                JobOffer.id == offer_id, JobOffer.job_id == job_id
            )
        )).scalar_one_or_none()
        if not offer:
            raise HTTPException(status_code=404, detail="Taklif topilmadi")
        if offer.status == OfferStatus.withdrawn:
            raise HTTPException(
                status_code=400,
                detail="Bu taklif usta tomonidan qaytarib olingan",
            )

        offer.status = OfferStatus.accepted
        job.status = JobStatus.assigned
        job.assigned_provider_id = offer.provider_id
        job.assigned_at = _now()

        # Qolgan barcha takliflar avtomatik rad etiladi
        await db.execute(
            sa_update(JobOffer)
            .where(
                JobOffer.job_id == job_id,
                JobOffer.id != offer_id,
                JobOffer.status == OfferStatus.pending,
            )
            .values(status=OfferStatus.rejected)
        )
        await db.commit()
        await db.refresh(job)

        # Tanlangan ustaga xabar
        owner_id = await JobService._provider_owner(db, offer.provider_id)
        await _notify(
            owner_id, "job_accepted", "Taklifingiz qabul qilindi",
            f"'{job.title}' ishi sizga topshirildi. Mijoz bilan bog'laning.",
        )

        # Rad etilganlarga ham xabar
        rejected = (await db.execute(
            select(JobOffer.provider_id).where(
                JobOffer.job_id == job_id,
                JobOffer.id != offer_id,
                JobOffer.status == OfferStatus.rejected,
            )
        )).scalars().all()
        for pid in rejected:
            oid = await JobService._provider_owner(db, pid)
            await _notify(
                oid, "job_rejected", "Boshqa usta tanlandi",
                f"'{job.title}' e'loni bo'yicha boshqa usta tanlandi.",
            )
        return job

    @staticmethod
    async def mark_offers_seen(db: AsyncSession, job_id: int, user_id: int) -> None:
        job = await JobService.get_by_id(db, job_id)
        if job.user_id != user_id:
            raise HTTPException(status_code=403, detail="Bu e'lon sizniki emas")
        await db.execute(
            sa_update(JobOffer)
            .where(JobOffer.job_id == job_id, JobOffer.is_seen == False)  # noqa: E712
            .values(is_seen=True)
        )
        await db.commit()
