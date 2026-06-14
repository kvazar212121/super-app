from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update

from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.shopping_list import ShoppingList
from app.models.product_catalog import ProductCatalog
from app.schemas.dailies import (
    ShoppingListCreate, ShoppingListOut, ShoppingListUpdate,
    ShoppingPriceEstimateRequest, ShoppingPriceEstimateResponse,
    ShoppingItemPriceUpdate,
)

router = APIRouter(prefix="/shopping", tags=["shopping"])

# ── O'zbekiston bozor narxlari (AI taxminiy narxlari) ──────────────────────
# unit_price: so'm / birlik (kg, dona, litr)
_DEFAULT_PRICES = {
    # Mevalar
    "olma": {"unit": "kg", "price": 15000},
    "banan": {"unit": "kg", "price": 22000},
    "anor": {"unit": "kg", "price": 25000},
    "uzum": {"unit": "kg", "price": 18000},
    "nok": {"unit": "kg", "price": 20000},
    "shaftoli": {"unit": "kg", "price": 22000},
    "gilos": {"unit": "kg", "price": 30000},
    "qulupnay": {"unit": "kg", "price": 35000},
    "limon": {"unit": "kg", "price": 28000},
    "apelsin": {"unit": "kg", "price": 20000},
    "mandarin": {"unit": "kg", "price": 18000},
    "tarvuz": {"unit": "kg", "price": 5000},
    "qovun": {"unit": "kg", "price": 8000},
    "xurmo": {"unit": "kg", "price": 35000},
    "anjir": {"unit": "kg", "price": 40000},
    "olcha": {"unit": "kg", "price": 25000},
    "o'rik": {"unit": "kg", "price": 20000},
    
    # Sabzavotlar
    "pomidor": {"unit": "kg", "price": 12000},
    "bodring": {"unit": "kg", "price": 10000},
    "kartoshka": {"unit": "kg", "price": 6000},
    "piyoz": {"unit": "kg", "price": 5000},
    "sarimsoq": {"unit": "kg", "price": 40000},
    "sabzi": {"unit": "kg", "price": 7000},
    "karam": {"unit": "kg", "price": 6000},
    "baqlajon": {"unit": "kg", "price": 12000},
    "qalampir": {"unit": "kg", "price": 15000},
    "ko'k qalampir": {"unit": "kg", "price": 15000},
    "turp": {"unit": "kg", "price": 8000},
    "lavlagi": {"unit": "kg", "price": 5000},
    "sholgom": {"unit": "kg", "price": 5000},
    "ukrop": {"unit": "bog'", "price": 2000},
    "kinza": {"unit": "bog'", "price": 2000},
    "jambil": {"unit": "bog'", "price": 2000},
    "rayhon": {"unit": "bog'", "price": 2000},
    "ko'katlar": {"unit": "bog'", "price": 2000},
    
    # Go'sht
    "mol go'shti": {"unit": "kg", "price": 95000},
    "go'sht": {"unit": "kg", "price": 90000},
    "qo'y go'shti": {"unit": "kg", "price": 110000},
    "tovuq": {"unit": "kg", "price": 35000},
    "tovuq go'shti": {"unit": "kg", "price": 35000},
    "baliq": {"unit": "kg", "price": 45000},
    "jigar": {"unit": "kg", "price": 60000},
    "qiyma": {"unit": "kg", "price": 80000},
    "kolbasa": {"unit": "kg", "price": 65000},
    "sosiska": {"unit": "kg", "price": 55000},
    
    # Sut mahsulotlari
    "sut": {"unit": "litr", "price": 8000},
    "qatiq": {"unit": "litr", "price": 10000},
    "tvorog": {"unit": "kg", "price": 25000},
    "smetana": {"unit": "kg", "price": 30000},
    "sariyog'": {"unit": "kg", "price": 85000},
    "pishloq": {"unit": "kg", "price": 70000},
    "suzma": {"unit": "kg", "price": 20000},
    "qaymoq": {"unit": "litr", "price": 25000},
    "kefir": {"unit": "litr", "price": 12000},
    "yogurt": {"unit": "dona", "price": 5000},
    "tuxum": {"unit": "dona", "price": 1800},
    
    # Non va un mahsulotlari
    "non": {"unit": "dona", "price": 3000},
    "lepyoshka": {"unit": "dona", "price": 3500},
    "somsa": {"unit": "dona", "price": 7000},
    "un": {"unit": "kg", "price": 7000},
    "makaron": {"unit": "kg", "price": 10000},
    "guruch": {"unit": "kg", "price": 15000},
    "grechixa": {"unit": "kg", "price": 14000},
    
    # Moylar
    "o'simlik moyi": {"unit": "litr", "price": 22000},
    "moy": {"unit": "litr", "price": 22000},
    "zaytun moyi": {"unit": "litr", "price": 80000},
    
    # Ichimliklar
    "suv": {"unit": "litr", "price": 2000},
    "sharbat": {"unit": "litr", "price": 10000},
    "pepsi": {"unit": "litr", "price": 8000},
    "coca-cola": {"unit": "litr", "price": 8000},
    "mineral suv": {"unit": "litr", "price": 3000},
    "kompot": {"unit": "litr", "price": 15000},
    "choy": {"unit": "kg", "price": 50000},
    "kofe": {"unit": "kg", "price": 80000},
    
    # Boshqa
    "shakar": {"unit": "kg", "price": 10000},
    "tuz": {"unit": "kg", "price": 3000},
    "yog'": {"unit": "litr", "price": 22000},
    "ketchup": {"unit": "dona", "price": 15000},
    "mayonez": {"unit": "dona", "price": 12000},
    "sirka": {"unit": "litr", "price": 8000},
    "zira": {"unit": "kg", "price": 80000},
    "murch": {"unit": "kg", "price": 100000},
}


