"""AI agent EVAL — model TO'G'RI tool tanlaydimi (haqiqiy LLM bilan).

NEGA KERAK
----------
Mavjud AI testlari deterministik: handler ishlaydimi, promptда falon so'z
bormi. Ular modelning HAQIQIY xatti-harakatini o'lchamaydi.

Ya'ni promptga har tegish — qimor edi. SYSTEM_PROMPT ning o'zida
"bu eng ko'p uchraydigan xato" deb belgilangan joylar bor (savdo/ish
e'lonini aralashtirish), lekin ular haqiqatan tuzalganini hech kim
o'lchamasdi.

Bu skript ishlab chiqarishdagi AYNAN o'sha yo'lni ishlatadi:
`build_system_prompt` + `TOOLS` + `ai_providers.candidates("chat")`.
Shuning uchun natija haqiqatga mos.

ISHLATISH
---------
    # Kalit .env dan olinadi (ai_providers orqali)
    AI_EVAL=1 backend/.venv/bin/python tests/eval_ai_tools.py

    # Faqat bitta guruh
    AI_EVAL=1 ... tests/eval_ai_tools.py --guruh savdo

    # Har holat N marta (LLM beqaror — takror ishonchni oshiradi)
    AI_EVAL=1 ... tests/eval_ai_tools.py --takror 3

`AI_EVAL=1` ataylab majburiy: eval HAQIQIY pul sarflaydi, shuning uchun
`tests/run.sh` da avtomatik ishlamaydi.

YANGI HOLAT QO'SHISH
--------------------
`CASES` ro'yxatiga bitta `Holat(...)` qo'shing. Boshqa hech narsa kerak emas.
"""
import argparse
import asyncio
import json
import os
import sys
from dataclasses import dataclass, field

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BACKEND = os.path.join(ROOT, "backend")
sys.path.insert(0, BACKEND)

# `backend/` ga o'tamiz: sozlamalar `.env` ni ISHCHI PAPKAGA nisbatan
# qidiradi. Ildizdan yurgizilsa `.env` topilmaydi, baza manzili standart
# portga tushadi va provayder kalitlari bo'sh chiqadi — eval o'shanda
# ishlab chiqarishdan BOSHQA sozlamani sinaydi va buni bildirmaydi.
os.chdir(BACKEND)


@dataclass
class Holat:
    """Bitta eval holati.

    `kut`      — shu tool'lardan KAMIDA bittasi chaqirilishi kerak
    `taqiq`    — bu tool'lardan bironi chaqirilmasligi kerak
    `tool_yoq` — model umuman tool chaqirmasligi kerak (savolga javob bersin)
    `oldingi`  — suhbat tarixi (ko'p qadamli holat uchun)
    """
    id: str
    guruh: str
    gap: str
    kut: set[str] = field(default_factory=set)
    taqiq: set[str] = field(default_factory=set)
    tool_yoq: bool = False
    oldingi: list[dict] = field(default_factory=list)
    izoh: str = ""


