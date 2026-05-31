#!/usr/bin/env bash
# Let's Encrypt HTTPS sertifikat (bepul, avtomatik yangilanadi)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SERVER_IP="$(curl -sf --max-time 5 ifconfig.me 2>/dev/null || echo '47.84.60.201')"
DOMAINS=(hubservis.uz www.hubservis.uz api.hubservis.uz)
EMAIL="${CERTBOT_EMAIL:-admin@hubservis.uz}"

echo "==> HTTPS sertifikat o'rnatish (Let's Encrypt)"
echo "    Server IP: $SERVER_IP"
echo ""

# DNS tekshiruvi
dns_ok=true
for d in hubservis.uz api.hubservis.uz; do
  ip="$(dig +short "$d" A @8.8.8.8 2>/dev/null | head -1)"
  if [[ "$ip" == "$SERVER_IP" ]]; then
    echo "  OK  $d -> $ip"
  else
    echo "  XATO  $d -> ${ip:-DNS topilmadi} (kutilgan: $SERVER_IP)"
    dns_ok=false
  fi
done

if [[ "$dns_ok" != true ]]; then
  echo ""
  echo "DNS hali tayyor emas. @HOST panelda yozuvlarni saqlang va 1-24 soat kuting."
  echo "Keyin qayta ishga tushiring: bash $0"
  echo ""
  echo "Kerakli DNS yozuvlar:"
  echo "  @    A    $SERVER_IP"
  echo "  api  A    $SERVER_IP"
  echo "  www  CNAME  hubservis.uz"
  exit 1
fi

# 80-port
if ! curl -sf --connect-timeout 5 "http://hubservis.uz/api/v1/health" -H "Host: api.hubservis.uz" >/dev/null 2>&1; then
  if ! curl -sf --connect-timeout 5 "http://$SERVER_IP/admin/login" -o /dev/null; then
    echo "XATO: 80-port ochiq emas. Aliyun Security Group da TCP 80 va 443 qo'shing."
    exit 1
  fi
fi

echo ""
echo "==> certbot o'rnatish..."
sudo apt-get update -qq
sudo apt-get install -y certbot python3-certbot-nginx

echo ""
echo "==> Sertifikat olish..."
sudo certbot --nginx \
  --non-interactive \
  --agree-tos \
  --email "$EMAIL" \
  -d hubservis.uz \
  -d www.hubservis.uz \
  -d api.hubservis.uz \
  --redirect

echo ""
echo "==> Avtomatik yangilash tekshiruvi..."
sudo certbot renew --dry-run

echo ""
echo "Tayyor! HTTPS manzillar:"
echo "  https://hubservis.uz/"
echo "  https://hubservis.uz/admin/login"
echo "  https://api.hubservis.uz/api/v1/health"
echo "  https://api.hubservis.uz/docs"
