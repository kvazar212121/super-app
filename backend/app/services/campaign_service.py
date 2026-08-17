"""Sezonli reyting (aksiya) xizmati.

Ovoz berish qoidalari SHU YERDA jamlangan, endpointda sochilib ketmasin:
  1. Aksiya mavjud bo'lishi kerak
  2. Aksiya FAOL bo'lishi kerak (is_active) va hozirgi vaqt oralig'ida
  3. Provayder mavjud va faol bo'lishi kerak
  4. Aksiya kategoriyaga bog'langan bo'lsa, provayder o'sha kategoriyadan
  5. Bir foydalanuvchi bitta aksiyada faqat BIR MARTA ovoz beradi
"""

from datetime import datetime, timezone

from fastapi import HTTPException
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.campaign import Campaign, CampaignVote
from app.models.order import Order, OrderStatus
from app.models.provider import Provider


def _now() -> datetime:
    return datetime.now(timezone.utc)


class CampaignService:

    # ── O'qish ────────────────────────────────────────────────────────
    @staticmethod
    async def get_by_id(db: AsyncSession, campaign_id: int) -> Campaign:
        c = (await db.execute(
            select(Campaign).where(Campaign.id == campaign_id)
        )).scalar_one_or_none()
        if not c:
            raise HTTPException(status_code=404, detail="Aksiya topilmadi")
        return c

    @staticmethod
    async def list_campaigns(
        db: AsyncSession,
        only_active: bool = False,
        category_id: int | None = None,
    ) -> list[Campaign]:
        """Aksiyalar ro'yxati.

        only_active=True bo'lsa faqat HOZIR ketayotganlari (mobil ilova
        uchun). Admin panel hammasini ko'radi.
        """
        q = select(Campaign).order_by(Campaign.starts_at.desc())
        if category_id is not None:
            q = q.where(Campaign.category_id == category_id)
        if only_active:
            now = _now()
            q = q.where(
                Campaign.is_active == True,  # noqa: E712
                Campaign.starts_at <= now,
                Campaign.ends_at >= now,
            )
        return list((await db.execute(q)).scalars().all())

    @staticmethod
    async def get_active(db: AsyncSession) -> Campaign | None:
        """Hozir ketayotgan aksiya (bosh sahifa uchun eng yaqin tugaydigani)."""
        now = _now()
        q = (
            select(Campaign)
            .where(
                Campaign.is_active == True,  # noqa: E712
                Campaign.starts_at <= now,
                Campaign.ends_at >= now,
            )
            .order_by(Campaign.ends_at.asc())
            .limit(1)
        )
        return (await db.execute(q)).scalar_one_or_none()

    # ── Reyting ───────────────────────────────────────────────────────
    @staticmethod
    async def leaderboard(
        db: AsyncSession, campaign_id: int, limit: int = 50
    ) -> list[dict]:
        """Aksiya reytingi: eng ko'p OVOZ olgan provayderlar.

        Yulduz emas, OVOZ SONI bo'yicha. Teng bo'lsa ilgari ovoz
        yig'gani (kichik provider_id) oldinda -- natija barqaror bo'lsin.
        """
        await CampaignService.get_by_id(db, campaign_id)  # mavjudligini tekshirish

        # Provider.to_dict() `self.category.key` ni o'qiydi. `category`
        # lazy bo'lgani uchun uni OLDINDAN yuklamasak, async kontekstda
        # MissingGreenlet xatosi chiqadi (haqiqiy testda aniqlangan).
        q = (
            select(
                Provider,
                func.count(CampaignVote.id).label("votes"),
            )
            .options(selectinload(Provider.category))
            .join(CampaignVote, CampaignVote.provider_id == Provider.id)
            .where(CampaignVote.campaign_id == campaign_id)
            .group_by(Provider.id)
            .order_by(func.count(CampaignVote.id).desc(), Provider.id.asc())
            .limit(limit)
        )
        rows = (await db.execute(q)).all()

        out = []
        for i, (provider, votes) in enumerate(rows, start=1):
            item = provider.to_dict()
            item["votes"] = votes
            item["position"] = i
            out.append(item)
        return out

    @staticmethod
    async def my_vote(
        db: AsyncSession, campaign_id: int, user_id: int
    ) -> CampaignVote | None:
        """Foydalanuvchi shu aksiyada ovoz berganmi? (UI tugmani o'chirishi uchun)"""
        return (await db.execute(
            select(CampaignVote).where(
                CampaignVote.campaign_id == campaign_id,
                CampaignVote.user_id == user_id,
            )
        )).scalar_one_or_none()

    # ── Ovoz berish ───────────────────────────────────────────────────
    @staticmethod
    async def vote(
        db: AsyncSession, campaign_id: int, user_id: int, provider_id: int
    ) -> CampaignVote:
        campaign = await CampaignService.get_by_id(db, campaign_id)

        now = _now()
        status = campaign.status(now)
        if status == "disabled":
            raise HTTPException(status_code=400, detail="Aksiya vaqtincha to'xtatilgan")
        if status == "upcoming":
            raise HTTPException(
                status_code=400,
                detail="Aksiya hali boshlanmagan",
            )
        if status == "finished":
            raise HTTPException(status_code=400, detail="Aksiya yakunlangan")

        provider = (await db.execute(
            select(Provider).where(Provider.id == provider_id)
        )).scalar_one_or_none()
        if not provider or not provider.is_active:
            raise HTTPException(status_code=404, detail="Provayder topilmadi")

        if campaign.category_id is not None and provider.category_id != campaign.category_id:
            raise HTTPException(
                status_code=400,
                detail="Bu provayder aksiya kategoriyasiga kirmaydi",
            )

        # SOXTA OVOZGA QARSHI: faqat haqiqiy mijoz ovoz bera oladi.
        # Sovrin pul bo'lgani uchun bu shart -- aks holda soxta akkauntlar
        # bilan ovoz yig'ish mumkin. Loyihaning sharh tizimi ham aynan shu
        # qoidani qo'llaydi (provider_service.add_review).
        if campaign.require_completed_order:
            has_order = (await db.execute(
                select(Order.id).where(
                    Order.user_id == user_id,
                    Order.provider_id == provider_id,
                    Order.status == OrderStatus.completed,
                ).limit(1)
            )).scalar_one_or_none()
            if not has_order:
                raise HTTPException(
                    status_code=403,
                    detail=(
                        "Ovoz berish uchun ushbu provayderda yakunlangan "
                        "buyurtmangiz bo'lishi kerak"
                    ),
                )

        # Oldindan tekshiruv: foydalanuvchiga tushunarli xabar berish uchun.
        # Yakuniy kafolat esa DB'dagi UNIQUE cheklovda (pastdagi except).
        existing = await CampaignService.my_vote(db, campaign_id, user_id)
        if existing:
            raise HTTPException(
                status_code=409,
                detail="Siz bu aksiyada allaqachon ovoz bergansiz",
            )

        vote = CampaignVote(
            campaign_id=campaign_id, user_id=user_id, provider_id=provider_id
        )
        db.add(vote)
        try:
            await db.commit()
        except IntegrityError:
            # Bir vaqtda kelgan ikkinchi so'rov: UNIQUE cheklov ushladi
            await db.rollback()
            raise HTTPException(
                status_code=409,
                detail="Siz bu aksiyada allaqachon ovoz bergansiz",
            )
        await db.refresh(vote)
        return vote

    # ── Admin CRUD ────────────────────────────────────────────────────
    @staticmethod
    async def create(db: AsyncSession, data: dict) -> Campaign:
        if data["ends_at"] <= data["starts_at"]:
            raise HTTPException(
                status_code=400,
                detail="Tugash sanasi boshlanish sanasidan keyin bo'lishi kerak",
            )
        campaign = Campaign(**data)
        db.add(campaign)
        await db.commit()
        await db.refresh(campaign)
        return campaign

    @staticmethod
    async def update(db: AsyncSession, campaign_id: int, data: dict) -> Campaign:
        campaign = await CampaignService.get_by_id(db, campaign_id)
        # DIQQAT: `if v is not None` DEMAYMIZ. Endpoint exclude_unset bilan
        # chaqiradi, ya'ni bu yerga FAQAT yuborilgan maydonlar keladi.
        # `is not None` tekshiruvi bo'lsa `is_active=False` yoki
        # `require_completed_order=False` HECH QACHON saqlanmaydi --
        # ya'ni aksiyani to'xtatib bo'lmaydi. Faqat majburiy (nullable
        # bo'lmagan) maydonlarga None kelishidan himoyalanamiz.
        NOT_NULLABLE = {"title", "starts_at", "ends_at", "is_active",
                        "require_completed_order"}
        for k, v in data.items():
            if v is None and k in NOT_NULLABLE:
                continue
            setattr(campaign, k, v)
        if campaign.ends_at <= campaign.starts_at:
            raise HTTPException(
                status_code=400,
                detail="Tugash sanasi boshlanish sanasidan keyin bo'lishi kerak",
            )
        await db.commit()
        await db.refresh(campaign)
        return campaign

    @staticmethod
    async def delete(db: AsyncSession, campaign_id: int) -> None:
        campaign = await CampaignService.get_by_id(db, campaign_id)
        await db.delete(campaign)
        await db.commit()

    @staticmethod
    async def vote_count(db: AsyncSession, campaign_id: int) -> int:
        return (await db.execute(
            select(func.count(CampaignVote.id)).where(
                CampaignVote.campaign_id == campaign_id
            )
        )).scalar() or 0
