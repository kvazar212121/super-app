#!/usr/bin/env bash
# Super-app testlarini ishga tushiradi.
#
# Ishlatish:
#   bash tests/run.sh
#   PYTHON=/path/to/venv/bin/python bash tests/run.sh
#
# Integratsiya testi HAQIQIY PostgreSQL talab qiladi. Berilmasa SKIP:
#   SUPERAPP_TEST_DB=postgresql+asyncpg://user:pass@host:port/db bash tests/run.sh
#
# DIQQAT: test bazasi drop_all/create_all qiladi — ishchi bazani
# KO'RSATMANG, alohida test bazasi yarating.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PYTHON="${PYTHON:-python3}"

pass=0
fail=0
failed=""

for t in "$ROOT"/tests/test_*.py; do
    name="$(basename "$t")"
    printf '── %-36s ' "$name"
    if out="$("$PYTHON" "$t" 2>&1)"; then
        if echo "$out" | grep -q '^SKIP:'; then
            echo "SKIP"
        else
            echo "O'TDI"
        fi
        pass=$((pass + 1))
    else
        echo "YIQILDI"
        echo "$out" | tail -20 | sed 's/^/      /'
        fail=$((fail + 1))
        failed="$failed $name"
    fi
done

echo ""
echo "Natija: $pass o'tdi, $fail yiqildi"
if [ "$fail" -gt 0 ]; then
    echo "Yiqilganlar:$failed"
    exit 1
fi
