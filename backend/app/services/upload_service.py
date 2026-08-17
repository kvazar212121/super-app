import io
import uuid
from pathlib import Path

from fastapi import HTTPException, status, UploadFile
from PIL import Image

from app.core.config import settings


# Ruxsat etilgan fayl turlari
ALLOWED_CONTENT_TYPES = {
    "image/jpeg",
    "image/png",
    "image/webp",
}


class UploadService:
    """Barcha rasm yuklamalari JPEG'ga o'tkazilib, kichraytirilib saqlanadi.

    Maqsad: diskda va AI'ga jo'natishda rasm hajmi kichik bo'lishi
    (odatda bir necha o'n KB). PNG/WebP ham JPEG bo'lib saqlanadi.
    """

    @staticmethod
    def _validate_file(file: UploadFile) -> None:
        """Fayl turini va hajmini tekshirish."""
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

    @staticmethod
    def _compress_to_jpeg(contents: bytes, max_side: int, quality: int) -> bytes:
        """Rasmni JPEG'ga o'tkazib, eng katta tomonini max_side gacha kichraytiradi."""
        try:
            img = Image.open(io.BytesIO(contents))
            img.load()
        except Exception:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Rasmni o'qib bo'lmadi. Buzilmagan jpg/png/webp yuboring.",
            )

        # Shaffof fonli PNG/WebP — oq fonga tushiriladi
        if img.mode in ("RGBA", "LA"):
            background = Image.new("RGB", img.size, (255, 255, 255))
            background.paste(img, mask=img.split()[-1])
            img = background
        elif img.mode != "RGB":
            img = img.convert("RGB")

        img.thumbnail((max_side, max_side), Image.LANCZOS)

        buffer = io.BytesIO()
        img.save(buffer, "JPEG", quality=quality, optimize=True)
        return buffer.getvalue()

    @staticmethod
    async def _save_compressed(
        file: UploadFile, subdir: str, prefix: str, max_side: int, quality: int
    ) -> str:
        """Validatsiya + siqish + saqlash. Ommaviy URL qaytaradi."""
        UploadService._validate_file(file)
        contents = await file.read()
        compressed = UploadService._compress_to_jpeg(contents, max_side, quality)

        filename = f"{prefix}_{uuid.uuid4().hex}.jpg"
        upload_dir = Path(settings.upload_dir) / subdir
        upload_dir.mkdir(parents=True, exist_ok=True)
        (upload_dir / filename).write_bytes(compressed)

        return f"/uploads/{subdir}/{filename}"

    @staticmethod
    async def upload_avatar(file: UploadFile) -> str:
        """Foydalanuvchi avatarini yuklash. URL qaytaradi."""
        return await UploadService._save_compressed(file, "avatars", "avatar", 512, 75)

    @staticmethod
    async def upload_promo_image(file: UploadFile) -> str:
        """Aksiya banneri fon rasmini yuklash (admin panel). URL qaytaradi."""
        return await UploadService._save_compressed(file, "promos", "promo", 1280, 72)

    @staticmethod
    async def upload_job_photo(file: UploadFile) -> str:
        """Ish e'loni rasmini yuklash ("joyni rasmga olib"). URL qaytaradi."""
        return await UploadService._save_compressed(file, "jobs", "job", 1280, 75)

    @staticmethod
    async def upload_cover(file: UploadFile) -> str:
        """Provayder muqova rasmini yuklash. URL qaytaradi."""
        return await UploadService._save_compressed(file, "covers", "cover", 1280, 75)
