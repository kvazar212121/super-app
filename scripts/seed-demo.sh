#!/usr/bin/env bash
# Demo ma'lumotlarni DB ga yuklash yoki o'chirish
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/backend"

if [[ "${1:-}" == "--clear" ]]; then
  echo "==> Demo ma'lumotlar o'chirilmoqda..."
  docker compose exec backend python -m app.seed --clear
  echo "Tayyor. Demo ma'lumotlar o'chirildi."
elif [[ "${1:-}" == "--reset" ]]; then
  echo "==> Demo ma'lumotlar qayta yuklanmoqda..."
  docker compose exec backend python -m app.seed --clear
  docker compose exec backend python -m app.seed
  echo "Tayyor. Demo ma'lumotlar qayta yuklandi."
else
  echo "==> Demo ma'lumotlar yuklanmoqda..."
  docker compose exec backend python -m app.seed
  echo ""
  echo "Demo foydalanuvchi: +998901112233 / demo1234"
  echo "Admin: admin / admin123"
  echo ""
  echo "O'chirish:  bash $0 --clear"
  echo "Qayta yuklash: bash $0 --reset"
fi
