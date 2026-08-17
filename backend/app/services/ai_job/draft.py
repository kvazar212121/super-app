"""Suhbat davomida yig'ilayotgan e'lon qoralamasi.

AI foydalanuvchi bilan bir necha xabar almashadi va ma'lumotni
bo'lak-bo'lak yig'adi. Qoralama shu yig'indini saqlaydi.

DIQQAT: qoralama BAZAGA YOZILMAYDI. U faqat suhbat kontekstida
yashaydi va foydalanuvchi tasdiqlagandagina haqiqiy JobPost
yaratiladi. Sababi: yarim yozilgan e'lon ustalar lentasiga chiqib
qolmasligi kerak.
"""
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional


@dataclass
class JobDraft:
    """AI suhbatidan yig'ilgan e'lon ma'lumotlari."""

    # Majburiy maydonlar
    category_id: Optional[int] = None
    title: Optional[str] = None
    description: Optional[str] = None
    address: Optional[str] = None

    # Ixtiyoriy
    photos: list[str] = field(default_factory=list)
    budget: Optional[float] = None
    needed_at: Optional[datetime] = None
    lat: Optional[float] = None
    lng: Optional[float] = None

    def merge(self, **kwargs) -> "JobDraft":
        """Yangi ma'lumotni qo'shadi. None qiymatlar ESKISINI O'CHIRMAYDI.

        Bu muhim: AI ikkinchi chaqiruvda faqat bitta maydonni yuborsa
        (masalan manzilni), oldin yig'ilgan tavsif yo'qolmasligi kerak.
        """
        for key, value in kwargs.items():
            if value is None or not hasattr(self, key):
                continue
            if key == "photos":
                # Rasmlar to'planadi, almashtirilmaydi
                existing = set(self.photos)
                for url in value:
                    if url not in existing:
                        self.photos.append(url)
                continue
            setattr(self, key, value)
        return self

    def to_job_payload(self) -> dict:
        """JobCreate sxemasiga mos lug'at."""
        payload = {
            "category_id": self.category_id,
            "title": self.title,
            "description": self.description,
            "address": self.address,
            "photos": self.photos,
        }
        if self.budget is not None:
            payload["budget"] = self.budget
        if self.needed_at is not None:
            payload["needed_at"] = self.needed_at
        if self.lat is not None and self.lng is not None:
            payload["lat"] = self.lat
            payload["lng"] = self.lng
        return payload

    def summary_uz(self, category_title: str | None = None) -> str:
        """Foydalanuvchiga tasdiq uchun ko'rsatiladigan xulosa."""
        lines = [f"📋 {self.title or '—'}"]
        if category_title:
            lines.append(f"🔧 Soha: {category_title}")
        if self.description:
            lines.append(f"📝 {self.description}")
        lines.append(f"📍 {self.address or '—'}")
        if self.needed_at:
            lines.append(f"🗓 {self.needed_at.strftime('%d.%m.%Y %H:%M')}")
        if self.budget is not None:
            lines.append(f"💰 {self.budget:,.0f} so'm".replace(",", " "))
        else:
            lines.append("💰 Narxni ustalar aytadi")
        if self.photos:
            lines.append(f"🖼 {len(self.photos)} ta rasm")
        return "\n".join(lines)

    def summary_ru(self, category_title: str | None = None) -> str:
        """То же самое по-русски (пользователь может писать на русском)."""
        lines = [f"📋 {self.title or '—'}"]
        if category_title:
            lines.append(f"🔧 Сфера: {category_title}")
        if self.description:
            lines.append(f"📝 {self.description}")
        lines.append(f"📍 {self.address or '—'}")
        if self.needed_at:
            lines.append(f"🗓 {self.needed_at.strftime('%d.%m.%Y %H:%M')}")
        if self.budget is not None:
            lines.append(f"💰 {self.budget:,.0f} сум".replace(",", " "))
        else:
            lines.append("💰 Цену предложат мастера")
        if self.photos:
            lines.append(f"🖼 {len(self.photos)} фото")
        return "\n".join(lines)
