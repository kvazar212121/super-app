"""
Web-admin sahifalari statik HTML/CSS/JS: `app/static/admin/`.
Brauzer: `/admin`, `/admin/login`. API: `/api/v1/admin/*`.
Flutter tomonda admin ekrani yo'q.
"""
from pathlib import Path

from fastapi import APIRouter, HTTPException, Request
from fastapi.responses import FileResponse

from app.core.limiter import limiter

router = APIRouter(prefix="/admin", tags=["admin panel"])

ADMIN_DIR = Path(__file__).resolve().parents[2] / "static" / "admin"


@router.get("/login")
@limiter.limit("50/minute")
async def admin_login_page(request: Request) -> FileResponse:
    response = FileResponse(ADMIN_DIR / "login.html")
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    return response


@router.get("")
@limiter.limit("50/minute")
async def admin_dashboard_page(request: Request) -> FileResponse:
    response = FileResponse(ADMIN_DIR / "index.html")
    response.headers["Cache-Control"] = "no-cache, no-store, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    return response


@router.get("/static/{filename}")
@limiter.limit("50/minute")
async def admin_static_file(request: Request, filename: str):
    """Serve static CSS/JS files for admin panel."""
    file_path = ADMIN_DIR / filename
    if not file_path.exists() or not file_path.is_file():
        raise HTTPException(status_code=404, detail="File not found")
    return FileResponse(file_path)
