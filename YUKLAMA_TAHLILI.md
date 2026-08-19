# Yuklama tahlili: tizim 1 mln foydalanuvchini ko'taradimi?

> **Sana:** 2026-08-18
> **Usul:** taxmin emas — `tests/load_test.py` bilan HAQIQIY o'lchov
> (ishchi serverda, konteyner ichidan, tarmoq kechikishisiz).

---

## 1. Qisqa javob

**Hozirgi server bilan — yo'q.** Taxminan **8-15 ming kunlik faol
foydalanuvchi** (DAU) ni ko'taradi. 1 mln DAU uchun server 8-10 barobar
kuchaytirilishi va gorizontal bo'linishi kerak.

Yaxshi xabar: **arxitektura to'g'ri** — Redis pub/sub, ko'p worker,
stateless backend. Ya'ni muammo kodda emas, resursda. Bu esa server
qo'shish bilan hal bo'ladi.

---

## 2. Hozirgi server va o'lchangan natija

| Resurs | Qiymat |
|---|---|
| CPU | **2 yadro** (Xeon Platinum 8280 @ 2.7 GHz) |
| RAM | 7.8 GB (2.1 GB band) |
| Disk | 24 GB (tozalashdan keyin 70% band) |

### O'lchangan sig'im

| Parallel so'rov | Sig'im | Median javob | p95 javob | Xato |
|---|---|---|---|---|
| 20 | ~694 so'rov/sek | 46-135 ms | 104-696 ms | 0% |
| 50 | ~502 so'rov/sek | ~300 ms | ~1500 ms | 0% |
| 100 | ~308 so'rov/sek | 530-1320 ms | 1700-3550 ms | 0% |
| 200 | ~316 so'rov/sek | 870-2210 ms | 5000-6900 ms | 0.9% |

**Xulosa:** qulay ishlash chegarasi — **~50 parallel so'rov**.
Undan keyin javob vaqti keskin oshadi (foydalanuvchi "sekin" deb
seza boshlaydi).

### To'siq nima (o'lchangan)

Yuklama paytidagi holat:

```
backend : CPU 109%   RAM 428 MB   ← TO'SIQ SHU YERDA
db      : CPU  21%   RAM 146 MB
redis   : CPU 0.7%   RAM   9 MB
nginx   : CPU   0%   RAM  17 MB
```

Backend 2 yadroning 1.1 tasini yeb turibdi, baza esa bo'sh.
**To'siq — protsessor**, baza yoki xotira emas.

---

## 3. 1 mln foydalanuvchi nimani anglatadi

Real ilovalarda odatiy nisbatlar:

| Ko'rsatkich | Hisob | Qiymat |
|---|---|---|
| Ro'yxatdan o'tgan | — | 1 000 000 |
| Kunlik faol (DAU) | ~15% | 150 000 |
| Bir vaqtda onlayn (peak) | DAU ning ~5% | **7 500** |
| So'rov/sek (peak) | onlayn × 0.2 | **~1 500 RPS** |
| WebSocket ulanishi | onlayn ning ~60% | **~4 500** |

Bizning o'lchov: **~300-700 RPS** (yuklamaga qarab).
Kerak: **~1 500 RPS**. Ya'ni **2-5 barobar** yetishmaydi.

---

## 4. Topilgan va tuzatilgan muammolar

| # | Muammo | Ta'siri | Holat |
|---|---|---|---|
| 1 | `ulimit -n = 1024` | WebSocket **1018 tada** to'xtardi (32% xato) | ✅ 65535 |
| 2 | nginx `worker_connections 1024` | ~500 onlayn chegarasi | ✅ 16384 |
| 3 | PostgreSQL standart sozlama (`shared_buffers` 128 MB) | Baza diskdan o'qirdi | ✅ 2 GB |
| 4 | `Category.providers` `lazy="selectin"` | Har `/categories` da BARCHA provayder RAM'ga tortilardi | ✅ `lazy="raise"` |
| 5 | Disk 87% band (5.1 GB Docker axlati) | Disk to'lsa baza to'xtaydi | ✅ 70% |

