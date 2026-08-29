#!/usr/bin/env bash
# Emulatorda ekranlarni ketma-ket ochib skrinshot oladi (dizayn tekshiruvi).
#
# NEGA bu shaklda: oldingi urinishda `keyevent 4` (orqaga) ilovadan butunlay
# CHIQIB ketardi va qolgan rasmlar Android bosh ekranini suratga olardi.
# Endi har bir bo'lim oldidan ilova QAYTA ishga tushiriladi — holat har doim
# bir xil (bosh sahifa), koordinatalar esa ishonchli bo'ladi.
#
# Koordinatalar 1080x2400 (Pixel 7 emulator) uchun.
set -u

ADB="$HOME/Android/Sdk/platform-tools/adb"
PAKET="uz.hubservis.app"
CHIQISH="${1:-/tmp/lux-shots}"
rm -rf "$CHIQISH"; mkdir -p "$CHIQISH"

bos()  { $ADB shell input tap "$1" "$2"; sleep "${3:-3}"; }
rasm() { $ADB exec-out screencap -p > "$CHIQISH/$1.png"; echo "  → $1"; }

# Ilovani toza holatda qayta ochadi (force-stop + launch).
boshiga() {
  $ADB shell am force-stop "$PAKET"
  sleep 1
  $ADB shell monkey -p "$PAKET" 1 >/dev/null 2>&1
  sleep "${1:-9}"
}

# Bosh sahifadan bitta elementni ochib rasmga oladi.
ochib_ol() {
  local x="$1" y="$2" nom="$3" kut="${4:-4}"
  boshiga
  bos "$x" "$y" "$kut"
  rasm "$nom"
}

echo "Ekranlar ko'zdan kechirilmoqda -> $CHIQISH"

boshiga
rasm "01-asosiy"

# ── Kundalik kartalari (3 ustun x 2 qator) ──
ochib_ol 200 1120 "02-kaloriya"
ochib_ol 540 1120 "03-fitnes"
ochib_ol 875 1120 "04-rejalarim"
ochib_ol 200 1520 "05-moliyam"
ochib_ol 540 1520 "06-aqlli-savdo"
ochib_ol 875 1520 "07-budilnik"

# ── Header tugmalari ──
ochib_ol 830 228 "08-bildirishnoma"
ochib_ol 970 228 "09-profil"
ochib_ol 215 228 "10-ob-havo" 3
ochib_ol 578 228 "11-valyuta" 3

# ── Hero banner va barcha xizmatlar ──
ochib_ol 540 560  "12-aksiya-xarita" 6
ochib_ol 540 1840 "13-barcha-xizmatlar" 5

# ── Pastki menyu tablari ──
ochib_ol 330 2245 "14-xizmatlar" 3
ochib_ol 540 2245 "16-aihub-chat" 5
ochib_ol 750 2245 "17-aloqa" 3
ochib_ol 960 2245 "18-buyurtmalar" 4

# Xizmatlar ichidagi bitta hub (ikki bosqichli).
boshiga
bos 330 2245 3
bos 200 600 5
rasm "15-xizmat-hub"

echo "Tayyor: $(ls -1 "$CHIQISH" | wc -l) ta rasm"
