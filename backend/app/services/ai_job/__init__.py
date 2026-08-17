"""AI orqali ish e'loni berish.

OQIM (foydalanuvchi so'ragan):
    Mijoz AI chatda rasm yuboradi va "shu joyni tamirlash kerak,
    ertaga" deb yozadi -> AI rasmni ko'radi, yetishmagan ma'lumotni
    SO'RAYDI (manzil, sana, soha) -> hammasi yig'ilgach mijozga
    ko'rsatib TASDIQ oladi -> e'lon yaratiladi va faqat SHU
    HUDUDDAGI mos soha ustalariga ko'rinadi.

NIMA UCHUN ALOHIDA PAKET:
    Foydalanuvchi "bunga ham alohida fayllar qilgin va alohida papka"
    dedi. Bundan tashqari bu mantiq ai_agent'dan mustaqil: uni
    keyinchalik boshqa kanaldan (masalan Telegram bot) ham chaqirish
    mumkin.

Modullar:
    vision.py     — rasmdan ish tavsifini ajratish
    validator.py  — nima yetishmayapti va qaysi savolni berish
    limits.py     — e'lon chegaralari (oddiy/premium)
    draft.py      — suhbat davomida yig'ilayotgan e'lon qoralamasi
"""

from .draft import JobDraft
from .limits import check_can_create_job, job_expiry_days
from .validator import missing_fields, next_question

__all__ = [
    "JobDraft",
    "check_can_create_job",
    "job_expiry_days",
    "missing_fields",
    "next_question",
]
