"""Platform sozlamalari xizmati — PlatformSetting (kalit-qiymat) ni keshlab o'qiydi/yozadi.

AI provayder/model tanlovi va bo'lim (feature) flaglari shu yerда saqlanadi, admin
paneldan o'zgartiriladi va kod/env o'zgartirmasдан kuchга kiradi. Kesh TTL (30s) tufayli
admin o'zgarishlari tez tarqaladi, lekin har chaqiruvда DB'ga urilmaydi.
"""
import json
import logging
import time

from app.db.session import sync_session
from app.core.redis_client import get_redis
from app.models.setting import PlatformSetting

logger = logging.getLogger(__name__)

# Kesh Redis'да saqlanadi (barcha worker'lar ko'radi) + qisqa lokal mikro-kesh (2s).
# Shunda admin o'zgarishi ~2s ичида hamma worker'ga yetadi, lekin har chaqiruvда Redis'ga urilmaydi.
_REDIS_KEY = "platform_settings_json"
_local: dict[str, str] = {}
_local_ts: float = 0.0
_LOCAL_TTL = 2.0

# Ilova bo'limlari (feature flags) — admin yoqib/o'chira oladi
FEATURE_DEFS = [
    ("plans", "Rejalarim"),
    ("finance", "Mening moliyam"),
    ("shopping", "Aqlli savdo"),
    ("services", "Barcha xizmatlar"),
    ("calorie", "Kaloriya hisoblagich"),
    ("fitness", "Fitnes trener"),
    ("alarm", "Majburlovchi budilnik"),
    ("ai_chat", "AI Yordamchi"),
]
AI_FEATURES = ["vision", "chat", "translate"]
DEFAULT_COMING_SOON = "Bu bo'lim tez orada ishga tushadi ⏳"


def _reload_from_db() -> dict[str, str]:
    """DB'dan to'liq o'qib, Redis keshini yangilaydi va dict qaytaradi."""
    data: dict[str, str] = {}
    try:
        with sync_session() as db:
            data = {r.key: r.value for r in db.query(PlatformSetting).all()}
        try:
            get_redis().set(_REDIS_KEY, json.dumps(data))
        except Exception:
            pass
    except Exception as e:
        logger.error(f"SettingsService DB reload failed: {e}")
    return data


def _refresh_local() -> None:
    global _local, _local_ts
    data = None
    try:
        raw = get_redis().get(_REDIS_KEY)
        if raw:
            data = json.loads(raw)
    except Exception:
        data = None
    if data is None:
        data = _reload_from_db()
    _local = data
    _local_ts = time.time()


def get(key: str, default: str | None = None) -> str | None:
    if time.time() - _local_ts > _LOCAL_TTL or not _local:
        _refresh_local()
    return _local.get(key, default)


def get_bool(key: str, default: bool = True) -> bool:
    val = get(key, None)
    if val is None:
        return default
    return str(val).strip().lower() in ("1", "true", "yes", "on")


def set_value(key: str, value: str, description: str | None = None) -> None:
    try:
        with sync_session() as db:
            row = db.query(PlatformSetting).filter(PlatformSetting.key == key).first()
            if row:
                row.value = str(value)
                if description:
                    row.description = description
            else:
                db.add(PlatformSetting(key=key, value=str(value), description=description or ""))
            db.commit()
    except Exception as e:
        logger.error(f"SettingsService set_value({key}) failed: {e}")
    _reload_from_db()  # DB + Redis keshni yangilaymiz (barcha worker uchun)
    _refresh_local()


def set_many(items: dict[str, str]) -> None:
    try:
        with sync_session() as db:
            existing = {r.key: r for r in db.query(PlatformSetting).all()}
            for k, v in items.items():
                if k in existing:
                    existing[k].value = str(v)
                else:
                    db.add(PlatformSetting(key=k, value=str(v)))
            db.commit()
    except Exception as e:
        logger.error(f"SettingsService set_many failed: {e}")
    _reload_from_db()  # DB + Redis keshni yangilaymiz (barcha worker uchun)
    _refresh_local()


PROVIDER_URLS = {
    "openai": "https://api.openai.com/v1/chat/completions",
    "groq": "https://api.groq.com/openai/v1/chat/completions",
    "deepseek": "https://api.deepseek.com/v1/chat/completions",
}


def resolve_ai(
    feature: str,
    env_provider: str,
    keys: dict[str, str],
    default_models: dict[str, str],
) -> tuple[str, str, str]:
    """AI provayder+model tanlovini DB'dan (admin sozlagan) o'qib, (api_url, key, model) qaytaradi.

    Barcha provayderlar OpenAI-mos /chat/completions formatidan foydalanadi.
    `keys` va `default_models` — provayder nomi bo'yicha lug'atlar.
    DB'da sozlanmagan bo'lsa env qiymatiga tushadi.
    """
    provider = (get(f"ai_{feature}_provider", env_provider) or "groq").strip().lower()
    if provider not in PROVIDER_URLS:
        provider = "groq"
    model = get(f"ai_{feature}_model", "") or default_models.get(provider, "")
    return (PROVIDER_URLS[provider], keys.get(provider, ""), model)


