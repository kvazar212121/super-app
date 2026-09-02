#!/usr/bin/env bash
# Premium dizayn shriftlarini Google Fonts CSS API orqali yuklaydi.
#
# NEGA CSS API: `fonts.google.com/download` HTML sahifa qaytaradi (ZIP emas),
# raw.githubusercontent esa katalog nomlari mos kelmasa 404 beradi. CSS API
# esa har og'irlik uchun to'g'ridan-to'g'ri .ttf havolasini beradi.
set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)/assets/fonts"
mkdir -p "$DIR"
UA="Mozilla/5.0 (X11; Linux x86_64)"

yukla() {
  local oila="$1" ogirlik="$2" fayl="$3"
  local url
  url=$(curl -s -A "$UA" \
    "https://fonts.googleapis.com/css2?family=${oila}:wght@${ogirlik}" \
    | grep -o 'https://[^)]*\.ttf' | head -1)
  if [ -z "$url" ]; then
    echo "XATO: $oila $ogirlik uchun havola topilmadi" >&2
    return 1
  fi
  curl -s -o "$DIR/$fayl" "$url"
  echo "$(stat -c%s "$DIR/$fayl") bayt  $fayl"
}

yukla "Plus+Jakarta+Sans" 400 PlusJakartaSans-Regular.ttf
yukla "Plus+Jakarta+Sans" 500 PlusJakartaSans-Medium.ttf
yukla "Plus+Jakarta+Sans" 600 PlusJakartaSans-SemiBold.ttf
yukla "Plus+Jakarta+Sans" 700 PlusJakartaSans-Bold.ttf

yukla "Cormorant+Garamond" 300 CormorantGaramond-Light.ttf
yukla "Cormorant+Garamond" 400 CormorantGaramond-Regular.ttf
yukla "Cormorant+Garamond" 600 CormorantGaramond-SemiBold.ttf
yukla "Cormorant+Garamond" 700 CormorantGaramond-Bold.ttf

yukla "Syne" 400 Syne-Regular.ttf
yukla "Syne" 600 Syne-SemiBold.ttf
yukla "Syne" 700 Syne-Bold.ttf
