from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends
from fastapi.responses import JSONResponse
import logging
from app.core.call_manager import manager
from app.core.config import settings
from app.core.security import decode_token
from app.db.session import async_session
from app.api.dependencies import get_current_user
from sqlalchemy import select
from app.models.user import User
from app.models.provider import Provider
from app.models.category import Category

router = APIRouter(prefix="/calls", tags=["calls"])
logger = logging.getLogger(__name__)

async def get_user_from_token(token: str):
    if not token:
        raise Exception("No token provided")
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        raise Exception("Invalid or expired token")
    user_id = int(payload["sub"])
    
    async with async_session() as db:
        result = await db.execute(select(User).where(User.id == user_id))
        user = result.scalar_one_or_none()
        if not user:
            raise Exception("User not found")
        return user


async def check_provider_availability(target_id: int, category_key: str | None = None) -> tuple[bool, str]:
    """Target foydalanuvchining provider sifatida faolligini tekshiradi.

    Qaytaradi: (available: bool, reason: str)

    MUHIM tuzatishlar:
      1. `is_verified` FILTRLANMAYDI — bu tasdiq belgisi (badge), chaqiruv
         ruxsati emas. Default False bo'lgani uchun u BARCHA yangi providerga
         qo'ng'iroqni "topilmadi" deb bloklab qo'ygan edi.
      2. Telefon fallback: eski providerlarda owner_user_id NULL bo'lishi
         mumkin (telefon raqami orqali bog'langan) — _get_user_provider kabi.
      3. KAMIDA BITTA profil ochiq bo'lsa — ruxsat (oldin bitta paused profil
         hammasini bloklardi).
      4. Yozuv topilmasa — FAIL-OPEN (chaqiruvga ruxsat): bog'lanish yozuvi
         noaniq bo'lsa asosiy chaqiruv funksiyasi buzilmasligi kerak; blok
         faqat ANIQ bloklangan/tanaffusdagi provider uchun.
    """
    from sqlalchemy import or_

    async with async_session() as db:
        # Telefon fallback uchun target userning raqamini olamiz
        target_user = await db.get(User, target_id)
        phone = target_user.phone if target_user else None

        cond = (
            or_(Provider.owner_user_id == target_id, Provider.phone == phone)
            if phone
            else (Provider.owner_user_id == target_id)
        )
        query = select(Provider).where(cond)
        if category_key:
            query = query.join(Category, Provider.category_id == Category.id).where(
                Category.key == category_key
            )

        result = await db.execute(query)
        providers = result.scalars().all()

        if not providers:
            # Yozuv topilmadi — bloklamaymiz (fail-open), faqat logga yozamiz.
            logger.warning(
                f"check_provider_availability: provider yozuvi topilmadi "
                f"(target={target_id}, category={category_key}) — chaqiruvga ruxsat"
            )
            return True, "ok"

        # Kamida bitta ochiq profil yetarli; hammasi yopiq bo'lsa — birinchi sabab.
        first_reason: str | None = None
        for provider in providers:
            if provider.is_blocked:
                first_reason = first_reason or "provider_blocked"
                continue
            if not provider.is_active:
                first_reason = first_reason or "provider_inactive"
                continue
            if provider.is_paused:
                first_reason = first_reason or "provider_paused"
                continue
            if provider.metadata_json and provider.metadata_json.get("is_suspended"):
                first_reason = first_reason or "provider_suspended"
                continue
            return True, "ok"

        return False, first_reason or "provider_inactive"


@router.get("/ice-servers")
async def get_ice_servers(current_user: User = Depends(get_current_user)):
    """
    Autentifikatsiya qilingan foydalanuvchilar uchun ICE server
    konfiguratsiyasini qaytaradi (STUN + TURN credentials).
    """
    ice_servers = [
        {"urls": settings.stun_server_url},
    ]
    # TURN server faqat credentials mavjud bo'lganda qo'shiladi
    if settings.turn_server_password:
        ice_servers.append({
            "urls": settings.turn_server_url,
            "username": settings.turn_server_username,
            "credential": settings.turn_server_password,
        })
        # UDP va TCP variantlari
        ice_servers.append({
            "urls": settings.turn_server_url.replace("turn:", "turn:") + "?transport=tcp",
            "username": settings.turn_server_username,
            "credential": settings.turn_server_password,
        })
    return {"iceServers": ice_servers}