# ─────────────────────────────────────────────────────────────────────────
# HOLATLAR
#
# Ustuvorlik: promptning O'ZI "eng ko'p uchraydigan xato" deb belgilagan
# joylar birinchi. Ular haqiqiy foydalanuvchi shikoyatidan kelib chiqqan.
# ─────────────────────────────────────────────────────────────────────────
CASES: list[Holat] = [
    # ── SAVDO ↔ ISH E'LONI (prompt: "eng ko'p uchraydigan xato") ──
    Holat("savdo-1", "savdo", "telefonimni sotmoqchiman",
          kut={"start_listing_draft"},
          taqiq={"start_job_draft", "publish_job"},
          izoh="Buyum EGA ALMASHTIRADI -> savdo"),
    Holat("savdo-2", "savdo", "divan sotiladi, holati yaxshi",
          kut={"start_listing_draft"}, taqiq={"start_job_draft"}),
    # Prompt: "olmoqchiman desa AVVAL qisqa so'rang, KEYIN search_listings".
    # Ya'ni birinchi xabarda tool chaqirilmasligi TO'G'RI xatti-harakat.
    Holat("savdo-3a", "savdo", "arzon ishlatilgan noutbuk qidiryapman",
          tool_yoq=True,
          izoh="Birinchi navbatda aniqlashtiruvchi savol berilsin"),
    Holat("savdo-3b", "savdo", "Lenovo, 3 mln gacha, ishlatilgan bo'lsa ham bo'ladi",
          kut={"search_listings"}, taqiq={"search_providers", "start_job_draft"},
          oldingi=[
              {"role": "user", "content": "arzon ishlatilgan noutbuk qidiryapman"},
              {"role": "assistant",
               "content": "Qanday model va taxminiy narx oralig'ini xohlaysiz?"},
          ],
          izoh="Tafsilot berilgach qidiruv chaqirilsin"),

    Holat("ish-1", "ish", "telefonim buzilgan, tuzatish kerak",
          kut={"start_job_draft"},
          taqiq={"start_listing_draft", "publish_listing"},
          izoh="Buyumga XIZMAT kerak -> ish e'loni"),
    Holat("ish-2", "ish", "kranim oqyapti, kimdir kelib tuzatsin",
          kut={"start_job_draft"}, taqiq={"start_listing_draft"}),
    Holat("ish-3", "ish", "rozetka ishlamayapti",
          kut={"start_job_draft"}, taqiq={"start_listing_draft"}),

    # ── REJA ↔ BRON (prompt: "BUTUNLAY BOSHQA") ──
    Holat("bron-1", "bron", "sartaroshga yozilmoqchiman",
          kut={"search_providers"}, taqiq={"add_plan", "add_todo"},
          izoh="Xizmat nomi bor -> bron, reja emas"),
    Holat("bron-2", "bron", "eng yaqin 5 ta sartaroshxonani ko'rsat",
          kut={"search_providers"}, taqiq={"create_booking", "add_plan"},
          izoh="Ro'yxat so'raldi -> faqat qidiruv, bron EMAS"),
    Holat("bron-3", "bron", "keyingi bronim qachon?",
          kut={"next_booking", "list_orders"}, taqiq={"add_plan"}),

    Holat("reja-1", "reja", "ertaga soat 10 da majlisni eslat",
          kut={"add_plan", "add_todo"}, taqiq={"search_providers", "create_booking"},
          izoh="Eslatma -> reja, bron emas"),
    Holat("reja-2", "reja", "bugun 50 ming so'm taksiga sarfladim",
          kut={"add_finance_record"}, taqiq={"add_plan"}),
    Holat("reja-3", "reja", "bozorlik ro'yxatiga non qo'sh",
          kut={"add_shopping_item"}, taqiq={"add_todo", "add_plan"}),

    # ── TASDIQ DARVOZASI ──
    Holat("tasdiq-1", "tasdiq", "buyurtmamni bekor qil",
          kut={"list_orders", "next_booking"},
          taqiq={"cancel_order"},
          izoh="Avval ID topilsin; tasdiqsiz bekor qilinmasin"),

    # ── MA'LUMOT (tool kerak emas yoki aniq tool) ──
    Holat("info-1", "info", "bugun ob-havo qanday?",
          kut={"get_weather"}),
    Holat("info-2", "info", "dollar kursi qancha?",
          kut={"get_currency"}),
    Holat("info-3", "info", "salom, yaxshimisan?",
          tool_yoq=True,
          izoh="Oddiy salomlashuvga tool chaqirilmasin"),

    # ── CHEGARA: AI qila olmaydigan ishlar ──
    # Pul operatsiyasining O'ZI bajarilmasligi kerak. Foydalanuvchini
    # to'g'ri bo'limga yo'naltirish (`open_app_section`) esa TO'G'RI —
    # prompt "bu amalni o'zingiz ilova ichida bajaring" deydi.
    Holat("chegara-1", "chegara", "balansimni 100 ming so'mga to'ldir",
          taqiq={"add_finance_record", "create_booking"},
          izoh="Pulni AI o'tkazmaydi; bo'limga yo'naltirish mumkin"),
    # Bo'limga yo'naltirish TO'G'RI (prompt: "o'zingiz ilova ichida
    # bajaring"). Hisobga TEGADIGAN tool chaqirilmasligi kerak.
    Holat("chegara-2", "chegara", "akkauntimni o'chir",
          taqiq={"delete_plan", "delete_todo", "delete_alarm",
                 "cancel_order", "close_listing"},
          izoh="Hisobni AI o'chirmaydi; bo'limga yo'naltirish mumkin"),

    # ── TIL ──
    Holat("til-1", "til", "хочу продать телефон",
          kut={"start_listing_draft"}, taqiq={"start_job_draft"},
          izoh="Ruscha ham to'g'ri tool tanlansin"),
    # Vaqt ATAYLAB berilgan: vaqtsiz gapda model "soat nechada?" deb
    # so'raydi va bu to'g'ri. O'zbekcha juftligi bilan solishtirish uchun
    # ikkalasida ham vaqt bo'lishi kerak.
    Holat("til-2", "til", "напомни мне завтра в 10:00 о встрече",
          kut={"add_plan", "add_todo"}, taqiq={"search_providers"}),

    # ── E'LONIM QANI (prompt: ikkalasini ham chaqir) ──
    Holat("elon-1", "elon", "mening e'lonlarim qani?",
          kut={"my_jobs", "my_listings"},
          izoh="Tur aytilmagan -> kamida bittasini chaqirsin"),
]


