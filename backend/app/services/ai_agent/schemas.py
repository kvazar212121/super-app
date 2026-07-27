"""AI chat so'rov/javob sxemalari (Pydantic)."""
from typing import List

from pydantic import BaseModel, Field


class ChatMessage(BaseModel):
    role: str = Field(..., pattern=r"^(user|assistant)$")
    content: str = Field(..., min_length=1, max_length=2000)


class ChatRequest(BaseModel):
    messages: List[ChatMessage] = Field(..., min_length=1, max_length=50)


class ChatResponse(BaseModel):
    reply: str
    # Mobil ilova bajaradigan yon-amallar (masalan budilnikni lokal rejalashtirish)
    actions: list[dict] = []
