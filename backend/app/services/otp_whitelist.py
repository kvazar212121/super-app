"""OTP'siz kiradigan raqamlar (test va DEMO).

Bu ro'yxatdagi raqamlar SMS kutmaydi: `111111` kodi bilan darhol
kiradi (`auth.py` dagi `/otp/send` va `/otp/verify`).

Ikki guruh bor:
  1. TEST raqamlari — qo'lda yozilgan 26 ta.
  2. DEMO provayderlar — bazadagi provayder telefonlari. Ular
     `scripts/seed_demo.py` bilan yaratiladi va shu ro'yxatga
     `demo_phones.txt` orqali qo'shiladi. Shunda ularning
     kabinetiga kirib ko'rish mumkin.

⚠️ Bu faqat DEMO uchun. Haqiqiy foydalanuvchi raqamini bu yerga
   yozmang — u SMS tasdiqlashsiz kirib qoladi.
"""
import logging
import os

logger = logging.getLogger(__name__)

WHITELIST_NUMBERS = [
    # Bu yerdagi 26 ta raqam OTP tasdiqlamasdan to'g'ridan-to'g'ri tizimga kiradi
    # Siz aytgan 26 ta maxsus raqamni quyidagi formatda yozamiz
    "+998901234501", "+998901234502", "+998901234503", "+998901234504", "+998901234505",
    "+998901234506", "+998901234507", "+998901234508", "+998901234509", "+998901234510",
    "+998901234511", "+998901234512", "+998901234513", "+998901234514", "+998901234515",
    "+998901234516", "+998901234517", "+998901234518", "+998901234519", "+998901234520",
    "+998901234521", "+998901234522", "+998901234523", "+998901234524", "+998901234525",
    "+998901234526"
]

# Demo provayderlar ro'yxati (fayldan). Fayl bo'lmasa e'tiborsiz
# qoldiriladi — demo yo'q muhitda hech narsa o'zgarmaydi.
_DEMO_FAYL = os.path.join(os.path.dirname(__file__), "demo_phones.txt")
try:
    if os.path.exists(_DEMO_FAYL):
        with open(_DEMO_FAYL, encoding="utf-8") as f:
            qoshildi = 0
            for qator in f:
                raqam = qator.strip()
                if raqam.startswith("+") and raqam not in WHITELIST_NUMBERS:
                    WHITELIST_NUMBERS.append(raqam)
                    qoshildi += 1
        if qoshildi:
            logger.info("OTP whitelist: %d ta demo raqam qo'shildi", qoshildi)
except Exception as exc:  # ro'yxat o'qilmasa ham auth ISHLAYVERADI
    logger.warning("Demo raqamlar o'qilmadi: %s", exc)
