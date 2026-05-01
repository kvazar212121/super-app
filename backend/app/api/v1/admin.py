from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.category import Category, CategoryVariant
from app.models.provider import Provider
from app.models.order import Order
from app.services.order_service import OrderService
from app.schemas.category import CategoryCreate, CategoryOut, VariantCreate, VariantOut
from app.schemas.provider import ProviderCreate, ProviderUpdate, ProviderOut
from app.schemas.order import OrderOut, OrderStatusUpdate
from app.schemas.common import PaginatedResponse

router = APIRouter(prefix="/admin", tags=["admin"])

admin_only_msg = "Faqat admin uchun ruxsat"


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    if not current_user.is_admin:
        from fastapi import HTTPException
        raise HTTPException(status_code=403, detail=admin_only_msg)
    return current_user


@router.get("/orders", response_model=PaginatedResponse)
async def list_all_orders(
    status: str | None = Query(None),
    category_id: int | None = Query(None),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    items, total = await OrderService.list_all(db, status, category_id, page, per_page)
    pages = (total + per_page - 1) // per_page
    return PaginatedResponse(
        items=[OrderOut.model_validate(o) for o in items],
        total=total, page=page, per_page=per_page, pages=pages,
    )


@router.patch("/orders/{order_id}/status", response_model=OrderOut)
async def admin_update_order_status(
    order_id: int,
    data: OrderStatusUpdate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Order).where(Order.id == order_id))
    order = result.scalar_one_or_none()
    if not order:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Buyurtma topilmadi")
    from app.models.order import OrderStatus
    order.status = OrderStatus(data.status)
    await db.flush()
    await db.refresh(order)
    return order


@router.post("/categories", response_model=CategoryOut, status_code=201)
async def create_category(
    data: CategoryCreate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    cat = Category(**data.model_dump())
    db.add(cat)
    await db.flush()
    await db.refresh(cat)
    return cat


@router.post("/categories/{category_id}/variants", response_model=VariantOut, status_code=201)
async def create_variant(
    category_id: int,
    data: VariantCreate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    v = CategoryVariant(category_id=category_id, **data.model_dump())
    db.add(v)
    await db.flush()
    await db.refresh(v)
    return v


@router.post("/providers", response_model=ProviderOut, status_code=201)
async def create_provider(
    data: ProviderCreate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    p = Provider(**data.model_dump(exclude={"metadata_json"}))
    if data.metadata_json:
        p.metadata = data.metadata_json
    db.add(p)
    await db.flush()
    await db.refresh(p)
    return p


@router.patch("/providers/{provider_id}", response_model=ProviderOut)
async def update_provider(
    provider_id: int,
    data: ProviderUpdate,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Provider).where(Provider.id == provider_id))
    p = result.scalar_one_or_none()
    if not p:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Provayder topilmadi")
    update_data = data.model_dump(exclude_unset=True, exclude={"metadata_json"})
    for key, val in update_data.items():
        setattr(p, key, val)
    if data.metadata_json is not None:
        p.metadata = data.metadata_json
    await db.flush()
    await db.refresh(p)
    return p


@router.delete("/providers/{provider_id}", status_code=204)
async def delete_provider(
    provider_id: int,
    _admin: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Provider).where(Provider.id == provider_id))
    p = result.scalar_one_or_none()
    if not p:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Provayder topilmadi")
    await db.delete(p)