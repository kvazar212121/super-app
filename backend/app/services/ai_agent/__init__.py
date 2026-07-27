"""AI agent paketi — komponentlarga bo'lingan tuzilma.

Tashqi kod (ai_chat.py) uchun import yuzasi o'zgarmagan:
    from app.services.ai_agent import TOOLS, handle_tool_call, fallback_local_parse, ...

Komponentlar:
    schemas.py        — ChatMessage / ChatRequest / ChatResponse
    prompt.py         — SYSTEM_PROMPT + build_system_prompt (dinamik kategoriyalar)
    tools_schema.py   — TOOLS (function-calling sxemalari)
    personal_tools.py — qo'shish: reja, moliya, bozorlik, budilnik
    provider_tools.py — search_providers (qat'iy filter), create_booking
    read_tools.py     — list_* / get_* (o'qish)
    manage_tools.py   — bekor qilish / o'chirish / tahrirlash (confirm bilan)
    info_tools.py     — ob-havo, valyuta, namoz vaqtlari
    dispatcher.py     — handle_tool_call (tool → handler yo'naltirish)
    fallback.py       — fallback_local_parse (AI ishlamasa lokal parser)
"""
from .schemas import ChatMessage, ChatRequest, ChatResponse
from .prompt import SYSTEM_PROMPT, build_system_prompt
from .tools_schema import TOOLS
from .dispatcher import HANDLERS, handle_tool_call
from .fallback import fallback_local_parse

__all__ = [
    "ChatMessage",
    "ChatRequest",
    "ChatResponse",
    "SYSTEM_PROMPT",
    "build_system_prompt",
    "TOOLS",
    "HANDLERS",
    "handle_tool_call",
    "fallback_local_parse",
]
