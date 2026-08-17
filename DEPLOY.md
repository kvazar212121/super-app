# Serverga chiqarish (deploy)

Bu hujjat `hubservis.uz` serveriga yangi versiyani chiqarish tartibini
beradi. Har bir qadam nima uchun kerakligi izohlangan.

---

## 1. Bu chiqarishda nima yangi

| Bo'lim | Nima qo'shildi |
|---|---|
| Sovrinli sezonli reyting | `campaigns`, `campaign_votes` jadvallari, admin panel bo'limi, Flutter ekrani |
| Ish e'lonlari | `job_posts`, `job_offers` jadvallari, 11 endpoint, mijoz va usta ekranlari |
| Moliya | kelajakdagi sana rad etiladi, rejalashtirilgan to'lovda summa validatsiyasi |
| Mini-ilovalar | 5 ta mantiqiy xato tuzatildi (tur, manfiy summa, budilnik `repeat_days`) |
| Admin monitoring | firibgarlik statistikasi, push qamrovi, e'lonlar konversiyasi |

Ilova versiyasi: **1.2.0+2025**.

---

## 2. Bazaga o'zgarish (MUHIM)

Yangi **4 ta jadval** qo'shildi: `campaigns`, `campaign_votes`,
`job_posts`, `job_offers`.

Alembic migratsiyasi **yozilmagan**, chunki loyiha ishga tushishda
`Base.metadata.create_all` chaqiradi (`app/core/startup.py`) va u
yetishmayotgan jadvallarni o'zi yaratadi.

Bu ish holati **haqiqiy PostgreSQL 16 da sinab ko'rildi**: eski kod
bilan baza yaratilib, ustiga yangi kod qo'yildi. Natija: 4 ta jadval
ham, soxta ovozga qarshi `uq_campaign_vote_once` UNIQUE cheklovi ham
to'g'ri yaratildi.

> Diqqat: `create_all` MAVJUD jadvalga yangi ustun qo'sha olmaydi.
> Bu chiqarishda mavjud jadvallarga ustun qo'shilmagan, shuning uchun
> muammo yo'q. Kelgusida ustun qo'shsangiz, `startup.py` dagi
> `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` uslubidan foydalaning.

Zaxira nusxa (chiqarishdan oldin doim):

```bash
docker compose exec db pg_dump -U postgres superapp > ~/superapp_$(date +%F_%H%M).sql
```

---

## 3. Server tomoni

```bash
cd ~/super-app          # serverdagi joylashuv
git pull origin main

cd backend
docker compose build backend      # requirements o'zgargan bo'lsa
docker compose up -d backend nginx

# Jadvallar yaratilganini tasdiqlash
docker compose exec db psql -U postgres -d superapp -c "\dt" | grep -E 'campaign|job_'
```

`app/` katalogi volume orqali ulangani uchun Python kodi rebuild'siz
ham yangilanadi, lekin **konteynerni qayta ishga tushirish shart**
(`startup.py` yangi jadvallarni o'shanda yaratadi).

Tekshirish:

```bash
curl -s -o /dev/null -w "%{http_code}\n" https://hubservis.uz/api/v1/health          # 200
curl -s -o /dev/null -w "%{http_code}\n" https://hubservis.uz/api/v1/campaigns/active # 200
curl -s -o /dev/null -w "%{http_code}\n" https://hubservis.uz/api/v1/jobs/feed        # 401 (token kerak — normal)
```

`404` qaytsa, yangi kod hali ko'tarilmagan.

### Nginx

`deploy/nginx/` dagi konfiglar haqiqiy nginx 1.24 bilan
`nginx -t` orqali sinaldi, sintaksis to'g'ri.

---

## 4. Ilova (APK)

```bash
./build-apk.sh              # release APK, prod URL bilan
./build-apk.sh --install    # qurib, ulangan telefonga o'rnatish
```

APK **debug kalit** bilan imzolanadi (telefonga to'g'ridan-to'g'ri
o'rnatish uchun). Play Market'ga boradigan AAB esa release kalit bilan:

```bash
flutter build appbundle --release
```

Kerakli, lekin git'da saqlanmaydigan fayllar:

- `android/app/google-services.json` (Firebase push)
- `android/key.properties` va keystore (release imzo)
- `backend/.env`, `backend/serviceAccountKey.json`

### Telefonga debug versiya

```bash
flutter build apk --debug
adb install -r -t -d build/app/outputs/flutter-apk/app-debug.apk
```

`-d` bayrog'i versiya raqami telefondagidan kichik bo'lsa kerak
(`INSTALL_FAILED_VERSION_DOWNGRADE`).

Lokal backendga ulash uchun `lib/config/app_config.dart` da
`apiBaseUrl` ni kompyuter IP'siga o'zgartiring VA o'sha IP'ni
`android/app/src/main/res/xml/network_security_config.xml` ga
qo'shing (aks holda Android cleartext HTTP so'rovni bloklaydi).
Chiqarishdan oldin ikkalasini ham qaytarishni unutmang.

---

## 5. Chiqarishdan oldingi tekshiruv

```bash
# Flutter
flutter analyze && flutter test

# Backend (haqiqiy PostgreSQL kerak)
export SUPERAPP_TEST_DB="postgresql+asyncpg://postgres@127.0.0.1:5435/superapp_test"
for f in tests/test_*.py; do python "$f"; done
```

Hozirgi holat: Flutter 10 test, `analyze` 0 error;
backend 6 fayl, 165 tekshiruv.

---

## 6. Orqaga qaytarish

```bash
git log --oneline -5
git checkout <oldingi_commit>
cd backend && docker compose up -d --build backend
```

Jadvallar qo'shilishi **buzuvchi emas**: eski kod yangi jadvallarni
shunchaki ko'rmaydi, mavjud ma'lumotga tegilmaydi. Shuning uchun
orqaga qaytarish uchun bazani tiklash shart emas.
