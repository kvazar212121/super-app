from typing import Dict, Any
from fastapi import WebSocket
import logging

logger = logging.getLogger(__name__)

class CallManager:
    def __init__(self):
        # Maps user_id to their active WebSocket connection
        self.active_connections: Dict[int, WebSocket] = {}

    async def connect(self, websocket: WebSocket, user_id: int):
        await websocket.accept()
        self.active_connections[user_id] = websocket
        logger.info(f"User {user_id} connected to signaling WebSocket. Total: {len(self.active_connections)}")

    def disconnect(self, user_id: int):
        if user_id in self.active_connections:
            del self.active_connections[user_id]
            logger.info(f"User {user_id} disconnected from signaling WebSocket. Total: {len(self.active_connections)}")

    async def send_personal_message(self, message: dict, user_id: int) -> bool:
        """Sends a JSON message to a specific user. Returns True if successful, False if offline."""
        websocket = self.active_connections.get(user_id)
        if websocket:
            try:
                await websocket.send_json(message)
                return True
            except Exception as e:
                logger.error(f"Error sending message to {user_id}: {e}")
                self.disconnect(user_id)
                return False
        return False

manager = CallManager()
