from datetime import datetime, timedelta, timezone
from pydantic import BaseModel, Field, field_validator
from typing import Literal, Optional, List

# Faqat shu ikkitasi. Ilgari oddiy `str` edi va istalgan qiymat qabul
# qilinardi -- masalan type="allaqanday" bo'lsa yozuv statistikaga
# UMUMAN kirmaydi (finance.py:123 faqat income/expense ni sanaydi),
# ya'ni foydalanuvchi puli "yo'qoladi".
RecordType = Literal["income", "expense"]

# Amaliy yuqori chegara: 1 trillion so'm. Bitta noto'g'ri kiritish
# (masalan nol ortiqcha) butun statistikani buzmasligi uchun.
MAX_AMOUNT = 1_000_000_000_000

# FinanceRecord — bu ALLAQACHON SODIR BO'LGAN daromad/xarajat (fakt).
# Kelajakdagi to'lovlar uchun loyihada alohida `PlannedPayment` modeli bor.
# Kelajak sanali yozuv joriy oy statistikasiga kirmaydi va foydalanuvchi
# "pulim qayerda?" degan holatga tushadi, shuning uchun rad etamiz.
# Soat mintaqasi farqi va qurilma soati ozgina oldinda bo'lishi mumkin,
# shuning uchun 1 kunlik yon beriladi.
FUTURE_TOLERANCE = timedelta(days=1)


def _check_not_future(value: datetime) -> datetime:
    """Sana kelajakda emasligini tekshiradi (1 kunlik yon berish bilan)."""
    if value is None:
        return value
    now = datetime.now(timezone.utc)
    # Naive sana kelsa UTC deb qaraymiz (aks holda taqqoslash xato beradi)
    candidate = value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    if candidate > now + FUTURE_TOLERANCE:
        raise ValueError(
            "Sana kelajakda bo'lishi mumkin emas. Kelajakdagi to'lov uchun "
            "\"Rejalashtirilgan to'lovlar\" bo'limidan foydalaning."
        )
    return value


class FinanceRecordBase(BaseModel):
    type: RecordType
    # Manfiy summa MANTIQAN NOTO'G'RI: "-100000 xarajat" aslida daromad
    # bo'lib qoladi va balans noto'g'ri chiqadi.
    amount: float = Field(..., gt=0, le=MAX_AMOUNT)
    category: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = None
    date: datetime

    @field_validator("date")
    @classmethod
    def _validate_date(cls, v: datetime) -> datetime:
        return _check_not_future(v)


class FinanceRecordCreate(FinanceRecordBase):
    pass


class FinanceRecordUpdate(BaseModel):
    type: Optional[RecordType] = None
    amount: Optional[float] = Field(default=None, gt=0, le=MAX_AMOUNT)
    category: Optional[str] = Field(default=None, min_length=1, max_length=100)
    description: Optional[str] = None
    date: Optional[datetime] = None

    @field_validator("date")
    @classmethod
    def _validate_date(cls, v: Optional[datetime]) -> Optional[datetime]:
        return _check_not_future(v) if v is not None else v


class FinanceRecordOut(FinanceRecordBase):
    id: int
    user_id: int
    user_name: Optional[str] = None  # kim qo'shgani (oilaviy hisobda)
    created_at: datetime

    class Config:
        from_attributes = True


class FinanceCategoryStat(BaseModel):
    category: str
    amount: float
    percentage: float


class FinanceMemberStat(BaseModel):
    user_id: int
    name: str
    income: float
    expense: float


class FinanceStatsOut(BaseModel):
    total_income: float
    total_expense: float
    balance: float
    category_stats: List[FinanceCategoryStat]
    insight: str
    # Oilaviy hisob: har a'zoning ulushi (guruh bo'lsa)
    member_stats: List[FinanceMemberStat] = []


# ── Oilaviy moliya guruhi ──

class FinanceGroupMember(BaseModel):
    user_id: int
    name: str
    is_owner: bool


class FinanceGroupOut(BaseModel):
    id: int
    name: str
    invite_code: str
    is_owner: bool
    members: List[FinanceGroupMember]


class JoinGroupIn(BaseModel):
    code: str
