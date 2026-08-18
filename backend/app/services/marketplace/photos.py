"""Rasm qoidalari: kamida 3 ta, ko'pi 6 ta (premium 10).

Foydalanuvchi aniq talab qildi: rasmsiz e'lon bo'lmaydi, chunki
xaridor rasmga qarab ishonadi. Chegaradan oshgani KESILADI —
xatolik berish o'rniga, aks holda AI suhbati tiqilib qoladi.
"""
from __future__ import annotations

from app.models.user import User

from .limits import max_photos, min_photos


def normalize(photos) -> list[str]:
    """Har xil ko'rinishdagi kirishni toza URL ro'yxatiga aylantiradi.

    AI ba'zan bitta satr, ba'zan ro'yxat yuboradi; takrorlanishi ham
    mumkin (foydalanuvchi bir rasmni ikki marta jo'natsa).
    """
    if photos is None:
        return []
    if isinstance(photos, str):
        photos = [photos]
    out: list[str] = []
    for p in photos:
        if not p:
            continue
        url = str(p).strip()
        if url and url not in out:
            out.append(url)
    return out


def trim(photos: list[str], user: User | None = None) -> list[str]:
    """Chegaradan oshiq rasmlarni kesadi (birinchilari qoladi)."""
    return normalize(photos)[: max_photos(user)]


def check(photos: list[str], user: User | None = None,
          lang: str = "uz") -> str | None:
    """Rasm yetarlimi. Yetarli bo'lsa None, aks holda tushuntirish."""
    n = len(normalize(photos))
    kerak = min_photos()
    if n >= kerak:
        return None
    yetishmayapti = kerak - n
    if lang == "ru":
        return (f"Нужно ещё {yetishmayapti} фото (сейчас {n}, "
                f"минимум {kerak}).")
    return (f"Yana {yetishmayapti} ta rasm kerak "
            f"(hozir {n} ta, kamida {kerak} ta).")


def is_enough(photos: list[str]) -> bool:
    return len(normalize(photos)) >= min_photos()
