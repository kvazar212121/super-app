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

echo "=== Flutter APK (release) yig'ilmoqda ==="
flutter build apk --release

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