# ── Feature flags ────────────────────────────────────────────────────────────

def feature_enabled(key: str) -> bool:
    return get_bool(f"feature_{key}_enabled", True)


def feature_message(key: str) -> str:
    return get(f"feature_{key}_msg", "") or DEFAULT_COMING_SOON


def all_features() -> list[dict]:
    return [
        {
            "key": k,
            "label": label,
            "enabled": feature_enabled(k),
            "message": feature_message(k),
        }
        for k, label in FEATURE_DEFS
    ]


def feature_premium(key: str) -> bool:
    """Bu bo'lim premium (pullik obuna) talab qiladimi."""
    return get_bool(f"feature_{key}_premium", False)


def features_public() -> dict:
    """Ilova uchun: {key: {enabled, message, premium}} ko'rinishida."""
    return {
        k: {
            "enabled": feature_enabled(k),
            "message": feature_message(k),
            "premium": feature_premium(k),
        }
        for k, _label in FEATURE_DEFS
    }


def premium_config() -> dict:
    """Premium obuna narxi va muddati."""
    try:
        price = float(get("premium_price", "0") or 0)
    except (TypeError, ValueError):
        price = 0.0
    try:
        days = int(get("premium_duration_days", "30") or 30)
    except (TypeError, ValueError):
        days = 30
    return {"price": price, "duration_days": days}


# ── Xizmat kategoriyalari flaglari (26 ta xizmat) ────────────────────────────

def category_enabled(cat_key: str) -> bool:
    return get_bool(f"cat_{cat_key}_enabled", True)


def category_message(cat_key: str) -> str:
    return get(f"cat_{cat_key}_msg", "") or DEFAULT_COMING_SOON


# ── Huquqiy hujjatlar (CMS: shartlar, maxfiylik, FAQ) ────────────────────────

LEGAL_DOCS = [
    ("terms", "Foydalanish shartlari"),
    ("privacy", "Maxfiylik siyosati"),
    ("faq", "Ko'p so'raladigan savollar (FAQ)"),
]

DEFAULT_LEGAL = {
    "terms": (
        "HubServis — Foydalanish shartlari\n\n"
        "1. Umumiy qoidalar\n"
        "HubServis turli xizmatlarни topshirish va buyurtma qilish uchun onlayn platforma. "
        "Ilovadan foydalanish orqali siz ushbu shartlarga rozilik bildirasiz.\n\n"
        "2. Platformaning roli\n"
        "HubServis mijozlar va mustaqil ustalar o'rtasidagi vositachi. Shartnoma mijoz va usta o'rtasida tuziladi.\n\n"
        "3. Foydalanuvchi majburiyatlari\n"
        "Haqiqiy ma'lumot kiriting, qonuniy maqsadда foydalaning, ustalar bilan hurmat bilan muomala qiling.\n\n"
        "4. To'lov va keshbek\n"
        "Narx usta bilan kelishiladi. Keshbek shartlari o'zgarishi mumkin.\n\n"
        "5. Mas'uliyat cheklovi\n"
        "HubServis xizmat natijasi uchun qonun ruxsat bergan darajада javobgar emas.\n\n"
        "6. Bog'lanish\n"
        "Savollar bo'lsa qo'llab-quvvatlash orqali murojaat qiling.\n\n"
        "(Ushbu matnни admin panelдан tahrirlashingiz mumkin.)"
    ),
    "privacy": (
        "HubServis — Maxfiylik siyosati\n\n"
        "Biz shaxsiy ma'lumotlaringizni (ism, telefon, manzil) faqat xizmat ko'rsatish maqsadida "
        "yig'amiz va saqlaymiz. Ma'lumotlaringiz qonun talab qilgan hollardan tashqari uchinchi "
        "shaxslarga berilmaydi. Hisobingizni istalgan vaqtда o'chirishingiz mumkin.\n\n"
        "(Ushbu matnни admin panelдан tahrirlashingiz mumkin.)"
    ),
    "faq": (
        "Ko'p so'raladigan savollar\n\n"
        "Savol: Buyurtmani qanday beraman?\n"
        "Javob: Kerakli xizmatни tanlab, ustani tanlang va vaqt/manzilни kiriting.\n\n"
        "(Ushbu matnни admin panelдан tahrirlashingiz mumkin.)"
    ),
}


def get_legal(doc: str) -> str:
    return get(f"legal_{doc}", "") or DEFAULT_LEGAL.get(doc, "")


def all_legal() -> dict:
    return {doc: get_legal(doc) for doc, _ in LEGAL_DOCS}
