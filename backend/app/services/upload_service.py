import uuid
from pathlib import Path
from fastapi import HTTPException, status, UploadFile

from app.core.config import settings


# Ruxsat etilgan fayl turlari
ALLOWED_CONTENT_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
}

# Fayl kengaytmalari xaritasi
CONTENT_TYPE_TO_EXT = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
}


class UploadService:

    @staticmethod
    def _validate_file(file: UploadFile) -> str:
        """Fayl turini va hajmini tekshirish. Kengaytmani qaytaradi."""
        if file.content_type not in ALLOWED_CONTENT_TYPES:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Noto'g'ri fayl turi. Faqat jpg, png, webp ruxsat etiladi. "
                       f"Qabul qilingan: {file.content_type}",
            )

        max_bytes = settings.max_upload_size_mb * 1024 * 1024
        # Fayl hajmini tekshirish — boshidan max_bytes + 1 bayt o'qish
        contents = file.file.read(max_bytes + 1)
        if len(contents) > max_bytes:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Fayl hajmi juda katta. Maksimal: {settings.max_upload_size_mb}MB",
            )

        # Fayl ko'rsatkichini boshiga qaytarish
        file.file.seek(0)
        return CONTENT_TYPE_TO_EXT[file.content_type]

    @staticmethod
    async def upload_avatar(file: UploadFile) -> str:
        """Foydalanuvchi avatarini yuklash. URL qaytaradi."""
        ext = UploadService._validate_file(file)
        filename = f"avatar_{uuid.uuid4().hex}{ext}"
        upload_dir = Path(settings.upload_dir) / "avatars"
        upload_dir.mkdir(parents=True, exist_ok=True)

        contents = await file.read()
        filepath = upload_dir / filename
        filepath.write_bytes(contents)

        return f"/uploads/avatars/{filename}"

    @staticmethod
    async def upload_promo_image(file: UploadFile) -> str:
        """Aksiya banneri fon rasmini yuklash (admin panel). URL qaytaradi."""
        ext = UploadService._validate_file(file)
        filename = f"promo_{uuid.uuid4().hex}{ext}"
        upload_dir = Path(settings.upload_dir) / "promos"
        upload_dir.mkdir(parents=True, exist_ok=True)

        contents = await file.read()
        filepath = upload_dir / filename
        filepath.write_bytes(contents)

        return f"/uploads/promos/{filename}"

    @staticmethod
    async def upload_food_photo(file: UploadFile) -> str:
        """Kaloriya hisoblagich uchun taom rasmini yuklash. URL qaytaradi."""
        ext = UploadService._validate_file(file)
        filename = f"food_{uuid.uuid4().hex}{ext}"
        upload_dir = Path(settings.upload_dir) / "food"
        upload_dir.mkdir(parents=True, exist_ok=True)

        contents = await file.read()
        filepath = upload_dir / filename
        filepath.write_bytes(contents)

        return f"/uploads/food/{filename}"

    @staticmethod
    async def upload_cover(file: UploadFile) -> str:
        """Provayder muqova rasmini yuklash. URL qaytaradi."""
        ext = UploadService._validate_file(file)
        filename = f"cover_{uuid.uuid4().hex}{ext}"
        upload_dir = Path(settings.upload_dir) / "covers"
        upload_dir.mkdir(parents=True, exist_ok=True)

        contents = await file.read()
        filepath = upload_dir / filename
        filepath.write_bytes(contents)

        return f"/uploads/covers/{filename}"