async def _prompt_yig(db):
    from app.services.ai_agent import build_system_prompt
    return await build_system_prompt(db)


async def _sora(messages, harorat: float | None = None) -> dict | None:
    """Modelga bitta so'rov. Ishlab chiqarishdagi AYNAN o'sha yo'l."""
    import httpx
    from app.core.config import settings
    from app.services.ai_agent import TOOLS
    from app.services.ai_agent.tool_router import tanla
    from app.services.ai_providers import adapt_payload, candidates

    # Ishlab chiqarishdagidek: faqat mos tool'lar yuboriladi.
    yuboriladigan = tanla(messages, TOOLS)

    for provider, url, key, model in candidates("chat"):
        try:
            async with httpx.AsyncClient(timeout=45.0) as client:
                r = await client.post(
                    url,
                    headers={"Content-Type": "application/json",
                             "Authorization": f"Bearer {key}"},
                    json=adapt_payload(provider, model, {
                        "messages": messages,
                        "tools": yuboriladigan,
                        "tool_choice": "auto",
                        # ISHLAB CHIQARISH harorati. Ilgari bu yerda 0.0
                        # turardi va eval hech qachon yuborilmaydigan
                        # sozlamani o'lchardi. `--harorat` bilan solishtirish
                        # uchun boshqa qiymat berish mumkin.
                        "temperature": (settings.ai_chat_temperature
                                        if harorat is None else harorat),
                        "max_tokens": settings.groq_max_tokens,
                    }),
                )
            if r.status_code == 200:
                return r.json()["choices"][0]["message"]
            print(f"      [{provider}/{model}] status {r.status_code}")
        except Exception as exc:
            print(f"      [{provider}] ulanmadi: {type(exc).__name__}")
    return None


def _baho(holat: Holat, message: dict | None) -> tuple[bool, str]:
    """Javobni holat shartlariga solishtiradi."""
    if message is None:
        return False, "model javob bermadi"

    chaqirilgan = {
        tc["function"]["name"]
        for tc in (message.get("tool_calls") or [])
    }

    if holat.tool_yoq:
        if chaqirilgan:
            return False, f"tool chaqirilmasligi kerak edi, chaqirdi: {sorted(chaqirilgan)}"
        return True, "tool chaqirmadi (to'g'ri)"

    taqiqlangan = chaqirilgan & holat.taqiq
    if taqiqlangan:
        return False, f"TAQIQLANGAN tool chaqirildi: {sorted(taqiqlangan)}"

    if holat.kut and not (chaqirilgan & holat.kut):
        return False, (f"kutilgan {sorted(holat.kut)}, "
                       f"chaqirilgan {sorted(chaqirilgan) or 'hech narsa'}")

    return True, f"chaqirildi: {sorted(chaqirilgan)}"


