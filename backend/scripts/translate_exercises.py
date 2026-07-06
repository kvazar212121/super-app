"""
Exercises datasetdagi mashq nomlari va ko'rsatmalarini o'zbekchaga tarjima qilish.

Bir martalik, davom ettiriladigan (resumable) skript:
- app/data/exercises.json dan inglizcha nom + qadamlarni oladi;
- Groq text-modeli bilan 15 tadan batch qilib tarjima qiladi;
- har batch'dan keyin app/data/exercises_uz.json ga yozadi (crash-safe);
- qayta ishga tushirilsa, tarjima qilinganlarini o'tkazib yuboradi.

Ishga tushirish (backend/ papkasidan, GROQ_API_KEY .env da bo'lishi kerak):
    python scripts/translate_exercises.py
"""
import json
import os
import sys
import time
from pathlib import Path

import httpx

BACKEND_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BACKEND_ROOT))
os.chdir(BACKEND_ROOT)  # .env fayli topilishi uchun

from app.core.config import settings  # noqa: E402

DATA_DIR = BACKEND_ROOT / "app" / "data"
SOURCE_FILE = DATA_DIR / "exercises.json"
OUTPUT_FILE = DATA_DIR / "exercises_uz.json"

BATCH_SIZE = 15
MAX_RETRIES = 5

SYSTEM_PROMPT = """Siz professional fitnes tarjimonisiz. Inglizcha mashq nomlari va bajarish
ko'rsatmalarini o'zbek tiliga (lotin alifbosida) tarjima qilasiz.

QOIDALAR:
- Har bir qadamni alohida, buyruq ohangida tarjima qiling ("Yotib oling", "Ko'taring").
- Qadamlar soni va tartibi aynan saqlanishi SHART.
- Mashq nomlarida umum qabul qilingan atamalarni saqlang (masalan: "squat" -> "prisedaniya emas, cho'kka o'tirish"; "plank" -> "plank").
- FAQAT JSON qaytaring, boshqa matn yozmang.

JAVOB FORMATI (JSON):
{"items": [{"id": "0001", "name_uz": "...", "instructions_uz": ["...", "..."]}]}"""


def _resolve_provider() -> tuple[str, str, str]:
    """TRANSLATE_PROVIDER ga qarab (api_url, api_key, model) qaytaradi (OpenAI-mos format)."""
    provider = (settings.translate_provider or "groq").strip().lower()
    if provider == "openai":
        return (
            "https://api.openai.com/v1/chat/completions",
            settings.openai_api_key,
            settings.openai_translate_model,
        )
    return (
        "https://api.groq.com/openai/v1/chat/completions",
        settings.groq_api_key,
        settings.groq_translate_model,
    )


def call_groq(batch: list[dict]) -> dict:
    api_url, api_key, model = _resolve_provider()
    payload = [
        {"id": e["id"], "name": e["name"], "steps": e["steps"]}
        for e in batch
    ]
    user_msg = (
        "Quyidagi mashqlarni o'zbekchaga tarjima qiling. JSON formatda javob bering:\n"
        + json.dumps(payload, ensure_ascii=False)
    )

    for attempt in range(MAX_RETRIES):
        try:
            response = httpx.post(
                api_url,
                headers={
                    "Content-Type": "application/json",
                    "Authorization": f"Bearer {api_key}",
                },
                json={
                    "model": model,
                    "messages": [
                        {"role": "system", "content": SYSTEM_PROMPT},
                        {"role": "user", "content": user_msg},
                    ],
                    "response_format": {"type": "json_object"},
                    "temperature": 0.2,
                    "max_tokens": 8000,
                },
                timeout=120.0,
            )
        except httpx.HTTPError as exc:
            print(f"  Tarmoq xatosi: {exc}, {2 ** attempt}s kutilmoqda...")
            time.sleep(2 ** attempt)
            continue

        if response.status_code == 429:
            wait = min(60, 5 * (2 ** attempt))
            print(f"  Rate limit (429), {wait}s kutilmoqda...")
            time.sleep(wait)
            continue

        if response.status_code != 200:
            print(f"  Groq xatosi {response.status_code}: {response.text[:200]}")
            time.sleep(2 ** attempt)
            continue

        try:
            content = response.json()["choices"][0]["message"]["content"]
            return json.loads(content)
        except (KeyError, IndexError, json.JSONDecodeError) as exc:
            print(f"  JSON o'qib bo'lmadi: {exc}, qayta urinish...")
            time.sleep(2)

    return {}


