#!/bin/bash
# Super App — release APK yig'ish va ixtiyoriy o'rnatish
set -e

export JAVA_HOME="${JAVA_HOME:-$HOME/.local/jdk-17}"
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Android/Sdk}"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

cd "$(dirname "$0")"

# APK telefonga to'g'ridan-to'g'ri o'rnatish uchun eski (debug) kalit bilan imzolanadi.
# Play Market'ga boradigan AAB esa release kalit bilan: flutter build appbundle --release
export ORG_GRADLE_PROJECT_debugSign=true

# Xarita kaliti. Kod ichida saqlanmaydi — build paytida beriladi.
#   MAPTILER_KEY=... ./build-apk.sh
# yoki .env.local faylida saqlanadi (git'ga tushmaydi).
if [ -z "${MAPTILER_KEY:-}" ] && [ -f ".env.local" ]; then
  set -a; . ./.env.local; set +a
fi
DEFINES=""
if [ -n "${MAPTILER_KEY:-}" ]; then
  DEFINES="--dart-define=MAPTILER_KEY=$MAPTILER_KEY"
  echo "Xarita: MapTiler (kalit topildi)"
else
  echo "OGOHLANTIRISH: MAPTILER_KEY yo'q — xarita OSM demo serverida ishlaydi."
  echo "  Ommaviy relizda bu TAQIQLANGAN (OSM Tile Usage Policy): so'rovlar bloklanib xarita oq bo'lib qolishi mumkin."
  echo "  Tuzatish: MAPTILER_KEY=sizning_kalitingiz ./build-apk.sh"
fi

echo "=== Flutter APK (release) yig'ilmoqda ==="
flutter build apk --release $DEFINES

APK="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK" ]; then
  echo "Xatolik: APK topilmadi: $APK"
  exit 1
fi

echo ""
echo "Tayyor: $APK"
ls -lh "$APK"

INSTALL="${1:-}"
if [ "$INSTALL" = "--install" ] || [ "$INSTALL" = "-i" ]; then
  PHYSICAL=$(adb devices | grep -v 'List\|emulator' | grep 'device$' | awk '{print $1}' | head -1)
  if [ -z "$PHYSICAL" ]; then
    echo "Telefon ulanmagan — APK ni qo'lda o'rnating yoki USB debugging yoqing."
    exit 1
  fi
  echo ""
  echo "O'rnatilmoqda: $PHYSICAL"
  adb -s "$PHYSICAL" install -r "$APK"
  echo "O'rnatildi."
fi