### WebSocket o'lchovi

**Tuzatishdan OLDIN** (haqiqiy o'lchov):

| Ulanish | Natija |
|---|---|
| 200 | 200/200 tirik, 0 xato |
| 500 | 500/500 tirik, 0 xato |
| 900 | 900/900 tirik, 0 xato |
| 1500 | **1018 tirik, 482 xato (OSError)** ← `ulimit 1024` chegarasi |

Chegara aynan `ulimit -n = 1024` ga to'g'ri keldi (1018 ulanish +
xizmat fayllari), ya'ni sabab aniq topilgan.

> ⚠️ **Tuzatishdan KEYIN qayta o'lchanmagan.** Yangi `ulimit`
> qiymati konteynerda qo'llangani tekshirildi (`ulimit -n` → `65535`),
> lekin 1500+ ulanish bilan sinov o'tkazilmadi — serverga ulanish
> uzilib qoldi. Nazariy jihatdan chegara endi RAM va CPU ga bog'liq
> (har ulanish ~10-50 KB), ya'ni o'n minglab bo'lishi kerak.
> **Buni albatta tasdiqlang:**
>
> ```bash
> docker exec "$CID" python /app/load_test.py --users 2 --repeat 1 --ws 3000
> ```
>
> Kutilayotgan natija: 3000/3000 tirik, 0 xato.
> Agar yana ~1018 da to'xtasa — `ulimit` konteyner qayta
> ishga tushganda tiklanmagan, `docker-compose.yml` dagi
> `ulimits.nofile` ni tekshiring.

---

## 5. Kerakli server (bosqichma-bosqich)

### A. Hozirgi holat uchun yetarli (0-10 ming DAU)

| Resurs | Qiymat |
|---|---|
| CPU | 4 yadro |
| RAM | 8 GB |
| Disk | 100 GB SSD |
| Narx (taxminan) | $40-60/oy |

Bitta serverda hammasi (backend + db + redis + nginx).

### B. O'rta bosqich (50-150 ming DAU)

| Rol | CPU | RAM | Disk | Soni |
|---|---|---|---|---|
| Backend (API + WS) | 8 | 16 GB | 50 GB | 2 |
| PostgreSQL | 8 | 32 GB | 200 GB NVMe | 1 (+1 replika) |
| Redis | 2 | 8 GB | 20 GB | 1 |
| Nginx / balanslagich | 2 | 4 GB | 20 GB | 1 |

Narx: ~$400-600/oy.

### C. 1 mln foydalanuvchi (150 ming DAU, 7.5 ming onlayn)

| Rol | CPU | RAM | Disk | Soni | Izoh |
|---|---|---|---|---|---|
| **Backend (API)** | 8 | 16 GB | 50 GB | **4** | har biri ~400 RPS |
| **WebSocket** | 4 | 8 GB | 20 GB | **2** | alohida: uzoq ulanishlar |
| **PostgreSQL (asosiy)** | 16 | 64 GB | 500 GB NVMe | 1 | yozuv |
| **PostgreSQL (replika)** | 16 | 64 GB | 500 GB NVMe | 2 | o'qish (read replica) |
| **Redis** | 4 | 16 GB | 50 GB | 2 | kesh + pub/sub |
| **coturn (TURN)** | 4 | 8 GB | 20 GB | 2 | qo'ng'iroq relay |
| **Nginx / LB** | 4 | 8 GB | 50 GB | 2 | |
| **Fayl (rasm)** | — | — | S3/Spaces | — | serverda saqlamang |

**Jami: ~15 server, ~$2 500-4 000/oy** (DigitalOcean/Hetzner narxlari).

Arzonroq yo'l: Kubernetes/autoscale bilan yuklama past paytda
serverlarni o'chirish (tunda 3-4 barobar arzon).

---

## 6. Qo'ng'iroq (WebRTC) alohida hisob

Qo'ng'iroqlar odatda **peer-to-peer** ketadi, ya'ni server orqali
o'tmaydi. Lekin ~20% holatda (NAT/firewall) **TURN relay** kerak
bo'ladi va u trafikni o'zidan o'tkazadi.

| Ko'rsatkich | Hisob |
|---|---|
| Bir vaqtda qo'ng'iroq (peak) | onlayn ning ~2% = **150** |
| TURN kerak bo'ladiganlari | ~20% = **30** |
| Bitta ovozli qo'ng'iroq | ~50 kbit/s × 2 tomon |
| **TURN trafigi** | 30 × 100 kbit/s = **3 Mbit/s** |
| Video bo'lsa (500 kbit/s) | **30 Mbit/s** |

Xulosa: ovoz uchun 1 ta coturn server yetarli. **Video qo'shilsa**
kanal kengligi (bandwidth) asosiy xarajatga aylanadi — buni oldindan
hisoblang.

---

## 7. Kodda hali qilinishi kerak bo'lgan ishlar

Server qo'shish yetarli emas. 1 mln uchun quyidagilar shart:

### Yuqori ustuvorlik

1. **Rasmlarni S3/Spaces ga ko'chirish.** Hozir `uploads` volumida
   (55 MB). 1 mln foydalanuvchida bu yuzlab gigabayt bo'ladi va
   serverni ko'paytirganda rasmlar bitta serverda qolib ketadi.

2. **O'qish uchun replika.** Qidiruv va ro'yxatlar replikadan
   o'qilsin, asosiy baza faqat yozuvga.

3. **Keshlash.** `/categories`, `/config/features`, provayderlar
   ro'yxati — bular deyarli o'zgarmaydi, lekin har so'rovda bazadan
   o'qiladi. Redis'ga 60 soniyaga qo'yilsa baza yuki keskin tushadi.

4. **Sahifalash majburiy.** 40 ta joyda `scalars().all()` limitsiz
   ishlatilgan. Jadval o'sganda bu xotirani yeydi.

### O'rta ustuvorlik

5. **WebSocket'ni alohida servisga ajratish.** Uzoq ulanishlar API
   worker'larini band qiladi.

6. **Rate limiting'ni kuchaytirish.** Hozir Redis'da, lekin
   `/ai/chat` kabi qimmat yo'llarga alohida chegara kerak.

7. **Monitoring.** Prometheus + Grafana: RPS, javob vaqti, xatolar,
   baza ulanishlari. Hozir muammoni faqat foydalanuvchi aytganda
   bilamiz.

8. **AI xarajati.** 150 ming DAU × kuniga 2 so'rov = 300 ming
   AI chaqiruvi/kun. Gemini/OpenAI narxida bu oyiga minglab dollar.
   Keshlash va limit qo'yish shart.

---

## 8. O'lchashni qanday takrorlash

```bash
# Serverda (konteyner ichidan — tarmoq kechikishisiz)
CID=$(docker compose ps -q backend | head -1)
docker cp tests/load_test.py "$CID":/app/load_test.py

# Bosqichma-bosqich yuklama
docker exec "$CID" python /app/load_test.py --users 20  --repeat 5
docker exec "$CID" python /app/load_test.py --users 100 --repeat 4
docker exec "$CID" python /app/load_test.py --users 200 --repeat 4

# WebSocket sig'imi
docker exec "$CID" python /app/load_test.py --users 3 --repeat 1 --ws 900

# Yuklama paytida to'siqni topish
docker stats --no-stream
```

**O'qish qoidasi:**
- `p95 < 500 ms` va `xato < 1%` — sog'lom
- `p95 > 2000 ms` — foydalanuvchi sekinlikni sezadi
- `xato > 1%` — chegaraga yetildi
- `docker stats` da qaysi konteyner 100% ga yaqin — o'sha to'siq