def validate_item(item: dict, source: dict) -> bool:
    """Tarjima natijasi to'g'ri formatda va qadamlar soni mos ekanini tekshirish."""
    if not isinstance(item.get("name_uz"), str) or not item["name_uz"].strip():
        return False
    steps = item.get("instructions_uz")
    if not isinstance(steps, list) or not all(isinstance(s, str) for s in steps):
        return False
    # Qadamlar soni ±1 farqgacha qabul qilinadi (ba'zan model qo'shib/birlashtirib yuboradi)
    return abs(len(steps) - len(source["steps"])) <= 1


def main():
    api_url, api_key, model = _resolve_provider()
    if not api_key:
        print(f"XATO: {settings.translate_provider} uchun API kalit .env faylida topilmadi.")
        sys.exit(1)
    print(f"Provayder: {settings.translate_provider}, model: {model}")

    source = json.loads(SOURCE_FILE.read_text(encoding="utf-8"))
    exercises = [
        {"id": e["id"], "name": e["name"], "steps": (e.get("instruction_steps") or {}).get("en") or []}
        for e in source
    ]

    done: dict[str, dict] = {}
    if OUTPUT_FILE.exists():
        done = json.loads(OUTPUT_FILE.read_text(encoding="utf-8"))
        print(f"Davom ettirilmoqda: {len(done)} ta allaqachon tarjima qilingan.")

    remaining = [e for e in exercises if e["id"] not in done]
    print(f"Jami: {len(exercises)}, qolgan: {len(remaining)}")

    by_id = {e["id"]: e for e in exercises}

    for batch_start in range(0, len(remaining), BATCH_SIZE):
        batch = remaining[batch_start : batch_start + BATCH_SIZE]
        batch_no = batch_start // BATCH_SIZE + 1
        total_batches = (len(remaining) + BATCH_SIZE - 1) // BATCH_SIZE
        print(f"Batch {batch_no}/{total_batches} ({batch[0]['id']}..{batch[-1]['id']})...")

        result = call_groq(batch)
        items = result.get("items") or []
        got_ids = set()

        for item in items:
            item_id = str(item.get("id", ""))
            if item_id in by_id and validate_item(item, by_id[item_id]):
                done[item_id] = {
                    "name_uz": item["name_uz"].strip(),
                    "instructions_uz": [s.strip() for s in item["instructions_uz"]],
                }
                got_ids.add(item_id)

        # Batch'da tushib qolganlar — bitta-bitta qayta so'raladi
        missing = [e for e in batch if e["id"] not in got_ids]
        for e in missing:
            print(f"  Alohida qayta: {e['id']} ({e['name']})")
            single = call_groq([e])
            for item in single.get("items") or []:
                if str(item.get("id")) == e["id"] and validate_item(item, e):
                    done[e["id"]] = {
                        "name_uz": item["name_uz"].strip(),
                        "instructions_uz": [s.strip() for s in item["instructions_uz"]],
                    }

        OUTPUT_FILE.write_text(
            json.dumps(done, ensure_ascii=False, indent=1), encoding="utf-8"
        )
        print(f"  Saqlandi: jami {len(done)}/{len(exercises)}")

    failed = [e["id"] for e in exercises if e["id"] not in done]
    if failed:
        print(f"Tarjima qilinmaganlar ({len(failed)}): {failed[:20]}...")
        print("Skriptni qayta ishga tushiring — faqat shulari qayta so'raladi.")
    else:
        print("Hammasi tayyor! Endi: python -m app.seed_exercises")


if __name__ == "__main__":
    main()
