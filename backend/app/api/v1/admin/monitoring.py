"""Admin: monitoring bo'limlari — firibgarlik, ish e'lonlari, faollik.

Bu modul mavjud admin panelda YETISHMAYOTGAN kuzatuv imkoniyatlarini
qo'shadi. Har biri uchun ma'lumot allaqachon to'planardi, lekin admin
uni KO'RA OLMASDI:

  - provider_fraud_stats: no_show/disputed statistikasi yig'iladi-yu,
    hech qayerda ko'rsatilmasdi. Ya'ni firibgar provayder aniqlanmasdi.
  - job_posts / job_offers: yangi e'lon tizimi (moderatsiya kerak)
  - blocked_user: provayder kimni bloklagani ko'rinmasdi
  - device_token: nechta qurilma push oladi (bildirishnoma yetib
    boradimi degan savolga javob)
  - daily_activity: kunlik faollik
"""

from datetime import date, datetime, timedelta, timezone

from fastapi import APIRouter, Depends, Query
from sqlalchemy import case, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.v1.admin.dependencies import require_admin
from app.db.session import get_db
from app.models.blocked_user import BlockedUser
from app.models.job import JobOffer, JobPost, JobStatus, OfferStatus
from app.models.provider import Provider
from app.models.provider_fraud_stats import FraudFlagLevel, ProviderFraudStats
from app.models.user import User

router = APIRouter()


