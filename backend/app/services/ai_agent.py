"""AI agent yadrosi — tool sxemalari, tool bajaruvchi va lokal fallback parser.

`ai_chat.py` endpointi shu moduldan foydalanadi. Bu yerda tashqi API chaqiruvi yo'q —
faqat tool logikasi va DB amallari.
"""
import json
import logging
from datetime import datetime, timezone
from typing import List

from pydantic import BaseModel, Field
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.plan import Plan
from app.models.finance_record import FinanceRecord
from app.models.shopping_list import ShoppingList

logger = logging.getLogger(__name__)


SYSTEM_PROMPT = """Siz HubServis SuperApp (universal ilovasi) uchun sun'iy intellekt yordamchi AGENTsiz.
Sizning vazifangiz: foydalanuvchi nomidan ilovadagi deyarli HAMMA ishni bajarish — reja/vazifa/xarajat/bozorlik/budilnik qo'shish, ularni ko'rish, tahrirlash, o'chirish, xizmat bron qilish va bekor qilish, hamda ob-havo/valyuta/namoz vaqtlari kabi ma'lumotlarni berish.

ILOVANING ASOSIY BO'LIMLARI:
1. Rejalarim / Vazifalar (todo): sana-vaqtli rejalar va vazifalar.
2. Mening moliyam: daromad/xarajat, oylik xulosa, balans.
3. Aqlli savdo: bozorlik ro'yxati.
4. Barcha xizmatlar: ustalar (sartarosh, tozalash, santexnik va h.k.) bron qilish.
5. Majburlovchi budilnik: budilnik qo'yish/yoqish/o'chirish.
6. Fitnes: bugungi qadamlar.
7. Ma'lumot: ob-havo, valyuta kurslari, namoz vaqtlari.

SIZ QILA OLADIGAN AMALLAR (tool'lar orqali):
- QO'SHISH: add_plan, add_finance_record, add_shopping_item, set_alarm, search_providers→create_booking
- KO'RISH: list_orders, list_plans, list_todos, list_alarms, list_shopping, get_finance_summary, get_account_info, get_steps_today
- O'ZGARTIRISH/BEKOR: cancel_order, complete_plan, delete_plan, complete_todo, delete_todo, toggle_alarm, delete_alarm, mark_shopping_bought, delete_finance_record
- MA'LUMOT: get_weather, get_currency, get_prayer_times

MUHIM QOIDALAR:
- Faqat o'zbek tilida, qisqa va aniq javob bering. Emojilardan foydalaning.
- SIZ QILA OLMAYDIGAN narsalar: hisobni (akkauntni) o'chirish, tizimdan chiqish (logout), va HAR QANDAY PUL operatsiyasi (balans to'ldirish, premium sotib olish, pul o'tkazish). Bunday so'rovda: "Bu amalni o'zingiz ilova ichida bajarishingiz kerak" deb ayting.

- BEKOR QILISH / O'CHIRISH — IKKI QADAMLI TASDIQ:
  1) Avval kerakli ID'ni topish uchun mos list_* tool'ini chaqiring.
  2) Foydalanuvchiga aniq nima o'chirilishini/bekor qilinishini ayting va "Tasdiqlaysizmi?" deb SO'RANG. Bu bosqichда o'chirish/bekor tool'ini confirm=false bilan chaqirmang yoki umuman chaqirmang.
  3) Foydalanuvchi "ha / tasdiqlayman / bekor qil" deb aniq javob bergandagina tegishli tool'ni confirm=true bilan chaqiring.

- BRON QILISH (aqlli):
  1) search_providers bilan ustalarni toping, 2-3 tasini taklif qiling.
  2) Kerakli ma'lumot (manzil, vaqt, necha kishi, qaysi joy) yetishmasa — foydalanuvchidan SO'RANG.
  3) Lekin foydalanuvchi "o'zing tanla / farqi yo'q / bemalol" desa yoki javob bermasa — mantiqiy DEFAULT qiymatni o'zingiz belgilab (masalan eng yuqori reytingli usta, yaqin vaqt), create_booking bilan bron qiling.

- ⚠️ REJA (add_plan) va BRON (search_providers→create_booking) — BUTUNLAY BOSHQA:
  • "sartaroshxona/salon/ustani BRON qil / band qil / buyurtma ber / chaqir / topib ber" → BU BRON. add_plan ISHLATMANG! Avval search_providers, keyin create_booking.
  • "eslat / rejamga qo'sh / kun tartibimga yoz / vazifa qo'sh" (masalan 'ertaga majlisni eslat') → BU REJA, add_plan ishlating.
  • Shubha bo'lsa: agar gapда biror XIZMAT/USTA nomi bo'lsa (sartarosh, tozalash, massaj...) — bu deyarli har doim BRON, reja emas.

- Har qanday xarajat/daromad/reja/bozorlik/budilnik haqida yozsa, MAJBURIY mos tool'ni chaqiring.
- Hozirgi sana va vaqt (UTC): {current_time}
- Tool natijasini olganingizdan so'ng, foydalanuvchiga tabiiy, qisqa javob yozing (masalan "3 ta faol buyurtmangiz bor:", "Buyurtma bekor qilindi ✅")."""

