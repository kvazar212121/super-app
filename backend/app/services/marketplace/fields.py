"""Toifalar va har toifa uchun so'raladigan MAYDONLAR.

Nega bitta joyda: AI foydalanuvchiga "menga quyidagilar kerak" deb
BIR YO'LA ro'yxat beradi (foydalanuvchi shuni so'radi). Ro'yxat kod
ichiga tarqalib ketsa, savollar bir-biriga zid bo'lib qoladi.

Maydon nomlari `Listing.attributes` JSON kalitlariga to'g'ri keladi;
umumiy maydonlar (title, price, condition, address) esa ustunlar.
"""
from __future__ import annotations

# Har toifada BOR bo'lgan umumiy maydonlar — alohida yozilmaydi.
COMMON_REQUIRED = ("title", "price", "condition", "address")

# Umumiy maydonlar uchun savol matni.
COMMON_LABELS_UZ = {
    "title": "Nomi (masalan: iPhone 13 Pro 256GB)",
    "price": "Narxi (so'm yoki dollar; kelishamiz bo'lsa shunday yozing)",
    "condition": "Holati (yangi / ideal / yaxshi / ishlatilgan / ehtiyot qismga)",
    "address": "Manzil (qaysi shahar, tuman)",
}
COMMON_LABELS_RU = {
    "title": "Название (например: iPhone 13 Pro 256GB)",
    "price": "Цена (сум или доллар; можно «договорная»)",
    "condition": "Состояние (новое / идеальное / хорошее / б/у / на запчасти)",
    "address": "Адрес (город, район)",
}


class Category:
    """Toifa ta'rifi: nomi va unga xos maydonlar."""

    def __init__(self, key: str, title_uz: str, title_ru: str,
                 required: tuple[tuple[str, str, str], ...] = (),
                 optional: tuple[tuple[str, str, str], ...] = ()):
        self.key = key
        self.title_uz = title_uz
        self.title_ru = title_ru
        # Har element: (kalit, uz_savol, ru_savol)
        self.required = required
        self.optional = optional


CATEGORIES: dict[str, Category] = {
    c.key: c for c in [
        Category(
            "telefon", "Telefonlar", "Телефоны",
            required=(
                ("model", "Model (masalan: iPhone 13 Pro)", "Модель"),
                ("xotira", "Xotira (128/256 GB)", "Память (128/256 ГБ)"),
            ),
            optional=(
                ("rang", "Rangi", "Цвет"),
                ("quti", "Quti va hujjati bormi", "Есть ли коробка и документы"),
            ),
        ),
        Category(
            "kompyuter", "Kompyuter va noutbuk", "Компьютеры и ноутбуки",
            required=(
                ("model", "Model", "Модель"),
                ("protsessor", "Protsessor", "Процессор"),
                ("ram", "Operativ xotira (RAM)", "Оперативная память"),
                ("xotira", "Diskal xotira (SSD/HDD)", "Накопитель (SSD/HDD)"),
            ),
            optional=(("videokarta", "Videokarta", "Видеокарта"),),
        ),
        Category(
            "elektronika", "Elektron jihozlar", "Электроника",
            required=(
                ("tur", "Turi (televizor, quloqchin, planshet...)",
                 "Тип (телевизор, наушники, планшет...)"),
                ("model", "Model", "Модель"),
            ),
        ),
        Category(
            "maishiy", "Maishiy texnika", "Бытовая техника",
            required=(
                ("tur", "Turi (muzlatgich, kir yuvish mashinasi...)",
                 "Тип (холодильник, стиральная машина...)"),
                ("brend", "Brendi", "Бренд"),
            ),
        ),
        Category(
            "avto", "Avtomobillar", "Автомобили",
            required=(
                ("model", "Model (masalan: Cobalt)", "Модель"),
                ("yil", "Ishlab chiqarilgan yili", "Год выпуска"),
                ("probeg", "Probegi (km)", "Пробег (км)"),
            ),
            optional=(
                ("karobka", "Karobka (mexanika/avtomat)",
                 "Коробка (механика/автомат)"),
                ("yoqilgi", "Yoqilg'i (benzin/metan/propan)",
                 "Топливо (бензин/метан/пропан)"),
                ("rang", "Rangi", "Цвет"),
            ),
        ),
        Category(
            "qurilish", "Qurilish mollari", "Стройматериалы",
            required=(
                ("tur", "Turi (g'isht, sement, taxta...)",
                 "Тип (кирпич, цемент, доска...)"),
                ("hajm", "Miqdori yoki o'lchami", "Количество или размер"),
            ),
        ),
        Category(
            "kiyim", "Kiyim-kechak", "Одежда",
            required=(
                ("tur", "Turi (kurtka, ko'ylak, poyabzal...)",
                 "Тип (куртка, платье, обувь...)"),
                ("olcham", "O'lchami", "Размер"),
            ),
            optional=(("brend", "Brendi", "Бренд"),),
        ),
        Category(
            "hayvon", "Hayvonlar", "Животные",
            required=(
                ("turi", "Qaysi hayvon", "Какое животное"),
                ("yoshi", "Yoshi", "Возраст"),
            ),
            optional=(("zoti", "Zoti", "Порода"),),
        ),
        Category(
            "mebel", "Mebel", "Мебель",
            required=(
                ("tur", "Turi (divan, shkaf, stol...)",
                 "Тип (диван, шкаф, стол...)"),
            ),
            optional=(
                ("material", "Materiali", "Материал"),
                ("olcham", "O'lchami", "Размер"),
            ),
        ),
        Category("boshqa", "Boshqa", "Разное"),
    ]
}

