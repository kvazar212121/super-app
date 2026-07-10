"""Payme (Paycom) va Click to'lov webhook'lari.

To'lov provayderi to'lovni tasdiqlaganda premium AVTOMATIK ochiladi — admin
aralashuvi shart emas. Merchant kalitlari (payme_key / click_secret_key) faqat
shu yerda, imzoni tekshirish uchun ishlatiladi.

Merchant ID'lar sozlanmagan bo'lsa, webhook'lar 404 qaytaradi (hali ulanmagan).
Sozlamalar kelgach, bu endpoint'lar hech qanday kod o'zgarishisiz ishlay boshlaydi.

Payme cabinet'da Endpoint URL sifatida:  https://<domain>/api/v1/payments/payme
Click cabinet'da Prepare/Complete URL:   https://<domain>/api/v1/payments/click
"""
from __future__ import annotations

import base64
import hashlib
import logging
from datetime import datetime, timezone

from fastapi import APIRouter, Request, Depends
from fastapi.responses import JSONResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.user import User
from app.models.premium import PremiumPayment
from app.models.transaction import Transaction
from app.services import settings_service, premium_service

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/payments", tags=["payments"])


# ─────────────────────────── umumiy premium ochish ───────────────────────────

async def _confirm_payment(db: AsyncSession, payment: PremiumPayment, method: str) -> None:
    """To'lov tasdiqlandi — premium'ni ochamiz (idempotent)."""
    if payment.status == "confirmed":
        return
    user = (await db.execute(select(User).where(User.id == payment.user_id))).scalar_one_or_none()
    if user is None:
        return
    premium_service.activate_premium(user, payment, payment.duration_days, method=method)
    db.add(Transaction(
        user_id=user.id, type="premium_subscription", amount=payment.amount,
        description=f"Premium obuna ({method})", status="completed",
    ))
    await db.commit()
    logger.info("Premium ochildi: user=%s method=%s payment=%s", user.id, method, payment.id)


# ══════════════════════════════════ PAYME ════════════════════════════════════
# Payme Merchant API — JSON-RPC 2.0. Har so'rov Authorization: Basic base64("Paycom:KEY").

# Payme xato kodlari
_PAYME_ERR = {
    "auth": {"code": -32504, "message": "Insufficient privileges"},
    "method": {"code": -32601, "message": "Method not found"},
    "order": {"code": -31050, "message": {"ru": "Заказ не найден", "uz": "Buyurtma topilmadi", "en": "Order not found"}},
    "amount": {"code": -31001, "message": {"ru": "Неверная сумма", "uz": "Summa noto'g'ri", "en": "Wrong amount"}},
    "state": {"code": -31008, "message": "Invalid transaction state"},
}


def _payme_error(req_id, err) -> JSONResponse:
    return JSONResponse({"jsonrpc": "2.0", "id": req_id, "error": err})


def _payme_ok(req_id, result) -> JSONResponse:
    return JSONResponse({"jsonrpc": "2.0", "id": req_id, "result": result})


def _check_payme_auth(request: Request, key: str) -> bool:
    header = request.headers.get("Authorization", "")
    if not header.startswith("Basic "):
        return False
    try:
        decoded = base64.b64decode(header[6:]).decode("utf-8")
    except Exception:
        return False
    # "Paycom:KEY"
    _, _, got_key = decoded.partition(":")
    return bool(key) and got_key == key


async def _payme_load_payment(db: AsyncSession, params: dict) -> PremiumPayment | None:
    field = settings_service.payment_config()["payme_account_field"]
    account = params.get("account") or {}
    raw = account.get(field)
    if raw is None:
        return None
    try:
        pid = int(raw)
    except (TypeError, ValueError):
        return None
    return (await db.execute(select(PremiumPayment).where(PremiumPayment.id == pid))).scalar_one_or_none()


