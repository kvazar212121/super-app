#!/usr/bin/env bash
# PROWORKER (tez_ish) ni to'liq to'xtatish — nginx + docker
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# sudo bilan ishga tushganda $HOME=/root — asl foydalanuvchi papkasi
DEVOPS_HOME="${SUDO_USER:+$(getent passwd "$SUDO_USER" | cut -d: -f6)}"
DEVOPS_HOME="${DEVOPS_HOME:-/home/devops}"
TEZ_ISH="${TEZ_ISH_DIR:-$DEVOPS_HOME/tez_ish}"

echo "==> PROWORKER docker to'xtatish ($TEZ_ISH)..."
if [[ -f "$TEZ_ISH/docker-compose.yml" ]]; then
  (cd "$TEZ_ISH" && docker compose down) || true
fi
while read -r c; do
  docker stop "$c" 2>/dev/null || true
  docker rm "$c" 2>/dev/null || true
done < <(docker ps -a --format '{{.Names}}' 2>/dev/null | grep -E '^tez_ish-' || true)

echo "==> PROWORKER nginx o'chirish..."
rm -f /etc/nginx/sites-enabled/proworker.conf

echo "==> hubservis nginx qo'llash..."
bash "$ROOT/scripts/apply-nginx.sh"

echo ""
echo "PROWORKER to'xtatildi. Super App:"
echo "  http://hubservis.uz/"
echo "  http://hubservis.uz/admin/login"
echo "  http://api.hubservis.uz/api/v1/health"
