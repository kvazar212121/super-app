"""Super admin login/parolini o'rnatadi.

NEGA KERAK: admin panelga kirish `users.phone` ustuni orqali ishlaydi
(`auth_service.login` da `phone` login sifatida qabul qilinadi).
Parolni tiklash yoki yangi super admin qo'shish uchun qo'lda SQL
yozish o'rniga shu skript ishlatiladi — parol to'g'ri xeshlanadi.

Ishlatish (serverda):
    CID=$(docker compose ps -q backend | head -1)
    docker cp scripts/set_admin.py "$CID":/app/set_admin.py
    docker exec "$CID" python /app/set_admin.py gvazar 1qaz2wsx

Parol berilmasa faqat `is_super_admin` yoqiladi (parol tegilmaydi).
"""
from __future__ import annotations

import asyncio
import os
import sys

_ILDIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _ILDIZ not in sys.path:
    sys.path.insert(0, _ILDIZ)
if "/app" not in sys.path and os.path.isdir("/app/app"):
    sys.path.insert(0, "/app")


async def main(login: str, parol: str | None, eski_login: str | None) -> None:
    from sqlalchemy import select

    from app.core.security import hash_password, verify_password
    from app.db.session import async_session
    from app.models.user import User

    async with async_session() as db:
        user = (await db.execute(
            select(User).where(User.phone == login)
        )).scalars().first()

        # Login o'zgartirilayotgan bo'lsa eskisidan topamiz.
        if user is None and eski_login:
            user = (await db.execute(
                select(User).where(User.phone == eski_login)
            )).scalars().first()

        if user is None:
            if not parol:
                print(f"✗ '{login}' topilmadi va parol berilmadi — "
                      "yangi admin yaratib bo'lmaydi.")
                return
            user = User(name=login, surname="Admin", phone=login,
                        hashed_password=hash_password(parol))
            db.add(user)
            print(f"  yangi admin yaratildi: {login}")

        user.phone = login
        if parol:
            user.hashed_password = hash_password(parol)
        user.is_admin = True
        user.is_super_admin = True
        user.is_active = True
        await db.commit()
        await db.refresh(user)

        print(f"  id            : {user.id}")
        print(f"  login (phone) : {user.phone}")
        print(f"  super_admin   : {user.is_super_admin}")
        if parol:
            # Xeshlash to'g'ri ishlaganini SHU YERDA tasdiqlaymiz:
            # noto'g'ri xesh bilan panelga kira olmay qolinardi.
            print(f"  parol ishlaydi: "
                  f"{verify_password(parol, user.hashed_password)}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    _login = sys.argv[1]
    _parol = sys.argv[2] if len(sys.argv) > 2 else None
    _eski = sys.argv[3] if len(sys.argv) > 3 else None
    asyncio.run(main(_login, _parol, _eski))
