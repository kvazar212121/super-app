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

QOIDALAR:
- Faqat o'zbek tilida, qisqa va aniq javob bering. Emojilardan foydalaning.
- Agar foydalanuvchi biron bir xarajat ("bugun oshga 50 ming ketdi"), daromad, reja ("ertaga soat 10 da majlis"), yoki bozorlik ("bozorlikka 2kg go'sht qo'sh") haqida yozsa, MAJBURIY ravishda mos tool ni chaqiring.
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
    }
]

class ChatMessage(BaseModel):
    role: str = Field(..., pattern=r"^(user|assistant)$")
    content: str = Field(..., min_length=1, max_length=2000)

class ChatRequest(BaseModel):
    messages: List[ChatMessage] = Field(..., min_length=1, max_length=50)

class ChatResponse(BaseModel):
    reply: str


async def handle_tool_call(db: AsyncSession, user_id: int, tool_call: dict) -> str:
    """Tool (function) ni lokal bazada bajarish."""
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
            return '{"status": "success", "message": "Reja muvaffaqiyatli qo\'shildi."}'
            
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
            return '{"status": "success", "message": "Moliya yozuvi muvaffaqiyatli qo\'shildi."}'
            
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
            return '{"status": "success", "message": "Mahsulot bozorlik ro\'yxatiga muvaffaqiyatli qo\'shildi."}'
            
        else:
            return '{"status": "error", "message": "Noma\'lum funksiya"}'
    except Exception as e:
        logger.error(f"Tool execution failed: {e}")
        return f'{{"status": "error", "message": "Xatolik: {str(e)}"}}'


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
    if not settings.groq_api_key:
        raise HTTPException(status_code=503, detail="AI xizmati hozircha sozlanmagan.")

    current_time_str = datetime.now(timezone.utc).isoformat()
    system_prompt_formatted = SYSTEM_PROMPT.replace("{current_time}", current_time_str)

    # Initial message list
    groq_messages = [{"role": "system", "content": system_prompt_formatted}]
    for msg in body.messages:
        groq_messages.append({"role": msg.role, "content": msg.content})

    async def call_groq(messages):
        async with httpx.AsyncClient(timeout=30.0) as client:
            return await client.post(
                "https://api.groq.com/openai/v1/chat/completions",
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {settings.groq_api_key}",
                },
                json={
                    "model": settings.groq_model,
                    "messages": messages,
                    "tools": TOOLS,
                    "tool_choice": "auto",
                    "temperature": 0.7,
                    "max_tokens": settings.groq_max_tokens,
                },
            )

    try:
        response = await call_groq(groq_messages)
        if response.status_code != 200:
            raise HTTPException(status_code=502, detail="AI xizmatidan javob olishda xatolik.")

        data = response.json()
        message = data["choices"][0]["message"]
        
        # Agar model Tool (funksiya) chaqirsa
        if message.get("tool_calls"):
            groq_messages.append(message) # Append assistant's tool_call request
            
            for tool_call in message["tool_calls"]:
                tool_call_id = tool_call["id"]
                tool_result_str = await handle_tool_call(db, current_user.id, tool_call)
                
                # Append tool result to messages
                groq_messages.append({
                    "role": "tool",
                    "tool_call_id": tool_call_id,
                    "name": tool_call["function"]["name"],
                    "content": tool_result_str
                })
            
            # Ikkinchi marta so'rov yuborish (natijani aytib berish uchun)
            second_response = await call_groq(groq_messages)
            if second_response.status_code != 200:
                raise HTTPException(status_code=502, detail="AI xizmatidan tasdiq olishda xatolik.")
                
            second_data = second_response.json()
            final_reply = second_data["choices"][0]["message"]["content"]
            
        else:
            final_reply = message["content"]

        # Clean <think> blocks just in case
        import re
        final_reply = re.sub(r"<think>.*?</think>", "", final_reply, flags=re.DOTALL).strip()
        return ChatResponse(reply=final_reply)

    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="AI javob berishda vaqt tugadi. Qayta urinib ko'ring.")
    except HTTPException:
        raise
    except Exception as e:
        logger.error("AI chat proxy xatolik: %s", str(e))
        raise HTTPException(status_code=500, detail="Kutilmagan xatolik yuz berdi.")
