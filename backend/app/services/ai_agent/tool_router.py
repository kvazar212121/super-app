"""Tool'larni suhbatga qarab TANLAB yuborish.

MUAMMO
------
46 ta tool sxemasi ~6 800 token, system prompt ~4 000 token. Bu HAR
chaqiruvda va HAR tool raundida qaytadan yuboriladi. Universal agentga
(usta kabineti + qolgan bo'limlar, §20.2) o'tilsa tool soni ikki barobar
oshadi va yuk ~20 000 tokenga chiqadi.

YECHIM VA UNING CHEGARASI
-------------------------
Suhbat matniga qarab kerakli GURUHNI aniqlab, faqat o'shani yuboramiz.

Eng muhim qoida: **ishonch bo'lmasa — HAMMASINI yuboramiz.** Noto'g'ri
guruh tanlangandan ko'ra ortiqcha token yuborgan afzal: birinchi holatda
agent vazifani UMUMAN bajara olmaydi va foydalanuvchi sababini
tushunmaydi.

Shu sababli qisqartirish faqat quyidagi hollarda ishlaydi:
  • matnda guruhning aniq kalit so'zi bor, VA
  • boshqa guruhning kalit so'zi yo'q (ikkilanish bo'lsa — hammasi)

Suhbatda allaqachon biror guruh tool'i ishlatilgan bo'lsa, o'sha guruh
doim qo'shiladi: yarim yig'ilgan qoralama uzilib qolmasin.
"""
from __future__ import annotations

import re

# Har doim yuboriladigan tool'lar: navigatsiya, hisob, umumiy ro'yxatlar.
# Ular deyarli har suhbatda kerak bo'ladi va arzon.
CORE = {
    "open_app_section",
    "get_account_info",
    "list_orders",
}

# Guruh -> tool'lar
GROUPS: dict[str, set[str]] = {
    "savdo": {
        "start_listing_draft", "update_listing_draft", "add_listing_photos",
        "publish_listing", "search_listings", "get_listing", "my_listings",
        "close_listing",
    },
    "ish": {
        "start_job_draft", "update_job_draft", "publish_job", "my_jobs",
    },
    "bron": {
        "search_providers", "create_booking", "next_booking",
        "get_booking_details", "check_availability", "reschedule_booking",
        "update_booking", "get_provider_info", "cancel_order",
    },
    "shaxsiy": {
        "add_plan", "list_plans", "complete_plan", "delete_plan",
        "add_todo", "list_todos", "complete_todo", "delete_todo",
        "set_alarm", "list_alarms", "toggle_alarm", "delete_alarm",
        "add_shopping_item", "list_shopping", "mark_shopping_bought",
        "add_finance_record", "get_finance_summary", "delete_finance_record",
        "get_steps_today",
    },
    "info": {"get_weather", "get_currency", "get_prayer_times"},
    "shikoyat": {"report_complaint"},
    # USTA tomoni — mijoz tool'laridan ALOHIDA guruh.
    "usta": {
        "provider_my_orders", "provider_stats", "provider_open_jobs",
        "provider_send_offer", "provider_block_time",
    },
}

# Kalit so'zlar. O'zbekcha + ruscha: ruscha yozganda ham to'g'ri guruh
# tanlanishi kerak (eval `til` guruhi shuni qo'riqlaydi).
KEYWORDS: dict[str, tuple[str, ...]] = {
    "savdo": (
        "sot", "sotmoq", "sotil", "sotib ol", "olmoqchi", "e'lon ber",
        "arzon", "narxi", "ishlatilgan", "yangi holatda",
        "прода", "продаж", "купи", "куплю", "объявлени", "бэушн",
    ),
    "ish": (
        "buzil", "ishlamayap", "tuzat", "ta'mir", "tamirla", "oqyap",
        "sindi", "usta kerak", "chaqir",
        "слома", "почини", "ремонт", "не работает", "течет",
    ),
    "bron": (
        "bron", "band qil", "yozil", "navbat", "sartarosh", "salon",
        "massaj", "shifokor", "hamshira", "enaga", "repetitor",
        "eng yaqin", "ro'yxatini", "royxatini", "usta",
        "запиш", "брон", "ближайш", "мастер", "парикмахер",
    ),
    "shaxsiy": (
        "eslat", "reja", "vazifa", "budilnik", "uyg'ot", "bozorlik",
        "ro'yxatga qo'sh", "sarfla", "xarajat", "daromad", "balans",
        "qadam", "kun tartibi",
        "напомни", "план", "задач", "будильник", "покупк", "потрати",
        "расход", "доход", "шаг",
    ),
    "info": (
        "ob-havo", "havo qanday", "valyuta", "kurs", "namoz", "dollar",
        "погод", "валют", "курс", "намаз",
    ),
    "usta": (
        "menga kelgan", "buyurtmalarim", "reytingim", "balansim",
        "taklif ber", "taklif yubor", "bandman", "dam olaman",
        "yangi ish bormi", "ishlarim qanday",
        "мои заказы", "мой рейтинг", "мой баланс", "отправить предложение",
        "я занят",
    ),
    "shikoyat": (
        "shikoyat", "alda", "firibgar", "qo'pol", "qopol", "pulimni",
        "norozi", "arz qil",
        "жалоб", "обману", "обманул", "мошенник", "хамств", "недоволен",
    ),
}


def _matn(messages: list[dict]) -> str:
    """Suhbatdagi foydalanuvchi matnini yig'adi (system'siz)."""
    bolaklar = []
    for m in messages:
        if m.get("role") in ("user", "assistant") and isinstance(m.get("content"), str):
            bolaklar.append(m["content"])
    return " ".join(bolaklar).lower()


def _ishlatilgan_guruhlar(messages: list[dict]) -> set[str]:
    """Suhbatda allaqachon chaqirilgan tool'lar qaysi guruhga tegishli."""
    nomlar: set[str] = set()
    for m in messages:
        for tc in (m.get("tool_calls") or []):
            try:
                nomlar.add(tc["function"]["name"])
            except (KeyError, TypeError):
                pass
        if m.get("role") == "tool" and m.get("name"):
            nomlar.add(m["name"])
    return {g for g, tools in GROUPS.items() if nomlar & tools}


def tanla(messages: list[dict], tools: list[dict]) -> list[dict]:
    """Suhbatga mos tool sxemalarini qaytaradi.

    Ishonch bo'lmasa TO'LIQ ro'yxat qaytadi — bu ataylab.
    """
    matn = _matn(messages)
    mos = {g for g, kalitlar in KEYWORDS.items()
           if any(k in matn for k in kalitlar)}

    # Suhbat davom etayotgan guruh doim qoladi (qoralama uzilmasin).
    mos |= _ishlatilgan_guruhlar(messages)

    # Hech narsa mos kelmadi yoki bir nechta guruh da'vo qilyapti —
    # ikkilanmaymiz, hammasini yuboramiz.
    if len(mos) != 1:
        return tools

    guruh = next(iter(mos))
    ruxsat = CORE | GROUPS[guruh]
    tanlangan = [t for t in tools if t["function"]["name"] in ruxsat]
    # Xavfsizlik: nomlar mos kelmay qolsa (tool qayta nomlangan) —
    # bo'sh ro'yxat yubormaymiz.
    return tanlangan or tools
