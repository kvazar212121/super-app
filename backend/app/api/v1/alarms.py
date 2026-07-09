"""Majburlovchi budilnik API: budilnik CRUD, rasm-vazifa tekshiruvi, statistika.

Budilnikning o'zi mobil ilovada lokal jiringlaydi (internetsiz ishonchli);
bu API budilniklarni serverda sinxron saqlaydi va rasm-vazifasini AI orqali tekshiradi.
"""
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession
from starlette.requests import Request

from app.core.limiter import limiter
from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.alarm import Alarm, AlarmLog
from app.schemas.alarm import (
    AlarmCreate,
    AlarmUpdate,
    AlarmOut,
    PhotoVerifyOut,
    AlarmEventIn,
    AlarmStatsOut,
)
from app.services.vision_service import verify_photo_contains
from app.services.upload_service import UploadService

router = APIRouter(prefix="/alarms", tags=["alarms"])


async def _get_owned_alarm(alarm_id: int, user: User, db: AsyncSession) -> Alarm:
    result = await db.execute(
        select(Alarm).where(Alarm.id == alarm_id, Alarm.user_id == user.id)
    )
    alarm = result.scalar_one_or_none()
    if not alarm:
        raise HTTPException(status_code=404, detail="Budilnik topilmadi")
    return alarm


@router.get("", response_model=list[AlarmOut])
async def list_alarms(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Alarm)
        .where(Alarm.user_id == current_user.id)
        .order_by(Alarm.hour.asc(), Alarm.minute.asc())
    )
    return result.scalars().all()


@router.post("", response_model=AlarmOut, status_code=201)
async def create_alarm(
    data: AlarmCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    alarm = Alarm(**data.model_dump(), user_id=current_user.id)
    db.add(alarm)
    await db.commit()
    await db.refresh(alarm)
    return alarm


@router.put("/{alarm_id}", response_model=AlarmOut)
async def update_alarm(
    alarm_id: int,
    data: AlarmUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    alarm = await _get_owned_alarm(alarm_id, current_user, db)
    for key, value in data.model_dump(exclude_unset=True).items():
        setattr(alarm, key, value)
    await db.commit()
    await db.refresh(alarm)
    return alarm


@router.patch("/{alarm_id}/toggle", response_model=AlarmOut)
async def toggle_alarm(
    alarm_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    alarm = await _get_owned_alarm(alarm_id, current_user, db)
    alarm.is_enabled = not alarm.is_enabled
    await db.commit()
    await db.refresh(alarm)
    return alarm


@router.delete("/{alarm_id}", status_code=204)
async def delete_alarm(
    alarm_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    alarm = await _get_owned_alarm(alarm_id, current_user, db)
    await db.delete(alarm)
    await db.commit()


@router.post("/verify-photo", response_model=PhotoVerifyOut)
@limiter.limit("20/minute")
async def verify_alarm_photo(
    request: Request,
    file: UploadFile = File(...),
    target: str = Form(...),
    current_user: User = Depends(get_current_user),
):
    """Budilnik rasm-vazifasi: yuborilgan rasmda `target` bor-yo'qligini AI tekshiradi."""
    # Content-type allowlist + o'lcham cheki (katta body bilan OOM/DoS oldini oladi)
    UploadService._validate_file(file)
    contents = await file.read()
    if not contents:
        raise HTTPException(status_code=400, detail="Rasm bo'sh")
    # Xotirada JPEG'ga siqamiz — o'zboshimcha content-type provayderga o'tmaydi
    compressed = UploadService._compress_to_jpeg(contents, 1024, 70)
    return await verify_photo_contains(compressed, "image/jpeg", target)


@router.post("/{alarm_id}/event", status_code=204)
async def log_alarm_event(
    alarm_id: int,
    data: AlarmEventIn,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Budilnik o'chirilganda statistika hodisasini yozadi."""
    alarm = await _get_owned_alarm(alarm_id, current_user, db)
    log = AlarmLog(
        alarm_id=alarm.id,
        user_id=current_user.id,
        mission_type=alarm.mission_type,
        fired_at=data.fired_at or datetime.now(),
        dismissed_at=data.dismissed_at,
        dismiss_seconds=data.dismiss_seconds,
        snooze_count=data.snooze_count,
    )
    db.add(log)
    await db.commit()


@router.get("/stats", response_model=AlarmStatsOut)
async def get_alarm_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    total_alarms = await db.scalar(
        select(func.count(Alarm.id)).where(Alarm.user_id == current_user.id)
    )
    enabled_alarms = await db.scalar(
        select(func.count(Alarm.id)).where(
            Alarm.user_id == current_user.id, Alarm.is_enabled.is_(True)
        )
    )

    log_stats = await db.execute(
        select(
            func.count(AlarmLog.id),
            func.avg(AlarmLog.dismiss_seconds),
            func.coalesce(func.sum(AlarmLog.snooze_count), 0),
        ).where(AlarmLog.user_id == current_user.id)
    )
    total_fired, avg_dismiss, total_snoozes = log_stats.one()

    return AlarmStatsOut(
        total_alarms=int(total_alarms),
        enabled_alarms=int(enabled_alarms),
        total_fired=int(total_fired),
        avg_dismiss_seconds=float(avg_dismiss) if avg_dismiss is not None else None,
        total_snoozes=int(total_snoozes),
    )
