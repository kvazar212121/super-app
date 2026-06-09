from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.shopping_list import ShoppingList
from app.models.product_catalog import ProductCatalog
from app.schemas.dailies import ShoppingListCreate, ShoppingListOut

router = APIRouter(prefix="/shopping", tags=["shopping"])

@router.get("/", response_model=list[ShoppingListOut])
async def get_shopping_lists(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(ShoppingList).where(ShoppingList.user_id == current_user.id).order_by(ShoppingList.created_at.desc()))
    return result.scalars().all()

@router.post("/estimate", response_model=ShoppingListOut)
async def create_and_estimate_shopping_list(
    data: ShoppingListCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    items_with_price = []
    total_price = 0.0
    
    for item in data.items:
        # Search catalog for average price
        result = await db.execute(select(ProductCatalog).where(ProductCatalog.name.ilike(f"%{item.name}%")).limit(1))
        product = result.scalar_one_or_none()
        
        estimated_unit_price = product.average_price if product else 0.0
        item_total = estimated_unit_price * item.qty
        total_price += item_total
        
        items_with_price.append({
            "name": item.name,
            "qty": item.qty,
            "unit": item.unit,
            "estimated_price": item_total,
            "unit_price": estimated_unit_price
        })
        
    shopping_list = ShoppingList(
        user_id=current_user.id,
        items=items_with_price,
        total_estimated_price=total_price
    )
    
    db.add(shopping_list)
    await db.commit()
    await db.refresh(shopping_list)
    
    return shopping_list