# AI Tools sxemalari
TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "add_plan",
            "description": "Foydalanuvchining SHAXSIY kun tartibiga eslatma/vazifa qo'shish (masalan 'ertaga majlis', 'soat 3da shifokorga borish', 'onamga qo'ng'iroq qilish'). DIQQAT: bu FAQAT o'zi uchun eslatma. Agar foydalanuvchi biror USTA/XIZMATNI bron qilishni so'rasa (sartarosh, tozalash, santexnik, salon, massaj va h.k.) — bu add_plan EMAS, balki search_providers→create_booking ishlatiladi.",
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
            "description": "Xizmat ustalari/joylarini (sartarosh, sartaroshxona, salon, santexnik, tozalash, massaj, repetitor, avto-yordam va h.k.) qidirish. Foydalanuvchi 'bron qil', 'band qil', 'rezerv qil', 'buyurtma ber', 'chaqir', 'topib ber' desa — ENG BIRINCHI shu tool chaqiriladi (create_booking'дан oldin). Bu reja/eslatma EMAS.",
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
    },
    # ── O'QISH (READ) toollari — foydalanuvchi "nima bor / qancha" deb so'raganda ──
    {
        "type": "function",
        "function": {
            "name": "list_orders",
            "description": "Foydalanuvchining buyurtmalari (bronlari) ro'yxati. 'buyurtmalarim', 'qanaqa bronlarim bor' kabi so'rovlarда, shuningdek bekor qilishдан OLDIN id topish uchun chaqiring.",
            "parameters": {
                "type": "object",
                "properties": {
                    "only_active": {"type": "boolean", "description": "true bo'lsa faqat faol (bekor/yakunlanmagan) buyurtmalar. Default true."}
                },
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "list_plans",
            "description": "Foydalanuvchining rejalari ro'yxati. 'rejalarim', 'bugun nima rejam bor' kabi so'rovlarда yoki reja bekor/bajarilgan qilishдан oldin id topish uchun.",
            "parameters": {"type": "object", "properties": {
                "only_pending": {"type": "boolean", "description": "true bo'lsa faqat bajarilmagan rejalar. Default true."}
            }}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "list_todos",
            "description": "Foydalanuvchining vazifalari (todo) ro'yxati.",
            "parameters": {"type": "object", "properties": {
                "only_pending": {"type": "boolean", "description": "true bo'lsa faqat bajarilmagan vazifalar. Default true."}
            }}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "list_alarms",
            "description": "Foydalanuvchining budilniklari ro'yxati. Budilnik o'chirish/yoqishдан oldin id topish uchun.",
            "parameters": {"type": "object", "properties": {}}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "list_shopping",
            "description": "Foydalanuvchining joriy bozorlik (xarid) ro'yxati mahsulotlari.",
            "parameters": {"type": "object", "properties": {}}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_finance_summary",
            "description": "Joriy oy uchun moliya xulosasi: jami daromad, jami xarajat, balans va toifalar bo'yicha. 'bu oy qancha sarfladim', 'balansim' kabi so'rovlarда.",
            "parameters": {"type": "object", "properties": {}}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_account_info",
            "description": "Foydalanuvchi hisobi haqida: ism, hamyon balansi (so'm), premium holati. 'balansim qancha', 'premiumim bormi' kabi so'rovlarда.",
            "parameters": {"type": "object", "properties": {}}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_steps_today",
            "description": "Bugungi qadamlar soni va yoqilган kaloriya (fitnes). 'bugun necha qadam yurdim' kabi so'rovlarда.",
            "parameters": {"type": "object", "properties": {}}
        }
    },
    # ── BEKOR / O'CHIRISH / TAHRIRLASH — HAMISHA confirm bilan (2-qadamli) ──
    {
        "type": "function",
        "function": {
            "name": "cancel_order",
            "description": "Foydalanuvchining buyurtmasini (bronini) bekor qilish. FAQAT foydalanuvchi aniq tasdiqlaganда confirm=true bilan chaqiring. Avval confirm=false bilan chaqirib, foydalanuvchiдан tasdiq so'rang.",
            "parameters": {
                "type": "object",
                "properties": {
                    "order_id": {"type": "integer", "description": "Bekor qilinadigan buyurtma id'si (list_orders'дан)"},
                    "confirm": {"type": "boolean", "description": "Foydalanuvchi 'ha, bekor qil' deb aniq tasdiqlaganда true. Aks holda false."}
                },
                "required": ["order_id", "confirm"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "complete_plan",
            "description": "Rejani 'bajarildi' deb belgilash. confirm shart emas (zararsiz amal).",
            "parameters": {"type": "object", "properties": {
                "plan_id": {"type": "integer", "description": "Reja id'si (list_plans'дан)"}
            }, "required": ["plan_id"]}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "delete_plan",
            "description": "Rejani butunlay o'chirish. FAQAT foydalanuvchi tasdiqlaganда confirm=true.",
            "parameters": {"type": "object", "properties": {
                "plan_id": {"type": "integer", "description": "Reja id'si"},
                "confirm": {"type": "boolean", "description": "Tasdiqlanганда true"}
            }, "required": ["plan_id", "confirm"]}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "complete_todo",
            "description": "Vazifani (todo) bajarildi deb belgilash.",
            "parameters": {"type": "object", "properties": {
                "todo_id": {"type": "integer", "description": "Vazifa id'si (list_todos'дан)"}
            }, "required": ["todo_id"]}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "delete_todo",
            "description": "Vazifani o'chirish. FAQAT tasdiqlanганда confirm=true.",
            "parameters": {"type": "object", "properties": {
                "todo_id": {"type": "integer", "description": "Vazifa id'si"},
                "confirm": {"type": "boolean"}
            }, "required": ["todo_id", "confirm"]}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "toggle_alarm",
            "description": "Budilnikni yoqish yoki o'chirish (is_enabled). Bu zararsiz — confirm shart emas.",
            "parameters": {"type": "object", "properties": {
                "alarm_id": {"type": "integer", "description": "Budilnik id'si (list_alarms'дан)"},
                "enabled": {"type": "boolean", "description": "Yoqish uchun true, o'chirish uchun false"}
            }, "required": ["alarm_id", "enabled"]}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "delete_alarm",
            "description": "Budilnikni butunlay o'chirish. FAQAT tasdiqlanганда confirm=true.",
            "parameters": {"type": "object", "properties": {
                "alarm_id": {"type": "integer", "description": "Budilnik id'si"},
                "confirm": {"type": "boolean"}
            }, "required": ["alarm_id", "confirm"]}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "mark_shopping_bought",
            "description": "Bozorlik ro'yxatidagi mahsulotni 'sotib olindi' deb belgilash.",
            "parameters": {"type": "object", "properties": {
                "item_name": {"type": "string", "description": "Mahsulot nomi (list_shopping'дан)"}
            }, "required": ["item_name"]}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "delete_finance_record",
            "description": "Moliya yozuvini o'chirish. FAQAT tasdiqlanганда confirm=true.",
            "parameters": {"type": "object", "properties": {
                "record_id": {"type": "integer", "description": "Yozuv id'si"},
                "confirm": {"type": "boolean"}
            }, "required": ["record_id", "confirm"]}
        }
    },
    # ── FOYDALI MA'LUMOTLAR (utility) — tashqi API'lar ──
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Ob-havo ma'lumoti (harorat, holat, shamol). 'ob-havo qanaqa', 'bugun sovuqmi' kabi so'rovlarда.",
            "parameters": {"type": "object", "properties": {
                "city": {"type": "string", "description": "Shahar nomi (default: Tashkent)"}
            }}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_currency",
            "description": "Valyuta kurslari (USD, EUR, RUB, GBP, KZT — CBU rasmiy). 'dollar kursi qancha' kabi so'rovlarда.",
            "parameters": {"type": "object", "properties": {}}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_prayer_times",
            "description": "Namoz vaqtlari. 'namoz vaqtlari', 'peshin qachon' kabi so'rovlarда.",
            "parameters": {"type": "object", "properties": {
                "city": {"type": "string", "description": "Shahar nomi (default: Tashkent)"}
            }}
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

        # ══════════════ O'QISH (READ) toollari ══════════════
        elif func_name == "list_orders":
            from app.models.order import Order, OrderStatus
            from app.models.provider import Provider
            only_active = args.get("only_active", True)
            stmt = select(Order).where(Order.user_id == user_id)
            if only_active:
                stmt = stmt.where(Order.status.notin_([OrderStatus.completed, OrderStatus.cancelled, OrderStatus.no_show]))
            stmt = stmt.order_by(Order.created_at.desc()).limit(15)
            orders = (await db.execute(stmt)).scalars().all()
            out = []
            for o in orders:
                prov = await db.get(Provider, o.provider_id)
                out.append({
                    "order_id": o.id,
                    "service_name": o.service_name,
                    "provider": prov.name if prov else None,
                    "status": o.status.value,
                    "date": o.date.isoformat() if o.date else None,
                    "price": o.price,
                })
            return json.dumps({"status": "success", "orders": out, "count": len(out)}, ensure_ascii=False), None

        elif func_name == "list_plans":
            only_pending = args.get("only_pending", True)
            stmt = select(Plan).where(Plan.user_id == user_id)
            if only_pending:
                stmt = stmt.where(Plan.is_completed == False)
            stmt = stmt.order_by(Plan.due_date.asc()).limit(20)
            plans = (await db.execute(stmt)).scalars().all()
            out = [{"plan_id": p.id, "title": p.title, "due_date": p.due_date.isoformat() if p.due_date else None,
                    "is_completed": p.is_completed} for p in plans]
            return json.dumps({"status": "success", "plans": out, "count": len(out)}, ensure_ascii=False), None

        elif func_name == "list_todos":
            from app.models.todo import Todo
            only_pending = args.get("only_pending", True)
            stmt = select(Todo).where(Todo.user_id == user_id)
            if only_pending:
                stmt = stmt.where(Todo.is_completed == False)
            stmt = stmt.order_by(Todo.created_at.desc()).limit(20)
            todos = (await db.execute(stmt)).scalars().all()
            out = [{"todo_id": t.id, "title": t.title, "is_completed": t.is_completed} for t in todos]
            return json.dumps({"status": "success", "todos": out, "count": len(out)}, ensure_ascii=False), None

        elif func_name == "list_alarms":
            from app.models.alarm import Alarm
            alarms = (await db.execute(
                select(Alarm).where(Alarm.user_id == user_id).order_by(Alarm.hour, Alarm.minute)
            )).scalars().all()
            out = [{"alarm_id": a.id, "label": a.label, "time": f"{a.hour:02d}:{a.minute:02d}",
                    "is_enabled": a.is_enabled, "repeat_days": a.repeat_days} for a in alarms]
            return json.dumps({"status": "success", "alarms": out, "count": len(out)}, ensure_ascii=False), None

        elif func_name == "list_shopping":
            result = await db.execute(
                select(ShoppingList).where(ShoppingList.user_id == user_id).order_by(ShoppingList.id.desc()).limit(1)
            )
            s_list = result.scalar_one_or_none()
            items = (s_list.items if s_list and s_list.items else [])
            out = [{"name": it.get("name"), "qty": it.get("qty"), "unit": it.get("unit"),
                    "is_bought": it.get("is_bought", False)} for it in items]
            return json.dumps({"status": "success", "items": out, "count": len(out)}, ensure_ascii=False), None

        elif func_name == "get_finance_summary":
            income = float(await db.scalar(
                select(func.coalesce(func.sum(FinanceRecord.amount), 0)).where(
                    FinanceRecord.user_id == user_id, FinanceRecord.type == "income",
                    func.extract("month", FinanceRecord.date) == datetime.now(timezone.utc).month,
                    func.extract("year", FinanceRecord.date) == datetime.now(timezone.utc).year,
                )
            ) or 0)
            expense = float(await db.scalar(
                select(func.coalesce(func.sum(FinanceRecord.amount), 0)).where(
                    FinanceRecord.user_id == user_id, FinanceRecord.type == "expense",
                    func.extract("month", FinanceRecord.date) == datetime.now(timezone.utc).month,
                    func.extract("year", FinanceRecord.date) == datetime.now(timezone.utc).year,
                )
            ) or 0)
            return json.dumps({
                "status": "success", "month_income": income, "month_expense": expense,
                "balance": income - expense,
            }, ensure_ascii=False), None

        elif func_name == "get_account_info":
            from app.models.user import User as _U
            u = await db.get(_U, user_id)
            if not u:
                return '{"status": "error", "message": "Foydalanuvchi topilmadi"}', None
            from app.services import premium_service
            return json.dumps({
                "status": "success", "name": u.name,
                "balance": float(u.balance or 0),
                "is_premium": premium_service.is_active(u),
                "premium_until": u.premium_until.isoformat() if u.premium_until else None,
            }, ensure_ascii=False), None

        elif func_name == "get_steps_today":
            from app.models.daily_activity import DailyActivity
            from datetime import date as _date
            row = (await db.execute(
                select(DailyActivity).where(
                    DailyActivity.user_id == user_id, DailyActivity.date == _date.today()
                )
            )).scalar_one_or_none()
            return json.dumps({
                "status": "success",
                "steps": (row.steps if row else 0),
                "calories": (round(row.calories, 1) if row else 0),
            }, ensure_ascii=False), None

        # ══════════════ BEKOR / O'CHIRISH / TAHRIRLASH ══════════════
        elif func_name == "cancel_order":
            from app.models.order import Order, OrderStatus
            if not args.get("confirm"):
                return json.dumps({"status": "needs_confirmation",
                    "message": "Bekor qilishni tasdiqlashini so'rang."}, ensure_ascii=False), None
            o = (await db.execute(
                select(Order).where(Order.id == int(args.get("order_id")), Order.user_id == user_id)
            )).scalar_one_or_none()
            if not o:
                return '{"status": "error", "message": "Buyurtma topilmadi"}', None
            if o.status in (OrderStatus.completed, OrderStatus.cancelled, OrderStatus.no_show):
                return '{"status": "error", "message": "Bu buyurtmani bekor qilib bo\'lmaydi"}', None
            o.status = OrderStatus.cancelled
            await db.commit()
            return json.dumps({"status": "success", "message": "Buyurtma bekor qilindi", "order_id": o.id},
                              ensure_ascii=False), {"type": "orders_changed"}

        elif func_name == "complete_plan":
            p = (await db.execute(
                select(Plan).where(Plan.id == int(args.get("plan_id")), Plan.user_id == user_id)
            )).scalar_one_or_none()
            if not p:
                return '{"status": "error", "message": "Reja topilmadi"}', None
            p.is_completed = True
            await db.commit()
            return '{"status": "success", "message": "Reja bajarildi deb belgilandi."}', {"type": "plans_changed"}

        elif func_name == "delete_plan":
            if not args.get("confirm"):
                return '{"status": "needs_confirmation", "message": "O\'chirishni tasdiqlashini so\'rang."}', None
            p = (await db.execute(
                select(Plan).where(Plan.id == int(args.get("plan_id")), Plan.user_id == user_id)
            )).scalar_one_or_none()
            if not p:
                return '{"status": "error", "message": "Reja topilmadi"}', None
            await db.delete(p)
            await db.commit()
            return '{"status": "success", "message": "Reja o\'chirildi."}', {"type": "plans_changed"}

        elif func_name == "complete_todo":
            from app.models.todo import Todo
            t = (await db.execute(
                select(Todo).where(Todo.id == int(args.get("todo_id")), Todo.user_id == user_id)
            )).scalar_one_or_none()
            if not t:
                return '{"status": "error", "message": "Vazifa topilmadi"}', None
            t.is_completed = True
            await db.commit()
            return '{"status": "success", "message": "Vazifa bajarildi deb belgilandi."}', {"type": "todos_changed"}

        elif func_name == "delete_todo":
            from app.models.todo import Todo
            if not args.get("confirm"):
                return '{"status": "needs_confirmation", "message": "O\'chirishni tasdiqlashini so\'rang."}', None
            t = (await db.execute(
                select(Todo).where(Todo.id == int(args.get("todo_id")), Todo.user_id == user_id)
            )).scalar_one_or_none()
            if not t:
                return '{"status": "error", "message": "Vazifa topilmadi"}', None
            await db.delete(t)
            await db.commit()
            return '{"status": "success", "message": "Vazifa o\'chirildi."}', {"type": "todos_changed"}

        elif func_name == "toggle_alarm":
            from app.models.alarm import Alarm
            a = (await db.execute(
                select(Alarm).where(Alarm.id == int(args.get("alarm_id")), Alarm.user_id == user_id)
            )).scalar_one_or_none()
            if not a:
                return '{"status": "error", "message": "Budilnik topilmadi"}', None
            a.is_enabled = bool(args.get("enabled"))
            await db.commit()
            msg = "Budilnik yoqildi." if a.is_enabled else "Budilnik o'chirildi."
            return json.dumps({"status": "success", "message": msg}, ensure_ascii=False), {"type": "alarms_changed", "alarm_id": a.id, "enabled": a.is_enabled}

        elif func_name == "delete_alarm":
            from app.models.alarm import Alarm
            if not args.get("confirm"):
                return '{"status": "needs_confirmation", "message": "O\'chirishni tasdiqlashini so\'rang."}', None
            a = (await db.execute(
                select(Alarm).where(Alarm.id == int(args.get("alarm_id")), Alarm.user_id == user_id)
            )).scalar_one_or_none()
            if not a:
                return '{"status": "error", "message": "Budilnik topilmadi"}', None
            aid = a.id
            await db.delete(a)
            await db.commit()
            return '{"status": "success", "message": "Budilnik o\'chirildi."}', {"type": "alarms_changed", "alarm_id": aid, "deleted": True}

        elif func_name == "mark_shopping_bought":
            result = await db.execute(
                select(ShoppingList).where(ShoppingList.user_id == user_id).order_by(ShoppingList.id.desc()).limit(1)
            )
            s_list = result.scalar_one_or_none()
            if not s_list or not s_list.items:
                return '{"status": "error", "message": "Bozorlik ro\'yxati bo\'sh"}', None
            name_q = (args.get("item_name") or "").strip().lower()
            items = list(s_list.items)
            found = False
            for it in items:
                if (it.get("name") or "").strip().lower() == name_q:
                    it["is_bought"] = True
                    found = True
                    break
            if not found:
                return '{"status": "error", "message": "Mahsulot topilmadi"}', None
            s_list.items = items
            await db.commit()
            return '{"status": "success", "message": "Mahsulot sotib olindi deb belgilandi."}', {"type": "shopping_changed"}

        elif func_name == "delete_finance_record":
            if not args.get("confirm"):
                return '{"status": "needs_confirmation", "message": "O\'chirishni tasdiqlashini so\'rang."}', None
            r = (await db.execute(
                select(FinanceRecord).where(FinanceRecord.id == int(args.get("record_id")), FinanceRecord.user_id == user_id)
            )).scalar_one_or_none()
            if not r:
                return '{"status": "error", "message": "Yozuv topilmadi"}', None
            await db.delete(r)
            await db.commit()
            return '{"status": "success", "message": "Moliya yozuvi o\'chirildi."}', {"type": "finance_changed"}

        # ══════════════ FOYDALI MA'LUMOTLAR (utility) ══════════════
        elif func_name == "get_weather":
            import httpx as _httpx
            city = args.get("city") or "Tashkent"
            try:
                async with _httpx.AsyncClient(timeout=10.0) as client:
                    resp = await client.get(
                        "https://api.open-meteo.com/v1/forecast?latitude=41.2995&longitude=69.2401&current_weather=true"
                    )
                    resp.raise_for_status()
                    cur = resp.json().get("current_weather", {})
                    return json.dumps({"status": "success", "city": city,
                        "temperature": cur.get("temperature"), "windspeed": cur.get("windspeed")},
                        ensure_ascii=False), None
            except Exception:
                return '{"status": "error", "message": "Ob-havo olinmadi"}', None

        elif func_name == "get_currency":
            import httpx as _httpx
            try:
                async with _httpx.AsyncClient(timeout=10.0) as client:
                    resp = await client.get("https://cbu.uz/uz/arkhiv-kursov-valyut/json/")
                    resp.raise_for_status()
                    data = resp.json()
                    want = ["USD", "EUR", "RUB", "GBP", "KZT"]
                    rates = {i["Ccy"]: i["Rate"] for i in data if i["Ccy"] in want}
                    return json.dumps({"status": "success", "rates": rates}, ensure_ascii=False), None
            except Exception:
                return '{"status": "error", "message": "Valyuta kurslari olinmadi"}', None

        elif func_name == "get_prayer_times":
            import httpx as _httpx
            city = args.get("city") or "Tashkent"
            try:
                async with _httpx.AsyncClient(timeout=10.0) as client:
                    resp = await client.get(
                        f"https://api.aladhan.com/v1/timingsByCity?city={city}&country=Uzbekistan&method=3"
                    )
                    resp.raise_for_status()
                    t = resp.json()["data"]["timings"]
                    return json.dumps({"status": "success", "timings": {
                        "Bomdod": t.get("Fajr"), "Quyosh": t.get("Sunrise"), "Peshin": t.get("Dhuhr"),
                        "Asr": t.get("Asr"), "Shom": t.get("Maghrib"), "Xufton": t.get("Isha"),
                    }}, ensure_ascii=False), None
            except Exception:
                return '{"status": "error", "message": "Namoz vaqtlari olinmadi"}', None

        else:
            return '{"status": "error", "message": "Noma\'lum funksiya"}', None
    except Exception as e:
        # Sessiyani tozalaymiz — aks holda keyingi barcha tool chaqiruvlari PendingRollbackError bilan yiqiladi
        try:
            await db.rollback()
        except Exception:
            pass
        logger.error(f"Tool execution failed: {e}")
        return '{"status": "error", "message": "Amalni bajarishda xatolik yuz berdi."}', None


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
