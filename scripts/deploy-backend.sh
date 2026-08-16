#!/usr/bin/env bash
# Backendni serverda yangilash.
#
# Nima qiladi:
#   1. Konteynerni qayta quradi va ishga tushiradi
#   2. Startup init yangi xizmat kategoriyalarini bazaga qo'shadi
#      (telefonUsta, kompyuterUsta, itXizmat, game_zona, sport_maydon,
#       boshqa_xizmatlar) — mavjudlariga tegmaydi
#   3. Natijani HTTP orqali tekshiradi
#
# Ishlatish (SERVERDA):
#   cd ~/super-app && git pull && bash scripts/deploy-backend.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BASE_URL="${BASE_URL:-http://localhost:8000}"

echo "==> 1/3 Backend konteyneri qayta quriladi..."
cd "$ROOT/backend"
docker compose up -d --build backend

echo ""
echo "==> 2/3 Backend tayyor bo'lishini kutamiz..."
for i in $(seq 1 30); do
  if curl -sf -m 3 "$BASE_URL/api/v1/health" >/dev/null 2>&1; then
    echo "    Backend tayyor (${i}-urinish)"
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "    XATO: backend 60 soniyada ko'tarilmadi"
    echo "    Loglar: docker compose logs --tail=50 backend"
    exit 1
  fi
  sleep 2
done

echo ""
echo "==> 3/3 Yangi kategoriyalar tekshirilmoqda..."
MISSING=""
for key in telefonUsta kompyuterUsta itXizmat game_zona sport_maydon boshqa_xizmatlar; do
  if curl -sf -m 5 "$BASE_URL/api/v1/categories" | grep -q "\"$key\""; then
    echo "    OK  $key"
  else
    echo "    YO'Q $key"
    MISSING="$MISSING $key"
  fi
done

echo ""
echo "==> Reyting bo'yicha saralash tekshiruvi:"
curl -sf -m 5 "$BASE_URL/api/v1/providers?per_page=5&sort=rating" \
  | python3 -c "
import json, sys
try:
    items = json.load(sys.stdin)['items']
except Exception:
    print('    javobni o\'qib bo\'lmadi'); raise SystemExit(1)
ratings = [p['rating'] for p in items]
for p in items:
    print(f\"    {p['rating']:>4}  {p['review_count']:>4} sharh  {p['name']}\")
if ratings != sorted(ratings, reverse=True):
    print('    XATO: saralash ishlamayapti'); raise SystemExit(1)
print('    OK: kamayish tartibida')
"

echo ""
if [ -n "$MISSING" ]; then
  echo "DIQQAT: quyidagi kategoriyalar qo'shilmadi:$MISSING"
  echo "Loglarni ko'ring: docker compose logs --tail=100 backend | grep -i kategoriya"
  exit 1
fi

echo "Deploy muvaffaqiyatli yakunlandi."
