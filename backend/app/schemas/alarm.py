from datetime import datetime
from typing import Literal, Optional
from pydantic import BaseModel, Field, field_validator

MissionType = Literal["math", "photo", "speech"]


def _validate_repeat_days(v: Optional[str]) -> Optional[str]:
    """CSV ISO weekday: "1,2,3,4,5" (1=Dushanba ... 7=Yakshanba).

    Ilgari tekshirilmasdi: "9,abc,-3" qabul qilinardi. Flutter bunday
    qiymatlarni JIMGINA tashlab yuboradi (alarm.dart:repeatDayList) va
    budilnik "bir martalik" bo'lib qoladi -- ya'ni foydalanuvchi har
    kuni jiringlaydi deb o'ylaydi, aslida bir marta jiringlaydi yoki
    umuman jiringlamaydi. Shuning uchun noto'g'ri qiymat DARHOL rad
    etilishi kerak.
    """
    if v is None:
        return v
    raw = v.strip()
    if not raw:
        return ""
    days = []
    for part in raw.split(","):
        part = part.strip()
        if not part:
            continue
        if not part.isdigit():
            raise ValueError(
                f"Takror kunlari 1..7 oralig'idagi raqamlar bo'lishi kerak "
                f"(xato: '{part}')"
            )
        d = int(part)
        if d < 1 or d > 7:
            raise ValueError(
                f"Takror kuni 1 (Dushanba) dan 7 (Yakshanba) gacha bo'lishi "
                f"kerak, kelgan: {d}"
            )
        days.append(d)
    # Takrorlarni olib tashlab, tartiblab qaytaramiz
    return ",".join(str(d) for d in sorted(set(days)))


class AlarmBase(BaseModel):
    label: str = "Budilnik"
    hour: int = Field(..., ge=0, le=23)
    minute: int = Field(..., ge=0, le=59)
    repeat_days: str = ""  # CSV ISO weekday: "1,2,3,4,5"
    ringtone: str = "default"
    mission_type: MissionType = "math"
    mission_config: dict = Field(default_factory=dict)
    snooze_enabled: bool = True
    snooze_minutes: int = Field(default=5, ge=1, le=60)
    is_enabled: bool = True

    @field_validator("repeat_days")
    @classmethod
    def _check_repeat_days(cls, v):
        return _validate_repeat_days(v)


class AlarmCreate(AlarmBase):
    pass


class AlarmUpdate(BaseModel):
    label: Optional[str] = None
    hour: Optional[int] = Field(default=None, ge=0, le=23)
    minute: Optional[int] = Field(default=None, ge=0, le=59)
    repeat_days: Optional[str] = None
    ringtone: Optional[str] = None
    mission_type: Optional[MissionType] = None
    mission_config: Optional[dict] = None
    snooze_enabled: Optional[bool] = None
    snooze_minutes: Optional[int] = Field(default=None, ge=1, le=60)
    is_enabled: Optional[bool] = None

    @field_validator("repeat_days")
    @classmethod
    def _check_repeat_days(cls, v):
        return _validate_repeat_days(v)


class AlarmOut(AlarmBase):
    id: int
    user_id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


class PhotoVerifyOut(BaseModel):
    matched: bool
    confidence: float
    detail: str


class AlarmEventIn(BaseModel):
    """Budilnik o'chirilganda mobil ilova yuboradigan statistika hodisasi."""
    fired_at: Optional[datetime] = None
    dismissed_at: Optional[datetime] = None
    dismiss_seconds: Optional[int] = None
    snooze_count: int = 0


class AlarmStatsOut(BaseModel):
    total_alarms: int
    enabled_alarms: int
    total_fired: int
    avg_dismiss_seconds: Optional[float] = None
    total_snoozes: int
