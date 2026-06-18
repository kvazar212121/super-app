import random
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, func

from app.db.session import get_db
from app.api.v1.admin.dependencies import require_admin
from app.models.user import User
from app.models.product_catalog import ProductCatalog, ProductPriceEntry
from app.schemas.product_catalog import (
    ProductCatalogOut, ProductCatalogCreate, ProductCatalogUpdate,
    ProductPriceEntryCreate
)

router = APIRouter(prefix="/products", tags=["admin products"])

# ── helper function to recalculate average price ───────────────────────────
async def _recalculate_avg_price(db: AsyncSession, product_id: int):
    result = await db.execute(
        select(ProductPriceEntry.price).where(ProductPriceEntry.product_id == product_id)
    )
    prices = result.scalars().all()
    if prices:
        avg = sum(prices) / len(prices)
        avg = round(avg, 0)
    else:
        avg = 0.0
        
    await db.execute(
        update(ProductCatalog)
        .where(ProductCatalog.id == product_id)
        .values(average_price=avg)
    )
    await db.commit()

# ── GET admin/products ──────────────────────────────────────────────────────
@router.get("/")
async def get_admin_products(
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1),
    search: str = Query("", description="Qidirish kaliti"),
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    stmt = select(ProductCatalog)
    if search:
        stmt = stmt.where(ProductCatalog.name.ilike(f"%{search}%"))
    
    # Get total count
    count_stmt = select(func.count()).select_from(stmt.subquery())
    total = (await db.execute(count_stmt)).scalar() or 0
    
    # Pagination
    stmt = stmt.order_by(ProductCatalog.name.asc()).offset((page - 1) * per_page).limit(per_page)
    result = await db.execute(stmt)
    items = result.scalars().all()
    
    pages = (total + per_page - 1) // per_page
    
    # Convert to schema structure
    items_out = []
    for item in items:
        # Load price entries manually to ensure clean serialization
        entries_res = await db.execute(
            select(ProductPriceEntry)
            .where(ProductPriceEntry.product_id == item.id)
            .order_by(ProductPriceEntry.created_at.desc())
        )
        entries = entries_res.scalars().all()
        
        items_out.append({
            "id": item.id,
            "name": item.name,
            "unit": item.unit,
            "average_price": item.average_price,
            "created_at": item.created_at,
            "updated_at": item.updated_at,
            "price_entries": [
                {
                    "id": pe.id,
                    "product_id": pe.product_id,
                    "source_type": pe.source_type,
                    "price": pe.price,
                    "created_at": pe.created_at
                } for pe in entries
            ]
        })
        
    return {
        "items": items_out,
        "total": total,
        "page": page,
        "per_page": per_page,
        "pages": pages
    }

# ── POST admin/products (create manual product) ─────────────────────────────
@router.post("/", response_model=ProductCatalogOut)
async def create_admin_product(
    data: ProductCatalogCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    # Check if exists
    exists_res = await db.execute(
        select(ProductCatalog).where(ProductCatalog.name.ilike(data.name))
    )
    if exists_res.scalar_one_or_none():
        raise HTTPException(status_code=400, detail="Bu nomdagi mahsulot allaqachon mavjud")
        
    product = ProductCatalog(
        name=data.name,
        unit=data.unit,
        average_price=data.average_price
    )
    db.add(product)
    await db.flush()
    
    # Add initial price entry if set
    if data.average_price > 0:
        pe = ProductPriceEntry(
            product_id=product.id,
            source_type="admin",
            price=data.average_price
        )
        db.add(pe)
        await db.commit()
        await db.refresh(product)
        
    return product

# ── PUT admin/products/{product_id} ─────────────────────────────────────────
@router.put("/{product_id}", response_model=ProductCatalogOut)
async def update_admin_product(
    product_id: int,
    data: ProductCatalogUpdate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    res = await db.execute(select(ProductCatalog).where(ProductCatalog.id == product_id))
    product = res.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
        
    if data.name is not None:
        product.name = data.name
    if data.unit is not None:
        product.unit = data.unit
        
    await db.commit()
    await db.refresh(product)
    return product

# ── DELETE admin/products/{product_id} ──────────────────────────────────────
@router.delete("/{product_id}")
async def delete_admin_product(
    product_id: int,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    res = await db.execute(select(ProductCatalog).where(ProductCatalog.id == product_id))
    product = res.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
        
    await db.delete(product)
    await db.commit()
    return {"detail": "O'chirildi"}

# ── POST admin/products/{product_id}/price (Manual Admin Price) ──────────────
@router.post("/{product_id}/price")
async def add_admin_price_entry(
    product_id: int,
    data: ProductPriceEntryCreate,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    res = await db.execute(select(ProductCatalog).where(ProductCatalog.id == product_id))
    product = res.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
        
    pe = ProductPriceEntry(
        product_id=product_id,
        source_type="admin",
        price=data.price
    )
    db.add(pe)
    await db.flush()
    
    # Recalculate average
    await _recalculate_avg_price(db, product_id)
    return {"detail": "Narx muvaffaqiyatli qo'shildi"}

# ── POST admin/products/{product_id}/ai-estimate (AI estimation) ───────────
@router.post("/{product_id}/ai-estimate")
async def ai_estimate_product_price(
    product_id: int,
    db: AsyncSession = Depends(get_db),
    admin: User = Depends(require_admin)
):
    res = await db.execute(select(ProductCatalog).where(ProductCatalog.id == product_id))
    product = res.scalar_one_or_none()
    if not product:
        raise HTTPException(status_code=404, detail="Mahsulot topilmadi")
        
    # Standard fallback price dictionary lookup
    from app.api.v1.shopping import _DEFAULT_PRICES
    lower = product.name.lower().strip()
    
    base_price = 0.0
    if lower in _DEFAULT_PRICES:
        base_price = _DEFAULT_PRICES[lower]["price"]
    else:
        for k, info in _DEFAULT_PRICES.items():
            if lower in k or k in lower:
                base_price = info["price"]
                break
                
    if base_price == 0.0:
        # Default backup price if nothing matched
        base_price = 15000.0
        
    # AI Estimation heuristic: standard price + random noise (-15% to +15%)
    noise = random.uniform(-0.15, 0.15)
    estimated_price = round(base_price * (1 + noise), -2)  # round to nearest 100 UZS
    
    pe = ProductPriceEntry(
        product_id=product_id,
        source_type="ai",
        price=estimated_price
    )
    db.add(pe)
    await db.flush()
    
    # Recalculate average
    await _recalculate_avg_price(db, product_id)
    return {
        "detail": "AI narx baholash muvaffaqiyatli yakunlandi",
        "estimated_price": estimated_price
    }
