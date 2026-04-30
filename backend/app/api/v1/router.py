from fastapi import APIRouter

from app.api.v1 import health, orders_stub

api_router = APIRouter()
api_router.include_router(health.router, tags=["health"])
api_router.include_router(orders_stub.router, prefix="/orders", tags=["orders"])
