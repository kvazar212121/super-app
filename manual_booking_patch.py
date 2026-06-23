from datetime import datetime
from pydantic import BaseModel
from sqlalchemy import select
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.database import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.order import Order, OrderStatus

class ManualCallOrderIn(BaseModel):
    user_id: int
    service_name: str
    date: datetime
    price: float
    address: str | None = None
    notes: str | None = "Tel orqali kelishildi"
