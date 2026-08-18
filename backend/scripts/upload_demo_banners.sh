#!/usr/bin/env bash
# Provayder bannerlari uchun rasmlarni serverga yuklaydi.
#
# Loyihada `assets/images/services3d/` da har xizmat uchun tayyor
# rasm bor (ilova ularni allaqachon ishlatadi). Backend esa faylni
# `/uploads/...` dan beradi, shuning uchun ular bir marta ko'chiriladi.
# Yangi rasm chizish yoki tashqi CDN shart emas.
#
# Ishlatish (lokal kompyuterdan):
#   bash backend/scripts/upload_demo_banners.sh devops@192.168.101.49
set -uo pipefail

TARGET="${1:-}"
if [ -z "$TARGET" ]; then
    echo "Ishlatish: bash $0 user@server"
    exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="$ROOT/assets/images/services3d"

if [ ! -d "$SRC" ]; then
    echo "Rasmlar topilmadi: $SRC"
    exit 1
fi

echo "── Rasmlar serverga ko'chirilmoqda ($(ls "$SRC" | wc -l) ta)"
# Avval vaqtinchalik joyga, keyin konteyner ichidagi uploads'ga:
# uploads volume orqali ulangani uchun to'g'ridan-to'g'ri host'da turadi.
ssh "$TARGET" 'mkdir -p ~/demo_banners'
scp -q "$SRC"/* "$TARGET":~/demo_banners/

ssh "$TARGET" 'bash -s' <<'EOF'
set -uo pipefail
cd ~/super-app/backend

# Rasmlar `superapp_uploads` volumida turadi (docker-compose.yml:
# `- superapp_uploads:/app/uploads`), shuning uchun ular konteyner
# qayta qurilganda ham YO'QOLMAYDI.
CID="$(docker compose ps -q backend | head -1)"
if [ -z "$CID" ]; then
    echo "  ✗ backend konteyneri topilmadi"
    exit 1
fi

docker exec "$CID" mkdir -p /app/uploads/services3d
for f in ~/demo_banners/*; do
    docker cp "$f" "$CID":/app/uploads/services3d/"$(basename "$f")"
done
echo "  konteynerda: $(docker exec "$CID" ls /app/uploads/services3d | wc -l) ta fayl"
EOF

echo "── Tekshirish"
curl -s -o /dev/null -w "  /uploads/services3d/sartarosh.jpg -> %{http_code}\n" \
    https://hubservis.uz/uploads/services3d/sartarosh.jpg
