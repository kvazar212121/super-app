#!/usr/bin/env bash
# Savdo bo'limini HAQIQIY server ustida uchdan-uchgacha sinaydi.
#
# Nega bu skript kerak: qolgan testlar kodni ichkaridan chaqiradi.
# Bu yerda esa ilova ko'radigan yo'l bosib o'tiladi — tarmoq orqali
# HTTP, haqiqiy PostgreSQL, haqiqiy fayl yuklash, haqiqiy CBU kursi.
# Ishga tushirish/ulanish xatolari faqat shu darajada ko'rinadi.
#
# Ishlatish:
#   bash tests/e2e_marketplace.sh
#
# PostgreSQL yo'q bo'lsa `pgserver` (pip) orqali sudo'siz ko'tariladi.
# Ishchi bazaga TEGMAYDI: alohida `superapp_test` bazasi ishlatiladi.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PY="${PYTHON:-$ROOT/backend/.venv/bin/python}"
PGDATA="${PGDATA_DIR:-/tmp/superapp_e2e_pg}"
PGPORT="${PGPORT:-5439}"
PORT="${E2E_PORT:-8899}"
B="http://127.0.0.1:$PORT/api/v1"

ok=0
fail=0
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"; [ -n "${SRV:-}" ] && kill "$SRV" 2>/dev/null; [ -n "${PGPID:-}" ] && kill "$PGPID" 2>/dev/null' EXIT

check() {  # check "nom" "kutilgan" "olingan"
    if [ "$2" = "$3" ]; then
        printf '  ✓ %s\n' "$1"; ok=$((ok + 1))
    else
        printf '  ✗ %s (kutildi: %s, olindi: %s)\n' "$1" "$2" "$3"; fail=$((fail + 1))
    fi
}

if ! "$PY" -c "import pgserver" 2>/dev/null; then
    echo "SKIP: pgserver yo'q. O'rnatish: $PY -m pip install pgserver"
    exit 0
fi

echo "── PostgreSQL ko'tarilmoqda ($PGDATA:$PGPORT)"
# DIQQAT: katalogni OLDINDAN yaratmaymiz va konfiguratsiyaga
# tegmaymiz — `initdb` bo'sh bo'lmagan katalogda yiqiladi. Port
# birinchi ishga tushirishdan KEYIN o'zgartiriladi (pastdagi skript).

cat > "$tmp/pg.py" <<EOF
import pgserver, time
# 1-qadam: standart holatda ko'taramiz (initdb shu yerda bajariladi).
db = pgserver.get_server("$PGDATA")

# 2-qadam: portni o'zgartiramiz — 5432 da ishchi Postgres turgan
# bo'lishi mumkin, unga urilmaymiz. Konfiguratsiya faqat initdb'dan
# KEYIN yoziladi, aks holda initdb bo'sh bo'lmagan katalogda yiqiladi.
conf = "$PGDATA/postgresql.conf"
if "port = $PGPORT" not in open(conf).read():
    db.cleanup()
    open(conf, "a").write("\nlisten_addresses = '127.0.0.1'\nport = $PGPORT\n")
    db = pgserver.get_server("$PGDATA")

# 3-qadam: bazani yaratamiz. db.psql() ishlatilmaydi: u pgserver
# ichida eslab qolgan ESKI manzilga ulanadi va socket topilmadi deydi.
# Shuning uchun psql to'g'ridan-to'g'ri yangi port bilan chaqiriladi.
import pathlib, subprocess
psql = pathlib.Path(pgserver.__file__).parent / "pginstall" / "bin" / "psql"
uri = "postgresql://postgres@/postgres?host=$PGDATA" + "&port=$PGPORT"
r = subprocess.run([str(psql), uri, "-c", "CREATE DATABASE superapp_test"],
                   capture_output=True, text=True)
if r.returncode and "already exists" not in (r.stderr or ""):
    print("XATO:", r.stderr.strip(), flush=True)
print("TAYYOR", flush=True)
while True:
    time.sleep(3600)
EOF
"$PY" "$tmp/pg.py" > "$tmp/pg.log" 2>&1 &
PGPID=$!
for _ in $(seq 1 30); do
    grep -q TAYYOR "$tmp/pg.log" 2>/dev/null && break
    sleep 1
done
if ! grep -q TAYYOR "$tmp/pg.log"; then
    echo "SKIP: PostgreSQL ko'tarilmadi"; tail -5 "$tmp/pg.log"; exit 0
fi