@router.websocket("/ws")
async def websocket_call_endpoint(websocket: WebSocket, token: str):
    """
    WebSocket endpoint for WebRTC signaling.
    Client must connect with `ws://.../api/v1/calls/ws?token=...`
    """
    try:
        user = await get_user_from_token(token)
    except Exception as e:
        logger.error(f"WebSocket auth failed: {e}")
        await websocket.close(code=1008)
        return

    await manager.connect(websocket, user.id)
    
    try:
        while True:
            data = await websocket.receive_json()
            # Expected data format: {"type": "offer", "target_id": 123, "data": {...}}
            target_id = data.get("target_id")
            msg_type = data.get("type")
            
            if not target_id:
                logger.warning(f"No target_id provided by user {user.id}")
                continue

            # ── Zakaz qo'ng'irog'ida provider faolligini tekshirish ──
            if msg_type == "call_init":
                inner = data.get("data", {}) or {}
                to_role = inner.get("to_role", "")
                intent = inner.get("intent", "")
                category_key = inner.get("category", "")
                # Faqat zakaz qo'ng'iroqlari (mijoz → provider) uchun tekshiramiz
                if to_role == "provider" and intent == "order":
                    avail, reason = await check_provider_availability(
                        target_id, category_key if category_key else None
                    )
                    if not avail:
                        reason_map = {
                            "provider_not_found": "Soha egasi topilmadi",
                            "provider_blocked": "Soha egasi bloklangan",
                            "provider_inactive": "Soha egasi hozir faol emas",
                            "provider_paused": "Soha egasi tanaffusda",
                            "provider_suspended": "Soha egasi uzoq muddatli tanaffusda",
                        }
                        msg = reason_map.get(reason, "Soha egasi mavjud emas")
                        logger.info(
                            f"call_init BLOCKED: user={user.id} → target={target_id} "
                            f"category={category_key} reason={reason}"
                        )
                        await manager.send_personal_message({
                            "type": "provider_unavailable",
                            "sender_id": target_id,
                            "sender_name": "",
                            "data": {"reason": reason, "message": msg},
                        }, user.id)
                        continue
                # ──────────────────────────────────────────────────────

            # Forward the message to the target user
            # We inject the sender_id so the receiver knows who it's from
            payload = {
                "type": msg_type,
                "sender_id": user.id,
                "sender_name": f"{user.name} {user.surname}",
                "data": data.get("data", {})
            }
            
            success = await manager.send_personal_message(payload, target_id)
            if not success and msg_type in ["call_init", "offer"]:
                # Target ilovasi YOPIQ (WebSocket ulanmagan) — FCM push orqali uyg'otamiz.
                # Flutter background handler 'incoming_call' data'sini olib CallKit chiqaradi (jiringlaydi).
                pushed = 0
                try:
                    import asyncio as _asyncio
                    from app.services.notification_service import NotificationService
                    # Zakaz/kelishuv maydonlarini ham yuboramiz — ilova YOPIQ bo'lsa
                    # ham force-switch va kelishuv oqimi ishlashi uchun (call_init'dagi
                    # data: category / to_role / intent / call_id).
                    inner = data.get("data", {}) or {}
                    pushed = await _asyncio.to_thread(
                        NotificationService.push_data_to_user,
                        target_id,
                        {
                            "type": "incoming_call",
                            "caller_id": str(user.id),
                            "caller_name": f"{user.name} {user.surname}",
                            "category": str(inner.get("category") or ""),
                            "to_role": str(inner.get("to_role") or ""),
                            "intent": str(inner.get("intent") or ""),
                            "call_id": str(inner.get("call_id") or ""),
                        },
                    )
                except Exception as _e:
                    logger.error(f"Call FCM push xatosi: {_e}")

                if pushed:
                    # Qurilmasi bor — push yuborildi (CallKit jiringlaydi). Caller UZMAYDI, KUTADI:
                    # foydalanuvchi javob berganda 'call_accepted' keladi va odatdagi oqim davom etadi.
                    await manager.send_personal_message({
                        "type": "callee_ringing",
                        "target_id": target_id
                    }, user.id)
                else:
                    # Umuman qurilma yo'q — haqiqatan ulanib bo'lmaydi. Caller uzadi.
                    await manager.send_personal_message({
                        "type": "target_offline",
                        "target_id": target_id
                    }, user.id)

    except WebSocketDisconnect:
        manager.disconnect(user.id)
    except Exception as e:
        logger.error(f"WebSocket error for user {user.id}: {e}")
        manager.disconnect(user.id)


