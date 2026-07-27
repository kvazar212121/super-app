"""Lokal (kalit so'zli) fallback parser — AI provayder ishlamay qolganda.

Groq/DeepSeek 429/xato qaytarsa ham foydalanuvchining oddiy buyruqlari
(xarajat, reja, bozorlik, budilnik) ishlashda davom etadi.
"""
import json
import re
from datetime import datetime, timedelta, timezone

from sqlalchemy.ext.asyncio import AsyncSession

from .dispatcher import handle_tool_call
from .schemas import ChatResponse


async def fallback_local_parse(user_msg: str, user_id: int, db: AsyncSession) -> ChatResponse:
    """
    Failsafe / Local keyword parsing to handle user intents when Groq is unavailable,
    rate-limited, or throws an error.
    """
    text_lc = user_msg.lower().strip()
    digits = re.findall(r'\d+', text_lc)
    parsed = None

    # 1.1 Finance record check
    if digits:
        amount = float(digits[0])
        # Check if contains 'ming' or 'k'
        if 'ming' in text_lc or re.search(r'\b\d+\s*k\b', text_lc):
            amount *= 1000

        is_expense = any(x in text_lc for x in ["ketdi", "xarajat", "ishlatdim", "sarfladim", "sotib oldim", "to'ladim", "berdim", "spent"])
        is_income = any(x in text_lc for x in ["daromad", "tushdi", "oldim", "ishlab topdim", "maosh", "oylik", "earned"])

        if is_expense or is_income or "so'm" in text_lc or "som" in text_lc:
            category = "Boshqa"
            if any(x in text_lc for x in ["osh", "ovqat", "kafe", "restoran", "tushlik", "non", "ovqatlanish"]):
                category = "Oziq-ovqat"
            elif any(x in text_lc for x in ["taksi", "avtobus", "benzin", "metro", "yo'l", "transport"]):
                category = "Transport"
            elif any(x in text_lc for x in ["uy", "ijara", "gaz", "svet", "suv", "kommunal"]):
                category = "Kommunal"
            elif any(x in text_lc for x in ["maosh", "oylik", "daromad", "pul"]):
                category = "Maosh"

            rec_type = "income" if is_income else "expense"
            parsed = {
                "tool": "add_finance_record",
                "arguments": {
                    "type": rec_type,
                    "amount": amount,
                    "category": category,
                    "description": user_msg
                }
            }

    # 1.2 Plan check
    if not parsed and any(x in text_lc for x in ["reja", "eslatma", "vazifa", "majlis", "uchrashuv", "yig'ilish", "shifokor", "ish", "dars"]):
        title = user_msg
        for kw in ["reja", "eslatma", "vazifa", "qo'sh", "qil", "rejalashtir", "qo'shish", "ertaga", "bugun", "soat", "beshga", "5 ga", "5ga", "12 da", "12da"]:
            title = re.sub(rf'\b{kw}\b', '', title, flags=re.IGNORECASE)
        title = title.strip(".!? ")
        if not title:
            title = "Yangi vazifa"

        # Calculate date from context if possible
        due_date = datetime.now(timezone.utc)
        if "ertaga" in text_lc:
            due_date += timedelta(days=1)

        # Parse time if possible (e.g. "soat beshga", "12:00")
        time_match = re.search(r'\b(\d{1,2})[:.](\d{2})\b', text_lc)
        if time_match:
            hours, minutes = int(time_match.group(1)), int(time_match.group(2))
            due_date = due_date.replace(hour=hours, minute=minutes, second=0, microsecond=0)
        elif "beshga" in text_lc or "5 ga" in text_lc or "soat 5" in text_lc or "soat besh" in text_lc:
            due_date = due_date.replace(hour=17, minute=0, second=0, microsecond=0)
        elif "12 da" in text_lc or "soat 12" in text_lc:
            due_date = due_date.replace(hour=12, minute=0, second=0, microsecond=0)

        parsed = {
            "tool": "add_plan",
            "arguments": {
                "title": title[:50],
                "due_date": due_date.isoformat(),
                "description": "Lokal fallback orqali qo'shildi"
            }
        }

    # 1.3 Shopping item check
    if not parsed and any(x in text_lc for x in ["bozorlik", "bozor", "sotib", "olish", "ro'yxat", "olamiz", "qo'sh"]):
        qty = 1.0
        unit = "dona"
        if digits:
            qty = float(digits[0])
        if "kg" in text_lc or "kilogram" in text_lc:
            unit = "kg"
        elif "litr" in text_lc or re.search(r'\b\d+\s*l\b', text_lc):
            unit = "litr"

        name_clean = user_msg
        for kw in ["bozorlik", "bozorlikka", "qo'sh", "olish", "sotib", "ro'yxatiga", "ro'yxat", "kg", "dona", "litr", "ta", "olamiz"]:
            name_clean = re.sub(rf'\b{kw}\b', '', name_clean, flags=re.IGNORECASE)
        name_clean = re.sub(r'\d+', '', name_clean)
        name_clean = name_clean.strip(".!? ")
        if not name_clean:
            name_clean = "Mahsulot"
        parsed = {
            "tool": "add_shopping_item",
            "arguments": {
                "name": name_clean[:30],
                "qty": qty,
                "unit": unit,
                "estimated_price": 0.0
            }
        }

    # 1.4 Budilnik check
    if not parsed and any(x in text_lc for x in ["budilnik", "uyg'ot", "uygot", "uyg'onish", "alarm"]):
        hour, minute = 7, 0
        tm = re.search(r'\b(\d{1,2})[:.](\d{2})\b', text_lc)
        if tm:
            hour, minute = int(tm.group(1)), int(tm.group(2))
        elif digits:
            h = int(digits[0])
            if 0 <= h <= 23:
                hour = h
        repeat = ""
        if any(x in text_lc for x in ["har kuni", "kunlik", "har kun"]):
            repeat = "1,2,3,4,5,6,7"
        elif any(x in text_lc for x in ["ish kun", "budni"]):
            repeat = "1,2,3,4,5"
        parsed = {
            "tool": "set_alarm",
            "arguments": {
                "hour": max(0, min(23, hour)),
                "minute": max(0, min(59, minute)),
                "label": "Budilnik",
                "repeat_days": repeat,
                "mission_type": "math",
            }
        }

    # 2. Execute if parsed, else general reply
    action = None
    if parsed:
        tool_call = {
            "id": "mock_call_id",
            "function": {
                "name": parsed["tool"],
                "arguments": json.dumps(parsed["arguments"])
            }
        }
        res_str, action = await handle_tool_call(db, user_id, tool_call)
        res_data = json.loads(res_str)
        if res_data.get("status") == "success":
            if parsed["tool"] == "add_finance_record":
                reply = f"💵 Xarajat muvaffaqiyatli saqlandi! ({int(parsed['arguments']['amount'])} so'm, {parsed['arguments']['category']} toifasiga qo'shildi). Loyihaning 'Mening moliyam' bo'limidan tekshirishingiz mumkin. 📈"
            elif parsed["tool"] == "add_plan":
                try:
                    dt = datetime.fromisoformat(parsed['arguments']['due_date'].replace('Z', '+00:00'))
                    time_str = dt.strftime("%H:%M")
                    date_str = "ertaga" if "ertaga" in text_lc else "bugun"
                    reply = f"📅 Reja muvaffaqiyatli saqlandi! {date_str.capitalize()} soat {time_str} da '{parsed['arguments']['title']}' vazifasi rejalaringiz ro'yxatiga qo'shildi. 📝"
                except Exception:
                    reply = f"📅 Reja muvaffaqiyatli saqlandi! '{parsed['arguments']['title']}' vazifasi rejalaringiz ro'yxatiga qo'shildi. 📝"
            elif parsed["tool"] == "add_shopping_item":
                reply = f"🛒 Bozorlik ro'yxatiga muvaffaqiyatli qo'shildi: {parsed['arguments']['qty']} {parsed['arguments']['unit']} {parsed['arguments']['name']}. Uni 'Aqlli savdo' bo'limida ko'rishingiz mumkin! 🍎"
            elif parsed["tool"] == "set_alarm":
                a = parsed['arguments']
                tstr = f"{a['hour']:02d}:{a['minute']:02d}"
                reply = f"⏰ Budilnik {tstr} ga qo'yildi! O'chirish uchun vazifa bajarasiz. 'Majburlovchi budilnik' bo'limida ko'rishingiz mumkin. 💪"
            else:
                reply = "Muvaffaqiyatli bajarildi! 👍"
        else:
            reply = f"Xatolik yuz berdi: {res_data.get('message')}"
    else:
        if "salom" in text_lc:
            reply = "Assalomu alaykum! Men HubServis AI yordamchisiman. Sizga qanday yordam bera olaman? Reja qo'shish, xarajat yozish yoki bozorlik ro'yxatini boshqarishga yordam berishim mumkin! 😊"
        elif any(x in text_lc for x in ["ilova", "app", "nima", "yordamchi"]):
            reply = "Bu HubServis SuperApp universal ilovasi bo'lib, unda siz:\n1. 📅 Rejalaringizni boshqarishingiz (Kalendar/Todo)\n2. 💵 Kunlik daromad va xarajatlaringizni kuzatishingiz (Moliya)\n3. 🛒 Bozorlik ro'yxatini tuzishingiz (Aqlli savdo)\n4. 🛠 Ustalar, sartaroshlar va boshqa xizmatlarni bron qilishingiz mumkin! Qaysi bo'lim haqida batafsil ma'lumot beray? 🤖"
        elif any(x in text_lc for x in ["sartarosh", "salon", "sartaroshxona", "usta", "xizmat", "bron"]):
            reply = "Ilovamiz orqali sartaroshxona, tozalash xizmati, enaga, repetitor va avto-yordam ustalarini osongina topib, band qilishingiz mumkin. Buning uchun 'Barcha xizmatlar' yoki Asosiy ekrandagi bo'limlarni tanlang! 🛠💈"
        elif any(x in text_lc for x in ["moliya", "xarajat", "daromad", "pul", "sarf"]):
            reply = "Mening moliyam bo'limida siz kirim va chiqimlaringizni nazorat qilishingiz mumkin. Menga shunchaki 'oshga 40000 ketdi' yoki '100000 daromad tushdi' deb yozsangiz, men uni avtomatik ravishda moliya ro'yxatiga qo'shib qo'yaman! 💵📈"
        elif any(x in text_lc for x in ["reja", "kalendar", "todo", "vazifa"]):
            reply = "Rejalarim bo'limida siz vazifalar va eslatmalar qo'shishingiz mumkin. Menga 'ertaga soat 10 da majlis bor' deb yozsangiz, men uni rejalaringiz ro'yxatiga qo'shib qo'yaman! 📅📝"
        elif any(x in text_lc for x in ["bozor", "bozorlik", "savdo", "ro'yxat"]):
            reply = "Aqlli savdo bo'limida bozorlik ro'yxatini shakllantirishingiz mumkin. Menga 'bozorlikka 2 kg olma qo'sh' deb yozsangiz, mahsulot darhol ro'yxatga qo'shiladi! 🛒🍎"
        else:
            reply = "Sizni tushunishga harakat qilyapman! 🤖 Menga:\n- Reja qo'shish ('ertaga soat 5 da ish')\n- Xarajat yozish ('taksiga 15000 so'm ketdi')\n- Bozorlik yozish ('ro'yxatga 2 litr sut qo'sh')\nkabi ko'rsatmalarni bersangiz, ularni avtomatik tarzda tegishli bo'limga qo'shib qo'yaman! 💡"

    return ChatResponse(reply=reply, actions=[action] if action else [])
