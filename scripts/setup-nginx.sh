#!/usr/bin/env bash
# Production serverda nginx + backend o'rnatish (sudo kerak)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONF_SRC="$ROOT/deploy/nginx/hubservis.conf"

echo "==> nginx o'rnatish..."
sudo apt-get update -qq
sudo apt-get install -y nginx

echo "==> hubservis.uz nginx konfiguratsiyasi..."
sudo cp "$CONF_SRC" /etc/nginx/sites-available/hubservis
sudo ln -sf /etc/nginx/sites-available/hubservis /etc/nginx/sites-enabled/hubservis
sudo rm -f /etc/nginx/sites-enabled/default 2>/dev/null || true
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl reload nginx

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
echo "  cp $ROOT/backend/.env.production $ROOT/backend/.env"
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
echo "HTTPS uchun:"
echo "  bash $ROOT/scripts/setup-ssl.sh"
