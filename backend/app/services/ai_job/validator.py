"""E'lon uchun ma'lumot yetarlimi va yetishmasa qaysi savolni berish.

Foydalanuvchi talabi: "ai chatdan olib kamchiligi bo'lsa ai so'rab
e'lon buyurtma qilib yuboradi".

Savollar IKKI TILDA, chunki foydalanuvchi rus tilida yozsa AI ham
rus tilida gapirishi kerak.
"""
from .draft import JobDraft

# Majburiy maydonlar. Tartib MUHIM: savollar shu ketma-ketlikda
# beriladi, ya'ni avval "nima ish", keyin "qayerda", keyin "qachon".
# Bir vaqtda 5 ta savol berish foydalanuvchini charchatadi.
REQUIRED = ("category_id", "title", "description", "address")

QUESTIONS_UZ = {
    "category_id": "Bu qanday ish? Masalan: elektrik, santexnik, "
                   "usta, tozalash.",
    "title": "Ishni qisqa nomlab bering. Masalan: «Rozetka almashtirish».",
    "description": "Muammoni biroz batafsil ayting — usta nima "
                   "kerakligini bilishi kerak.",
    "address": "Qayerga kelishsin? Manzilni yozing.",
}

QUESTIONS_RU = {
    "category_id": "Какая это работа? Например: электрик, сантехник, "
                   "мастер, уборка.",
    "title": "Коротко назовите работу. Например: «Замена розетки».",
    "description": "Опишите проблему подробнее — мастеру нужно знать, "
                   "что требуется.",
    "address": "Куда приехать? Напишите адрес.",
}

# Sana MAJBURIY EMAS: foydalanuvchi "imkon boricha tezroq" deyishi
# mumkin. Summa ham majburiy emas — "narxni ustalar aytsin" holati.


def missing_fields(draft: JobDraft) -> list[str]:
    """Yetishmayotgan majburiy maydonlar ro'yxati (tartib bo'yicha)."""
    missing = []
    for name in REQUIRED:
        value = getattr(draft, name, None)
        if value is None:
            missing.append(name)
            continue
        # Bo'sh yoki juda qisqa matn — yo'q bilan barobar.
        # JobCreate: title min_length=3, description min_length=5,
        # address min_length=3. Shu chegaralarga moslaymiz, aks holda
        # AI e'lon yaratmoqchi bo'lib 422 oladi.
        if isinstance(value, str):
            text = value.strip()
            limit = 5 if name == "description" else 3
            if len(text) < limit:
                missing.append(name)
    return missing


def next_question(draft: JobDraft, lang: str = "uz") -> str | None:
    """Keyingi so'raladigan savol. Hammasi to'liq bo'lsa None."""
    missing = missing_fields(draft)
    if not missing:
        return None
    questions = QUESTIONS_RU if lang == "ru" else QUESTIONS_UZ
    return questions.get(missing[0])


def is_complete(draft: JobDraft) -> bool:
    """E'lon yaratishga tayyormi."""
    return not missing_fields(draft)