DBURL="postgresql+asyncpg://postgres@/superapp_test?host=$PGDATA&port=$PGPORT"
export DATABASE_URL="$DBURL"
export DATABASE_SYNC_URL="postgresql://postgres@/superapp_test?host=$PGDATA&port=$PGPORT"
export REQUIRE_OTP_AUTH=false
export RUN_SCHEDULERS=false

echo "── Server ishga tushmoqda (:$PORT)"
(cd "$ROOT/backend" && "$PY" -m uvicorn app.main:app --host 127.0.0.1 \
    --port "$PORT" > "$tmp/server.log" 2>&1) &
SRV=$!
for _ in $(seq 1 40); do
    curl -s -m 2 "$B/health" > /dev/null 2>&1 && break
    sleep 1
done
if ! curl -s -m 3 "$B/health" | grep -q '"ok"'; then
    echo "  ✗ Server ko'tarilmadi:"; tail -15 "$tmp/server.log"; exit 1
fi
check "server /health javob beradi" "ok" \
      "$(curl -s "$B/health" | "$PY" -c 'import sys,json;print(json.load(sys.stdin)["status"])')"

echo "── Test foydalanuvchilari"
# Jadvallarni SERVER yaratadi (Alembic yo'q, startup create_all).
# /health startupdan oldin ham javob berishi mumkin, shuning uchun
# `users` jadvali paydo bo'lgunча kutamiz.
for _ in $(seq 1 40); do
    BACKEND="$ROOT/backend" "$PY" - <<'PYEOF' > /dev/null 2>&1 && break
import asyncio, os, sys
sys.path.insert(0, os.environ["BACKEND"])
async def m():
    from sqlalchemy import text
    from app.db.session import async_session
    async with async_session() as db:
        await db.execute(text("SELECT 1 FROM users LIMIT 1"))
asyncio.run(m())
PYEOF
    sleep 1
done
cat > "$tmp/seed.py" <<'EOF'
import asyncio, os, sys
sys.path.insert(0, os.environ["BACKEND"])


async def m():
    from sqlalchemy import delete, select
    from app.core.security import hash_password
    from app.db.session import async_session
    from app.models.marketplace import Listing
    from app.models.user import User

    async with async_session() as db:
        # Har yurishда toza boshlanadi: e'lon chegarasi oldingi
        # yurishdan qolgan e'lonlarга urilib qolmasin.
        eski = (await db.execute(select(User).where(
            User.phone.in_(["+998911110001", "+998911110002",
                            "+998911110009"])))).scalars().all()
        for u in eski:
            await db.execute(delete(Listing).where(Listing.user_id == u.id))
            await db.delete(u)
        await db.commit()

        sot = User(name="Sotuvchi", surname="Test", phone="+998911110001",
                   hashed_password=hash_password("parol123"), balance=5000)
        xar = User(name="Xaridor", surname="Test", phone="+998911110002",
                   hashed_password=hash_password("parol123"), balance=0)
        adm = User(name="Admin", surname="Test", phone="+998911110009",
                   hashed_password=hash_password("parol123"),
                   is_admin=True, is_super_admin=True)
        db.add_all([sot, xar, adm])
        await db.commit()
    print("seed ok")


asyncio.run(m())
EOF
if ! BACKEND="$ROOT/backend" "$PY" "$tmp/seed.py" > "$tmp/seed.log" 2>&1; then
    echo "  ✗ Foydalanuvchilar yaratilmadi:"; tail -8 "$tmp/seed.log"; exit 1
fi


tok() {
    curl -s -X POST "$B/auth/login" -H 'Content-Type: application/json' \
        -d "{\"phone\":\"$1\",\"password\":\"parol123\"}" \
        | "$PY" -c 'import sys,json;print(json.load(sys.stdin)["access_token"])'
}
SOT="$(tok +998911110001)"
XAR="$(tok +998911110002)"
ADM="$(tok +998911110009)"

echo "── 1. Toifalar"
check "toifalar ochiladi" "10" \
      "$(curl -s "$B/marketplace/categories" -H "Authorization: Bearer $SOT" \
         | "$PY" -c 'import sys,json;print(len(json.load(sys.stdin)["categories"]))')"

echo "── 2. HAQIQIY rasm yuklash"
"$PY" - "$tmp" <<'EOF'
import struct, sys, zlib
d = sys.argv[1]
def ch(t, b):
    return struct.pack('>I', len(b)) + t + b + struct.pack('>I', zlib.crc32(t + b) & 0xffffffff)
for i, c in enumerate([(255, 0, 0), (0, 255, 0), (0, 0, 255)]):
    raw = b''.join(b'\x00' + bytes(c) * 8 for _ in range(8))
    open(f"{d}/r{i}.png", "wb").write(
        b'\x89PNG\r\n\x1a\n'
        + ch(b'IHDR', struct.pack('>IIBBBBB', 8, 8, 8, 2, 0, 0, 0))
        + ch(b'IDAT', zlib.compress(raw)) + ch(b'IEND', b''))
