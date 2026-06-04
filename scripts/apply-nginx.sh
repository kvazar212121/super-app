#!/usr/bin/env bash
# hubservis nginx — faqat HTTP, SSL yo'q
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONF="$ROOT/deploy/nginx/hubservis.conf"

echo "==> hubservis nginx (HTTP 80)"
echo "    hubservis.uz      → landing + admin"
echo "    api.hubservis.uz  → API"
echo "    Backend:           127.0.0.1:8000"
echo ""

if ! curl -sf --max-time 2 http://127.0.0.1:8000/api/v1/health >/dev/null; then
  echo "Ogohlantirish: backend 8000 da javob bermayapti."
  echo "  cd $ROOT/backend && docker compose up -d db redis backend"
  echo ""
fi

rm -f /etc/nginx/sites-enabled/proworker.conf

cp "$CONF" /etc/nginx/sites-available/hubservis
ln -sf /etc/nginx/sites-available/hubservis /etc/nginx/sites-enabled/hubservis
nginx -t
nginx -s reload

echo ""
echo "Tayyor!"
echo "  http://hubservis.uz/"
echo "  http://hubservis.uz/admin/login"
echo "  http://api.hubservis.uz/api/v1/health"
