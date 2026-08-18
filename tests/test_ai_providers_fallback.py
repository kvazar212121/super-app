"""AI provayderlar: ZAXIRA zanjiri va adminkadan boshqarish.

HAQIQIY MUAMMO: Gemini "high demand" (503) berdi va kaloriya
hisoblagich butunlay ishlamay qoldi — foydalanuvchi "rasm tahlili
ishlamayapti" dedi. Bitta provayderga bog'lanib qolish ko'p
obunachili tizimda qabul qilib bo'lmaydi.

Bu yerda tekshiriladi:
  • band provayderdan keyingisiga avtomatik o'tish
  • kalitni adminkadan berish (server qayta ishga tushmasdan)
  • rasmni ko'ra olmaydigan provayder (DeepSeek) vision'ga tushmasligi
  • hammasi ishlamaganda tushunarli xato
"""
import asyncio
import os
import sys

PROJ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(PROJ, "backend"))

# Bu test BAZAGA murojaat qilmaydi (faqat provayder mantig'i), lekin
# import zanjiri engine yaratadi.
import tempfile

_tmp = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
_tmp.close()
os.environ.setdefault("DATABASE_URL", f"sqlite+aiosqlite:///{_tmp.name}")
os.environ.setdefault("DATABASE_SYNC_URL", f"sqlite:///{_tmp.name}")
os.environ["REQUIRE_OTP_AUTH"] = "false"
# Har provayderga soxta kalit: tanlash mantig'i sinaladi, tarmoqqa
# chiqilmaydi (so'rov o'rniga soxta mijoz qo'yiladi).
os.environ.setdefault("GEMINI_API_KEY", "test-gemini")
os.environ.setdefault("OPENAI_API_KEY", "test-openai")
os.environ.setdefault("GROQ_API_KEY", "test-groq")
os.environ.setdefault("DEEPSEEK_API_KEY", "test-deepseek")

ok, fail = [], []


def check(name, cond, detail=""):
    (ok if cond else fail).append(f"{name}{'' if cond else ': ' + detail}")


class SoxtaJavob:
    """httpx.Response o'rnini bosadi."""

    def __init__(self, status_code, data=None, text=""):
        self.status_code = status_code
        self._data = data or {}
        self.text = text or str(data)

    def json(self):
        return self._data


class SoxtaMijoz:
    """httpx.AsyncClient o'rnini bosadi: URL bo'yicha javob beradi."""

    javoblar: dict = {}
    chaqiruvlar: list = []

    def __init__(self, *a, **kw):
        pass

    async def __aenter__(self):
        return self

    async def __aexit__(self, *a):
        return False

    async def post(self, url, headers=None, json=None, **kw):
        SoxtaMijoz.chaqiruvlar.append({"url": url, "model": (json or {}).get("model")})
        for bolak, javob in SoxtaMijoz.javoblar.items():
            if bolak in url:
                if isinstance(javob, Exception):
                    raise javob
                return javob
        return SoxtaJavob(200, {"choices": [{"message": {"content": "{}"}}]})