# AI toifani "telefon sotaman" kabi erkin matndan topishi kerak.
_ALIASES = {
    "telefon": ("telefon", "phone", "смартфон", "телефон", "iphone",
                "samsung", "redmi", "xiaomi"),
    "kompyuter": ("kompyuter", "noutbuk", "notebook", "laptop", "компьютер",
                  "ноутбук", "pc"),
    "elektronika": ("elektronika", "televizor", "planshet", "quloqchin",
                    "электроника", "телевизор", "планшет"),
    "maishiy": ("maishiy", "muzlatgich", "kir yuvish", "changyutgich",
                "бытовая", "холодильник", "стиральная"),
    "avto": ("avto", "mashina", "avtomobil", "машина", "авто", "car",
             "nexia", "cobalt", "malibu"),
    "qurilish": ("qurilish", "g'isht", "gisht", "sement", "стройматериал",
                 "кирпич", "цемент"),
    "kiyim": ("kiyim", "ko'ylak", "poyabzal", "kurtka", "одежда", "обувь"),
    "hayvon": ("hayvon", "it", "mushuk", "qo'y", "животное", "собака", "кот"),
    "mebel": ("mebel", "divan", "shkaf", "stol", "мебель", "диван", "шкаф"),
}


def resolve_category(hint: str | None) -> str:
    """Erkin matndan toifa kalitini topadi. Topilmasa `boshqa`.

    Ataylab hech qachon xato bermaydi: toifa aniq bo'lmasa ham
    foydalanuvchi e'lon bera olishi kerak.
    """
    if not hint:
        return "boshqa"
    text = str(hint).strip().lower()
    if text in CATEGORIES:
        return text
    for key, words in _ALIASES.items():
        for w in words:
            if w in text:
                return key
    return "boshqa"


def category_of(key: str | None) -> Category:
    return CATEGORIES.get(key or "boshqa", CATEGORIES["boshqa"])


def required_attributes(key: str | None) -> tuple[str, ...]:
    """Shu toifada MAJBURIY bo'lgan qo'shimcha maydon kalitlari."""
    return tuple(k for k, _uz, _ru in category_of(key).required)


def field_checklist(key: str | None, lang: str = "uz") -> list[str]:
    """AI foydalanuvchiga ko'rsatadigan TO'LIQ ro'yxat (bir yo'la)."""
    cat = category_of(key)
    common = COMMON_LABELS_RU if lang == "ru" else COMMON_LABELS_UZ
    out = [common[f] for f in COMMON_REQUIRED]
    for _k, uz, ru in cat.required:
        out.append(ru if lang == "ru" else uz)
    return out


def optional_checklist(key: str | None, lang: str = "uz") -> list[str]:
    cat = category_of(key)
    return [(ru if lang == "ru" else uz) for _k, uz, ru in cat.optional]


def category_list(lang: str = "uz") -> list[dict]:
    """Ilova va AI uchun toifalar ro'yxati."""
    return [
        {"key": c.key, "title": c.title_ru if lang == "ru" else c.title_uz}
        for c in CATEGORIES.values()
    ]
