"""Suhbat davomida yig'ilayotgan E'LON qoralamasi.

`ai_job/draft.py` bilan bir xil falsafada: qoralama BAZAGA
YOZILMAYDI. Yarim to'ldirilgan e'lon xaridorlar qidiruviga chiqib
qolmasligi kerak.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Optional

from app.models.marketplace import ListingCondition

from .fields import category_of

# Foydalanuvchi holatni erkin yozadi — kalitga aylantiramiz.
_CONDITION_WORDS = {
    ListingCondition.new: ("yangi", "new", "новый", "новое", "yangi holatda"),
    ListingCondition.like_new: ("ideal", "like_new", "идеал", "как новый",
                                "deyarli yangi"),
    ListingCondition.good: ("yaxshi", "good", "хорошее", "хороший", "yaxshi holatda"),
    ListingCondition.used: ("ishlatilgan", "used", "б/у", "бу", "eski"),
    ListingCondition.parts: ("ehtiyot", "parts", "запчаст", "на запчасти"),
}


def parse_condition(value) -> ListingCondition | None:
    """Erkin matndan holatni aniqlaydi. Tushunmasa None (savol beriladi)."""
    if value is None:
        return None
    if isinstance(value, ListingCondition):
        return value
    text = str(value).strip().lower()
    if not text:
        return None
    for cond, words in _CONDITION_WORDS.items():
        for w in words:
            if w in text:
                return cond
    return None


def parse_price(value) -> tuple[Optional[float], bool]:
    """Narxni o'qiydi. (narx, kelishamiz_mi) qaytaradi.

    "kelishamiz" — foydalanuvchi aniq so'ragan holat: narx yo'q,
    lekin e'lon yaratilaveradi.
    """
    if value is None:
        return None, False
    if isinstance(value, (int, float)):
        return (float(value), False) if value > 0 else (None, False)
    text = str(value).strip().lower()
    if any(w in text for w in ("kelish", "договор", "narxi kelishilad")):
        return None, True
    # "4 500 000 so'm" -> 4500000
    digits = "".join(ch for ch in text if ch.isdigit() or ch == ".")
    try:
        num = float(digits)
    except ValueError:
        return None, False
    return (num, False) if num > 0 else (None, False)


@dataclass
class ListingDraft:
    """AI suhbatidan yig'ilgan e'lon ma'lumotlari."""

    category_key: Optional[str] = None
    title: Optional[str] = None
    description: Optional[str] = None
    price: Optional[float] = None
    currency: str = "UZS"
    is_negotiable: bool = False
    condition: Optional[ListingCondition] = None
    address: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    attributes: dict = field(default_factory=dict)
    photos: list[str] = field(default_factory=list)

    def merge(self, **kwargs) -> "ListingDraft":
        """Yangi ma'lumotni qo'shadi. None ESKISINI O'CHIRMAYDI.

        AI ko'pincha bitta maydonni yuboradi (foydalanuvchi javobiga
        qarab) — oldin yig'ilgani yo'qolsa suhbat aylanib qoladi.
        """
        for key, value in kwargs.items():
            if value is None or not hasattr(self, key):
                continue
            if key == "photos":
                mavjud = set(self.photos)
                for url in value:
                    if url and url not in mavjud:
                        self.photos.append(url)
                        mavjud.add(url)
                continue
            if key == "attributes":
                if isinstance(value, dict):
                    # Bo'sh qiymat eski to'g'ri javobni o'chirmasin.
                    for k, v in value.items():
                        if v not in (None, ""):
                            self.attributes[k] = v
                continue
            setattr(self, key, value)
        return self

    def price_text(self, lang: str = "uz") -> str:
        if self.is_negotiable or self.price is None:
            return "Kelishamiz" if lang != "ru" else "Договорная"
        birlik = "so'm" if self.currency == "UZS" else self.currency
        if lang == "ru" and self.currency == "UZS":
            birlik = "сум"
        return f"{self.price:,.0f} {birlik}".replace(",", " ")

    def auto_description(self) -> str:
        """Tavsif yozilmagan bo'lsa, yig'ilgan ma'lumotdan tuzadi.

        Nega kerak: AI ba'zan `description` ni tashlab ketadi va
        e'lon xaridorga quruq nom bo'lib ko'rinadi. Bu yerda YANGI
        ma'lumot O'YLAB TOPILMAYDI — faqat foydalanuvchi aytganlari
        tabiiy jumlaga yig'iladi.
        """
        holatlar = {
            ListingCondition.new: "yangi",
            ListingCondition.like_new: "ideal holatda",
            ListingCondition.good: "yaxshi holatda",
            ListingCondition.used: "ishlatilgan",
            ListingCondition.parts: "ehtiyot qismga",
        }
        bolaklar: list[str] = []
        nom = (self.title or "").strip()
        holat = holatlar.get(self.condition) if self.condition else None
        if nom and holat:
            bolaklar.append(f"{nom}, {holat}.")
        elif nom:
            bolaklar.append(f"{nom}.")

        # Toifaga xos maydonlar: "Xotira: 256GB, Model: iPhone 13 Pro"
        xos = [f"{k}: {v}" for k, v in (self.attributes or {}).items() if v]
        if xos:
            bolaklar.append(", ".join(xos) + ".")

        if self.is_negotiable:
            bolaklar.append("Narx kelishiladi.")
        if (self.address or "").strip():
            bolaklar.append(f"Manzil: {self.address.strip()}.")

        return " ".join(bolaklar).strip()

    def summary(self, lang: str = "uz") -> str:
        """Tasdiq oldidan ko'rsatiladigan xulosa."""
        cat = category_of(self.category_key)
        holat = self.condition.value if self.condition else "—"
        lines = [
            f"🏷 {self.title or '—'}",
            f"📂 {cat.title_ru if lang == 'ru' else cat.title_uz}",
            f"💰 {self.price_text(lang)}",
            f"📦 {holat}",
            f"📍 {self.address or '—'}",
        ]
        if self.description:
            lines.insert(2, f"📝 {self.description}")
        for k, v in (self.attributes or {}).items():
            lines.append(f"• {k}: {v}")
        lines.append(
            f"🖼 {len(self.photos)} ta rasm" if lang != "ru"
            else f"🖼 {len(self.photos)} фото"
        )
        return "\n".join(lines)
