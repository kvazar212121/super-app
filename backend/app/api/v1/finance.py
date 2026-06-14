from datetime import datetime, timezone, date
import calendar
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.finance_record import FinanceRecord
from app.schemas.finance import (
    FinanceRecordOut,
    FinanceRecordCreate,
    FinanceRecordUpdate,
    FinanceStatsOut,
    FinanceCategoryStat,
)

router = APIRouter(prefix="/finance", tags=["finance"])


def get_month_bounds(month_str: str) -> tuple[datetime, datetime]:
    try:
        parts = month_str.split("-")
        year = int(parts[0])
        month = int(parts[1])
        start_date = datetime(year, month, 1, tzinfo=timezone.utc)
        
        last_day = calendar.monthrange(year, month)[1]
        end_date = datetime(year, month, last_day, 23, 59, 59, 999999, tzinfo=timezone.utc)
        return start_date, end_date
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid month format. Use YYYY-MM.")


@router.get("/", response_model=list[FinanceRecordOut])
async def get_finance_records(
    month_str: str | None = Query(None, alias="month"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = select(FinanceRecord).where(FinanceRecord.user_id == current_user.id)
    if month_str:
        start_date, end_date = get_month_bounds(month_str)
        query = query.where(FinanceRecord.date.between(start_date, end_date))
    
    result = await db.execute(query.order_by(FinanceRecord.date.desc()))
    return result.scalars().all()


@router.get("/stats", response_model=FinanceStatsOut)
async def get_finance_stats(
    month_str: str | None = Query(None, alias="month"),
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    if not month_str:
        today = date.today()
        month_str = f"{today.year}-{today.month:02d}"
    
    start_date, end_date = get_month_bounds(month_str)
    
    query = select(FinanceRecord).where(
        FinanceRecord.user_id == current_user.id,
        FinanceRecord.date.between(start_date, end_date)
    )
    result = await db.execute(query)
    records = result.scalars().all()
    
    total_income = 0.0
    total_expense = 0.0
    category_totals = {}
    
    for r in records:
        if r.type == "income":
            total_income += r.amount
        elif r.type == "expense":
            total_expense += r.amount
            category_totals[r.category] = category_totals.get(r.category, 0.0) + r.amount
            
    balance = total_income - total_expense
    
    category_stats = []
    for cat, amt in category_totals.items():
        pct = (amt / total_expense * 100) if total_expense > 0 else 0.0
        category_stats.append(FinanceCategoryStat(category=cat, amount=amt, percentage=pct))
        
    category_stats.sort(key=lambda x: x.amount, reverse=True)
    
    if total_income == 0 and total_expense == 0:
        insight = "Ushbu oyda hali moliyaviy ma'lumotlar kiritilmagan. Tranzaksiyalarni qo'shishni boshlang!"
    elif total_expense > 0:
        max_cat = category_stats[0]
        insight = f"Siz eng ko'p mablag'ni '{max_cat.category}' toifasiga sarfladingiz ({max_cat.percentage:.1f}%). "
        
        if total_expense > total_income:
            insight = "Diqqat! Xarajatlaringiz daromaddan ko'p bo'ldi. Tejashni boshlash tavsiya etiladi. " + insight
        elif total_income > 0 and (total_expense / total_income) > 0.8:
            insight = "Ehtiyot bo'ling, xarajatlaringiz daromadning 80% idan oshib ketdi. " + insight
        else:
            insight = "Moliyaviy holatingiz barqaror. Xarajatlar nazorat ostida! " + insight
    else:
        insight = "Ajoyib! Ushbu oyda faqat daromad qayd etildi. Xarajatlar yo'q."
        
    return FinanceStatsOut(
        total_income=total_income,
        total_expense=total_expense,
        balance=balance,
        category_stats=category_stats,
        insight=insight
    )


@router.post("/", response_model=FinanceRecordOut, status_code=201)
async def create_finance_record(
    data: FinanceRecordCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    new_record = FinanceRecord(**data.model_dump(), user_id=current_user.id)
    db.add(new_record)
    await db.commit()
    await db.refresh(new_record)
    return new_record


@router.patch("/{record_id}", response_model=FinanceRecordOut)
async def update_finance_record(
    record_id: int,
    data: FinanceRecordUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(FinanceRecord).where(
            FinanceRecord.id == record_id,
            FinanceRecord.user_id == current_user.id
        )
    )
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="Tranzaksiya topilmadi")
        
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(record, key, value)
        
    await db.commit()
    await db.refresh(record)
    return record


@router.delete("/{record_id}", status_code=204)
async def delete_finance_record(
    record_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(FinanceRecord).where(
            FinanceRecord.id == record_id,
            FinanceRecord.user_id == current_user.id
        )
    )
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="Tranzaksiya topilmadi")
        
    await db.delete(record)
    await db.commit()


# --- PLANNED PAYMENTS ENDPOINTS ---
from app.models.planned_payment import PlannedPayment
from app.schemas.planned_payment import (
    PlannedPaymentOut,
    PlannedPaymentCreate,
    PlannedPaymentUpdate,
)
from datetime import timedelta

def advance_month(dt):
    from datetime import timedelta
    try:
        if dt.month == 12:
            return dt.replace(year=dt.year + 1, month=1)
        else:
            import calendar
            next_month = dt.month + 1
            year = dt.year
            last_day = calendar.monthrange(year, next_month)[1]
            day = min(dt.day, last_day)
            return dt.replace(month=next_month, day=day)
    except Exception:
        return dt + timedelta(days=30)


@router.get("/planned", response_model=list[PlannedPaymentOut])
async def get_planned_payments(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    query = select(PlannedPayment).where(PlannedPayment.user_id == current_user.id)
    result = await db.execute(query.order_by(PlannedPayment.due_date.asc()))
    return result.scalars().all()


@router.post("/planned", response_model=PlannedPaymentOut, status_code=201)
async def create_planned_payment(
    data: PlannedPaymentCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    new_payment = PlannedPayment(**data.model_dump(), user_id=current_user.id)
    db.add(new_payment)
    await db.commit()
    await db.refresh(new_payment)
    return new_payment


@router.patch("/planned/{payment_id}", response_model=PlannedPaymentOut)
async def update_planned_payment(
    payment_id: int,
    data: PlannedPaymentUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(PlannedPayment).where(
            PlannedPayment.id == payment_id,
            PlannedPayment.user_id == current_user.id
        )
    )
    payment = result.scalar_one_or_none()
    if not payment:
        raise HTTPException(status_code=404, detail="Rejalashtirilgan to'lov topilmadi")

    update_data = data.model_dump(exclude_unset=True)
    
    if update_data.get("is_paid") is True and not payment.is_paid:
        from app.models.finance_record import FinanceRecord
        actual_record = FinanceRecord(
            user_id=current_user.id,
            type="expense",
            amount=payment.amount,
            category=payment.category,
            description=f"{payment.title} (Rejalashtirilgan to'lov)",
            date=payment.due_date
        )
        db.add(actual_record)
        
        if payment.is_recurring:
            payment.due_date = advance_month(payment.due_date)
            payment.is_notified = False
            update_data.pop("is_paid", None)
            payment.is_paid = False
        else:
            payment.is_paid = True
            payment.is_notified = True

    for key, value in update_data.items():
        setattr(payment, key, value)

    await db.commit()
    await db.refresh(payment)
    return payment


@router.delete("/planned/{payment_id}", status_code=204)
async def delete_planned_payment(
    payment_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(
        select(PlannedPayment).where(
            PlannedPayment.id == payment_id,
            PlannedPayment.user_id == current_user.id
        )
    )
    payment = result.scalar_one_or_none()
    if not payment:
        raise HTTPException(status_code=404, detail="Rejalashtirilgan to'lov topilmadi")

    await db.delete(payment)
    await db.commit()
