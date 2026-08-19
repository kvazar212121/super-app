#!/bin/bash
# Debug APK ni telefonga o'rnatish (tayyor APK dan — qayta qurmasdan).
#
# NEGA ALOHIDA SKRIPT:
#   `flutter run` har safar qaytadan quradi (~2 daqiqa). APK allaqachon
#   qurilgan bo'lsa, uni to'g'ridan-to'g'ri o'rnatish 10-20 soniya oladi.
#
# ISHLATISH:
#   ./install-debug.sh            # ulangan telefonga o'rnatadi
#   ./install-debug.sh --build    # avval qayta quradi, keyin o'rnatadi
#
# DIQQAT — EMULYATOR HAQIDA:
#   Bu kompyuterda emulyator ishlatmang. Yuklanish parametrlarida
#   `pci=nomsi` turgani uchun NVMe disk bitta band IRQ liniyasida qoladi
#   va emulyator diskni qotiradi (iowait 47%, tizim muzlaydi).
#   Batafsil: `pci=nomsi` ni /etc/default/grub dan olib tashlang.
#   Haqiqiy telefon har holda tezroq va ishonchliroq.
set -e

export JAVA_HOME="$HOME/.local/jdk-17"
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"

cd "$(dirname "$0")"
APK="build/app/outputs/flutter-apk/app-debug.apk"

if [ "$1" = "--build" ] || [ ! -f "$APK" ]; then
  echo "==> Debug APK qurilmoqda (~2 daqiqa)..."
  flutter build apk --debug
fi

echo "==> Telefon qidirilmoqda..."
# Fizik telefonni emulyator ustidan afzal ko'ramiz.
DEVICE=$(adb devices | grep -v 'List' | grep 'device$' | grep -v emulator | awk '{print $1}' | head -1)
[ -z "$DEVICE" ] && DEVICE=$(adb devices | grep 'device$' | awk '{print $1}' | head -1)

if [ -z "$DEVICE" ]; then
  cat <<'EOF'
XATO: qurilma topilmadi.

Tekshiring:
  1. Telefon USB kabel bilan ulanganmi (zaryadlash kabeli emas, ma'lumot kabeli)
  2. Sozlamalar > Dasturchi rejimi > USB orqali nosozliklarni tuzatish (USB debugging) YOQILGANmi
  3. Telefon ekranida "Ushbu kompyuterga ruxsat berilsinmi?" so'rovi chiqsa — Ruxsat bering
  4. Telefon USB rejimini "Fayl uzatish (MTP)" ga qo'ying

Keyin qayta ishga tushiring: ./install-debug.sh
EOF
  exit 1
fi

echo "==> Qurilma: $DEVICE"
echo "==> O'rnatilmoqda ($(du -h "$APK" | cut -f1))..."
adb -s "$DEVICE" install -r "$APK"

echo "==> Ishga tushirilmoqda..."
adb -s "$DEVICE" shell monkey -p uz.hubservis.app -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1 \
  || echo "(ilovani telefondan qo'lda oching)"

echo "✅ Tayyor. Loglarni ko'rish: adb -s $DEVICE logcat | grep flutter"
