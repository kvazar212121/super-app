#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND="$ROOT/backend"

echo "==> Super App (backend + admin panel + nginx)"

if ! docker info >/dev/null 2>&1; then
  if sg docker -c "docker info" >/dev/null 2>&1; then
    DOCKER="sg docker -c"
  else
    echo "XATO: Docker ishlamayapti."
    echo "Terminalni qayting oching yoki: newgrp docker"
    echo "yoki: cd $BACKEND && sudo docker compose up -d --build db redis backend"
    exit 1
  fi
else
  DOCKER=""
fi

run_docker() {
  if [[ -n "$DOCKER" ]]; then
    sg docker -c "$*"
  else
    eval "$@"
  fi
}

cd "$BACKEND"

if [[ ! -f "$BACKEND/.env" ]]; then
  cp "$BACKEND/.env.production" "$BACKEND/.env"
fi

run_docker "docker compose up -d --build db redis backend"

echo ""
echo "Tayyor!"
echo "  Admin:  http://hubservis.uz/admin/login  (admin / admin123)"
echo "  API:    http://api.hubservis.uz/api/v1/health"
echo "  Docs:   http://api.hubservis.uz/docs"