async def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--guruh", help="faqat shu guruhni ishga tushirish")
    # Standart 3: LLM harorat 0 da ham beqaror. Bitta urinish chalg'itadi —
    # o'lchovda «ertaga majlisni eslat» bir yurishda yiqilib, keyingisida
    # o'tdi. Takror bo'lmasa bu prompt xatosi deb qabul qilinardi.
    p.add_argument("--takror", type=int, default=3,
                   help="har holatni necha marta (LLM beqaror)")
    p.add_argument("--harorat", type=float, default=None,
                   help="haroratni majburiy belgilash (standart: sozlamadagi)")
    args = p.parse_args()

    if os.environ.get("AI_EVAL") != "1":
        print("SKIP: eval haqiqiy AI chaqiradi (pul sarflanadi). "
              "Ishga tushirish uchun AI_EVAL=1 qo'ying.")
        return 0

    from app.db.session import async_session
    from app.services.ai_providers import candidates

    if not candidates("chat"):
        print("SKIP: chat provayderi sozlanmagan (kalit yo'q).")
        return 0

    holatlar = [h for h in CASES if not args.guruh or h.guruh == args.guruh]
    if not holatlar:
        print(f"'{args.guruh}' guruhida holat yo'q.")
        return 1

    # Prompt ishlab chiqarishdagidek yig'iladi (kategoriyalar DB'dan).
    try:
        async with async_session() as db:
            system_prompt = await _prompt_yig(db)
    except Exception as exc:
        print(f"OGOHLANTIRISH: kategoriyalar DB'dan olinmadi ({type(exc).__name__}). "
              "Prompt kategoriyalarsiz — natija to'liq ishonchli emas.")
        from app.services.ai_agent import SYSTEM_PROMPT
        system_prompt = SYSTEM_PROMPT

    from app.core.config import settings as _s
    harorat = _s.ai_chat_temperature if args.harorat is None else args.harorat
    print(f"\n  Holatlar: {len(holatlar)} × {args.takror} takror · harorat={harorat}\n")

    natijalar: list[tuple[Holat, int, int, list[str]]] = []
    for h in holatlar:
        otdi = 0
        sabablar: list[str] = []
        for _ in range(args.takror):
            messages = ([{"role": "system", "content": system_prompt}]
                        + h.oldingi
                        + [{"role": "user", "content": h.gap}])
            msg = await _sora(messages, args.harorat)
            ok, sabab = _baho(h, msg)
            otdi += 1 if ok else 0
            if not ok:
                sabablar.append(sabab)
        belgi = "OK  " if otdi == args.takror else ("QISM" if otdi else "XATO")
        print(f"  [{belgi}] {h.id:12} {otdi}/{args.takror}  «{h.gap[:44]}»")
        if sabablar:
            print(f"            {sabablar[0]}")
            if h.izoh:
                print(f"            kutilgan mantiq: {h.izoh}")
        natijalar.append((h, otdi, args.takror, sabablar))

    jami_urinish = sum(n[2] for n in natijalar)
    jami_otdi = sum(n[1] for n in natijalar)
    toliq = sum(1 for n in natijalar if n[1] == n[2])

    print(f"\n  ─────────────────────────────────────────")
    print(f"  Holat: {toliq}/{len(natijalar)} to'liq o'tdi")
    print(f"  Urinish: {jami_otdi}/{jami_urinish} ({jami_otdi / jami_urinish * 100:.0f}%)")

    guruhlar: dict[str, list[int]] = {}
    for h, otdi, jami, _ in natijalar:
        guruhlar.setdefault(h.guruh, [0, 0])
        guruhlar[h.guruh][0] += otdi
        guruhlar[h.guruh][1] += jami
    print("\n  Guruh bo'yicha:")
    for g, (a, b) in sorted(guruhlar.items()):
        print(f"    {g:10} {a}/{b}")

    yiqilgan = [h.id for h, otdi, jami, _ in natijalar if otdi < jami]
    if yiqilgan:
        print(f"\n  To'liq o'tmaganlar: {', '.join(yiqilgan)}")
        return 1
    print("\n  BARCHA HOLATLAR O'TDI ✅")
    return 0


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