# ── Firibgarlik monitoringi ──────────────────────────────────────────
@router.get("/monitoring/fraud")
async def fraud_overview(
    month: str | None = Query(None, description="YYYY-MM, bo'sh bo'lsa joriy oy"),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Shubhali provayderlar: ko'p no_show yoki nizo.

    Bu ma'lumot ilgari ham yig'ilardi, lekin admin ko'ra olmasdi.
    """
    month = month or datetime.now(timezone.utc).strftime("%Y-%m")

    rows = (await db.execute(
        select(ProviderFraudStats, Provider)
        .join(Provider, Provider.id == ProviderFraudStats.provider_id)
        .where(ProviderFraudStats.month == month)
        .order_by(
            ProviderFraudStats.disputed_count.desc(),
            ProviderFraudStats.no_show_count.desc(),
        )
        .limit(200)
    )).all()

    items = []
    for stats, provider in rows:
        total = stats.total_orders or 0
        no_show_rate = round(stats.no_show_count / total * 100, 1) if total else 0.0
        items.append({
            "provider_id": provider.id,
            "provider_name": provider.name,
            "provider_phone": provider.phone,
            "is_active": provider.is_active,
            "month": stats.month,
            "total_orders": total,
            "no_show_count": stats.no_show_count,
            "disputed_count": stats.disputed_count,
            "no_show_rate": no_show_rate,
            "flag_level": getattr(stats.flag_level, "value", str(stats.flag_level)),
        })

    by_level: dict[str, int] = {}
    for it in items:
        by_level[it["flag_level"]] = by_level.get(it["flag_level"], 0) + 1

    return {
        "month": month,
        "items": items,
        "summary": {
            "total": len(items),
            "by_level": by_level,
            "suspended": by_level.get(FraudFlagLevel.suspended.value, 0),
            "alert": by_level.get(FraudFlagLevel.alert.value, 0),
        },
    }


@router.get("/monitoring/blocked-users")
async def blocked_users(
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Provayderlar bloklagan mijozlar — ko'p bloklangan odam shubhali."""
    rows = (await db.execute(
        select(BlockedUser, Provider, User)
        .join(Provider, Provider.id == BlockedUser.provider_id)
        .join(User, User.id == BlockedUser.user_id)
        .order_by(BlockedUser.created_at.desc())
        .limit(200)
    )).all()

    counts = dict((await db.execute(
        select(BlockedUser.user_id, func.count(BlockedUser.id))
        .group_by(BlockedUser.user_id)
    )).all())

    return {
        "items": [{
            "id": b.id,
            "provider_id": p.id,
            "provider_name": p.name,
            "user_id": u.id,
            "user_name": f"{u.name} {u.surname}".strip(),
            "user_phone": u.phone,
            # Nechta provayder shu odamni bloklagan
            "blocked_by_count": counts.get(u.id, 1),
            "created_at": b.created_at.isoformat() if b.created_at else None,
        } for b, p, u in rows],
        "total": len(rows),
    }


# ── Ish e'lonlari monitoringi ────────────────────────────────────────
@router.get("/monitoring/jobs")
async def jobs_overview(
    status: str | None = Query(None),
    limit: int = Query(100, ge=1, le=500),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Ish e'lonlari: nechta ochiq, nechta bajarildi, taklifsiz qolganlari."""
    q = (
        select(JobPost, User, func.count(JobOffer.id))
        .join(User, User.id == JobPost.user_id)
        .outerjoin(JobOffer, JobOffer.job_id == JobPost.id)
        .group_by(JobPost.id, User.id)
        .order_by(JobPost.created_at.desc())
        .limit(limit)
    )
    if status:
        q = q.where(JobPost.status == status)
    rows = (await db.execute(q)).all()

    by_status = dict((await db.execute(
        select(JobPost.status, func.count(JobPost.id)).group_by(JobPost.status)
    )).all())

    # Taklifsiz qolgan ochiq e'lonlar — platformada usta yetishmasligi belgisi
    no_offers = (await db.execute(
        select(func.count(JobPost.id))
        .outerjoin(JobOffer, JobOffer.job_id == JobPost.id)
        .where(JobPost.status == JobStatus.open)
        .group_by(JobPost.id)
        .having(func.count(JobOffer.id) == 0)
    )).all()

    accepted = (await db.execute(
        select(func.count(JobOffer.id)).where(JobOffer.status == OfferStatus.accepted)
    )).scalar() or 0
    total_offers = (await db.execute(select(func.count(JobOffer.id)))).scalar() or 0

    return {
        "items": [{
            "id": j.id,
            "title": j.title,
            "status": j.status.value if j.status else None,
            "budget": j.budget,
            "address": j.address,
            "user_id": u.id,
            "user_name": f"{u.name} {u.surname}".strip(),
            "user_phone": u.phone,
            "offers_count": cnt,
            "assigned_provider_id": j.assigned_provider_id,
            "created_at": j.created_at.isoformat() if j.created_at else None,
        } for j, u, cnt in rows],
        "summary": {
            "by_status": {
                (k.value if hasattr(k, "value") else str(k)): v
                for k, v in by_status.items()
            },
            "total_offers": total_offers,
            "accepted_offers": accepted,
            # Ochiq e'lonlardan nechtasiga hech kim taklif bermagan
            "open_without_offers": len(no_offers),
            "conversion_percent": (
                round(accepted / total_offers * 100, 1) if total_offers else 0.0
            ),
        },
    }


# ── Push/bildirishnoma yetkazish monitoringi ─────────────────────────
@router.get("/monitoring/push-reach")
async def push_reach(
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Nechta foydalanuvchiga push yetib boradi.

    Bildirishnoma yuborilyapti-yu, foydalanuvchida qurilma tokeni
    bo'lmasa u HECH NARSA ko'rmaydi. Bu ko'rsatkich 'nega odamlar
    xabar olmayapti' degan savolga javob beradi.
    """
    from app.models.device_token import DeviceToken

    total_users = (await db.execute(select(func.count(User.id)))).scalar() or 0
    with_token = (await db.execute(
        select(func.count(func.distinct(DeviceToken.user_id)))
    )).scalar() or 0
    total_tokens = (await db.execute(select(func.count(DeviceToken.id)))).scalar() or 0

    return {
        "total_users": total_users,
        "users_with_token": with_token,
        "users_without_token": total_users - with_token,
        "total_devices": total_tokens,
        "reach_percent": (
            round(with_token / total_users * 100, 1) if total_users else 0.0
        ),
    }


@router.get("/monitoring/activity")
async def activity_overview(
    days: int = Query(14, ge=1, le=90),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    """Kunlik faollik: nechta foydalanuvchi ilovaga kirgan."""
    from app.models.daily_activity import DailyActivity

    since = date.today() - timedelta(days=days)
    rows = (await db.execute(
        select(DailyActivity.date, func.count(func.distinct(DailyActivity.user_id)))
        .where(DailyActivity.date >= since)
        .group_by(DailyActivity.date)
        .order_by(DailyActivity.date.asc())
    )).all()
    return {
        "days": days,
        "items": [
            {"date": d.isoformat() if hasattr(d, "isoformat") else str(d),
             "active_users": cnt}
            for d, cnt in rows
        ],
    }