async def main():
    import httpx

    from app.services import ai_providers as ap

    asl_client = httpx.AsyncClient

    def tozala():
        SoxtaMijoz.javoblar = {}
        SoxtaMijoz.chaqiruvlar = []
        ap._cooldown.clear()

    # ── 1. Tartib va vision qo'llab-quvvatlash ───────────────────────
    tozala()
    vision = [c[0] for c in ap.candidates("vision")]
    chat = [c[0] for c in ap.candidates("chat")]
    check("vision uchun provayderlar bor", len(vision) >= 2, f"{vision}")
    check("chat uchun provayderlar bor", len(chat) >= 2, f"{chat}")
    check("DeepSeek rasm tahliliga TUSHMAYDI (vision yo'q)",
          "deepseek" not in vision, f"{vision}")
    check("DeepSeek matn uchun ishlatiladi", "deepseek" in chat, f"{chat}")
    check("har nomzodda model nomi bor",
          all(c[3] for c in ap.candidates("vision")),
          f"{ap.candidates('vision')}")

    # ── 2. Band provayderdan KEYINGISIGA o'tish ──────────────────────
    # Aynan chiqarishda bo'lgan holat: Gemini 503 "high demand".
    tozala()
    # Tartibni ANIQ belgilaymiz: `.env` dagi `vision_provider` muhitga
    # qarab har xil bo'lishi mumkin, test esa barqaror bo'lishi kerak.
    from app.services import settings_service as _ss

    _asl_get = _ss.get

    def _tartib_get(kalit, standart=None):
        if kalit == "ai_vision_provider":
            return "gemini"
        if kalit == "ai_vision_order":
            return "gemini,openai"
        return _asl_get(kalit, standart)

    _ss.get = _tartib_get
    httpx.AsyncClient = SoxtaMijoz
    try:
        SoxtaMijoz.javoblar = {
            "generativelanguage.googleapis.com": SoxtaJavob(
                503, text='{"error":{"message":"high demand"}}'
            ),
            "api.openai.com": SoxtaJavob(
                200, {"choices": [{"message": {"content": '{"ok":true}'}}]}
            ),
        }
        javob, provider, model = await ap.call_with_fallback(
            "vision", lambda m: {"model": m}
        )
        check("Gemini band bo'lsa zaxira ishlaydi", provider == "openai",
              f"{provider}")
        check("zaxira javobi qaytadi",
              javob["choices"][0]["message"]["content"] == '{"ok":true}',
              f"{javob}")
        check("ikkala provayder ham urinib ko'rildi",
              len(SoxtaMijoz.chaqiruvlar) == 2,
              f"{SoxtaMijoz.chaqiruvlar}")
        check("har provayder O'Z modeli bilan chaqirildi",
              SoxtaMijoz.chaqiruvlar[0]["model"]
              != SoxtaMijoz.chaqiruvlar[1]["model"],
              f"{SoxtaMijoz.chaqiruvlar}")

        # ── 3. Yiqilgan provayder bir muddat chetlab o'tiladi ────────
        check("band provayder cooldown'ga tushdi",
              ap._is_cooling("gemini"), "cooldown yo'q")
        keyingi = [c[0] for c in ap.candidates("vision")]
        check("cooldown'dagi provayder OXIRIGA suriladi",
              keyingi and keyingi[0] != "gemini", f"{keyingi}")
        check("lekin butunlay tashlab yuborilmaydi",
              "gemini" in keyingi, f"{keyingi}")

        # ── 4. Tarmoq uzilsa ham keyingisiga o'tadi ──────────────────
        tozala()
        SoxtaMijoz.javoblar = {
            "generativelanguage.googleapis.com": httpx.ConnectError("tarmoq yo'q"),
            "api.openai.com": SoxtaJavob(
                200, {"choices": [{"message": {"content": "ok"}}]}
            ),
        }
        _, provider, _ = await ap.call_with_fallback(
            "vision", lambda m: {"model": m}
        )
        check("tarmoq xatosida ham zaxiraga o'tiladi", provider == "openai",
              f"{provider}")

        # ── 5. HAMMASI ishlamasa tushunarli xato ─────────────────────
        tozala()
        SoxtaMijoz.javoblar = {"http": SoxtaJavob(503, text="band")}
        xato = None
        try:
            await ap.call_with_fallback("vision", lambda m: {"model": m})
        except RuntimeError as exc:
            xato = str(exc)
        check("hammasi band bo'lsa aniq xato beriladi",
              xato is not None and "javob bermadi" in xato, f"{xato}")
    finally:
        httpx.AsyncClient = asl_client
        _ss.get = _asl_get
        tozala()

    # ── 6. Adminka kaliti `.env` dan USTUN turadi ────────────────────
    from app.services import settings_service

    asl_get = settings_service.get

    def soxta_get(kalit, standart=None):
        if kalit == "ai_key_openai":
            return "admin-kiritgan-kalit"
        if kalit == "ai_vision_provider":
            return "openai"
        if kalit == "ai_vision_openai_model":
            return "gpt-4o-mini-admin"
        return asl_get(kalit, standart)

    settings_service.get = soxta_get
    try:
        check("adminka kaliti env'dan ustun",
              ap.api_key("openai") == "admin-kiritgan-kalit",
              f"{ap.api_key('openai')}")
        check("adminka modeli qo'llanadi",
              ap.model_for("vision", "openai") == "gpt-4o-mini-admin",
              f"{ap.model_for('vision', 'openai')}")
        check("adminka asosiy provayderi birinchi turadi",
              ap.provider_order("vision")[0] == "openai",
              f"{ap.provider_order('vision')}")
    finally:
        settings_service.get = asl_get

    # ── 7. Admin ko'rinishi: kalit YASHIRILADI ───────────────────────
    korinish = ap.admin_view("vision")
    check("admin ko'rinishida provayderlar bor",
          len(korinish["providers"]) == 4, f"{korinish}")
    for p in korinish["providers"]:
        check(f"'{p['key']}' kaliti to'liq ko'rsatilmaydi",
              "test-" not in (p.get("key_preview") or ""),
              f"{p.get('key_preview')}")
    check("qaysi provayder rasmni ko'rishi belgilangan",
          any(p["supports_vision"] for p in korinish["providers"]),
          "belgilanmagan")

    # ── 8. Kod hech qayerda provayderni QOTIRIB yozmagan ─────────────
    for yol, nom in [
        ("backend/app/services/vision_service.py", "kaloriya vision"),
        ("backend/app/services/ai_job/vision.py", "ish e'loni vision"),
        ("backend/app/api/v1/ai_chat.py", "AI chat"),
    ]:
        src = open(os.path.join(PROJ, yol)).read()
        check(f"{nom} zaxira zanjiridan foydalanadi",
              "ai_providers" in src, "eski usul qolgan")

    print()
    for x in ok:
        print("  ✓", x)
    if fail:
        print(f"\nYIQILDI ({len(fail)}):")
        for x in fail:
            print("  ✗", x)
        sys.exit(1)
    print(f"\nOK: {len(ok)} ta tekshiruv o'tdi")


asyncio.run(main())
