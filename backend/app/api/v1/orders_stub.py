"""Buyurtmalar — keyinroq PostgreSQL bilan to‘ldiriladi."""

from fastapi import APIRouter

router = APIRouter()


@router.get("/", summary="Demo buyurtmalar ro‘yxati")
async def list_orders():
    return {
        "items": [],
        "message": "Flutter AppProvider o‘rniga keyin bu yerda real ma’lumot bo‘ladi.",
    }
