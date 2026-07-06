"""
AI Agent Proxy — Groq API orqali Function Calling (Tool Calls).

Foydalanuvchi iltimosiga ko'ra avtomatik ravishda reja qo'shish,
moliya xarajatlarini qayd etish yoki bozorlik ro'yxatiga narsa qo'shish
mumkin bo'lgan Agentic AI yordamchisi.
"""
import json
import logging
from datetime import datetime, timezone
from typing import List

import httpx
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.api.dependencies import get_current_user
from app.core.config import settings
from app.core.limiter import limiter
from app.db.session import get_db
from app.models.user import User
from app.models.plan import Plan
from app.models.finance_record import FinanceRecord
from app.models.shopping_list import ShoppingList
from starlette.requests import Request

router = APIRouter(prefix="/ai", tags=["ai"])
logger = logging.getLogger(__name__)

SYSTEM_PROMPT = """Siz HubServis SuperApp (universal ilovasi) uchun sun'iy intellekt yordamchi agentsiz. 
Sizning vazifangiz: foydalanuvchi so'rovlariga javob berish va agar foydalanuvchi reja, xarajat yoki bozorlik haqida aytsa, funksiyalarni (tools) ishlatib, uni avtomatik ravishda bazaga qo'shishdir.

ILOVANING ASOSIY BO'LIMLARI VA FUNKSIYALARI:
1. Rejalarim: Foydalanuvchi ma'lum sana va vaqtga rejalar qo'shishi mumkin.
2. Mening moliyam: Daromad va xarajatlarni kiritish mumkin.
3. Aqlli savdo: Bozorga borishdan oldin mahsulot ro'yxatini tuzish.
4. Barcha xizmatlar: Ustalar, tozalash, repetitor kabi xizmatlarga buyurtma berish.
5. Aksiyalar: Chegirma kodlari.
6. Majburlovchi budilnik: Foydalanuvchi uchun budilnik qo'yish (o'chirish uchun vazifa bajariladi).

QOIDALAR:
- Faqat o'zbek tilida, qisqa va aniq javob bering. Emojilardan foydalaning.
- Agar foydalanuvchi biron bir xarajat ("bugun oshga 50 ming ketdi"), daromad, reja ("ertaga soat 10 da majlis"), bozorlik ("bozorlikka 2kg go'sht qo'sh"), yoki budilnik ("ertalab 7 da budilnik qo'y", "6:30 ga uyg'ot") haqida yozsa, MAJBURIY ravishda mos tool ni chaqiring.
- BRON (xizmat buyurtma qilish): foydalanuvchi biror xizmat/usta so'rasa ("sartarosh kerak", "uyga tozalash chaqir", "santexnik bron qil"):
  1) AVVAL `search_providers` ni chaqirib mos ustalarni toping va foydalanuvchiga 2-3 tasini (nomi, reytingi) taklif qiling.
  2) Foydalanuvchi ustani tanlagach, MANZIL va VAQTni so'rang (agar aytilmagan bo'lsa).
  3) So'ng `create_booking` ni chaqirib buyurtmani rasmiylashtiring. Buyurtmadan keyin "Buyurtmalarim"da ko'rish mumkinligini ayting.
- Hozirgi sana va vaqt (UTC): {current_time}
- Siz tool ni chaqirganingizdan keyin, tizim sizga natijani qaytaradi va siz foydalanuvchiga "Xarajat qo'shildi", "Reja saqlandi" degan ma'noda javob qilasiz. Qachonki tool result "success" bo'lsa, qisqa tasdiqlovchi matn yozing."""

