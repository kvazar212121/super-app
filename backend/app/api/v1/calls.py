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
                # Target is offline, notify the caller
                await manager.send_personal_message({
                    "type": "target_offline",
                    "target_id": target_id
                }, user.id)

    except WebSocketDisconnect:
        manager.disconnect(user.id)
    except Exception as e:
        logger.error(f"WebSocket error for user {user.id}: {e}")
        manager.disconnect(user.id)

