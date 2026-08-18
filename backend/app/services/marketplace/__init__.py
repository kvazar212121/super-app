"""Savdo (marketplace) — AI chat orqali OLX uslubidagi e'lonlar.

Nega `jobs` dan alohida paket: `jobs` — ISH e'loni (usta qidiriladi),
bu yerda esa BUYUM sotiladi. Aralashtirilsa ikkala oqim ham chalkashadi;
alohida paket kelajakda bo'limni butunlay o'chirishni ham osonlashtiradi.

Modullar:
    fields.py     — toifalar va har toifada so'raladigan maydonlar
    draft.py      — suhbat davomida yig'ilayotgan qoralama
    validator.py  — nima yetishmayapti (hammasi bir ro'yxatda)
    photos.py     — rasm qoidalari (kamida 3, ko'pi 6)
    limits.py     — muddat/soni chegaralari (oddiy va premium)
    currency.py   — xaridorga DOIM so'mda ko'rsatish
    search.py     — xaridor qidiruvi va saralash
    publisher.py  — qoralamadan e'lon, e'lonni boshqarish
    extend.py     — muddatni uzaytirish (to'lov yoki premium)
    safety.py     — firibgarlik ogohlantirishi va shikoyat
"""
from .draft import ListingDraft, parse_condition, parse_price
from .fields import CATEGORIES, category_list, field_checklist, resolve_category
from .limits import check_can_create, expires_at_for, marketplace_enabled
from .photos import check as check_photos, is_enough as photos_enough
from .publisher import (
    close_listing, create_listing, expire_old, get_public, mark_sold,
    my_listings, own_listing, reopen_listing,
)
from .search import search_listings
from .validator import ask_text, is_complete, missing_fields

__all__ = [
    "ListingDraft",
    "parse_condition",
    "parse_price",
    "CATEGORIES",
    "category_list",
    "field_checklist",
    "resolve_category",
    "check_can_create",
    "expires_at_for",
    "marketplace_enabled",
    "check_photos",
    "photos_enough",
    "close_listing",
    "create_listing",
    "expire_old",
    "get_public",
    "mark_sold",
    "my_listings",
    "own_listing",
    "reopen_listing",
    "search_listings",
    "ask_text",
    "is_complete",
    "missing_fields",
]