# AI Tools sxemalari
TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "add_plan",
            "description": "Foydalanuvchi uchun yangi reja (vazifa/eslatma) qo'shish.",
            "parameters": {
                "type": "object",
                "properties": {
                    "title": {"type": "string", "description": "Reja nomi yoki qisqacha tavsifi (masalan, 'Majlis', 'Shifokor qabuli')"},
                    "due_date": {"type": "string", "description": "ISO 8601 formatidagi sana va vaqt (masalan, '2026-06-19T10:00:00Z')"},
                    "description": {"type": "string", "description": "Reja bo'yicha qo'shimcha izoh yoki tafsilotlar"}
                },
                "required": ["title", "due_date"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "add_finance_record",
            "description": "Foydalanuvchi uchun moliyaviy kirim (daromad) yoki chiqim (xarajat) qayd etish.",
            "parameters": {
                "type": "object",
                "properties": {
                    "type": {"type": "string", "enum": ["income", "expense"], "description": "Tranzaksiya turi: kirim (income) yoki chiqim (expense)"},
                    "amount": {"type": "number", "description": "Pul miqdori (masalan, 50000)"},
                    "category": {"type": "string", "description": "Toifa nomi (masalan, 'Ovqatlanish', 'Transport', 'Maosh')"},
                    "description": {"type": "string", "description": "Tranzaksiya izohi"}
                },
                "required": ["type", "amount", "category"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "add_shopping_item",
            "description": "Bozorlik ro'yxatiga yangi mahsulot qo'shish.",
            "parameters": {
                "type": "object",
                "properties": {
                    "name": {"type": "string", "description": "Mahsulot nomi (masalan, 'Go\\'sht', 'Kartoshka')"},
                    "qty": {"type": "number", "description": "Miqdori (masalan, 2)"},
                    "unit": {"type": "string", "description": "O'lchov birligi (masalan, 'kg', 'dona', 'litr')"},
                    "estimated_price": {"type": "number", "description": "Kutilayotgan taxminiy narxi (so'mda)"}
                },
                "required": ["name", "qty", "unit"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "set_alarm",
            "description": "Foydalanuvchi uchun majburlovchi budilnik qo'shish. 'ertalab 7 da budilnik qo'y', '6:30 ga uyg'ot' kabi so'rovlarda chaqiring.",
            "parameters": {
                "type": "object",
                "properties": {
                    "hour": {"type": "integer", "description": "Soat (0-23)"},
                    "minute": {"type": "integer", "description": "Daqiqa (0-59)"},
                    "label": {"type": "string", "description": "Budilnik nomi (masalan 'Ishga uyg'onish')"},
                    "repeat_days": {"type": "string", "description": "Takror kunlar ISO CSV (1=Dushanba..7=Yakshanba). Har kuni uchun '1,2,3,4,5,6,7', ish kunlari '1,2,3,4,5'. Bir martalik uchun bo'sh."},
                    "mission_type": {"type": "string", "enum": ["math", "photo", "speech"], "description": "O'chirish vazifasi: matematik misol (math), rasmga olish (photo) yoki matn o'qish (speech). Default: math."}
                },
                "required": ["hour", "minute"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "search_providers",
            "description": "Xizmat ustalarini (sartarosh, santexnik, tozalash, repetitor, avto-yordam va h.k.) qidirish. Bron qilishdan OLDIN chaqiriladi.",
            "parameters": {
                "type": "object",
                "properties": {
                    "service_query": {"type": "string", "description": "Xizmat turi yoki usta nomi (masalan 'sartarosh', 'santexnik', 'tozalash')"}
                },
                "required": ["service_query"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "create_booking",
            "description": "Tanlangan ustaga xizmat buyurtmasini (bron) rasmiylashtirish. search_providers'дан keyin, manzil va vaqt aniqlangач chaqiriladi.",
            "parameters": {
                "type": "object",
                "properties": {
                    "provider_id": {"type": "integer", "description": "search_providers qaytargan usta id'si"},
                    "service_name": {"type": "string", "description": "Xizmat nomi (masalan 'Soch olish', 'Uy tozalash')"},
                    "date": {"type": "string", "description": "ISO 8601 sana va vaqt (masalan '2026-07-07T15:00:00Z')"},
                    "address": {"type": "string", "description": "Xizmat ko'rsatiladigan manzil"},
                    "price": {"type": "number", "description": "Kelishilган narx (so'mda). Noma'lum bo'lsa search natijasidagi taxminiy narx."}
                },
                "required": ["provider_id", "service_name", "date", "address", "price"]
            }
        }
    }
]


def _build_alarm_mission_config(mission_type: str) -> dict:
    if mission_type == "photo":
        return {"target_uz": "kran (yuvinish joyi)", "target_en": "bathroom sink or faucet"}
    if mission_type == "speech":
        return {"random": True}
    return {"difficulty": "medium", "count": 1}

class ChatMessage(BaseModel):
    role: str = Field(..., pattern=r"^(user|assistant)$")
    content: str = Field(..., min_length=1, max_length=2000)

class ChatRequest(BaseModel):
    messages: List[ChatMessage] = Field(..., min_length=1, max_length=50)

class ChatResponse(BaseModel):
    reply: str
    # Mobil ilova bajaradigan yon-amallar (masalan budilnikni lokal rejalashtirish)
    actions: list[dict] = []


async def handle_tool_call(db: AsyncSession, user_id: int, tool_call: dict) -> tuple[str, dict | None]:
    """Tool (function) ni lokal bazada bajarish. (natija_json, client_action|None) qaytaradi."""
    try:
        func_name = tool_call["function"]["name"]
        args = json.loads(tool_call["function"]["arguments"])
        
        if func_name == "add_plan":
            plan = Plan(
                user_id=user_id,
                title=args.get("title"),
                description=args.get("description", ""),
                due_date=datetime.fromisoformat(args.get("due_date").replace('Z', '+00:00'))
            )
            db.add(plan)
            await db.commit()
            return '{"status": "success", "message": "Reja muvaffaqiyatli qo\'shildi."}', None
            
        elif func_name == "add_finance_record":
            record = FinanceRecord(
                user_id=user_id,
                type=args.get("type"),
                amount=float(args.get("amount")),
                category=args.get("category"),
                description=args.get("description", ""),
                date=datetime.now(timezone.utc)
            )
            db.add(record)
            await db.commit()
            return '{"status": "success", "message": "Moliya yozuvi muvaffaqiyatli qo\'shildi."}', None
            
        elif func_name == "add_shopping_item":
            # Active shopping list ni topish yoki yaratish
            result = await db.execute(
                select(ShoppingList).where(ShoppingList.user_id == user_id, ShoppingList.total_estimated_price >= 0).order_by(ShoppingList.id.desc()).limit(1)
            )
            s_list = result.scalar_one_or_none()
            if not s_list:
                s_list = ShoppingList(user_id=user_id, name="Bozorlik (AI orqali)")
                db.add(s_list)
                await db.flush()
                
            items = list(s_list.items) if s_list.items else []
            items.append({
                "name": args.get("name"),
                "qty": float(args.get("qty")),
                "unit": args.get("unit"),
                "estimated_price": float(args.get("estimated_price", 0)),
                "actual_price": None,
                "is_bought": False
            })
            s_list.items = items
            
            # Recalculate total estimated price safely
            total_est = 0.0
            for item in items:
                est = item.get("estimated_price")
                if est is not None:
                    try:
                        total_est += float(est)
                    except ValueError:
                        pass
            s_list.total_estimated_price = total_est
            
            await db.commit()
            return '{"status": "success", "message": "Mahsulot bozorlik ro\'yxatiga muvaffaqiyatli qo\'shildi."}', None

        elif func_name == "set_alarm":
            from app.models.alarm import Alarm
            hour = max(0, min(23, int(args.get("hour"))))
            minute = max(0, min(59, int(args.get("minute"))))
            mission_type = args.get("mission_type") or "math"
            if mission_type not in ("math", "photo", "speech"):
                mission_type = "math"
            mission_config = _build_alarm_mission_config(mission_type)
            alarm = Alarm(
                user_id=user_id,
                label=args.get("label") or "Budilnik",
                hour=hour,
                minute=minute,
                repeat_days=args.get("repeat_days") or "",
                mission_type=mission_type,
                mission_config=mission_config,
            )
            db.add(alarm)
            await db.commit()
            await db.refresh(alarm)
            # Mobil ilova buni olib, budilnikni QURILMADA lokal rejalashtiradi
            action = {
                "type": "schedule_alarm",
                "alarm": {
                    "id": alarm.id,
                    "label": alarm.label,
                    "hour": alarm.hour,
                    "minute": alarm.minute,
                    "repeat_days": alarm.repeat_days,
                    "ringtone": alarm.ringtone,
                    "mission_type": alarm.mission_type,
                    "mission_config": alarm.mission_config,
                    "snooze_enabled": alarm.snooze_enabled,
                    "snooze_minutes": alarm.snooze_minutes,
                    "is_enabled": alarm.is_enabled,
                },
            }
            return '{"status": "success", "message": "Budilnik qo\'shildi va rejalashtirildi."}', action

        elif func_name == "search_providers":
            from app.models.provider import Provider
            from app.models.category import Category
            query = (args.get("service_query") or "").strip()
            ql = query.lower()
            cats = (await db.execute(select(Category))).scalars().all()
            matched_cat = None
            for c in cats:
                key_l = (c.key or "").lower()
                name_l = (c.title_uz or "").lower()
                if ql and (ql in key_l or ql in name_l or (name_l and name_l in ql) or (key_l and key_l in ql)):
                    matched_cat = c
                    break
            pstmt = select(Provider).where(Provider.is_active == True, Provider.is_paused == False)
            if matched_cat:
                pstmt = pstmt.where(Provider.category_id == matched_cat.id)
            elif query:
                pstmt = pstmt.where(Provider.name.ilike(f"%{query}%"))
            pstmt = pstmt.order_by(Provider.rating.desc()).limit(5)
            provs = (await db.execute(pstmt)).scalars().all()
            results = [
                {
                    "id": p.id, "name": p.name, "category_id": p.category_id,
                    "rating": p.rating, "review_count": p.review_count, "address": p.address,
                }
                for p in provs
            ]
            payload = {
                "status": "success",
                "providers": results,
                "matched_category": (
                    {"id": matched_cat.id, "key": matched_cat.key, "name": matched_cat.title_uz}
                    if matched_cat else None
                ),
            }
            return json.dumps(payload, ensure_ascii=False), None

        elif func_name == "create_booking":
            from app.models.provider import Provider
            from app.models.order import Order, OrderStatus
            from app.services.notification_service import NotificationService
            provider_id = int(args.get("provider_id"))
            prov = (await db.execute(select(Provider).where(Provider.id == provider_id))).scalar_one_or_none()
            if not prov:
                return '{"status": "error", "message": "Usta topilmadi"}', None
            price = float(args.get("price") or 0)
            if price <= 0:
                price = 50000.0
            try:
                booking_date = datetime.fromisoformat(
                    (args.get("date") or "").replace("Z", "+00:00")
                ).replace(tzinfo=None)
            except Exception:
                booking_date = datetime.now()
            order = Order(
                user_id=user_id,
                category_id=prov.category_id,
                provider_id=prov.id,
                service_name=args.get("service_name") or "Xizmat",
                address=args.get("address") or "Manzil kiritilmagan",
                date=booking_date,
                price=price,
                status=OrderStatus.pending,
                booking_mode="fixed",
            )
            db.add(order)
            await db.commit()
            await db.refresh(order)
            if prov.owner_user_id:
                NotificationService.notify_new_order_for_provider(prov.owner_user_id, order.id)
            action = {"type": "booking_created", "order_id": order.id, "provider_name": prov.name}
            return json.dumps(
                {"status": "success", "message": "Buyurtma yaratildi", "order_id": order.id},
                ensure_ascii=False,
            ), action

        else:
            return '{"status": "error", "message": "Noma\'lum funksiya"}', None
    except Exception as e:
        logger.error(f"Tool execution failed: {e}")
        return f'{{"status": "error", "message": "Xatolik: {str(e)}"}}', None
async def fallback_local_parse(user_msg: str, user_id: int, db: AsyncSession) -> ChatResponse:
    """
    Failsafe / Local keyword parsing to handle user intents when Groq is unavailable,
    rate-limited, or throws an error.
    """
    text_lc = user_msg.lower().strip()
    import re
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
        from datetime import timedelta
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


@router.post("/chat", response_model=ChatResponse)
@limiter.limit("20/minute")
async def ai_chat(
    request: Request,
    body: ChatRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    AI Agent Proxy — Groq API orqali foydalanuvchi so'rovlarini qabul qiladi
    va kerak bo'lganda avtomatik ravishda bazaga ma'lumot kiritish (tools) ni amalga oshiradi.
    """
    user_msg = body.messages[-1].content
    
    # Emojilarni va mikrofon belgilarini tozalash (masalan, 🎤, 💸)
    import re
    emoji_pattern = re.compile(
        "["
        "\U00010000-\U0010ffff"
        "\u2600-\u27BF"
        "\U0001F300-\U0001F9FF"
        "]+", flags=re.UNICODE
    )
    user_msg_clean = emoji_pattern.sub(r'', user_msg).strip()

    # Chat provayderi — admin panelдан (DB) tanlanadi, aks holda env (CHAT_PROVIDER)
    from app.services import settings_service
    _chat_url, _chat_key, _chat_model = settings_service.resolve_ai(
        feature="chat",
        env_provider=settings.chat_provider,
        keys={
            "openai": settings.openai_api_key,
            "groq": settings.groq_api_key,
            "deepseek": settings.deepseek_api_key,
        },
        default_models={
            "openai": settings.openai_chat_model,
            "groq": settings.groq_model,
            "deepseek": settings.deepseek_chat_model,
        },
    )

    if not _chat_key:
        return await fallback_local_parse(user_msg_clean, current_user.id, db)

    current_time_str = datetime.now(timezone.utc).isoformat()
    system_prompt_formatted = SYSTEM_PROMPT.replace("{current_time}", current_time_str)

    # Initial message list
    groq_messages = [{"role": "system", "content": system_prompt_formatted}]
    for msg in body.messages[:-1]:
        groq_messages.append({"role": msg.role, "content": msg.content})
    # Clean the last user message from emoji
    groq_messages.append({"role": "user", "content": user_msg_clean})

    async def call_groq(messages):
        async with httpx.AsyncClient(timeout=30.0) as client:
            return await client.post(
                _chat_url,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {_chat_key}",
                },
                json={
                    "model": _chat_model,
                    "messages": messages,
                    "tools": TOOLS,
                    "tool_choice": "auto",
                    "temperature": 0.7,
                    "max_tokens": settings.groq_max_tokens,
                },
            )

    try:
        # Agentic loop — model bir turда bir necha tool chaqira oladi (masalan: search → book → javob).
        actions: list[dict] = []
        final_reply = ""
        MAX_TOOL_ROUNDS = 5
        for _round in range(MAX_TOOL_ROUNDS):
            response = await call_groq(groq_messages)
            if response.status_code != 200:
                logger.warning(f"AI API status {response.status_code}. Falling back to local parse.")
                return await fallback_local_parse(user_msg_clean, current_user.id, db)

            message = response.json()["choices"][0]["message"]

            if not message.get("tool_calls"):
                final_reply = message.get("content") or ""
                break

            # Model tool(lar) chaqirdi — bajarib, natijani qaytaramiz
            groq_messages.append(message)
            for tool_call in message["tool_calls"]:
                tool_result_str, action = await handle_tool_call(db, current_user.id, tool_call)
                if action:
                    actions.append(action)
                groq_messages.append({
                    "role": "tool",
                    "tool_call_id": tool_call["id"],
                    "name": tool_call["function"]["name"],
                    "content": tool_result_str,
                })
        else:
            final_reply = "So'rovingiz bajarildi."  # tool rounds limiti

        # Clean <think> blocks just in case
        final_reply = re.sub(r"<think>.*?</think>", "", final_reply, flags=re.DOTALL).strip()
        return ChatResponse(reply=final_reply, actions=actions)

    except (httpx.TimeoutException, httpx.HTTPError) as e:
        logger.error(f"Groq API communication error ({type(e).__name__}): {e}. Falling back to local parse.")
        return await fallback_local_parse(user_msg_clean, current_user.id, db)
    except Exception as e:
        logger.error(f"Unexpected error in ai_chat: {e}. Falling back to local parse.")
        return await fallback_local_parse(user_msg_clean, current_user.id, db)
