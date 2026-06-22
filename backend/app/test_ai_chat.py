import asyncio
from app.db.session import async_session
from app.models.user import User
from app.api.v1.ai_chat import ai_chat, ChatRequest, ChatMessage
from sqlalchemy import select
from starlette.requests import Request

async def test_msg(msg_content: str):
    print(f"\n--- Testing message: '{msg_content}' ---")
    async with async_session() as db:
        result = await db.execute(select(User).limit(1))
        user = result.scalar_one_or_none()
        if not user:
            print("Error: No user found!")
            return
            
        scope = {
            "type": "http",
            "method": "POST",
            "path": "/api/v1/ai/chat",
            "headers": [],
            "client": ("127.0.0.1", 80),
        }
        request = Request(scope)
        request.state.rate_limit_exempt = True
        
        body = ChatRequest(
            messages=[ChatMessage(role="user", content=msg_content)]
        )
        
        try:
            response = await ai_chat(
                request=request,
                body=body,
                current_user=user,
                db=db
            )
            print(f"Response: '{response.reply}'")
        except Exception as e:
            print("Exception:", e)

async def main():
    await test_msg("Salom")
    await test_msg("Bugun 12:00 da uchrashuvim bor")

if __name__ == "__main__":
    asyncio.run(main())
