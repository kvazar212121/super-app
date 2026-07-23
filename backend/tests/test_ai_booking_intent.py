"""AI agent tool-tanlash yo'riqnomasi testi (deterministik, API'siz).

Real LLM chaqirmaydi — SYSTEM_PROMPT va tool tavsiflarида "bron" va "reja"
farqi aniq ko'rsatilganini tekshiradi. Maqsad: kelajakда kimdir promptни
buzsa (bron -> reja adashuvi qaytsa) test yiqiladi.
"""
import os
os.environ.setdefault('DATABASE_URL', 'postgresql+asyncpg://u:p@localhost/db')
os.environ.setdefault('DATABASE_SYNC_URL', 'postgresql+psycopg2://u:p@localhost/db')

from app.services.ai_agent import SYSTEM_PROMPT, TOOLS


def _tool(name):
    for t in TOOLS:
        if t["function"]["name"] == name:
            return t["function"]
    raise AssertionError(f"tool topilmadi: {name}")


def main():
    # ===== 1. Kerakli booking toollar mavjud =====
    sp = _tool("search_providers")
    cb = _tool("create_booking")
    ap = _tool("add_plan")
    print("OK 1: search_providers, create_booking, add_plan mavjud")

    # ===== 2. search_providers tavsifи 'bron' bilan bog'langan =====
    sp_desc = sp["description"].lower()
    assert "bron" in sp_desc, "FAIL: search_providers tavsifида 'bron' yo'q"
    assert "band qil" in sp_desc or "buyurtma" in sp_desc, "FAIL: bron sinonimlari yo'q"
    print("OK 2: search_providers tavsifи bron/band qil/buyurtma bilan bog'langan")

    # ===== 3. add_plan tavsifи BRON EMASligini aniq ko'rsatadi =====
    ap_desc = ap["description"].lower()
    assert "bron" in ap_desc, "FAIL: add_plan bronдан farqini aytmagan"
    assert "search_providers" in ap_desc or "create_booking" in ap_desc, \
        "FAIL: add_plan bron uchun to'g'ri toolга yo'naltirmagan"
    # aniq inkor: 'emas' so'zи bo'lishi kerak (add_plan EMAS)
    assert "emas" in ap_desc, "FAIL: add_plan 'bu bron EMAS' chegarasини qo'ymagan"
    print("OK 3: add_plan tavsifи 'sartarosh bron -> add_plan EMAS' chegarasiga ega")

    # ===== 4. SYSTEM_PROMPT REJA vs BRON farqини aniq tushuntiradi =====
    sp_prompt = SYSTEM_PROMPT.lower()
    assert "reja" in sp_prompt and "bron" in sp_prompt, "FAIL: prompt reja/bron so'zlari yo'q"
    # add_plan ISHLATMANG kabi qat'iy ko'rsatma
    assert "add_plan" in SYSTEM_PROMPT, "FAIL: promptда add_plan nomi yo'q"
    assert "ishlatmang" in sp_prompt or "emas" in sp_prompt, \
        "FAIL: promptда bron uchun add_plan taqiqи yo'q"
    print("OK 4: SYSTEM_PROMPT reja vs bron farqини qat'iy tushuntiradi")

    # ===== 5. create_booking to'g'ri ketma-ketlikни ko'rsatadi =====
    cb_desc = cb["description"].lower()
    assert "search_providers" in cb_desc, "FAIL: create_booking search_providers'дан keyinligini aytmagan"
    print("OK 5: create_booking search_providers'дан keyin chaqirilishi ko'rsatilgan")

    # ===== 6. Xizmat nomlari ikkala joyда ham bor (sartarosh) =====
    assert "sartarosh" in sp_desc, "FAIL: search_providers sartaroshни eslatmagan"
    assert "sartarosh" in ap_desc, "FAIL: add_plan sartaroshни misol qilmagan"
    print("OK 6: 'sartarosh' misoli ikkala tavsifда ham bor")

    print("\n=== BARCHA AI YO'RIQNOMA TESTLARI MUVAFFAQIYATLI ===")


if __name__ == "__main__":
    main()