EOF
: > "$tmp/urls.txt"
for i in 0 1 2; do
    curl -s -X POST "$B/marketplace/photo" -H "Authorization: Bearer $SOT" \
        -F "file=@$tmp/r$i.png" >> "$tmp/urls.txt"
    echo >> "$tmp/urls.txt"
done
check "3 ta rasm yuklandi" "3" "$(grep -c '"url"' "$tmp/urls.txt")"

"$PY" - "$tmp" <<'EOF'
import json, re, sys
d = sys.argv[1]
urls = re.findall(r'"url":"([^"]+)"', open(f"{d}/urls.txt").read())[:3]
json.dump({"category": "telefon", "title": "iPhone 13 Pro 256GB",
           "description": "Ideal holatda", "price": 4500000, "currency": "UZS",
           "condition": "ideal", "address": "Toshkent, Chilonzor",
           "lat": 41.31, "lng": 69.24,
           "attributes": {"model": "iPhone 13 Pro", "xotira": "256GB"},
           "photos": urls}, open(f"{d}/body.json", "w"))
json.dump({"category": "telefon", "title": "Samsung S23 Ultra",
           "description": "Dollarda narx", "price": 500, "currency": "USD",
           "condition": "yangi", "address": "Toshkent",
           "attributes": {"model": "S23", "xotira": "512GB"},
           "photos": urls}, open(f"{d}/usd.json", "w"))
json.dump({"category": "telefon", "title": "Kam rasmli", "price": 100000,
           "condition": "yaxshi", "address": "Toshkent",
           "attributes": {"model": "X", "xotira": "64GB"},
           "photos": urls[:1]}, open(f"{d}/kam.json", "w"))
EOF

echo "── 3. E'lon berish"
curl -s -X POST "$B/marketplace" -H "Authorization: Bearer $SOT" \
    -H 'Content-Type: application/json' --data-binary "@$tmp/body.json" > "$tmp/listing.json"
LID="$("$PY" -c 'import json,sys;print(json.load(open(sys.argv[1])).get("id",0))' "$tmp/listing.json")"
check "e'lon yaratildi" "true" "$([ "${LID:-0}" -gt 0 ] && echo true || echo false)"
check "3 ta rasm biriktirildi" "3" \
      "$("$PY" -c 'import json,sys;print(len(json.load(open(sys.argv[1]))["photos"]))' "$tmp/listing.json")"
check "muddat 7 kunga qo'yildi" "true" \
      "$("$PY" - "$tmp/listing.json" <<'EOF'
import json, sys
from datetime import datetime, timezone
d = json.load(open(sys.argv[1]))
kun = (datetime.fromisoformat(d["expires_at"]) - datetime.now(timezone.utc)).days
print(str(6 <= kun <= 7).lower())
EOF
)"

check "rasm HTTP orqali ochiladi" "200" \
      "$(curl -s -o /dev/null -w '%{http_code}' \
         "http://127.0.0.1:$PORT$("$PY" -c 'import json,sys;print(json.load(open(sys.argv[1]))["photos"][0])' "$tmp/listing.json")")"

check "kam rasmli e'lon rad etiladi" "400" \
      "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$B/marketplace" \
         -H "Authorization: Bearer $SOT" -H 'Content-Type: application/json' \
         --data-binary "@$tmp/kam.json")"

echo "── 4. Xaridor qidiruvi"
curl -s "$B/marketplace/search?category=telefon&lat=41.30&lng=69.25" \
    -H "Authorization: Bearer $XAR" > "$tmp/search.json"
check "e'lon qidiruvda topildi" "1" \
      "$("$PY" -c 'import json,sys;print(len(json.load(open(sys.argv[1]))))' "$tmp/search.json")"
check "masofa hisoblandi" "true" \
      "$("$PY" -c 'import json,sys;print(str(json.load(open(sys.argv[1]))[0]["distance_km"] is not None).lower())' "$tmp/search.json")"
check "TELEFON RAQAMI javobda YO'Q" "true" \
      "$("$PY" -c 'import json,sys;d=json.load(open(sys.argv[1]))[0];print(str(not any("phone" in k for k in d)).lower())' "$tmp/search.json")"
check "sotuvchi o'z e'lonini ko'rmaydi" "0" \
      "$(curl -s "$B/marketplace/search?category=telefon" -H "Authorization: Bearer $SOT" \
         | "$PY" -c 'import sys,json;print(len(json.load(sys.stdin)))')"

