from datetime import datetime, timezone, date
import calendar
import secrets
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.finance_record import FinanceRecord
from app.models.finance_group import FinanceGroup
from app.schemas.finance import (
    FinanceRecordOut,
    FinanceRecordCreate,
    FinanceRecordUpdate,
    FinanceStatsOut,
    FinanceCategoryStat,
    FinanceMemberStat,
    FinanceGroupOut,
    FinanceGroupMember,
    JoinGroupIn,
)

router = APIRouter(prefix="/finance", tags=["finance"])


# ─────────────── Oilaviy guruh yordamchilari ───────────────

async def _member_ids(db: AsyncSession, user: User) -> list[int]:
    """Foydalanuvchi shaxsiy bo'lsa [uning id]; oilaviy guruhda bo'lsa barcha a'zolar."""
    if not user.finance_group_id:
        return [user.id]
    rows = (
        await db.execute(
            select(User.id).where(User.finance_group_id == user.finance_group_id)
        )
    ).scalars().all()
    return list(rows) or [user.id]


async def _member_names(db: AsyncSession, ids: list[int]) -> dict[int, str]:
    if not ids:
        return {}
    rows = (await db.execute(select(User).where(User.id.in_(ids)))).scalars().all()
    return {u.id: (u.name or f"#{u.id}") for u in rows}


def _record_out(r: FinanceRecord, names: dict[int, str]) -> dict:
    return {
        "id": r.id,
        "user_id": r.user_id,
        "user_name": names.get(r.user_id),
        "type": r.type,
        "amount": r.amount,
        "category": r.category,
        "description": r.description,
        "date": r.date,
        "created_at": r.created_at,
    }


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
    ids = await _member_ids(db, current_user)
    query = select(FinanceRecord).where(FinanceRecord.user_id.in_(ids))
    if month_str:
        start_date, end_date = get_month_bounds(month_str)
        query = query.where(FinanceRecord.date.between(start_date, end_date))

    result = await db.execute(query.order_by(FinanceRecord.date.desc()))
    records = result.scalars().all()
    names = await _member_names(db, ids)
    return [_record_out(r, names) for r in records]


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

    ids = await _member_ids(db, current_user)
    query = select(FinanceRecord).where(
        FinanceRecord.user_id.in_(ids),
        FinanceRecord.date.between(start_date, end_date)
    )
    result = await db.execute(query)
    records = result.scalars().all()

    total_income = 0.0
    total_expense = 0.0
    category_totals = {}
    # Oilaviy hisob: har a'zoning kirim/chiqimi
    member_totals: dict[int, dict] = {}

    for r in records:
        m = member_totals.setdefault(r.user_id, {"income": 0.0, "expense": 0.0})
        if r.type == "income":
            total_income += r.amount
            m["income"] += r.amount
        elif r.type == "expense":
            total_expense += r.amount
            m["expense"] += r.amount
            category_totals[r.category] = category_totals.get(r.category, 0.0) + r.amount

    balance = total_income - total_expense

    # A'zolar statistikasi faqat guruh (2+ a'zo) bo'lsa
    member_stats = []
    if len(ids) > 1:
        names = await _member_names(db, ids)
        for uid in ids:
            mt = member_totals.get(uid, {"income": 0.0, "expense": 0.0})
            member_stats.append(FinanceMemberStat(
                user_id=uid, name=names.get(uid, f"#{uid}"),
                income=mt["income"], expense=mt["expense"],
            ))
        member_stats.sort(key=lambda x: x.expense, reverse=True)
    
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
        insight=insight,
        member_stats=member_stats,
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
    return _record_out(new_record, {current_user.id: current_user.name or f"#{current_user.id}"})


