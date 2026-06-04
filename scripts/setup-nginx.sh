#!/usr/bin/env bash
# Production serverda nginx + backend o'rnatish (sudo kerak)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONF_SRC="$ROOT/deploy/nginx/hubservis.conf"

echo "==> nginx o'rnatish..."
sudo apt-get update -qq
sudo apt-get install -y nginx

exec bash "$(dirname "$0")/apply-nginx.sh"

echo "==> Docker guruhiga qo'shish (agar kerak bo'lsa)..."
sudo usermod -aG docker "$USER" 2>/dev/null || true

echo ""
echo "Nginx sozlandi!"
echo ""
echo "DNS (@HOST) — quyidagicha bo'lishi kerak:"
echo "  api          A    47.84.60.201"
echo "  @            A    47.84.60.201"
echo "  www          A    47.84.60.201   (yoki CNAME → hubservis.uz)"
echo ""
echo "Keyin backend ishga tushiring:"
echo "  cp $ROOT/backend/.env.example $ROOT/backend/.env"
echo "  bash $ROOT/scripts/start.sh"
echo ""
echo "  (yoki terminal qayta ochilmasa: sg docker -c 'cd $ROOT/backend && docker compose up -d --build db redis backend')"
echo ""
echo "Manzillar:"
echo "  Sayt:    http://hubservis.uz/"
echo "  Admin:   http://hubservis.uz/admin/login"
echo "  API:     http://api.hubservis.uz/api/v1/health"
echo "  Docs:    http://api.hubservis.uz/docs"
echo ""