echo "── 5. Valyuta: dollarli e'lon so'mda ko'rinadi"
curl -s -X POST "$B/marketplace" -H "Authorization: Bearer $SOT" \
    -H 'Content-Type: application/json' --data-binary "@$tmp/usd.json" > "$tmp/usd_out.json"
check "dollar so'mga aylantirildi" "true" \
      "$("$PY" - "$tmp/usd_out.json" <<'EOF'
import json, sys
d = json.load(open(sys.argv[1]))
# Kurs CBU'dan keladi; aniq raqam emas, mantiqiy oraliq tekshiriladi.
print(str(d["currency"] == "USD" and d["price"] == 500
          and 5_000_000 < (d["price_uzs"] or 0) < 8_000_000).lower())
EOF
)"

echo "── 6. Modal ma'lumoti va ko'rishlar"
check "begona ko'rgani sanaladi" "1" \
      "$(curl -s "$B/marketplace/$LID" -H "Authorization: Bearer $XAR" \
         | "$PY" -c 'import sys,json;print(json.load(sys.stdin)["views"])')"
check "egasining ko'rishi sanalmaydi" "1" \
      "$(curl -s "$B/marketplace/$LID" -H "Authorization: Bearer $SOT" \
         | "$PY" -c 'import sys,json;print(json.load(sys.stdin)["views"])')"
check "yo'q e'lon uchun 404" "404" \
      "$(curl -s -o /dev/null -w '%{http_code}' "$B/marketplace/999999" -H "Authorization: Bearer $XAR")"

echo "── 7. Firibgarlik ogohlantirishi va shikoyat"
check "ogohlantirish firibgarlik haqida" "true" \
      "$(curl -s "$B/marketplace/$LID/safety" -H "Authorization: Bearer $XAR" \
         | "$PY" -c 'import sys,json;print(str("firibgar" in json.load(sys.stdin)["text"].lower()).lower())')"
check "shikoyat support ticketiga tushdi" "true" \
      "$(curl -s -X POST "$B/marketplace/$LID/report" -H "Authorization: Bearer $XAR" \
         -H 'Content-Type: application/json' -d '{"reason":"Boshqa gap aytdi"}' \
         | "$PY" -c 'import sys,json;print(str(json.load(sys.stdin).get("ticket_id",0)>0).lower())')"

echo "── 8. Begona e'longa tegib bo'lmaydi"
check "xaridor sotildi qila olmaydi" "404" \
      "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$B/marketplace/$LID/sold" \
         -H "Authorization: Bearer $XAR")"
check "xaridor uzaytira olmaydi" "404" \
      "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$B/marketplace/$LID/extend" \
         -H "Authorization: Bearer $XAR")"

echo "── 9. Muddatni uzaytirish (haqiqiy to'lov)"
ESKI="$(curl -s "$B/marketplace/$LID" -H "Authorization: Bearer $SOT" \
        | "$PY" -c 'import sys,json;print(json.load(sys.stdin)["expires_at"])')"
YANGI="$(curl -s -X POST "$B/marketplace/$LID/extend" -H "Authorization: Bearer $SOT" \
         | "$PY" -c 'import sys,json;print(json.load(sys.stdin).get("expires_at",""))')"
check "muddat uzaydi" "true" \
      "$("$PY" -c 'import sys;print(str(sys.argv[2] > sys.argv[1]).lower())' "$ESKI" "$YANGI")"
check "balansdan yechildi (5000 -> 0)" "0.0" \
      "$(curl -s "$B/users/me" -H "Authorization: Bearer $SOT" \
         | "$PY" -c 'import sys,json;print(json.load(sys.stdin).get("balance"))')"
check "balans tugagach 402" "402" \
      "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$B/marketplace/$LID/extend" \
         -H "Authorization: Bearer $SOT")"

echo "── 10. Sotildi / qayta e'lon"
check "sotildi belgilanadi" "sold" \
      "$(curl -s -X POST "$B/marketplace/$LID/sold" -H "Authorization: Bearer $SOT" \
         | "$PY" -c 'import sys,json;print(json.load(sys.stdin)["status"])')"
check "sotilgani qidiruvdan chiqadi" "true" \
      "$(curl -s "$B/marketplace/search?query=iPhone" -H "Authorization: Bearer $XAR" \
         | "$PY" -c 'import sys,json;print(str(len(json.load(sys.stdin))==0).lower())')"
check "qayta e'lon qilinadi" "active" \
      "$(curl -s -X POST "$B/marketplace/$LID/reopen" -H "Authorization: Bearer $SOT" \
         | "$PY" -c 'import sys,json;print(json.load(sys.stdin)["status"])')"

