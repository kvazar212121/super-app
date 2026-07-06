from datetime import datetime
from typing import Literal, Optional
from pydantic import BaseModel, Field

MissionType = Literal["math", "photo", "speech"]


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
