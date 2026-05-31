import re


def normalize_phone(phone: str) -> str:
    """+998XXXXXXXXX formatiga keltirish."""
    digits = re.sub(r"\D", "", phone or "")
    if digits.startswith("998") and len(digits) >= 12:
        digits = digits[:12]
    elif len(digits) == 9:
        digits = "998" + digits
    if len(digits) == 12 and digits.startswith("998"):
        return f"+{digits}"
    return phone.strip()


def is_valid_uz_phone(phone: str) -> bool:
    normalized = normalize_phone(phone)
    return bool(re.fullmatch(r"\+998\d{9}", normalized))
