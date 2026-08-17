# Serverga chiqarish (deploy)

Bu hujjat `hubservis.uz` serveriga yangi versiyani chiqarish tartibini
beradi. Har bir qadam nima uchun kerakligi izohlangan.

---

## 1. Bu chiqarishda nima yangi

| Bo'lim | Nima qo'shildi |
|---|---|
| AI orqali e'lon berish | rasm + suhbatdan e'lon, tasdiq so'rash, ikki tillilik, adminkada premium tugmasi |
| E'lon hududi | e'lon faqat shu hududdagi ustalarga ko'rinadi (50 km, sozlanadi) |
| Chat | xabar e'longa bog'lanadi, real vaqtda keladi, usta reytingi ko'rinadi |
| E'lon maxfiyligi | ustaning haqiqiy telefon raqami mijozga BERILMAYDI |
| E'lon chegaralari | 3 ta ochiq / 5 kun (premium 20 / cheksiz) — AI va formaga bir xil |
| Xarita | tile provayderi bitta joyda (`MapConfig`), MapTiler kaliti, litsenziya atributi |
| Xizmat hub | yangi ro'yxat + xarita dizayni 25 xizmatga tarqatildi, top reytingli bo'limi |
| Sovrinli sezonli reyting | `campaigns`, `campaign_votes` jadvallari, admin bo'limi, Flutter ekrani |

Ilova versiyasi: **1.3.0+2026**.

---

## 2. Bazaga o'zgarish (MUHIM)

Ikki xil o'zgarish bor va ular **turlicha** qo'llanadi:

**a) Yangi jadvallar** (`campaigns`, `campaign_votes`, `job_posts`,
`job_offers`) — ishga tushishda `Base.metadata.create_all`
(`app/core/startup.py`) ularni o'zi yaratadi.

**b) Mavjud jadvalga yangi ustun** — `create_all` buni **qila
olmaydi**. Shuning uchun `startup.py` da aniq `ALTER TABLE` yoziladi.
Bu chiqarishda:

```sql
ALTER TABLE direct_messages ADD COLUMN IF NOT EXISTS job_id INTEGER;
CREATE INDEX IF NOT EXISTS ix_direct_messages_job_id ON direct_messages (job_id);
```

U `startup.py` da allaqachon bor, ya'ni konteyner qayta ishga
tushganda o'zi bajariladi. Qo'lda hech narsa qilish shart emas,
lekin ko'tarilgandan keyin tasdiqlang:

```bash
docker compose exec db psql -U postgres -d superapp \
  -c "\d direct_messages" | grep job_id
```

Alembic migratsiyasi yozilmagan — loyiha shu uslubda ishlaydi.

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
MAPTILER_KEY=... ./build-apk.sh              # release APK, prod URL bilan
MAPTILER_KEY=... ./build-apk.sh --install    # qurib, telefonga o'rnatish
```

### ⚠️ XARITA KALITI (yangi, MAJBURIY)

Xarita tile'lari endi `MapConfig` orqali keladi. Kalit **build paytida**
beriladi, kodga yozilmaydi:

```bash
echo 'MAPTILER_KEY=sizning_kalitingiz' > .env.local   # git'ga tushmaydi
./build-apk.sh
```

Kalitsiz qurilsa ilova OSM demo serverida ishlaydi. Bu ommaviy relizda
**taqiqlangan** (OSM Tile Usage Policy): foydalanuvchi ko'paysa so'rovlar
bloklanadi va xarita oq bo'lib qoladi. `build-apk.sh` kalit yo'qligida
ogohlantiradi.

Kalit olish: <https://cloud.maptiler.com> (oyiga 100 000 so'rov bepul).

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

# 3D xarita HAQIQATAN binolarni ko'taradimi (brauzerda RENDER qiladi)
python3 scripts/check_3d_map.py

# Backend (bazasiz integratsiya testlari yiqilmaydi, SKIP bo'ladi)
PYTHON=backend/.venv/bin/python bash tests/run.sh
```

> `check_3d_map.py` kod tekshiruvi emas, haqiqiy render. U xaritani
> ilovadagi sozlamalar bilan chizadi va MapLibre'dan so'raydi: nechta
> bino ko'rinmoqda, balandliklari qanday, kamera qanday egilgan.
> Chrome kerak; bo'lmasa SKIP bo'ladi. Natija skrinshoti
> `build/map3d_tekshiruv.png` ga saqlanadi.

### Integratsiya testlari — SERVERDA, konteyner ichida

Server hostida Python kutubxonalari yo'q, shuning uchun testlar backend
image'i bilan ishlatiladi. Test bazasi **alohida** (`superapp_test`),
ishchi bazaga tegilmaydi:

```bash
# Bir marta: test bazasini yaratish
cd ~/super-app/backend
docker compose exec -T db psql -U postgres -c "CREATE DATABASE superapp_test"

# Testlar
cd ~/super-app
docker run --rm --network backend_default \
  -v ~/super-app/tests:/work/tests:ro \
  -v ~/super-app/backend:/work/backend:ro \
  -e SUPERAPP_TEST_DB="postgresql+asyncpg://postgres:postgres@db:5432/superapp_test" \
  -w /work backend-backend \
  bash -c 'for t in tests/test_*.py; do echo "== $t"; python "$t" | tail -3; done'
```

> Testlar sxemani tozalab qayta quradi. `SUPERAPP_TEST_DB` ga ishchi
> bazani (`superapp`) hech qachon ko'rsatmang.

Hozirgi holat (2026-08-17, serverda amalda tekshirilgan): Flutter
**163 test**, `analyze` 0 error; `tests/` da **13 fayl** — haqiqiy
PostgreSQL bilan **10 tasi o'tadi**, 3 tasi shu muhitga aloqasiz (SKIP).

> Bu qadamni tashlab ketmang: aynan shu tartib bugun ikkita haqiqiy
> xatoni topdi, ular bazasiz ko'rinmasdi.

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
