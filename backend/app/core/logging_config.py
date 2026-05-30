"""
Strukturalangan loglash konfiguratsiyasi.
Ishlab chiqarish (production): JSON formatli loglar.
Ishlanish (development): rangli konsol loglar.
"""
import logging
import sys
import uuid
from datetime import datetime, timezone
from typing import Any

from app.core.config import settings


# ---------------------------------------------------------------------------
# JSON formatter — production uchun
# ---------------------------------------------------------------------------
class JsonFormatter(logging.Formatter):
    """Log yozuvlarini JSON qatoriga aylantiradi."""

    def format(self, record: logging.LogRecord) -> str:
        import json

        log_entry: dict[str, Any] = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
        }

        # Request ID (agar mavjud bo'lsa)
        request_id = getattr(record, "request_id", None)
        if request_id:
            log_entry["request_id"] = request_id

        # Traceback
        if record.exc_info and record.exc_info[0] is not None:
            log_entry["traceback"] = self.formatException(record.exc_info)

        # Qo'shimcha maydonlar
        if hasattr(record, "extra"):
            log_entry.update(record.extra)

        return json.dumps(log_entry, ensure_ascii=False)


# ---------------------------------------------------------------------------
# Rangli formatter — development uchun
# ---------------------------------------------------------------------------
_COLORS = {
    "DEBUG": "\033[36m",     # cyan
    "INFO": "\033[32m",      # green
    "WARNING": "\033[33m",   # yellow
    "ERROR": "\033[31m",     # red
    "CRITICAL": "\033[35m",  # magenta
    "RESET": "\033[0m",
}


class ColoredFormatter(logging.Formatter):
    """Konsolda rangli log chiqaradi."""

    def format(self, record: logging.LogRecord) -> str:
        color = _COLORS.get(record.levelname, _COLORS["RESET"])
        reset = _COLORS["RESET"]

        request_id = getattr(record, "request_id", None)
        rid_str = f" [{request_id}]" if request_id else ""

        return (
            f"{color}{record.levelname}{reset} | "
            f"{record.name} | "
            f"{record.getMessage()}{rid_str}"
        )


# ---------------------------------------------------------------------------
# Logger sozlash
# ---------------------------------------------------------------------------
def setup_logging() -> None:
    """Ilovaning asosiy loggerini sozlaydi."""

    if settings.debug:
        # Development — rangli konsol
        formatter = ColoredFormatter()
        handler = logging.StreamHandler(sys.stdout)
    else:
        # Production — JSON format
        formatter = JsonFormatter()
        handler = logging.StreamHandler(sys.stdout)

    handler.setFormatter(formatter)

    # Root logger
    root_logger = logging.getLogger()
    root_logger.handlers.clear()
    root_logger.addHandler(handler)
    root_logger.setLevel(logging.DEBUG if settings.debug else logging.INFO)

    # Uchinchi tomon kutubxonalarini jimlashtirish
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("sqlalchemy.engine").setLevel(logging.WARNING)


# ---------------------------------------------------------------------------
# Yordamchi funksiyalar
# ---------------------------------------------------------------------------
def get_request_id() -> str:
    """Yangi request ID yaratadi yoki mavjudini qaytaradi."""
    return str(uuid.uuid4())


def add_request_id_to_record(record: logging.LogRecord, request_id: str) -> None:
    """LogRecord ga request_id qo'shadi."""
    record.request_id = request_id  # type: ignore[attr-defined]


class RequestIdFilter(logging.Filter):
    """Hamma log yozuvlariga request_id qo'shadi (agar mavjud bo'lsa)."""

    def __init__(self) -> None:
        super().__init__()
        self._request_id: str | None = None

    def set_request_id(self, request_id: str) -> None:
        self._request_id = request_id

    def filter(self, record: logging.LogRecord) -> bool:
        if self._request_id and not hasattr(record, "request_id"):
            record.request_id = self._request_id  # type: ignore[attr-defined]
        return True


# Global filter — middleware orqali to'ldiriladi
request_id_filter = RequestIdFilter()
