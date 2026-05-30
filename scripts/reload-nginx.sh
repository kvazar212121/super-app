#!/usr/bin/env bash
# Nginx konfiguratsiyasini yangilash (sudo kerak)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
sudo cp "$ROOT/deploy/nginx/hubservis.conf" /etc/nginx/sites-available/hubservis
sudo nginx -t && sudo systemctl reload nginx
echo "Nginx yangilandi."