@router.patch("/{record_id}", response_model=FinanceRecordOut)
async def update_finance_record(
    record_id: int,
    data: FinanceRecordUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    # Oilaviy hisobda har a'zo har qanday yozuvni tahrirlashi mumkin
    ids = await _member_ids(db, current_user)
    result = await db.execute(
        select(FinanceRecord).where(
            FinanceRecord.id == record_id,
            FinanceRecord.user_id.in_(ids),
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
    names = await _member_names(db, ids)
    return _record_out(record, names)


@router.delete("/{record_id}", status_code=204)
async def delete_finance_record(
    record_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    ids = await _member_ids(db, current_user)
    result = await db.execute(
        select(FinanceRecord).where(
            FinanceRecord.id == record_id,
            FinanceRecord.user_id.in_(ids),
        )
    )
    record = result.scalar_one_or_none()
    if not record:
        raise HTTPException(status_code=404, detail="Tranzaksiya topilmadi")

    await db.delete(record)
    await db.commit()


# ─────────────── Oilaviy moliya guruhi (QR ulash) ───────────────

async def _group_out(db: AsyncSession, group: FinanceGroup, me_id: int) -> FinanceGroupOut:
    members = (
        await db.execute(select(User).where(User.finance_group_id == group.id))
    ).scalars().all()
    return FinanceGroupOut(
        id=group.id,
        name=group.name,
        invite_code=group.invite_code,
        is_owner=(group.owner_id == me_id),
        members=[
            FinanceGroupMember(
                user_id=u.id, name=u.name or f"#{u.id}", is_owner=(u.id == group.owner_id)
            )
            for u in members
        ],
    )


@router.get("/group")
async def get_finance_group(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Joriy oila guruhi (yo'q bo'lsa null)."""
    if not current_user.finance_group_id:
        return {"group": None}
    group = (
        await db.execute(select(FinanceGroup).where(FinanceGroup.id == current_user.finance_group_id))
    ).scalar_one_or_none()
    if group is None:
        return {"group": None}
    return {"group": (await _group_out(db, group, current_user.id)).model_dump()}


@router.post("/group/invite")
async def create_finance_invite(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Taklif kodi/QR yaratish — guruh bo'lmasa yangi guruh ochadi."""
    if current_user.finance_group_id:
        group = (
            await db.execute(select(FinanceGroup).where(FinanceGroup.id == current_user.finance_group_id))
        ).scalar_one_or_none()
        if group is not None:
            return {"group": (await _group_out(db, group, current_user.id)).model_dump()}

    # Yangi guruh: noyob kod
    code = secrets.token_urlsafe(6)
    while (await db.execute(select(FinanceGroup).where(FinanceGroup.invite_code == code))).scalar_one_or_none():
        code = secrets.token_urlsafe(6)
    group = FinanceGroup(owner_id=current_user.id, invite_code=code, name="Oilaviy byudjet")
    db.add(group)
    await db.flush()
    current_user.finance_group_id = group.id
    await db.commit()
    await db.refresh(group)
    return {"group": (await _group_out(db, group, current_user.id)).model_dump()}


@router.post("/group/join")
async def join_finance_group(
    data: JoinGroupIn,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """QR/kod orqali oila guruhiga qo'shilish."""
    code = (data.code or "").strip()
    group = (
        await db.execute(select(FinanceGroup).where(FinanceGroup.invite_code == code))
    ).scalar_one_or_none()
    if group is None:
        raise HTTPException(status_code=404, detail="Kod noto'g'ri yoki eskirgan")
    if current_user.finance_group_id == group.id:
        return {"group": (await _group_out(db, group, current_user.id)).model_dump()}
    if current_user.finance_group_id and current_user.finance_group_id != group.id:
        raise HTTPException(status_code=400, detail="Avval joriy guruhdan chiqing")

    # Bir martaga o'zi yaratgan bo'sh (yakka) guruhi bo'lsa — uni o'chiramiz
    old_owned = (
        await db.execute(select(FinanceGroup).where(FinanceGroup.owner_id == current_user.id))
    ).scalars().all()

    current_user.finance_group_id = group.id
    await db.flush()
    for g in old_owned:
        if g.id != group.id:
            members = (await db.execute(select(User).where(User.finance_group_id == g.id))).scalars().all()
            if not members:
                await db.delete(g)
    await db.commit()
    return {"group": (await _group_out(db, group, current_user.id)).model_dump()}


@router.post("/group/leave")
async def leave_finance_group(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Oila guruhidan chiqish — yozuvlar shaxsiy hisobga qaytadi."""
    gid = current_user.finance_group_id
    current_user.finance_group_id = None
    await db.flush()
    if gid:
        group = (await db.execute(select(FinanceGroup).where(FinanceGroup.id == gid))).scalar_one_or_none()
        if group is not None:
            remaining = (await db.execute(select(User).where(User.finance_group_id == gid))).scalars().all()
            if not remaining:
                await db.delete(group)
    await db.commit()
    return {"status": "left"}


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
