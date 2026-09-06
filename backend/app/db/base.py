from sqlalchemy import DDL, event
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


# Trigram indekslari (`gin_trgm_ops`) shu kengaytmasiz yaratilmaydi.
# Metadata'ga bog'lanadi, `startup.py` ga emas: `create_all` ni chaqiradigan
# HAR yo'l (test tizimi, seed skriptlari, yangi muhit) o'zi ishlashi kerak.
# SQLite'da o'tkazib yuboriladi — testlar xotira bazasida ishlaydi.
event.listen(
    Base.metadata,
    "before_create",
    DDL("CREATE EXTENSION IF NOT EXISTS pg_trgm").execute_if(dialect="postgresql"),
)
