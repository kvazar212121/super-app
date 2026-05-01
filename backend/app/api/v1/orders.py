from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.services.order_service import OrderService
from app.schemas.order import OrderCreate, OrderOut, OrderStatusUpdate
from app.schemas.common import PaginatedResponse

router = APIRouter(prefix="/orders", tags=["orders"])


@router.post("", response_model=OrderOut, status_code=201)
async def create_order(
    data: OrderCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    order = await OrderService.create(db, current_user, data)
    return order


@router.get("/my", response_model=PaginatedResponse)
async def list_my_orders(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    items, total = await OrderService.list_by_user(db, current_user.id, page, per_page)
    pages = (total + per_page - 1) // per_page
    return PaginatedResponse(
        items=[OrderOut.model_validate(o) for o in items],
        total=total,
        page=page,
        per_page=per_page,
        pages=pages,
    )


@router.get("/my/{order_id}", response_model=OrderOut)
async def get_my_order(
    order_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await OrderService.get_by_id(db, current_user.id, order_id)


@router.patch("/my/{order_id}/status", response_model=OrderOut)
async def update_order_status(
    order_id: int,
    data: OrderStatusUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await OrderService.update_status(db, current_user.id, order_id, data)