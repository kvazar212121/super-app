#!/usr/bin/env bash
# Docker/sudo kerak emas — faqat backend + admin panel
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BACKEND="$ROOT/backend"
PG="$HOME/tools/postgresql-16.6.0-x86_64-unknown-linux-gnu"
PGDATA="$ROOT/data/pg"
ENV_FILE="$BACKEND/.env.local"

if [[ ! -f "$ENV_FILE" ]]; then
  cp "$BACKEND/.env.local.example" "$ENV_FILE"
  echo "Yangi .env.local yaratildi — ADMIN_DEFAULT_PASSWORD va SECRET_KEY ni o'zgartiring."
fi

export PATH="$PG/bin:$PATH"

mkdir -p "$ROOT/data"

# PostgreSQL
if [[ ! -f "$PGDATA/PG_VERSION" ]]; then
  echo "==> PostgreSQL init..."
  initdb -D "$PGDATA" -U postgres --auth=trust -A trust
fi

if ! pg_isready -p 5435 -h /tmp >/dev/null 2>&1; then
  echo "==> PostgreSQL ishga tushirish..."
  pg_ctl -D "$PGDATA" -l "$ROOT/data/pg.log" -o "-p 5435 -k /tmp" start
  sleep 2
fi

createdb -p 5435 -h /tmp -U postgres superapp 2>/dev/null || true

# Backend
if [[ ! -d "$BACKEND/.venv" ]]; then
  echo "==> Python venv..."
  python3 -m pip install --user virtualenv >/dev/null
  "$HOME/.local/bin/virtualenv" "$BACKEND/.venv"
  "$BACKEND/.venv/bin/pip" install -q -r "$BACKEND/requirements.txt"
fi

# Eski backend jarayonini to'xtatish
pkill -f "uvicorn app.main:app" 2>/dev/null || true
sleep 1

echo "==> Backend ishga tushirish (port 8000)..."
cd "$BACKEND"
set -a
source "$ENV_FILE"
set +a
nohup "$BACKEND/.venv/bin/uvicorn" app.main:app --host 0.0.0.0 --port 8000 \
  > "$ROOT/data/backend.log" 2>&1 &
echo $! > "$ROOT/data/backend.pid"

for i in $(seq 1 30); do
  if curl -sf http://127.0.0.1:8000/api/v1/health >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

# nginx (8080) — sudo kerak emas
NGINX_BIN="$HOME/.local/nginx/usr/sbin/nginx"
NGINX_PREFIX="$ROOT/data/nginx"
NGINX_CONF="$ROOT/deploy/nginx/local.conf"
mkdir -p "$NGINX_PREFIX/logs" "$NGINX_PREFIX/tmp/client_body" "$NGINX_PREFIX/tmp/proxy" \
  "$NGINX_PREFIX/tmp/fastcgi" "$NGINX_PREFIX/tmp/uwsgi" "$NGINX_PREFIX/tmp/scgi"

if [[ -x "$NGINX_BIN" ]]; then
  pkill -f "nginx: master process" 2>/dev/null || true
  sleep 1
  "$NGINX_BIN" -p "$NGINX_PREFIX" -c "$NGINX_CONF" 2>/dev/null || true
fi

echo ""
echo "Tayyor!"
if [[ -x "$NGINX_BIN" ]] && curl -sf http://127.0.0.1:8080/api/v1/health >/dev/null 2>&1; then
  echo "  Sayt (nginx):   http://localhost:8080"
  echo "  Admin panel:    http://localhost:8080/admin/login  (admin / admin123)"
else
  echo "  Admin panel:    http://localhost:8000/admin/login  (admin / admin123)"
fi
echo "  API health:     http://localhost:8000/api/v1/health"
echo "  API docs:       http://localhost:8000/docs"
exit 0
