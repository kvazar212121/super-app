import asyncio
import logging
import time
import traceback
from contextlib import asynccontextmanager
from pathlib import Path

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from slowapi.errors import RateLimitExceeded
from slowapi.middleware import SlowAPIMiddleware
from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.responses import Response

from app.api.v1.router import api_router
from app.api.v1.admin_panel import router as admin_panel_router
from app.core.config import settings
from app.core.limiter import limiter
from app.core.logging_config import (
    setup_logging,
    request_id_filter,
    get_request_id,
)
from app.db.session import engine
from app.core.schedulers import scheduler_supervisor
from app.core.startup import run_startup_init

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# Rate-limit oshib ketganda qaytariladigan javob
# ---------------------------------------------------------------------------
async def _rate_limit_exceeded_handler(request: Request, exc: RateLimitExceeded) -> JSONResponse:
    """Rate-limit oshib ketganda JSON javob qaytaradi."""
    logger.warning(
        "Rate-limit oshib ketdi: IP=%s path=%s",
        request.client.host if request.client else "unknown",
        request.url.path,
    )
    return JSONResponse(
        status_code=429,
        content={
            "detail": "Rate-limit oshib ketdi. Biroz kuting va qayta urinib ko'ring.",
        },
        headers={
            "Retry-After": str(exc.retry_after) if exc.retry_after else "60",
        },
    )


