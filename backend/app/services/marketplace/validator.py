"""Qoralamada nima yetishmayapti va AI nimani so'rashi kerak.

Farqi `ai_job/validator.py` dan: u savollarni BITTALAB beradi, bu
yerda esa foydalanuvchi aniq so'radi — "AI ro'yxat beradi", ya'ni
yetishmaganlarning HAMMASI bir xabarda ko'rsatiladi.
"""
from __future__ import annotations

from .draft import ListingDraft
from .fields import (
    COMMON_LABELS_RU, COMMON_LABELS_UZ, category_of, required_attributes,
)

MIN_TITLE = 3
MIN_DESCRIPTION = 0  # tavsif majburiy emas: nom + maydonlar yetarli


def missing_fields(draft: ListingDraft) -> list[str]:
    """Yetishmayotgan majburiy maydonlar (umumiy + toifaga xos)."""
    missing: list[str] = []

    title = (draft.title or "").strip()
    if len(title) < MIN_TITLE:
        missing.append("title")

    # Narx: `is_negotiable` bo'lsa narx shart emas ("Kelishamiz").
    if draft.price is None and not draft.is_negotiable:
        missing.append("price")

    if draft.condition is None:
        missing.append("condition")

    if len((draft.address or "").strip()) < 3:
        missing.append("address")

    for key in required_attributes(draft.category_key):
        value = (draft.attributes or {}).get(key)
        if value in (None, ""):
            missing.append(key)

    return missing


def _label(field: str, category_key: str | None, lang: str) -> str:
    common = COMMON_LABELS_RU if lang == "ru" else COMMON_LABELS_UZ
    if field in common:
        return common[field]
    cat = category_of(category_key)
    for k, uz, ru in cat.required + cat.optional:
        if k == field:
            return ru if lang == "ru" else uz
    return field


def missing_labels(draft: ListingDraft, lang: str = "uz") -> list[str]:
    """Yetishmaganlarning odam tilidagi ro'yxati."""
    return [_label(f, draft.category_key, lang) for f in missing_fields(draft)]


def ask_text(draft: ListingDraft, lang: str = "uz") -> str | None:
    """AI aytadigan tayyor matn. Hammasi to'liq bo'lsa None."""
    labels = missing_labels(draft, lang)
    if not labels:
        return None
    if lang == "ru":
        bosh = "Чтобы разместить объявление, нужны:"
        oxir = "Можно написать всё одним сообщением."
    else:
        bosh = "E'lon berish uchun quyidagilar kerak:"
        oxir = "Bir yozuvda hammasini yozsangiz ham bo'ladi."
    qatorlar = "\n".join(f"• {t}" for t in labels)
    return f"{bosh}\n{qatorlar}\n{oxir}"


def is_complete(draft: ListingDraft) -> bool:
    return not missing_fields(draft)
