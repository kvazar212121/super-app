from fastapi import Depends, HTTPException
from app.api.dependencies import get_current_user
from app.models.user import User

admin_only_msg = "Faqat admin uchun ruxsat"


def require_admin(current_user: User = Depends(get_current_user)) -> User:
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail=admin_only_msg)
    return current_user