def _estimate_item_price(name: str, qty: float) -> dict:
    """
    Estimate the price for a single item using the built-in catalog.
    Tries exact match first, then partial substring matching.
    """
    lower = name.lower().strip()
    
    # Exact match
    if lower in _DEFAULT_PRICES:
        info = _DEFAULT_PRICES[lower]
        return {
            "name": name,
            "qty": qty,
            "unit": info["unit"],
            "unit_price": info["price"],
            "estimated_price": round(info["price"] * qty, 0),
            "actual_price": None,
            "is_bought": False,
        }
    
    # Partial match
    for key, info in _DEFAULT_PRICES.items():
        if lower in key or key in lower:
            return {
                "name": name,
                "qty": qty,
                "unit": info["unit"],
                "unit_price": info["price"],
                "estimated_price": round(info["price"] * qty, 0),
                "actual_price": None,
                "is_bought": False,
            }
    
    # No match — return zero estimate
    return {
        "name": name,
        "qty": qty,
        "unit": "dona",
        "unit_price": 0.0,
        "estimated_price": 0.0,
        "actual_price": None,
        "is_bought": False,
    }


# ── GET all lists ──────────────────────────────────────────────────────────
@router.get("/", response_model=list[ShoppingListOut])
async def get_shopping_lists(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(ShoppingList)
        .where(ShoppingList.user_id == current_user.id)
        .order_by(ShoppingList.created_at.desc())
    )
    return result.scalars().all()