echo "── 11. Adminka: sozlama darhol kuchga kiradi"
check "admin sozlamalarni ko'radi" "8" \
      "$(curl -s "$B/admin/marketplace-settings" -H "Authorization: Bearer $ADM" \
         | "$PY" -c 'import sys,json;print(len(json.load(sys.stdin)["settings"]))')"
check "oddiy foydalanuvchi ko'ra olmaydi" "403" \
      "$(curl -s -o /dev/null -w '%{http_code}' "$B/admin/marketplace-settings" \
         -H "Authorization: Bearer $SOT")"

curl -s -X PUT "$B/admin/marketplace-settings" -H "Authorization: Bearer $ADM" \
    -H 'Content-Type: application/json' -d '{"values":{"market_min_photos":4}}' > /dev/null
sleep 4
check "yangi rasm chegarasi ilovaga yetdi" "4" \
      "$(curl -s "$B/marketplace/categories" -H "Authorization: Bearer $XAR" \
         | "$PY" -c 'import sys,json;print(json.load(sys.stdin)["min_photos"])')"
check "3 ta rasm endi yetmaydi" "400" \
      "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$B/marketplace" \
         -H "Authorization: Bearer $SOT" -H 'Content-Type: application/json' \
         --data-binary "@$tmp/body.json")"
curl -s -X PUT "$B/admin/marketplace-settings" -H "Authorization: Bearer $ADM" \
    -H 'Content-Type: application/json' -d '{"values":{"market_min_photos":3}}' > /dev/null
sleep 4

echo "── 12. Adminka: bo'limni o'chirish butun oqimni to'xtatadi"
curl -s "$B/admin/feature-flags" -H "Authorization: Bearer $ADM" > "$tmp/flags.json"
"$PY" - "$tmp" false <<'EOF'
import json, sys
d, holat = sys.argv[1], sys.argv[2] == "true"
fl = json.load(open(f"{d}/flags.json"))["flags"]
json.dump({"flags": [{"key": f["key"],
                      "enabled": holat if f["key"] == "marketplace" else f["enabled"],
                      "message": f.get("message") or "",
                      "premium": bool(f.get("premium"))} for f in fl]},
          open(f"{d}/flags_put.json", "w"))
EOF
curl -s -X PUT "$B/admin/feature-flags" -H "Authorization: Bearer $ADM" \
    -H 'Content-Type: application/json' --data-binary "@$tmp/flags_put.json" > /dev/null
sleep 4
check "o'chirilganda qidiruv to'xtaydi" "403" \
      "$(curl -s -o /dev/null -w '%{http_code}' "$B/marketplace/search" -H "Authorization: Bearer $XAR")"
check "o'chirilganda e'lon berilmaydi" "403" \
      "$(curl -s -o /dev/null -w '%{http_code}' -X POST "$B/marketplace" \
         -H "Authorization: Bearer $SOT" -H 'Content-Type: application/json' \
         --data-binary "@$tmp/body.json")"
check "ilova bayrog'i ham yopiq ko'rsatadi" "False" \
      "$(curl -s "$B/config/features" \
         | "$PY" -c 'import sys,json;print(json.load(sys.stdin)["features"]["marketplace"]["enabled"])')"

"$PY" - "$tmp" true <<'EOF'
import json, sys
d, holat = sys.argv[1], sys.argv[2] == "true"
fl = json.load(open(f"{d}/flags.json"))["flags"]
json.dump({"flags": [{"key": f["key"],
                      "enabled": holat if f["key"] == "marketplace" else f["enabled"],
                      "message": f.get("message") or "",
                      "premium": bool(f.get("premium"))} for f in fl]},
          open(f"{d}/flags_put.json", "w"))
EOF
curl -s -X PUT "$B/admin/feature-flags" -H "Authorization: Bearer $ADM" \
    -H 'Content-Type: application/json' --data-binary "@$tmp/flags_put.json" > /dev/null
sleep 4
check "qayta yoqilganda ishlaydi" "200" \
      "$(curl -s -o /dev/null -w '%{http_code}' "$B/marketplace/search" -H "Authorization: Bearer $XAR")"

echo "── 13. Mening e'lonlarim"
check "/my/list ishlaydi" "true" \
      "$(curl -s "$B/marketplace/my/list" -H "Authorization: Bearer $SOT" \
         | "$PY" -c 'import sys,json;d=json.load(sys.stdin);print(str(len(d["listings"])>0 and "price" in d["extend"]).lower())')"

echo ""
echo "Natija: $ok o'tdi, $fail yiqildi"
[ "$fail" -gt 0 ] && exit 1
exit 0
