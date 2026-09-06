"""Shikoyat tool'i — foydalanuvchi noroziligini YOZIB QO'YADI.

QAT'IY CHEGARA
--------------
Bu yerda faqat BITTA tool bor va u faqat yozadi. Jazo qo'yadigan,
bloklaydigan yoki shikoyat yozuvini o'chiradigan tool ATAYLAB
mavjud EMAS — shuning uchun AI ni qanday ko'ndirishga urinmasin,
u jazo tizimiga yeta olmaydi (ARXITEKTURA.md §20.4).

Shikoyat matni — foydalanuvchi MA'LUMOTI, buyruq emas. U tool
argumenti sifatida keladi va hech qachon promptga qo'shilmaydi.
"""
import json
import logging

from sqlalchemy.ext.asyncio import AsyncSession

from app.services import complaint_service

logger = logging.getLogger(__name__)


async def report_complaint(
    db: AsyncSession, user_id: int, args: dict, ctx: dict | None = None
) -> tuple[str, dict | None]:
    """Shikoyatni qabul qiladi va adminga yuboradi.

    Tasdiq (`confirm`) TALAB QILINADI: foydalanuvchi «shikoyat qilmoqchiman»
    deganda AI darhol yozib yubormasin — avval nimani yozayotganini
    ko'rsatib, roziligini olsin. Aks holda o'tkinchi norozilik rasmiy
    shikoyatga aylanib qolardi.
    """
    matn = (args.get("text") or "").strip()
    if not matn:
        return json.dumps({
            "status": "needs_more_info",
            "ask_user": "Nima bo'lganini qisqacha yozing — shikoyatga shuni kiritaman.",
        }, ensure_ascii=False), None

    if not args.get("confirm"):
        return json.dumps({
            "status": "needs_confirmation",
            "summary": matn[:300],
            "message": (
                "Shikoyat matnini foydalanuvchiga ko'rsating va "
                "«Shu shikoyatni yuborayinmi?» deb so'rang. "
                "«Yuborildi» deb YOZMANG — hali yuborilmadi."
            ),
        }, ensure_ascii=False), None

    # Kunlik cheklov — ommaviy tuhmatning oldini oladi.
    if await complaint_service.daily_count(db, user_id) >= complaint_service.DAILY_LIMIT:
        return json.dumps({
            "status": "error",
            "message": (
                "Bugun uchun shikoyat chegarasiga yetdingiz. "
                "Ertaga yozishingiz yoki qo'llab-quvvatlashga murojaat "
                "qilishingiz mumkin."
            ),
        }, ensure_ascii=False), None

    def _int(k):
        try:
            return int(args[k]) if args.get(k) not in (None, "") else None
        except (TypeError, ValueError):
            return None

    row = await complaint_service.create(
        db,
        reporter_user_id=user_id,
        text=matn,
        kind=str(args.get("kind") or "other"),
        provider_id=_int("provider_id"),
        target_user_id=_int("target_user_id"),
        order_id=_int("order_id"),
        ai_summary=(args.get("summary") or None),
    )
    await db.commit()

    return json.dumps({
        "status": "success",
        "complaint_id": row.id,
        "message": (
            "Shikoyat qabul qilindi va administratorga yuborildi. "
            "Ko'rib chiqilgach xabar beramiz."
        ),
        # AI ga ANIQ chegara: natijani va'da qilmasin.
        "note": (
            "Foydalanuvchiga jazo/blok haqida HECH NARSA va'da qilmang — "
            "qarorni administrator qabul qiladi."
        ),
    }, ensure_ascii=False), {"type": "complaint_created"}


HANDLERS = {
    "report_complaint": report_complaint,
}
