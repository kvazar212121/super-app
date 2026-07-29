"""Firebase Cloud Messaging (FCM) — server push yuborish.

Ilova YOPIQ/fon holatida ham qurilmaga bildirishnoma/qo'ng'iroq yetkazadi.
Service account kaliti: backend/serviceAccountKey.json (gitignore).
Kalit bo'lmasa — push jim o'chadi (xato bermaydi, DB yozuvi baribir saqlanadi).
"""
import logging
from pathlib import Path

logger = logging.getLogger(__name__)

GENERAL_CHANNEL = "super_app_channel_v2"  # Flutter'dagi ovozli kanal bilan bir xil

_initialized = False
_available = False


def _init() -> bool:
    """Firebase Admin SDK'ni bir marta ishga tushiradi. Muvaffaqiyatli bo'lsa True."""
    global _initialized, _available
    if _initialized:
        return _available
    _initialized = True
    cred_path = Path(__file__).resolve().parent.parent.parent / "serviceAccountKey.json"
    if not cred_path.is_file():
        logger.warning("FCM: serviceAccountKey.json topilmadi — push o'chiq (faqat DB yoziladi).")
        _available = False
        return False
    try:
        import firebase_admin
        from firebase_admin import credentials
        if not firebase_admin._apps:
            firebase_admin.initialize_app(credentials.Certificate(str(cred_path)))
        _available = True
        logger.info("FCM: Firebase Admin SDK ishga tushdi — push yoqilgan.")
    except Exception as e:
        logger.error(f"FCM init xato: {e}")
        _available = False
    return _available


def _is_dead_token(exc) -> bool:
    """Token butunlay yaroqsizmi (bazadan o'chirilishi kerakmi).

    firebase-admin aniq XATO SINFLARINI beradi — matn bo'yicha tekshirish
    ishonchsiz (avval shu sabab o'lik token'lar tozalanmay yig'ilib qolgan edi):
      • UnregisteredError   — ilova o'chirilgan / token eskirgan (code=NOT_FOUND)
      • SenderIdMismatchError — token boshqa Firebase loyihasiniki
      • InvalidArgumentError — token formati buzuq (code=INVALID_ARGUMENT)
    Vaqtinchalik xatolar (UnavailableError, InternalError, QuotaExceeded) —
    O'CHIRILMAYDI, keyingi urinishda ishlashi mumkin.
    """
    from firebase_admin import messaging, exceptions as fb_exc

    if isinstance(exc, (messaging.UnregisteredError, messaging.SenderIdMismatchError)):
        return True
    if isinstance(exc, fb_exc.InvalidArgumentError):
        return True
    return str(getattr(exc, "code", "")).upper() in {"NOT_FOUND", "INVALID_ARGUMENT"}


def _send_multicast(tokens, message_builder) -> tuple[int, list]:
    """Token'larga xabar yuboradi.

    Qaytaradi: (muvaffaqiyatli yetkazilganlar soni, o'chirilishi kerak token'lar).
    MUHIM: muvaffaqiyat SONI kerak — chaqiruvда "qurilma bor" degani "push yetdi"
    degani emas. Aks holda hamma token o'lik bo'lsa ham chaqiruvchiga "jiringlayapti"
    deb ko'rsatiladi, narigi telefon esa jim turadi.
    """
    if not _init() or not tokens:
        return 0, []
    from firebase_admin import messaging
    invalid = []
    try:
        msg = message_builder(messaging, tokens)
        resp = messaging.send_each_for_multicast(msg)
        for idx, r in enumerate(resp.responses):
            if not r.success and _is_dead_token(r.exception):
                invalid.append(tokens[idx])
        if resp.failure_count:
            logger.info(
                "FCM: %d yuborildi, %d xato (%d o'lik token o'chiriladi)",
                resp.success_count, resp.failure_count, len(invalid),
            )
        return resp.success_count, invalid
    except Exception as e:
        logger.error(f"FCM yuborishda xato: {e}")
        return 0, invalid


def send_notification_to_tokens(tokens, title: str, body: str, data: dict | None = None) -> tuple[int, list]:
    """Oddiy bildirishnoma (title+body) — Android yopiq holatda ham ovoz bilan ko'rsatadi.

    Qaytaradi: (yetkazilganlar soni, o'chirilishi kerak token'lar).
    """
    def build(messaging, toks):
        return messaging.MulticastMessage(
            tokens=toks,
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
            android=messaging.AndroidConfig(
                priority="high",
                notification=messaging.AndroidNotification(
                    channel_id=GENERAL_CHANNEL,
                    sound="default",
                    default_sound=True,
                ),
            ),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(aps=messaging.Aps(sound="default")),
            ),
        )
    return _send_multicast(tokens, build)


def send_data_to_tokens(tokens, data: dict) -> tuple[int, list]:
    """Faqat-data (silent) xabar — Flutter background handler qabul qiladi (masalan qo'ng'iroq/CallKit).

    Qaytaradi: (yetkazilganlar soni, o'chirilishi kerak token'lar).
    """
    def build(messaging, toks):
        return messaging.MulticastMessage(
            tokens=toks,
            data={k: str(v) for k, v in data.items()},
            android=messaging.AndroidConfig(priority="high"),
            apns=messaging.APNSConfig(
                headers={"apns-priority": "10", "apns-push-type": "voip"},
            ),
        )
    return _send_multicast(tokens, build)
