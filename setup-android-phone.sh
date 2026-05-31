#!/bin/bash
# Android telefon USB debug ruxsatini berish (bir marta ishga tushiring)
set -e
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
sudo cp "$SCRIPT_DIR/51-android-udev.rules" /etc/udev/rules.d/51-android.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
echo ""
echo "Telefonni USB dan chiqarib, qayta ulang."
echo "Telefonda 'USB debugging ruxsat berilsinmi?' degan oynada RUXSAT BER ni bosing."
echo ""
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$HOME/Android/Sdk/platform-tools:$PATH"
adb kill-server 2>/dev/null || true
adb start-server
adb devices -l
