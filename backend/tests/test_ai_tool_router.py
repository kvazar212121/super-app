"""Tool router: qaysi tool'lar modelga yuborilishini tekshiradi.

Deterministik — AI chaqirilmaydi, pul sarflanmaydi.

ENG MUHIM QOIDA: ikkilanish bo'lsa TO'LIQ ro'yxat yuborilishi kerak.
Noto'g'ri guruh tanlansa agent vazifani UMUMAN bajara olmaydi va
foydalanuvchi sababini tushunmaydi — ortiqcha token bundan arzon.
"""
import os
import sys

os.environ.setdefault("DATABASE_URL", "postgresql+asyncpg://u:p@localhost/db")
os.environ.setdefault("DATABASE_SYNC_URL", "postgresql+psycopg2://u:p@localhost/db")

from app.services.ai_agent import TOOLS  # noqa: E402
from app.services.ai_agent.tool_router import CORE, GROUPS, tanla  # noqa: E402

xato = 0


def check(nom: str, shart: bool, sabab: str = "") -> None:
    global xato
    if shart:
        print(f"  ✓ {nom}")
    else:
        xato += 1
        print(f"  ✗ {nom}" + (f" — {sabab}" if sabab else ""))


def nomlar(tools) -> set[str]:
    return {t["function"]["name"] for t in tools}


def gap(matn: str):
    return tanla([{"role": "user", "content": matn}], TOOLS)


def main() -> int:
    barcha = nomlar(TOOLS)

    print("\n=== Guruhlar to'g'ri e'lon qilinganmi ===")
    e_lon = set(CORE)
    for g, ts in GROUPS.items():
        e_lon |= ts
    yoq = e_lon - barcha
    check("router faqat MAVJUD tool nomlarini biladi", not yoq,
          f"mavjud emas: {sorted(yoq)}")

    kesishgan = []
    guruhlar = list(GROUPS.items())
    for i, (g1, t1) in enumerate(guruhlar):
        for g2, t2 in guruhlar[i + 1:]:
            if t1 & t2:
                kesishgan.append((g1, g2, sorted(t1 & t2)))
    check("guruhlar kesishmaydi", not kesishgan, str(kesishgan))

    print("\n=== Aniq niyat -> kerakli tool bor ===")
    holatlar = [
        ("telefonimni sotmoqchiman", "start_listing_draft"),
        ("kranim oqyapti, tuzatish kerak", "start_job_draft"),
        ("sartaroshga yozilmoqchiman", "search_providers"),
        ("ertaga majlisni eslat", "add_plan"),
        ("ob-havo qanday", "get_weather"),
        ("хочу продать телефон", "start_listing_draft"),
        ("напомни мне завтра о встрече", "add_plan"),
    ]
    for matn, kerak in holatlar:
        n = nomlar(gap(matn))
        check(f"«{matn[:34]}» -> {kerak}", kerak in n,
              f"yuborilgan: {len(n)} tool, {kerak} YO'Q")

    print("\n=== Ikkilanish -> TO'LIQ ro'yxat ===")
    for matn in ["salom", "rahmat", "yaxshimisan", ""]:
        n = nomlar(gap(matn))
        korinish = matn or "(bo'sh)"
        check(f"«{korinish}» -> to'liq", n == barcha,
              f"{len(n)}/{len(barcha)} tool yuborildi")

    # Ikki guruh kalit so'zi bir vaqtda uchrasa ham ikkilanish
    n = nomlar(gap("telefonimni sotmoqchiman, yana ob-havo qanday?"))
    check("ikki guruh da'vo qilsa -> to'liq", n == barcha,
          f"{len(n)}/{len(barcha)}")

    print("\n=== Boshlangan suhbat guruhi saqlanadi ===")
    # Qoralama yig'ilyapti: keyingi xabarda kalit so'z bo'lmasa ham
    # savdo tool'lari YO'QOLMASLIGI kerak.
    suhbat = [
        {"role": "user", "content": "telefonimni sotmoqchiman"},
        {"role": "assistant", "content": None,
         "tool_calls": [{"id": "1", "type": "function",
                         "function": {"name": "start_listing_draft", "arguments": "{}"}}]},
        {"role": "tool", "tool_call_id": "1", "name": "start_listing_draft",
         "content": "{}"},
        {"role": "user", "content": "3 million"},
    ]
    n = nomlar(tanla(suhbat, TOOLS))
    check("qoralama davom etsa savdo tool'lari qoladi",
          "update_listing_draft" in n and "publish_listing" in n,
          f"yuborilgan: {sorted(n)}")

    print("\n=== Xavfsizlik ===")
    check("hech qachon BO'SH ro'yxat qaytmaydi",
          all(len(gap(m)) > 0 for m in ["salom", "sotmoqchiman", "", "asdfgh"]))
    n = nomlar(gap("telefonimni sotmoqchiman"))
    check("CORE har doim bor", CORE <= n, f"yetishmaydi: {sorted(CORE - n)}")

    print("\n=== Qisqarish haqiqatan bormi ===")
    kichik = len(nomlar(gap("ob-havo qanday")))
    check("aniq niyatda ro'yxat qisqaradi", kichik < len(barcha),
          f"{kichik} vs {len(barcha)}")

    print()
    if xato:
        print(f"YIQILDI: {xato} ta tekshiruv o'tmadi")
        return 1
    print("BARCHA TEKSHIRUVLAR O'TDI ✅")
    return 0


if __name__ == "__main__":
    sys.exit(main())