@router.post("/payme")
async def payme_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    pay = settings_service.payment_config()
    if not pay["payme_merchant_id"] or not pay["payme_key"]:
        return JSONResponse({"error": "not_configured"}, status_code=404)

    body = await request.json()
    req_id = body.get("id")
    method = body.get("method")
    params = body.get("params") or {}

    if not _check_payme_auth(request, pay["payme_key"]):
        return _payme_error(req_id, _PAYME_ERR["auth"])

    now_ms = int(datetime.now(timezone.utc).timestamp() * 1000)

    if method == "CheckPerformTransaction":
        payment = await _payme_load_payment(db, params)
        if payment is None:
            return _payme_error(req_id, _PAYME_ERR["order"])
        if int(round(payment.amount * 100)) != int(params.get("amount", -1)):
            return _payme_error(req_id, _PAYME_ERR["amount"])
        return _payme_ok(req_id, {"allow": True})

    if method == "CreateTransaction":
        payment = await _payme_load_payment(db, params)
        if payment is None:
            return _payme_error(req_id, _PAYME_ERR["order"])
        if int(round(payment.amount * 100)) != int(params.get("amount", -1)):
            return _payme_error(req_id, _PAYME_ERR["amount"])
        txn = params.get("id")
        # Idempotent: shu txn allaqachon bog'langan bo'lsa qaytaramiz
        if payment.note and payment.note.startswith(f"payme:{txn}"):
            state = 2 if payment.status == "confirmed" else 1
            return _payme_ok(req_id, {"create_time": now_ms, "transaction": str(payment.id), "state": state})
        if payment.status == "confirmed":
            return _payme_error(req_id, _PAYME_ERR["state"])
        payment.note = f"payme:{txn}:{now_ms}"
        await db.commit()
        return _payme_ok(req_id, {"create_time": now_ms, "transaction": str(payment.id), "state": 1})

    if method == "PerformTransaction":
        txn = params.get("id")
        payment = (await db.execute(
            select(PremiumPayment).where(PremiumPayment.note.like(f"payme:{txn}:%"))
        )).scalar_one_or_none()
        if payment is None:
            return _payme_error(req_id, _PAYME_ERR["order"])
        await _confirm_payment(db, payment, "payme")
        perform_ms = int(payment.confirmed_at.timestamp() * 1000) if payment.confirmed_at else now_ms
        return _payme_ok(req_id, {"transaction": str(payment.id), "perform_time": perform_ms, "state": 2})

    if method == "CancelTransaction":
        txn = params.get("id")
        payment = (await db.execute(
            select(PremiumPayment).where(PremiumPayment.note.like(f"payme:{txn}:%"))
        )).scalar_one_or_none()
        if payment is None:
            return _payme_error(req_id, _PAYME_ERR["order"])
        payment.status = "rejected"
        await db.commit()
        return _payme_ok(req_id, {"transaction": str(payment.id), "cancel_time": now_ms, "state": -1})

    if method == "CheckTransaction":
        txn = params.get("id")
        payment = (await db.execute(
            select(PremiumPayment).where(PremiumPayment.note.like(f"payme:{txn}:%"))
        )).scalar_one_or_none()
        if payment is None:
            return _payme_error(req_id, _PAYME_ERR["order"])
        state = 2 if payment.status == "confirmed" else (-1 if payment.status == "rejected" else 1)
        perform_ms = int(payment.confirmed_at.timestamp() * 1000) if payment.confirmed_at else 0
        return _payme_ok(req_id, {
            "create_time": now_ms, "perform_time": perform_ms, "cancel_time": 0,
            "transaction": str(payment.id), "state": state, "reason": None,
        })

    if method == "GetStatement":
        return _payme_ok(req_id, {"transactions": []})

    return _payme_error(req_id, _PAYME_ERR["method"])


# ══════════════════════════════════ CLICK ════════════════════════════════════
# Click Merchant API — Prepare (action=0) va Complete (action=1). Imzo: md5.

def _click_sign(params: dict, secret: str, *, complete: bool) -> str:
    """Click imzosini hisoblaydi (md5)."""
    parts = [
        str(params.get("click_trans_id", "")),
        str(params.get("service_id", "")),
        secret,
        str(params.get("merchant_trans_id", "")),
    ]
    if complete:
        parts.append(str(params.get("merchant_prepare_id", "")))
    parts.append(str(params.get("amount", "")))
    parts.append(str(params.get("action", "")))
    parts.append(str(params.get("sign_time", "")))
    return hashlib.md5("".join(parts).encode("utf-8")).hexdigest()


@router.post("/click")
async def click_webhook(request: Request, db: AsyncSession = Depends(get_db)):
    pay = settings_service.payment_config()
    if not (pay["click_service_id"] and pay["click_secret_key"]):
        return JSONResponse({"error": "-8", "error_note": "not_configured"}, status_code=404)

    form = await request.form()
    params = {k: v for k, v in form.items()}

    action = str(params.get("action", ""))
    merchant_trans_id = params.get("merchant_trans_id")

    # Imzo tekshiruvi
    expected = _click_sign(params, pay["click_secret_key"], complete=(action == "1"))
    if params.get("sign_string") != expected:
        return JSONResponse({"error": -1, "error_note": "SIGN CHECK FAILED"})

    try:
        pid = int(merchant_trans_id)
    except (TypeError, ValueError):
        return JSONResponse({"error": -5, "error_note": "Order not found"})

    payment = (await db.execute(select(PremiumPayment).where(PremiumPayment.id == pid))).scalar_one_or_none()
    if payment is None:
        return JSONResponse({"error": -5, "error_note": "Order not found"})

    # Summa tekshiruvi
    try:
        if abs(float(params.get("amount", 0)) - float(payment.amount)) > 0.01:
            return JSONResponse({"error": -2, "error_note": "Incorrect amount"})
    except (TypeError, ValueError):
        return JSONResponse({"error": -2, "error_note": "Incorrect amount"})

    if action == "0":  # Prepare
        if payment.status == "rejected":
            return JSONResponse({"error": -9, "error_note": "Transaction cancelled"})
        return JSONResponse({
            "click_trans_id": params.get("click_trans_id"),
            "merchant_trans_id": merchant_trans_id,
            "merchant_prepare_id": pid,
            "error": 0, "error_note": "Success",
        })

    if action == "1":  # Complete
        if str(params.get("error", "0")) not in ("0", ""):
            payment.status = "rejected"
            await db.commit()
            return JSONResponse({"error": -9, "error_note": "Transaction cancelled"})
        await _confirm_payment(db, payment, "click")
        return JSONResponse({
            "click_trans_id": params.get("click_trans_id"),
            "merchant_trans_id": merchant_trans_id,
            "merchant_confirm_id": pid,
            "error": 0, "error_note": "Success",
        })

    return JSONResponse({"error": -3, "error_note": "Action not found"})