# ---------------------------------------------------------------------------
# So'rovlarni loglash middleware
# ---------------------------------------------------------------------------
class RequestLoggingMiddleware(BaseHTTPMiddleware):
    """Har bir HTTP so'rovni log qiladi va request ID qo'shadi."""

    async def dispatch(
        self, request: Request, call_next: RequestResponseEndpoint
    ) -> Response:
        # Request ID yaratish yoki mavjudini olish
        request_id = request.headers.get("X-Request-ID", get_request_id())
        request_id_filter.set_request_id(request_id)

        # Boshlash vaqti
        start_time = time.perf_counter()

        # So'rovni log qilish
        logger.info(
            "So'rov boshlandi: %s %s",
            request.method,
            request.url.path,
        )

        try:
            # Javobni olish
            response = await call_next(request)

            # Vaqtni hisoblash
            duration_ms = (time.perf_counter() - start_time) * 1000

            # Javobda request ID qo'shish
            response.headers["X-Request-ID"] = request_id

            # Rate-limit headerlarini qo'shish (agar mavjud bo'lsa)
            if hasattr(request.state, "view_rate_limit"):
                limit_info = request.state.view_rate_limit
                if isinstance(limit_info, dict):
                    response.headers["X-RateLimit-Limit"] = str(limit_info.get("limit", ""))
                    response.headers["X-RateLimit-Remaining"] = str(limit_info.get("remaining", ""))
                    response.headers["X-RateLimit-Reset"] = str(limit_info.get("reset", ""))

            # Javobni log qilish
            logger.info(
                "Javob: %s %s -> %d | %.1fms",
                request.method,
                request.url.path,
                response.status_code,
                duration_ms,
            )

            return response

        except Exception as exc:
            # Xatolikni log qilish
            duration_ms = (time.perf_counter() - start_time) * 1000
            logger.error(
                "Xatolik: %s %s -> 500 | %.1fms | %s\n%s",
                request.method,
                request.url.path,
                duration_ms,
                str(exc),
                traceback.format_exc(),
            )
            return JSONResponse(
                status_code=500,
                content={"detail": "Ichki server xatoligi."},
                headers={"X-Request-ID": request_id},
            )


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Loggingni sozlash
    setup_logging()
    root_logger = logging.getLogger()
    root_logger.addFilter(request_id_filter)

    # Production xavfsizlik guard'i — DB'дан OLDIN. Xavfli default sozlamalar
    # (secret_key, ochiq CORS, standart admin paroli) bilan prod'да ishga tushmaydi.
    from app.core.security_guard import enforce_production_config
    enforce_production_config(settings)

    # Startup DDL + seed — ko'p workerда FAQAT bitta worker bajaradi.
    await run_startup_init()

    # Qo'ng'iroq signali Redis subscriber — HAR workerда ishlaydi (worker'lar aro signal)
    from app.core.call_manager import manager as call_manager
    call_sub_task = asyncio.create_task(call_manager.start_subscriber())

    # Schedulerlar — Redis-lock leader orqali faqat BITTA workerда ishlaydi.
    # RUN_SCHEDULERS=false bo'lsa (masalan alohida web-only konteyner) umuman ishga tushmaydi.
    supervisor_task = None
    if settings.run_schedulers:
        supervisor_task = asyncio.create_task(scheduler_supervisor())
    else:
        logger.info("RUN_SCHEDULERS=false — bu protsessda schedulerlar ishga tushmadi.")

    yield

    # Cancel the background tasks
    call_sub_task.cancel()
    if supervisor_task:
        supervisor_task.cancel()
    for task in [call_sub_task, supervisor_task]:
        if task is None:
            continue
        try:
            await task
        except asyncio.CancelledError:
            pass

    await engine.dispose()


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        openapi_url=f"{settings.api_v1_prefix}/openapi.json",
        lifespan=lifespan,
    )

    # Rate-limiter
    app.state.limiter = limiter
    app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)
    app.add_middleware(SlowAPIMiddleware)

    # So'rovlarni loglash middleware
    app.add_middleware(RequestLoggingMiddleware)

    LANDING_HTML = Path(__file__).resolve().parent / "static" / "landing" / "index.html"
    PRIVACY_HTML = Path(__file__).resolve().parent / "static" / "landing" / "privacy.html"

    @app.get("/")
    async def root():
        if LANDING_HTML.is_file():
            return FileResponse(LANDING_HTML, media_type="text/html")
        return {
            "name": settings.app_name,
            "docs": "/docs",
            "health": f"{settings.api_v1_prefix}/health",
        }

    import html as _htmlmod
    from fastapi.responses import HTMLResponse
    from app.services import settings_service as _settings_svc

    def _legal_page(title: str, content: str) -> str:
        paras = "".join(
            f"<section><p>{p.replace(chr(10), '<br>')}</p></section>"
            for p in _htmlmod.escape(content or "").split("\n\n") if p.strip()
        )
        return (
            "<!DOCTYPE html><html lang=\"uz\"><head><meta charset=\"UTF-8\">"
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
            f"<title>HubServis — {_htmlmod.escape(title)}</title>"
            "<style>*{box-sizing:border-box;margin:0;padding:0}"
            "body{font-family:Inter,system-ui,sans-serif;background:#050505;color:#E5E7EB;line-height:1.65}"
            "nav{position:sticky;top:0;background:rgba(5,5,5,.85);backdrop-filter:blur(20px);border-bottom:1px solid rgba(255,255,255,.1)}"
            ".ni{max-width:820px;margin:0 auto;padding:16px 24px;display:flex;justify-content:space-between;align-items:center}"
            ".lg{font-weight:800;font-size:1.4rem;letter-spacing:-1px;color:#fff;text-decoration:none}"
            ".bk{color:#9CA3AF;text-decoration:none;font-size:.9rem}main{max-width:820px;margin:0 auto;padding:40px 24px 72px}"
            "h1{font-size:2rem;font-weight:800;margin-bottom:24px}"
            "section{margin-bottom:18px;padding:18px 22px;background:#101012;border:1px solid rgba(255,255,255,.1);border-radius:14px}"
            "p{color:#D1D5DB;font-size:.98rem}footer{border-top:1px solid rgba(255,255,255,.1);text-align:center;padding:28px;color:#52525B;font-size:.85rem}"
            "@media(prefers-color-scheme:light){body{background:#fff;color:#0F172A}nav{background:rgba(255,255,255,.9);border-color:rgba(0,0,0,.08)}"
            ".lg{color:#0F172A}section{background:#F8FAFC;border-color:rgba(0,0,0,.08)}p{color:#334155}}</style></head><body>"
            "<nav><div class=\"ni\"><a href=\"/\" class=\"lg\">HUBSERVIS</a><a href=\"/\" class=\"bk\">← Bosh sahifa</a></div></nav>"
            f"<main><h1>{_htmlmod.escape(title)}</h1>{paras}</main>"
            "<footer>© 2026 HUBSERVIS. Barcha huquqlar himoyalangan.</footer></body></html>"
        )

    def _multilang_legal_page(titles: dict, contents: dict) -> str:
        """Ko'p tilli huquqiy sahifa (uz/ru/en) — yuqorida til almashtirgich bilan."""
        LANGS = [("uz", "O'zbekcha"), ("ru", "Русский"), ("en", "English")]

        def _sections(text: str) -> str:
            return "".join(
                f"<section><p>{p.replace(chr(10), '<br>')}</p></section>"
                for p in _htmlmod.escape(text or "").split("\n\n") if p.strip()
            )

        tabs = "".join(
            f'<button class="lang-btn{" active" if code == "uz" else ""}" data-lang="{code}" '
            f'onclick="showLang(\'{code}\')">{label}</button>'
            for code, label in LANGS
        )
        blocks = "".join(
            f'<div class="lang-block" id="lang-{code}" style="display:{"block" if code == "uz" else "none"}">'
            f'<h1>{_htmlmod.escape(titles.get(code, titles.get("uz", "")))}</h1>'
            f'{_sections(contents.get(code) or contents.get("uz", ""))}</div>'
            for code, _ in LANGS
        )
        return (
            "<!DOCTYPE html><html lang=\"uz\"><head><meta charset=\"UTF-8\">"
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
            f"<title>HubServis — {_htmlmod.escape(titles.get('uz', ''))}</title>"
            "<style>*{box-sizing:border-box;margin:0;padding:0}"
            "body{font-family:Inter,system-ui,sans-serif;background:#050505;color:#E5E7EB;line-height:1.65}"
            "nav{position:sticky;top:0;background:rgba(5,5,5,.85);backdrop-filter:blur(20px);border-bottom:1px solid rgba(255,255,255,.1);z-index:10}"
            ".ni{max-width:820px;margin:0 auto;padding:16px 24px;display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap}"
            ".lg{font-weight:800;font-size:1.4rem;letter-spacing:-1px;color:#fff;text-decoration:none}"
            ".langs{display:flex;gap:6px}"
            ".lang-btn{background:transparent;color:#9CA3AF;border:1px solid rgba(255,255,255,.18);border-radius:9px;padding:6px 12px;font-size:.85rem;font-weight:600;cursor:pointer}"
            ".lang-btn.active{background:#6366F1;color:#fff;border-color:#6366F1}"
            ".bk{color:#9CA3AF;text-decoration:none;font-size:.9rem}main{max-width:820px;margin:0 auto;padding:40px 24px 72px}"
            "h1{font-size:2rem;font-weight:800;margin-bottom:24px}"
            "section{margin-bottom:18px;padding:18px 22px;background:#101012;border:1px solid rgba(255,255,255,.1);border-radius:14px}"
            "p{color:#D1D5DB;font-size:.98rem}footer{border-top:1px solid rgba(255,255,255,.1);text-align:center;padding:28px;color:#71717A;font-size:.85rem}"
            "@media(prefers-color-scheme:light){body{background:#fff;color:#0F172A}nav{background:rgba(255,255,255,.9);border-color:rgba(0,0,0,.08)}"
            ".lg{color:#0F172A}section{background:#F8FAFC;border-color:rgba(0,0,0,.08)}p{color:#334155}}</style></head><body>"
            "<nav><div class=\"ni\"><a href=\"/\" class=\"lg\">HUBSERVIS</a>"
            f"<div class=\"langs\">{tabs}</div>"
            "<a href=\"/\" class=\"bk\">← Bosh sahifa</a></div></nav>"
            f"<main>{blocks}</main>"
            "<footer>© 2026 HUBSERVIS. Barcha huquqlar himoyalangan.</footer>"
            "<script>function showLang(l){document.querySelectorAll('.lang-block').forEach(function(b){b.style.display='none'});"
            "document.getElementById('lang-'+l).style.display='block';"
            "document.querySelectorAll('.lang-btn').forEach(function(x){x.classList.toggle('active',x.dataset.lang===l)});"
            "window.scrollTo(0,0);}</script></body></html>"
        )

    @app.get("/terms", include_in_schema=False)
    async def terms():
        return HTMLResponse(_multilang_legal_page(
            {"uz": "Foydalanish shartlari", "ru": "Условия использования", "en": "Terms of Use"},
            {
                "uz": _settings_svc.get_legal("terms"),
                "ru": _settings_svc.get("legal_terms_ru", "") or _settings_svc.get_legal("terms"),
                "en": _settings_svc.get("legal_terms_en", "") or _settings_svc.get_legal("terms"),
            },
        ))

    @app.get("/privacy", include_in_schema=False)
    async def privacy():
        return HTMLResponse(_multilang_legal_page(
            {"uz": "Maxfiylik siyosati", "ru": "Политика конфиденциальности", "en": "Privacy Policy"},
            {
                "uz": _settings_svc.get_legal("privacy"),
                "ru": _settings_svc.get("legal_privacy_ru", "") or _settings_svc.get_legal("privacy"),
                "en": _settings_svc.get("legal_privacy_en", "") or _settings_svc.get_legal("privacy"),
            },
        ))

    @app.get("/yuklash", include_in_schema=False)
    async def download_apk():
        """Android ilovasini (APK) to'g'ridan-to'g'ri yuklab olish.

        Fayl `uploads` volumida yotadi — git'ga tushmaydi va konteyner qayta
        qurilganda ham yo'qolmaydi. Yangi versiya chiqsa shu nom bilan ustiga
        nusxalanadi, havola o'zgarmaydi.
        """
        from fastapi.responses import FileResponse
        apk = Path(settings.upload_dir) / "hubservis.apk"
        if not apk.is_file():
            raise HTTPException(status_code=404, detail="Ilova fayli hozircha mavjud emas")
        return FileResponse(
            path=str(apk),
            media_type="application/vnd.android.package-archive",
            filename="HubServis.apk",
        )

    @app.get("/delete-account", include_in_schema=False)
    async def delete_account_page():
        _support_email = _settings_svc.get("support_email", "") or "support@hubservis.uz"
        _uz = (
            "HUBSERVIS — AKKAUNTNI O'CHIRISH\n\n"
            "Ushbu sahifa HubServis ilovasi hisobingizni va unga bog'liq shaxsiy ma'lumotlarni "
            "qanday o'chirishni tushuntiradi.\n\n"
            "1-USUL — ILOVA ORQALI\n"
            "Ilovaga kiring → Profil → Sozlamalar → \"Akkauntni o'chirish\" tugmasini bosing va tasdiqlang.\n\n"
            "2-USUL — SO'ROV YUBORISH\n"
            f"Ilova ichidagi \"Qo'llab-quvvatlash\" bo'limi orqali yoki {_support_email} pochtasiga "
            "ro'yxatdan o'tgan telefon raqamingizni ko'rsatib xat yuboring. So'rov 30 kun ichida bajariladi.\n\n"
            "QANDAY MA'LUMOTLAR O'CHIRILADI\n"
            "Profil (ism, telefon, rasm), buyurtmalar tarixi, moliya/reja/bozorlik yozuvlari, "
            "kaloriya va mashg'ulot ma'lumotlari, qurilma (push) tokenlari va sharhlaringiz.\n\n"
            "QANDAY MA'LUMOTLAR VAQTINCHA SAQLANADI\n"
            "Qonun talab qilgan hollarda (masalan, to'lov/soliq yozuvlari) ayrim ma'lumotlar "
            "belgilangan muddat davomida saqlanib, so'ng butunlay o'chiriladi.\n\n"
            f"Savol bo'lsa: {_support_email}"
        )
        _ru = (
            "HUBSERVIS — УДАЛЕНИЕ АККАУНТА\n\n"
            "На этой странице описано, как удалить ваш аккаунт HubServis и связанные с ним "
            "персональные данные.\n\n"
            "СПОСОБ 1 — ЧЕРЕЗ ПРИЛОЖЕНИЕ\n"
            "Откройте приложение → Профиль → Настройки → нажмите «Удалить аккаунт» и подтвердите.\n\n"
            "СПОСОБ 2 — ОТПРАВИТЬ ЗАПРОС\n"
            f"Напишите через раздел «Поддержка» в приложении или на {_support_email}, указав ваш "
            "зарегистрированный номер телефона. Запрос выполняется в течение 30 дней.\n\n"
            "КАКИЕ ДАННЫЕ УДАЛЯЮТСЯ\n"
            "Профиль (имя, телефон, фото), история заказов, записи финансов/планов/покупок, "
            "данные о калориях и тренировках, токены устройств (push) и ваши отзывы.\n\n"
            "КАКИЕ ДАННЫЕ ХРАНЯТСЯ ВРЕМЕННО\n"
            "Если этого требует закон (например, платёжные/налоговые записи), часть данных хранится "
            "в течение установленного срока, затем полностью удаляется.\n\n"
            f"Вопросы: {_support_email}"
        )
        _en = (
            "HUBSERVIS — ACCOUNT DELETION\n\n"
            "This page explains how to delete your HubServis account and the associated personal data.\n\n"
            "METHOD 1 — IN THE APP\n"
            "Open the app → Profile → Settings → tap \"Delete account\" and confirm.\n\n"
            "METHOD 2 — SEND A REQUEST\n"
            f"Contact us via the \"Support\" section in the app or at {_support_email}, stating your "
            "registered phone number. Requests are completed within 30 days.\n\n"
            "WHAT DATA IS DELETED\n"
            "Profile (name, phone, photo), order history, finance/plan/shopping records, calorie and "
            "workout data, device (push) tokens, and your reviews.\n\n"
            "WHAT DATA IS TEMPORARILY RETAINED\n"
            "Where required by law (e.g. payment/tax records), some data is retained for the required "
            "period and then permanently deleted.\n\n"
            f"Questions: {_support_email}"
        )
        return HTMLResponse(_multilang_legal_page(
            {"uz": "Akkauntni o'chirish", "ru": "Удаление аккаунта", "en": "Account Deletion"},
            {"uz": _uz, "ru": _ru, "en": _en},
        ))

    # CORS
    if settings.cors_allow_all:
        origins = ["*"]
    else:
        origins = [o.strip() for o in settings.cors_origins.split(",") if o.strip()]
        if not origins:
            origins = ["http://localhost:3000"]

    app.add_middleware(
        CORSMiddleware,
        allow_origins=origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Xavfsizlik header'lari (barcha javoblarga)
    _CSP = (
        "default-src 'self'; "
        "script-src 'self' 'unsafe-inline'; "
        "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; "
        "img-src 'self' data: https:; "
        "font-src 'self' https://fonts.gstatic.com data:; "
        "connect-src 'self'; "
        "frame-ancestors 'self'; "
        "object-src 'none'; "
        "base-uri 'self'; "
        "form-action 'self'"
    )

    @app.middleware("http")
    async def maintenance_gate(request: Request, call_next):
        """Texnik xizmat rejimi yoqilganda API'ни vaqtincha yopadi.

        Admin panel (/admin), autentifikatsiya (/auth), health va docs ochiq qoladi —
        shунday qilib adminlar tizimга kirib rejimни o'chira oladi. Rejim admin
        panelдан (settings) yoqiladi va DB'да saqlanadi.
        """
        path = request.url.path
        _exempt = (
            path == "/"
            or path.startswith("/admin")
            or path.startswith("/api/v1/auth")
            or path.startswith("/api/v1/health")
            or path.startswith("/api/v1/ready")
            or path.startswith("/api/v1/config")
            or path.startswith("/docs")
            or path.startswith("/redoc")
            or path.startswith("/openapi")
            or path.startswith("/static")
            or path.startswith("/uploads")
            or path.startswith("/admin-assets")
            or path in ("/favicon.ico", "/favicon.png", "/robots.txt", "/sitemap.xml")
            or path in ("/terms", "/privacy", "/delete-account")
        )
        if not _exempt:
            try:
                from app.services import settings_service
                if settings_service.get_bool("maintenance_mode", False):
                    return JSONResponse(
                        status_code=503,
                        content={"detail": "Texnik ishlar olib borilmoqda. Iltimos, birozdan so'ng urinib ko'ring."},
                        headers={"Retry-After": "300"},
                    )
            except Exception as exc:
                logger.error("maintenance_gate xatosi: %s", exc)
        return await call_next(request)

    @app.middleware("http")
    async def security_headers(request: Request, call_next):
        response = await call_next(request)
        path = request.url.path
        # Swagger/Redoc CDN'lardan yuklanadi — ularга CSP qo'ymaymiz
        if not (path.startswith("/docs") or path.startswith("/redoc") or path.startswith("/openapi")):
            response.headers.setdefault("Content-Security-Policy", _CSP)
        response.headers.setdefault("X-Content-Type-Options", "nosniff")
        response.headers.setdefault("X-Frame-Options", "SAMEORIGIN")
        response.headers.setdefault("Referrer-Policy", "strict-origin-when-cross-origin")
        response.headers.setdefault(
            "Permissions-Policy", "geolocation=(), microphone=(), camera=(), payment=()"
        )
        if request.url.scheme == "https":
            response.headers.setdefault(
                "Strict-Transport-Security", "max-age=31536000; includeSubDomains"
            )
        return response

    # Static files for uploads
    upload_dir = Path(settings.upload_dir)
    upload_dir.mkdir(exist_ok=True)
    app.mount(
        "/uploads",
        StaticFiles(directory=str(upload_dir)),
        name="uploads",
    )

    # Static files for admin panel
    admin_static_dir = Path(__file__).resolve().parent / "static" / "admin"
    app.mount(
        "/admin-assets",
        StaticFiles(directory=str(admin_static_dir)),
        name="admin_static",
    )

    # General static files (favicon etc.)
    static_dir = Path(__file__).resolve().parent / "static"
    if static_dir.is_dir():
        app.mount(
            "/static",
            StaticFiles(directory=str(static_dir)),
            name="static_root",
        )

    # Favicon routes
    @app.get("/favicon.ico", include_in_schema=False)
    async def favicon_ico():
        ico = static_dir / "favicon.ico"
        png = static_dir / "favicon.png"
        if ico.is_file():
            return FileResponse(ico, media_type="image/x-icon")
        if png.is_file():
            return FileResponse(png, media_type="image/png")
        return JSONResponse({"detail": "not found"}, status_code=404)

    @app.get("/favicon.png", include_in_schema=False)
    async def favicon_png():
        png = static_dir / "favicon.png"
        if png.is_file():
            return FileResponse(png, media_type="image/png")
        return JSONResponse({"detail": "not found"}, status_code=404)

    @app.get("/robots.txt", include_in_schema=False)
    async def robots_txt():
        body = (
            "User-agent: *\n"
            "Allow: /\n"
            "Disallow: /admin\n"
            "Disallow: /api/\n"
            "Sitemap: https://hubservis.uz/sitemap.xml\n"
        )
        return Response(content=body, media_type="text/plain")

    @app.get("/sitemap.xml", include_in_schema=False)
    async def sitemap_xml():
        urls = ["https://hubservis.uz/", "https://hubservis.uz/terms", "https://hubservis.uz/privacy"]
        items = "".join(f"<url><loc>{u}</loc><changefreq>weekly</changefreq></url>" for u in urls)
        body = (
            '<?xml version="1.0" encoding="UTF-8"?>'
            '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
            f"{items}</urlset>"
        )
        return Response(content=body, media_type="application/xml")

    app.include_router(api_router, prefix=settings.api_v1_prefix)
    app.include_router(admin_panel_router)
    return app


app = create_app()