# ── POST calculate-price (estimate without saving) ─────────────────────────
@router.post("/calculate-price", response_model=ShoppingPriceEstimateResponse)
async def calculate_price(
    data: ShoppingPriceEstimateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Estimate prices for items using DB catalog, then built-in fallback."""
    estimated_items = []
    total = 0.0
    
    for item in data.items:
        # Try database catalog first
        result = await db.execute(
            select(ProductCatalog)
            .where(ProductCatalog.name.ilike(f"%{item.name}%"))
            .limit(1)
        )
        product = result.scalar_one_or_none()
        
        if product:
            unit_price = product.average_price
            est = {
                "name": item.name,
                "qty": item.qty,
                "unit": product.unit or item.unit,
                "unit_price": unit_price,
                "estimated_price": round(unit_price * item.qty, 0),
                "actual_price": None,
                "is_bought": False,
            }
        else:
            # Fallback to built-in prices
            est = _estimate_item_price(item.name, item.qty)
        
        total += est["estimated_price"]
        estimated_items.append(est)
    
    return {"items": estimated_items, "total_estimated_price": total}


# ── POST create list (estimate + save) ─────────────────────────────────────
@router.post("/", response_model=ShoppingListOut)
async def create_shopping_list(
    data: ShoppingListCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Create a new shopping list, auto-estimating prices for all items."""
    items_with_price = []
    total_price = 0.0
    
    for item in data.items:
        # Try database catalog first
        result = await db.execute(
            select(ProductCatalog)
            .where(ProductCatalog.name.ilike(f"%{item.name}%"))
            .limit(1)
        )
        product = result.scalar_one_or_none()
        
        if product:
            unit_price = product.average_price
            est = {
                "name": item.name,
                "qty": item.qty,
                "unit": product.unit or item.unit,
                "unit_price": unit_price,
                "estimated_price": round(unit_price * item.qty, 0),
                "actual_price": None,
                "is_bought": False,
            }
        else:
            est = _estimate_item_price(item.name, item.qty)
        
        total_price += est["estimated_price"]
        items_with_price.append(est)
    
    shopping_list = ShoppingList(
        user_id=current_user.id,
        name=data.name,
        items=items_with_price,
        total_estimated_price=total_price,
        total_actual_price=0.0,
    )
    
    db.add(shopping_list)
    await db.commit()
    await db.refresh(shopping_list)
    
    return shopping_list


# ── PUT update list ────────────────────────────────────────────────────────
@router.put("/{list_id}", response_model=ShoppingListOut)
async def update_shopping_list(
    list_id: int,
    data: ShoppingListUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(ShoppingList).where(
            ShoppingList.id == list_id,
            ShoppingList.user_id == current_user.id
        )
    )
    sl = result.scalar_one_or_none()
    if not sl:
        raise HTTPException(status_code=404, detail="Ro'yxat topilmadi")
    
    if data.name is not None:
        sl.name = data.name
    if data.items is not None:
        sl.items = data.items
    if data.total_estimated_price is not None:
        sl.total_estimated_price = data.total_estimated_price
    if data.total_actual_price is not None:
        sl.total_actual_price = data.total_actual_price
    if data.is_completed is not None:
        sl.is_completed = data.is_completed
    
    await db.commit()
    await db.refresh(sl)
    return sl


# ── PATCH update a single item's price/bought state ───────────────────────
@router.patch("/{list_id}/item", response_model=ShoppingListOut)
async def update_item_in_list(
    list_id: int,
    data: ShoppingItemPriceUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(ShoppingList).where(
            ShoppingList.id == list_id,
            ShoppingList.user_id == current_user.id
        )
    )
    sl = result.scalar_one_or_none()
    if not sl:
        raise HTTPException(status_code=404, detail="Ro'yxat topilmadi")
    
    items = list(sl.items)  # make a mutable copy of JSONB
    if data.item_index < 0 or data.item_index >= len(items):
        raise HTTPException(status_code=400, detail="Item index noto'g'ri")
    
    if data.actual_price is not None:
        items[data.item_index]["actual_price"] = data.actual_price
    if data.is_bought is not None:
        items[data.item_index]["is_bought"] = data.is_bought
    
    # Recalculate total actual price
    total_actual = sum(
        (itm.get("actual_price") or itm.get("estimated_price", 0))
        for itm in items
        if itm.get("is_bought")
    )
    
    sl.items = items
    sl.total_actual_price = total_actual
    
    # Check if all bought
    if all(itm.get("is_bought") for itm in items):
        sl.is_completed = True
    
    await db.commit()
    await db.refresh(sl)
    return sl


# ── DELETE a list ──────────────────────────────────────────────────────────
@router.delete("/{list_id}")
async def delete_shopping_list(
    list_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(ShoppingList).where(
            ShoppingList.id == list_id,
            ShoppingList.user_id == current_user.id
        )
    )
    sl = result.scalar_one_or_none()
    if not sl:
        raise HTTPException(status_code=404, detail="Ro'yxat topilmadi")
    
    await db.delete(sl)
    await db.commit()
    return {"detail": "O'chirildi"}
