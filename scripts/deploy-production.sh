#!/usr/bin/env bash
# Landing + HTTPS — bir martalik deploy (sudo kerak)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "1/3 Backend yangilash (landing sahifa)..."
cd "$ROOT/backend"
docker compose up -d --build backend

echo ""
echo "2/3 Nginx yangilash..."
bash "$ROOT/scripts/setup-nginx.sh"

echo ""
echo "3/3 SSL sertifikat (90 kun, avtomatik yangilanadi)..."
bash "$ROOT/scripts/setup-ssl.sh"

echo ""
echo "Tayyor!"
echo "  https://hubservis.uz/          — landing"
echo "  https://hubservis.uz/admin/login — admin"
