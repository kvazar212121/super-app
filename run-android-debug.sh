#!/bin/bash
# Super App — Android telefonda debug rejimida ishga tushirish
set -e

export JAVA_HOME="$HOME/.local/jdk-17"
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

cd "$(dirname "$0")"

echo "=== Ulangan qurilmalar ==="
flutter devices
echo ""

DEVICE="${1:-}"
if [ -z "$DEVICE" ]; then
  # Fizik telefonni emulator ustidan tanlash
  PHYSICAL=$(adb devices | grep -v 'List\|emulator' | grep 'device$' | awk '{print $1}' | head -1)
  if [ -n "$PHYSICAL" ]; then
    DEVICE="$PHYSICAL"
    echo "Fizik telefon tanlandi: $DEVICE"
  fi
fi

if [ -n "$DEVICE" ]; then
  flutter run -d "$DEVICE"
else
  flutter run
fi