from pydantic import BaseModel
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from app.db.session import get_db

class CallAckIn(BaseModel):
    caller_id: int


@router.post("/ack")
async def ack_incoming_call(
    data: CallAckIn,
    current_user: User = Depends(get_current_user),
):
    """Qabul qiluvchi qurilma chaqiruvni HAQIQATAN olganini bildiradi.

    WS ochiq bo'lsa callee 'call_ack' signalini o'zi yuboradi; ilova YOPIQ
    bo'lib FCM/CallKit orqali jiringlayotganda esa shu HTTP endpoint chaqiriladi.
    Backend chaqiruvchiga 'call_ack' yetkazadi — u shunda ringback ("tuut")
    chaladi. Ack kelmasa chaqiruvchi "abonent aloqada emas" deb uzadi.
    """
    delivered = await manager.send_personal_message({
        "type": "call_ack",
        "sender_id": current_user.id,
        "sender_name": f"{current_user.name} {current_user.surname}",
        "data": {},
    }, data.caller_id)
    return {"delivered": bool(delivered)}


class CallHistoryCreate(BaseModel):
    target_id: int
    duration: Optional[str] = "00:00"
    status: str
    is_incoming: bool
    category_key: Optional[str] = None

@router.post("/history")
async def save_call_history(
    data: CallHistoryCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from app.models.call_history import CallHistory
    from app.api.v1.provider_portal import _get_user_provider
    import traceback

    # if is_incoming, it means the current user received the call from target_id
    caller_id = data.target_id if data.is_incoming else current_user.id
    receiver_id = current_user.id if data.is_incoming else data.target_id
    
    provider_id = None
    if data.category_key:
        try:
            # We assume current user is provider, OR target user is provider.
            # But the history is shared, so we just try to resolve provider_id
            # Actually, _get_user_provider takes a user and category_key
            # If current_user is the provider:
            p = await _get_user_provider(db, current_user, data.category_key)
            provider_id = p.id
        except Exception as e:
            logger.error(f"Could not resolve provider: {e}")

    # If we couldn't resolve provider from current_user, try target_id? 
    # Usually the call is initiated from User -> Provider or Provider -> User
    # In either case, having `provider_id` makes it show up in provider's dashboard.
    if not provider_id and data.category_key:
        try:
            target_user = await db.get(User, data.target_id)
            if target_user:
                p = await _get_user_provider(db, target_user, data.category_key)
                provider_id = p.id
        except Exception:
            pass
            
    record = CallHistory(
        caller_id=caller_id,
        receiver_id=receiver_id,
        provider_id=provider_id,
        duration=data.duration,
        status=data.status
    )
    db.add(record)
    await db.commit()
    return {"detail": "Saqlandi", "id": record.id}


# ==========================================================================
#  KELISHUV (CallDeal) — zakaz qo'ng'irog'idan keyin ikki tomonlama tasdiq
# ==========================================================================
#
#  Oqim:
#   1. Mijoz provider'ga ZAKAZ qo'ng'irog'i qiladi (to_role=provider, intent=order).
#      Qo'ng'iroq boshlanishida mijoz UUID `call_id` yaratadi — u ikkala
#      qurilmaga ham yetadi (call_init signali orqali).
#   2. Qo'ng'iroq tugagach har ikki tomon "Kelishdingizmi?" savoliga javob beradi.
#      Har tomon shu yerga (POST /calls/deal/respond) o'z javobini yuboradi.
#   3. Backend ikki javobni AYNAN BIR `call_id` ostida yig'adi va holatni
#      hisoblaydi (_evaluate_deal). Nizo bo'lsa (bir "ha", bir "yo'q") maxsus
#      holat qaytariladi va Flutter qo'shimcha savol/xabar ko'rsatadi.
#
#  ANTI-BYPASS: provider "kelishdik" desa, mijoz jimgina "yo'q" deb qo'ya
#  olmaydi — status `client_recheck` bo'ladi va mijozdan qayta so'raladi.

from app.models.call_deal import CallDeal, CallDealStatus


class DealRespondIn(BaseModel):
    call_id: str
    other_user_id: int           # suhbatdoshning USER id'si
    category_key: Optional[str] = None
    i_am_provider: bool = False  # men shu qo'ng'iroqda provider (soha egasi)manmi
    response: str                # 'agreed' | 'declined'
    # Nizo (client_recheck) holatida mijozning QAYTA javobi bo'lsa — True.
    reconfirm: bool = False


def _evaluate_deal(deal: CallDeal) -> None:
    """Ikki javobdan `deal.status`ni hisoblaydi.

    Nizolar ATAYIN asimmetrik hal qilinadi (foydalanuvchi mantiqiga ko'ra):
      • provider="ha", mijoz="yo'q" → `client_recheck` (mijozdan qayta so'raladi,
        chunki provider kelishuvni tasdiqlagan — bu bypassga qarshi himoya).
      • provider="yo'q", mijoz="ha" → `declined` (ishni provider bajaradi;
        uning "yo'q"i hal qiladi, mijozga xabar beriladi).
    """
    p, c = deal.provider_response, deal.client_response

    if p is None and c is None:
        deal.status = CallDealStatus.await_provider.value
    elif p is None:
        deal.status = CallDealStatus.await_provider.value
    elif c is None:
        deal.status = CallDealStatus.await_client.value
    elif p == "agreed" and c == "agreed":
        deal.status = CallDealStatus.agreed.value
    elif p == "declined" and c == "declined":
        deal.status = CallDealStatus.declined.value
    elif p == "declined" and c == "agreed":
        # Provider rad etdi — ish bo'lmaydi. Mijozga "qayta urinib ko'ring" deyiladi.
        deal.status = CallDealStatus.declined.value
    elif p == "agreed" and c == "declined":
        # Provider tasdiqladi, mijoz inkor qildi — mijozdan qayta so'raymiz.
        deal.status = CallDealStatus.client_recheck.value


# Bir tomon javob bergach, ikkinchi tomonni kutish muddati (soniya).
# O'tib ketsa — kelishuv IKKI TOMON uchun ham AVTOMATIK rad etiladi.
DEAL_AUTO_DECLINE_SECONDS = 30


def _maybe_auto_decline(deal: CallDeal) -> bool:
    """30 soniya qoidasi: faqat BITTA tomon javob bergan (await_* holat) va
    oxirgi o'zgarishdan beri 30s o'tgan bo'lsa — jim turgan tomonga 'timeout'
    yozib, kelishuvni to'g'ridan-to'g'ri 'declined' qilamiz.

    DIQQAT: _evaluate_deal chaqirilmaydi — aks holda (provider=ha, client=timeout)
    kombinatsiyasi client_recheck'ka olib borardi; avto-rad esa YAKUNIY.
    Qaytaradi: True = holat o'zgardi (commit kerak).
    """
    from datetime import datetime, timezone

    if deal.status not in (
        CallDealStatus.await_provider.value,
        CallDealStatus.await_client.value,
    ):
        return False
    has_p = deal.provider_response is not None
    has_c = deal.client_response is not None
    if has_p == has_c:  # hali hech kim javob bermagan — taymer boshlanmagan
        return False
    updated = deal.updated_at
    if updated is None:
        return False
    if updated.tzinfo is None:
        updated = updated.replace(tzinfo=timezone.utc)
    if (datetime.now(timezone.utc) - updated).total_seconds() < DEAL_AUTO_DECLINE_SECONDS:
        return False
    if not has_p:
        deal.provider_response = "timeout"
    else:
        deal.client_response = "timeout"
    deal.status = CallDealStatus.declined.value
    return True


def _next_action(deal: CallDeal, is_provider: bool) -> str:
    """So'rovchi (provider yoki mijoz) uchun Flutter ko'rsatishi kerak bo'lgan
    keyingi harakatni qaytaradi. Butun UI mantig'i shu qiymatga bog'lanadi."""
    s = deal.status
    if s == CallDealStatus.agreed.value:
        return "agreed"                       # → bron bosqichiga (2.3)
    if s == CallDealStatus.await_provider.value:
        return "need_response" if is_provider else "await_other"
    if s == CallDealStatus.await_client.value:
        return "await_other" if is_provider else "need_response"
    if s == CallDealStatus.client_recheck.value:
        # Faqat mijozga qayta-savol; provider kutadi.
        return "await_other" if is_provider else "client_recheck"
    if s == CallDealStatus.declined.value:
        # Provider "yo'q" degan, mijoz esa "ha" degan holatda — mijozga
        # tushuntirish xabari (qayta qo'ng'iroq/boshqa usta) ko'rsatiladi.
        if (
            deal.provider_response == "declined"
            and deal.client_response == "agreed"
            and not is_provider
        ):
            return "inform_client_declined"
        return "declined"
    return "await_other"


@router.post("/deal/respond")
async def respond_call_deal(
    data: DealRespondIn,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Qo'ng'iroqdan keyingi "Kelishdingizmi?" javobini yozadi.

    `call_id` bo'yicha yozuvni topadi yoki YARATADI (birinchi javob bergan
    tomon yaratadi — lazy). So'ng holatni hisoblab, shu tomon uchun
    `next_action`ni qaytaradi.
    """
    if data.response not in ("agreed", "declined"):
        return JSONResponse({"detail": "response 'agreed' yoki 'declined' bo'lishi kerak"}, status_code=400)

    # call_id bo'yicha mavjud yozuvni qidiramiz
    result = await db.execute(select(CallDeal).where(CallDeal.call_id == data.call_id))
    deal = result.scalar_one_or_none()

    # 30s qoidasi: muddat o'tgan bo'lsa avval avto-rad qilamiz — KECHIKKAN
    # bosish kelishuvni "tiriltira" olmaydi (rad yakuniy holat).
    if deal is not None and _maybe_auto_decline(deal):
        await db.commit()
        await db.refresh(deal)
    if deal is not None and deal.status == CallDealStatus.declined.value:
        is_provider = current_user.id == deal.provider_user_id
        return {"deal": deal.to_dict(), "next_action": _next_action(deal, is_provider)}

    if deal is None:
        # Birinchi javob — yangi kelishuv yozuvini yaratamiz.
        # Kim provider, kim mijoz — `i_am_provider` bo'yicha aniqlanadi.
        if data.i_am_provider:
            deal = CallDeal(
                call_id=data.call_id,
                provider_user_id=current_user.id,
                client_id=data.other_user_id,
                category_key=data.category_key,
            )
        else:
            deal = CallDeal(
                call_id=data.call_id,
                client_id=current_user.id,
                provider_user_id=data.other_user_id,
                category_key=data.category_key,
            )
        db.add(deal)

    # So'rovchi ushbu yozuvda haqiqatan qaysi tomon ekanini id bo'yicha aniqlaymiz
    # (yolg'on `i_am_provider` yuborilsa ham, yaratilgandan keyin id hal qiladi).
    is_provider = current_user.id == deal.provider_user_id

    if is_provider:
        deal.provider_response = data.response
    else:
        # reconfirm — client_recheck holatida mijozning YAKUNIY javobi (override).
        deal.client_response = data.response

    _evaluate_deal(deal)

    # Agar kelishuv endi TO'LIQ tasdiqlangan bo'lsa va provider oldin PENDING
    # bron yaratgan bo'lsa (mijoz endi tasdiqladi) — bronni CONFIRMED qilamiz.
    if deal.status == CallDealStatus.agreed.value and deal.order_id is not None:
        from app.models.order import Order, OrderStatus
        order = await db.get(Order, deal.order_id)
        if order is not None and order.status == OrderStatus.pending:
            order.status = OrderStatus.confirmed
            await _notify_safe(
                deal.provider_user_id, "order",
                "Bron tasdiqlandi",
                "Mijoz bronni tasdiqladi.",
            )

    await db.commit()
    await db.refresh(deal)

    return {"deal": deal.to_dict(), "next_action": _next_action(deal, is_provider)}


@router.get("/deal/{call_id}")
async def get_call_deal(
    call_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Kelishuv holatini so'rash (polling) — bir tomon javob berib, ikkinchisini
    kutayotganda Flutter shu endpointni davriy so'rab, holat o'zgarishini kuzatadi."""
    result = await db.execute(select(CallDeal).where(CallDeal.call_id == call_id))
    deal = result.scalar_one_or_none()
    if deal is None:
        return JSONResponse({"detail": "Kelishuv topilmadi"}, status_code=404)

    # 30s qoidasi: polling paytida ham tekshiriladi — ikkinchi tomon jim
    # tursa, kutayotgan tomon keyingi so'rovda 'declined' holatini ko'radi.
    if _maybe_auto_decline(deal):
        await db.commit()
        await db.refresh(deal)

    # Bron yaratilgan bo'lsa — sanasi/holati ham qaytariladi. MIJOZ tomoni shu
    # orqali "qachonga bron bo'ldi"ni ko'radi (provider vaqtni belgilagach).
    booking = None
    if deal.order_id is not None:
        from app.models.order import Order
        order = await db.get(Order, deal.order_id)
        if order is not None:
            booking = {
                "order_id": order.id,
                "date": order.date.isoformat() if order.date else None,
                "status": order.status.value if hasattr(order.status, "value") else str(order.status),
                "service_name": order.service_name,
                "price": order.price,
            }

    is_provider = current_user.id == deal.provider_user_id
    return {
        "deal": deal.to_dict(),
        "next_action": _next_action(deal, is_provider),
        "booking": booking,
    }


# ==========================================================================
#  BRON (Order) — kelishuv bo'lgach provider sana/vaqtni belgilaydi
# ==========================================================================
#
#  MUHIM (to'lov modeli): bu bron per-order KOMISSIYA olmaydi — pul o'zaro,
#  off-platform o'tkaziladi. Komissiya faqat provider o'z balansini
#  to'ldirganda olinadi. Shuning uchun `OrderService.create` (lead fee bilan)
#  emas, to'g'ridan-to'g'ri `Order` yaratamiz.
#
#  Holat:
#   - Ikkala tomon "kelishdik" bo'lsa   → Order.status = confirmed.
#   - Provider "ha", mijoz hali javob bermagan bo'lsa → status = pending
#     ("kutilayotgan bron") + mijozga bildirishnoma. Mijoz keyin tasdiqlaydi
#     (kelishuv oqimida "kelishdik") yoki provider istagan paytda bekor qiladi.

from datetime import datetime as _dt


class DealBookingIn(BaseModel):
    date: _dt                       # kelishilgan sana/vaqt (ISO)
    service_name: Optional[str] = None
    address: Optional[str] = None
    price: Optional[float] = 0.0
    notes: Optional[str] = None


async def _notify_safe(user_id: int, ntype: str, title: str, message: str):
    """Bildirishnomani xavfsiz (xato bo'lsa ham oqim buzilmaydigan) yuborish."""
    try:
        import asyncio as _asyncio
        from app.services.notification_service import NotificationService
        await _asyncio.to_thread(
            NotificationService.send_notification, user_id, ntype, title, message
        )
    except Exception as _e:
        logger.error(f"Bron bildirishnomasi xatosi: {_e}")


@router.post("/deal/{call_id}/booking")
async def create_deal_booking(
    call_id: str,
    data: DealBookingIn,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Provider kelishilgan vaqtni kiritadi → BRON (Order) yaratiladi.

    Faqat ushbu kelishuvning PROVIDER tomoni chaqira oladi.
    """
    from app.models.order import Order, OrderStatus
    from app.models.category import Category
    from app.api.v1.provider_portal import _get_user_provider

    result = await db.execute(select(CallDeal).where(CallDeal.call_id == call_id))
    deal = result.scalar_one_or_none()
    if deal is None:
        return JSONResponse({"detail": "Kelishuv topilmadi"}, status_code=404)
    if current_user.id != deal.provider_user_id:
        return JSONResponse({"detail": "Faqat provider bron qila oladi"}, status_code=403)
    if deal.order_id is not None:
        return JSONResponse({"detail": "Bu kelishuv uchun bron allaqachon yaratilgan"}, status_code=400)

    # Provider yozuvi va kategoriya (category_id) ni aniqlaymiz.
    try:
        provider = await _get_user_provider(db, current_user, deal.category_key)
    except Exception:
        return JSONResponse({"detail": "Provider profili topilmadi"}, status_code=404)

    category_id = provider.category.id if provider.category else None
    if category_id is None and deal.category_key:
        cat = await db.scalar(select(Category).where(Category.key == deal.category_key))
        category_id = cat.id if cat else None
    if category_id is None:
        return JSONResponse({"detail": "Kategoriya aniqlanmadi"}, status_code=400)

    # Mijoz tasdiqlaganmi (ikkalasi kelishdik) → confirmed, aks holda pending.
    both_agreed = deal.client_response == "agreed" and deal.provider_response == "agreed"
    status = OrderStatus.confirmed if both_agreed else OrderStatus.pending

    order = Order(
        user_id=deal.client_id,
        category_id=category_id,
        provider_id=provider.id,
        service_name=(data.service_name or (provider.category.title_uz if provider.category else "Kelishilgan xizmat")),
        address=(data.address or "Kelishuv bo'yicha"),
        notes=data.notes,
        date=data.date,
        price=float(data.price or 0.0),
        status=status,
    )
    db.add(order)
    await db.flush()

    deal.order_id = order.id
    await db.commit()
    await db.refresh(order)

    # Mijozga bildirishnoma
    if both_agreed:
        await _notify_safe(
            deal.client_id, "order",
            "Bron tasdiqlandi",
            f"{provider.name} siz uchun {data.date.strftime('%Y-%m-%d %H:%M')} ga bron qildi.",
        )
    else:
        await _notify_safe(
            deal.client_id, "order",
            "Bronni tasdiqlang",
            f"{provider.name} {data.date.strftime('%Y-%m-%d %H:%M')} ga vaqt belgiladi. Iltimos, tasdiqlang.",
        )

    return {"order": order.to_dict(), "status": order.status.value, "both_agreed": both_agreed}


@router.post("/deal/{call_id}/cancel-booking")
async def cancel_deal_booking(
    call_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Provider kutilayotgan (yoki tasdiqlangan) bronni bekor qiladi — istalgan
    paytda, 24 soatni kutmasdan. Faqat provider tomoni."""
    from app.models.order import Order, OrderStatus

    result = await db.execute(select(CallDeal).where(CallDeal.call_id == call_id))
    deal = result.scalar_one_or_none()
    if deal is None or deal.order_id is None:
        return JSONResponse({"detail": "Bron topilmadi"}, status_code=404)
    if current_user.id != deal.provider_user_id:
        return JSONResponse({"detail": "Faqat provider bekor qila oladi"}, status_code=403)

    order = await db.get(Order, deal.order_id)
    if order is None:
        return JSONResponse({"detail": "Bron topilmadi"}, status_code=404)

    order.status = OrderStatus.cancelled
    await db.commit()

    await _notify_safe(
        deal.client_id, "order",
        "Bron bekor qilindi",
        "Soha egasi bronni bekor qildi.",
    )
    return {"detail": "Bron bekor qilindi", "order_id": order.id}

