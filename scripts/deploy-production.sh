#!/usr/bin/env bash
# Landing + HTTPS — bir martalik deploy (sudo kerak)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "1/3 Backend yangilash (landing sahifa)..."
cd "$ROOT/backend"
docker compose up -d --build backend

echo ""
echo "2/2 Nginx yangilash (HTTP 80)..."
bash "$ROOT/scripts/apply-nginx.sh"

echo ""
echo "Tayyor!"
echo "  http://hubservis.uz/          — landing"
echo "  http://hubservis.uz/admin/login — admin"
