# HubServis — Arxitektura Hujjati

> **Bu loyihaning YAGONA arxitektura hujjati.**
> Oxirgi tekshirilgan: **2026-09-06** · Tarmoq: `main`

---

## ⚠️ Bu hujjatni qanday yuritish kerak (AI agentlar uchun)

Bu fayl — loyihaning **yagona haqiqat manbai**. Ishni boshlashdan oldin shuni
o'qing, tugatgandan keyin shuni yangilang.

**Qoidalar:**

1. **Yangi arxitektura `.md` fayli YARATMANG.** O'zgarish kiritsangiz — shu
   faylning tegishli bo'limiga yozing. Loyihada ilgari 8 ta tarqoq hujjat bor
   edi, ular bir-biriga zid bo'lib qolgan edi. Shuning uchun birlashtirildi.
2. **Raqam yozsangiz — koddan oling, hujjatdan ko'chirmang.** Har bo'limdagi
   raqamlar (fayl soni, tool soni) qanday olinganini §3 dagi buyruqlar
   ko'rsatadi. Ular eskirsa — qayta hisoblang.
3. **O'zgarish kiritdingizmi — §19 "O'zgarishlar jurnali" ga bir qator qo'shing.**
   Sana + nima o'zgardi + qaysi bo'lim yangilandi.
4. **Hujjat kod bilan zid kelsa — KOD haqiqat.** Hujjatni tuzating, kodni emas.
5. Sarlavha raqamlarini o'zgartirmang (§1, §2 …) — ular havolalarda ishlatiladi.

**Bu hujjat qamramaydigan narsalar** (ataylab, chunki tez eskiradi):
konkret chiqarish qadamlari, vaqtinchalik rejalar, bajarilgan ishlar arxivi.
Ular uchun `git log` va `docs/qilingan_ishlar/` bor.

---

## 📑 Mundarija

| § | Bo'lim |
|---|---|
| [1](#1-loyiha-nima) | Loyiha nima |
| [2](#2-texnologiya-toplami) | Texnologiya to'plami |
| [3](#3-loyiha-raqamlarda) | Loyiha raqamlarda |
| [4](#4-tizim-arxitekturasi) | Tizim arxitekturasi |
| [5](#5-backend-arxitekturasi) | Backend arxitekturasi |
| [6](#6-malumotlar-bazasi) | Ma'lumotlar bazasi |
| [7](#7-migratsiyalar-alembic) | Migratsiyalar (Alembic) |
| [8](#8-autentifikatsiya-va-xavfsizlik) | Autentifikatsiya va xavfsizlik |
| [9](#9-real-time-qongiroq-va-chat) | Real-time: qo'ng'iroq va chat |
| [10](#10-ai-agent) | AI agent |
| [11](#11-fon-jarayonlari-scheduler) | Fon jarayonlari (scheduler) |
| [12](#12-flutter-arxitekturasi) | Flutter arxitekturasi |
| [13](#13-admin-panel) | Admin panel |
| [14](#14-moliya-modeli) | Moliya modeli |
| [15](#15-deployment) | Deployment |
| [16](#16-masshtab-va-unumdorlik) | **Masshtab va unumdorlik** (1 mln foydalanuvchi) |
| [17](#17-malum-muammolar) | Ma'lum muammolar |
| [18](#18-ishlash-qoidalari) | Ishlash qoidalari |
| [19](#19-ozgarishlar-jurnali) | O'zgarishlar jurnali |

---

## 1. Loyiha nima

**HubServis** (`super_app`) — O'zbekiston uchun xizmatlar super-app'i.
Uchta mustaqil biznes yo'nalishi bitta ilovada:

### A) Xizmatlar marketplace — asosiy biznes

Foydalanuvchi usta/xizmat qidiradi (sartarosh, elektrik, santexnik, enaga,
repetitor, hamshira va h.k. — **28 kategoriya**). Ikki yo'l bilan:

- **To'g'ridan-to'g'ri bron** — provayder profilini ochib vaqt tanlaydi
- **E'lon berish (`jobs`)** — "menga elektrik kerak" deb yozadi, ustalar
  taklif yuboradi

### B) Buyum savdosi (`marketplace` moduli, OLX uslubi)

Foydalanuvchilar buyum sotadi/sotib oladi. **`jobs` dan butunlay ALOHIDA
modul** — birlashtirmang (§18).

### C) Shaxsiy productivity modullari

Rejalar, moliya, kaloriya, fitnes, budilnik, bozorlik ro'yxati. Bular
foydalanuvchini ilovaga qaytarish uchun (retention), pul keltirmaydi.

### Monetizatsiya

| Manba | Kimdan | Qanday |
|---|---|---|
| **Lead fee** | Provayderdan | Buyurtma yakunlanganda balansdan yechiladi |
| **Premium obuna** | Foydalanuvchidan | Oylik/yillik, Payme/Click orqali |

Batafsil: §14.

---

## 2. Texnologiya to'plami

| Qatlam | Texnologiya |
|---|---|
| Mobil ilova | Flutter (Dart SDK `^3.10.7`) |
| Backend | FastAPI (Python 3.12), `uvicorn`, `WEB_CONCURRENCY=3` |
| Baza | PostgreSQL 16 (`postgres:16-alpine`) |
| Kesh / pub-sub | Redis 7 (`redis:7-alpine`) |
| ORM | SQLAlchemy 2.0 (async, `asyncpg`) + sync (`psycopg2`) |
| Migratsiya | Alembic |
| Qo'ng'iroq | WebRTC + `coturn` (TURN relay) |
| Reverse proxy | Nginx 1.27 |
| Admin panel | Vanilla HTML/JS (framework yo'q) |
| Push | Firebase Cloud Messaging |
| Orkestratsiya | Docker Compose |

---

## 3. Loyiha raqamlarda

> Raqamlar **2026-09-06** da quyidagi buyruqlar bilan olingan. Eskirsa qayta ishga tushiring.

```bash
# Flutter
find lib -name '*.dart' | wc -l                       # 315 fayl
find lib -name '*.dart' | xargs cat | wc -l           # 92 496 qator
find lib/screens -name '*.dart' | wc -l               # 173 ekran
find lib/services -name '*.dart' | wc -l              # 37 servis
find lib/widgets  -name '*.dart' | wc -l              # 56 vidjet
find lib/models   -name '*.dart' | wc -l              # 31 model
grep -rhoE '\b(test|testWidgets)\(' test integration_test | wc -l   # 268 test

# Backend
find backend/app -name '*.py' | wc -l                 # 225 fayl
find backend/app -name '*.py' | xargs cat | wc -l     # 29 810 qator
grep -c include_router backend/app/api/v1/router.py   # 49 router
grep -rh '__tablename__' backend/app/models/ | wc -l  # 47 jadval
find backend/app/services -name '*.py' | wc -l        # 70 servis
grep -c '"name":' backend/app/services/ai_agent/tools_schema.py   # 47 AI tool
```

---

## 4. Tizim arxitekturasi

```
┌─────────────────┐         ┌──────────────────┐
│  Flutter ilova  │◄───────►│   Nginx (443)    │
│  (Android/iOS)  │  HTTPS  │  reverse proxy   │
└────────┬────────┘   WSS   └────────┬─────────┘
         │                           │
         │ WebRTC (P2P)              ▼
         │                  ┌──────────────────┐
         │                  │  FastAPI backend │
         │                  │  3 uvicorn worker│
         │                  └───┬─────────┬────┘
         ▼                      │         │
   ┌───────────┐         ┌──────▼───┐ ┌──▼──────┐
   │  coturn   │         │PostgreSQL│ │  Redis  │
   │  (TURN)   │         │    16    │ │    7    │
   └───────────┘         └──────────┘ └─────────┘
```

**Redis nima uchun ishlatiladi** (4 ta vazifa):

1. **Pub/sub** — qo'ng'iroq signaling'i workerlar orasida (`core/call_manager.py`)
2. **Kesh** — kam o'zgaradigan ma'lumot, 2 qavatli: lokal 2s + Redis 60s (`core/cache.py`)
3. **Rate limiting** — `slowapi` (`core/limiter.py`)
4. **Leader saylovi** — schedulerlar faqat bitta workerda ishlashi uchun (`core/schedulers.py`)

> Redis o'chsa tizim **yiqilmaydi**: kesh chetlab o'tiladi, rate-limit xotiraga
> tushadi, schedulerlar shu protsessda ishlaydi. Bu ataylab shunday.

---

## 5. Backend arxitekturasi

### Qatlamlar

```
app/api/v1/*.py       ← HTTP qatlami: validatsiya, auth, javob
      ↓
app/services/*.py     ← biznes mantiq (BU YERDA)
      ↓
app/models/*.py       ← SQLAlchemy modellari
      ↓
app/db/session.py     ← sessiya va pul
```

**Qoida:** biznes mantiq `services/` da. API fayllari faqat so'rovni qabul
qilib servisga uzatadi.

### Kirish nuqtasi — `app/main.py`

- `lifespan` — startup: baza jadvallarini yaratish, kategoriya sinxroni,
  schedulerlarni ishga tushirish
- Middleware: `SlowAPIMiddleware` (rate limit), `RequestLoggingMiddleware`,
  CORS, xavfsizlik sarlavhalari
- `app.mount` — statik fayllar (admin panel, yuklamalar)
- Routerlar: `api_router` (`/api/v1` prefiksi) + `admin_panel_router`

### DB sessiya qatlami — `app/db/session.py`

Ikkita engine bor:

| Engine | Drayver | Pool | Nima uchun |
|---|---|---|---|
| `engine` (async) | `asyncpg` | 10 + 5 overflow | Barcha API so'rovlari |
| `sync_engine` | `psycopg2` | 2 + 3 overflow | Faqat notification/settings |

> `statement_cache_size=0` ataylab qo'yilgan: asyncpg so'rov rejasini keshlaydi,
> yangi jadval qo'shilgach eski reja yaroqsiz bo'lib tasodifiy 500 berardi.
> Bu haqiqiy chiqarishda uchragan.

### Papka tuzilishi

```
backend/app/
├── api/v1/           50 modul + admin/ (22 modul), router.py da 49 router
├── core/             config, security, cache, limiter, call_manager,
│                     schedulers, startup, logging_config, security_guard
├── db/               base.py, session.py
├── models/           47 jadval (marketplace/ alohida papkada)
├── schemas/          Pydantic sxemalari
├── services/         70 fayl — biznes mantiq
│   ├── ai_agent/     AI chat agenti (47 tool)
│   ├── ai_job/       e'lon yaratish AI yordamchisi + geo filtr
│   └── marketplace/  buyum savdosi mantig'i
├── static/admin/     admin panel (vanilla JS)
└── main.py
```

---

## 6. Ma'lumotlar bazasi

**47 jadval.** Asosiylari:

### Biznes yadrosi

| Jadval | Vazifasi | Muhim ustunlar |
|---|---|---|
| `users` | Foydalanuvchi | `phone` (unique), `balance`, `is_premium`, `premium_until` |
| `providers` | Usta/xizmat ko'rsatuvchi | `category_id`, `lat/lng`, `rating`, `balance`, `lead_fee`, `owner_user_id`, `metadata_json` |
| `categories` + `category_variants` | 28 xizmat toifasi | `lead_fee` (toifa darajasida) |
| `orders` | Buyurtma | `status` (enum), `booking_mode`, `date`, `price` |
| `reviews` | Sharh | `rating`, `provider_id` |
| `call_deals` | Bitim (aylanib o'tishga qarshi) | §9 |
| `transactions` | Pul harakati | `type` (`lead_fee`, `topup`, `premium`…) |

### E'lon va savdo

| Jadval | Vazifasi |
|---|---|
| `job_posts` + `job_offers` | Xizmat e'loni va ustalarning takliflari |
| `listings` + `listing_photos` | Buyum savdosi (OLX uslubi) |

### Boshqalar

`notifications`, `device_tokens`, `direct_messages`, `support_tickets`,
`support_messages`, `disputes`, `campaigns`, `promos`, `premium_payments`,
`admin_roles`, `audit_logs` + productivity modullari (`plans`, `todos`,
`alarms`, `finance_records`, `shopping_lists`, `workout_plans`, `meal_logs`…).

### Muhim naqshlar

- **`metadata_json`** — `providers` da har toifa uchun turlicha maydonlar shu
  JSON ustunda saqlanadi (`type`, `verification_status`, rol maydonlari).
  Yangi toifa qo'shishda jadval o'zgartirilmaydi.
- **Denormalizatsiya** — `providers.rating` va `review_count` oldindan
  hisoblangan, har so'rovda `AVG()` qilinmaydi.
- **`User.providers` ↔ `Provider.owner`** — `back_populates` bilan bog'langan
  (2026-09-06 da tuzatilgan; oldin ikkalasi bir FK ga mustaqil yozardi).

---

## 7. Migratsiyalar (Alembic)

> ⚠️ **Bu bo'lim 2026-09-06 da butunlay o'zgardi.** Ilgari hujjatlarda
> "Alembic ishlatilmaydi" deb yozilgan edi — bu endi **noto'g'ri**.

### Holat

Alembic **ishlaydi va modellar bilan to'liq mos**. Tekshirish:

```bash
cd backend && .venv/bin/alembic check     # "No new upgrade operations detected"
```

`alembic/env.py` **butun `app.models` paketini** import qiladi. Buni
buzmang: modellar to'liq import qilinmasa, `--autogenerate` ro'yxatga
tushmagan jadvallarni "ortiqcha" deb bilib **DROP TABLE** yozadi.

### Yangi migratsiya yaratish

```bash
cd backend
.venv/bin/alembic revision --autogenerate -m "nima qilindi"
.venv/bin/alembic check      # bo'sh chiqishi kerak
```

Yaratilgan faylni **albatta o'qing**. Autogenerate modellarda e'lon
qilinmagan indekslarni o'chirmoqchi bo'ladi.

### ⚠️ Mavjud bazalarda `upgrade head` ISHLATMANG

Ishchi baza va lokal baza jadvallarni `startup.py` dagi `create_all` orqali
olgan, ya'ni jadvallar bor, lekin Alembic ularni "yaratilmagan" deb biladi.
`upgrade head` qilsangiz `relation already exists` xatosi chiqadi.

**Mavjud baza uchun bir marta:**

```bash
.venv/bin/alembic stamp head    # "men shu versiyadaman" deb belgilaydi
```

To'liq `upgrade` faqat **yangi, bo'sh** baza uchun.

### Ustun qo'shish

Hozircha ikki yo'l birga ishlaydi: `startup.py` dagi
`ALTER TABLE ... IF NOT EXISTS` (eski uslub) va Alembic migratsiyasi (to'g'ri
uslub). **Yangi o'zgarish uchun Alembic ishlating.**

---

## 8. Autentifikatsiya va xavfsizlik

### Auth oqimi — SMS OTP

```
telefon raqam → OTP so'rash → SMS → kod tekshirish → JWT (access + refresh)
```

- Parol **yo'q** (`hashed_password` bor, lekin asosiy yo'l — OTP)
- OTP Redis'da, TTL bilan (`services/otp_service.py`)
- Test raqamlari: `services/otp_whitelist.py`

### JWT — `core/security.py`

| Token | Muddat |
|---|---|
| Access | 7 kun (10080 daqiqa) |
| Refresh | 365 kun |

Mobil ilova uchun ataylab uzun — foydalanuvchi har hafta qayta kirmasin.

### RBAC (admin)

`admin_roles` + `audit_logs`. Har admin amali jurnalga yoziladi.
`is_super_admin` — barcha huquqlar.

### Xavfsizlik choralari

- `core/security_guard.py` — production'da xavfli sozlama bilan ishga
  tushishni **bloklaydi** (`bypass_auth`, OTP oshkor qilish). Test bilan
  qo'riqlanadi.
- Rate limiting — `slowapi` (Redis)
- Xavfsizlik sarlavhalari — `main.py` middleware
- Sirlar `.env` da, kodda emas

---

## 9. Real-time: qo'ng'iroq va chat

### Signaling

WebSocket orqali. Ko'p worker bo'lgani uchun signaling Redis pub/sub bilan
tarqatiladi (`core/call_manager.py`) — aks holda 1-workerdagi foydalanuvchi
3-workerdagini ko'rmaydi.

Media **P2P** ketadi. NAT/firewall sabab ~20% holatda `coturn` (TURN) relay
kerak bo'ladi.

### CallDeal — biznes modelini himoya qilish

**Muammo:** mijoz va usta gaplashib, ilovadan tashqarida kelishib olsa,
platforma komissiyasiz qoladi.

**Yechim:** qo'ng'iroqdan keyin ikkala tomonga "kelishdingizmi?" dialogi
chiqadi. Kelishilsa `call_deals` yozuvi yaratiladi va buyurtmaga aylanadi.

> **Haqiqiy telefon raqami HECH QACHON berilmaydi.** Aloqa faqat ilova ichida
> (chat / WebRTC). Buni buzmang — biznes modeli shunga bog'liq (§18).

---

## 10. AI agent

`backend/app/services/ai_agent/` — **47 ta tool**.

### Yangi tool qo'shish

1. `tools_schema.py` ga sxema qo'shing
2. Mos modulga handler yozing (`booking_tools`, `market_tools`,
   `personal_tools`, `job_tools`, `manage_tools`, `read_tools`,
   `info_tools`, `nav_tools`, `provider_tools`)
3. `dispatcher.py` ga ulang

Sxema soni va handler soni **MOS** bo'lishi kerak — test tekshiradi.

### Qat'iy qoidalar

- **`confirm` darvozasi:** o'zgartiruvchi har amal avval xulosa qaytaradi,
  foydalanuvchi tasdiqlagach bajariladi. AI xato tushunsa haqiqiy bronni
  buzmasin.
- **`user_id` filtri majburiy:** har amal faqat so'rovchining o'z ma'lumotiga
  tegadi. Test qo'riqlaydi.
- **`dispatcher._parse_args` ni soddalashtirmang** — LLM ba'zan buzuq JSON
  qaytaradi, bu funksiya uni tiklaydi va haqiqiy 500 xatosini tuzatgan.

### Boshqa AI qismlar

- `ai_job/` — erkin gapdan e'lon yaratish + `geo.py` (hudud filtri)
- `services/vision_service.py` — rasm tahlili
- `services/ai_providers.py` — LLM provayderlari

### RAG/vektor qidiruv

**Ataylab ishlatilmaydi.** Asosiy filtrlar aniq (toifa, narx, holat, hudud) —
buni SQL tezroq va arzonroq bajaradi. AI erkin gapni shu filtrlarga aylantiradi.

---

## 11. Fon jarayonlari (scheduler)

`core/schedulers.py` — 7 ta scheduler. **Redis leader saylovi** bilan faqat
bitta workerda ishlaydi (leader o'lsa boshqasi oladi).

| Scheduler | Davri | Vazifasi |
|---|---|---|
| `plan_reminder_scheduler` | 15 s | Reja eslatmasi |
| `finance_reminder_scheduler` | 30 s | To'lov eslatmasi |
| `checkin_scheduler` | 15 s | Buyurtma check-in |
| `order_completion_scheduler` | 5 daq | Buyurtmani avtomatik yakunlash |
| `market_scraper_scheduler` | o'zgaruvchan | Narx yig'ish |
| `retention_scheduler` | 24 soat | 30 kundan eski `notifications` va `direct_messages` o'chirish |
| `listing_expiry_scheduler` | 30 daq | E'lon muddatini tekshirish |

> ⚠️ `plan_reminder_scheduler` ning so'rovi masshtabda muammoli — §16.3.

---

## 12. Flutter arxitekturasi

### Papkalar

```
lib/
├── config/       app_config.dart (API manzil), map_config.dart, provider_category_config.dart
├── l10n/         locale_controller.dart + translations.dart (uz/ru/en)
├── models/       31 model
├── providers/    holat boshqaruvi (provider paketi)
├── screens/      173 ekran
├── services/     37 servis (API mijozlari)
├── theme/        app_theme.dart, lux_tokens.dart, glass_tokens.dart
├── utils/
└── widgets/      56 qayta ishlatiluvchi vidjet
```

### Muhim naqshlar

- **Provayder kabineti birlashtirilgan:** har toifa uchun alohida ekran YO'Q.
  `UnifiedProviderDashboardScreen(config: ProviderCategoryConfig.<toifa>)`
  ishlatiladi. (Eski o'ramlar 2026-09-06 da o'chirildi.)
- **Tarjima:** `'matn'.tr` — `TrExtension` kengaytmasi
  (`l10n/locale_controller.dart`). Til o'zgarganda butun ilova qayta chiziladi.
- **Dizayn tizimi:** `LuxTokens` (Deep Navy + Soft Gold). Shriftlar **lokal
  asset** sifatida (`assets/fonts/`), `google_fonts` ataylab ishlatilmaydi —
  ilova oflaynda ham bir xil ko'rinadi va shrift "sakramaydi".
- **Xarita:** tile manzili faqat `lib/config/map_config.dart` da. Test qo'riqlaydi.

### 3D xarita

**Soxta 3D QILMANG.** Rasterni `Matrix4` bilan qiyshaytirish 3D emas —
binolar tekis qoladi. Haqiqiy 3D vektor style (`streets-v4`) + MapLibre
`pitch` bilan (`lib/screens/navigation_3d_screen.dart`). Bu bir marta
noto'g'ri qilingan va rad etilgan.

---

## 13. Admin panel

`backend/app/static/admin/` — vanilla HTML/JS, framework yo'q.

```
static/admin/
├── index.html
└── js/
    ├── router.js
    └── pages/        18 sahifa (dashboard, users, providers, orders,
                      finance, premium, campaigns, promos, reviews,
                      support, products, categories, notifications,
                      monitoring, reports, admins, ai_content, settings)
```

Backend tomoni: `app/api/v1/admin/` (22 modul) + `admin_panel.py`.

---

## 14. Moliya modeli

### Asosiy tamoyil

Platforma **buyurtma pulini ushlab qolmaydi**. Mijoz ustaga to'g'ridan-to'g'ri
to'laydi (naqd yoki o'zaro kelishuv). Platforma faqat **lead fee** oladi.

### Yagona hamyon — `user.balance`

Provayder balansni to'ldiradi, lead fee shundan yechiladi.

### Lead fee

- **Qachon:** buyurtma **yakunlanganda** (yaratilganda emas)
- **Qayerda:** `services/order_service.py`
- **Miqdor (ustuvorlik):** `provider.lead_fee` → `category.lead_fee` → `default_lead_fee` (platforma sozlamasi)
- **Idempotent:** bir buyurtma uchun ikki marta yechilmaydi (`transactions` da `type='lead_fee'` bo'yicha tekshiriladi)
- **Test:** `backend/tests/test_lead_fee.py`

### Premium obuna

Oddiy foydalanuvchidan. Payme/Click orqali. `users.is_premium` +
`premium_until`. Admin panelidan qo'lda ham berish mumkin (favqulodda holat).
Premium **balansga tegmaydi** — alohida oqim (`test_admin_balance_premium.py`).

### Tranzaksiya turlari

`transactions.type`: `lead_fee`, `topup`, `premium`, `refund` va h.k.

> Keshbek (`cashback`) — **deprecated**, olib tashlangan. `users.cashback` va
> `orders.cashback_earned` ustunlari qolgan, lekin ishlatilmaydi.

---

## 15. Deployment

### Tarkib

`backend/docker-compose.yml` — 5 xizmat: `db` (postgres:16), `redis`,
`backend` (`WEB_CONCURRENCY=3`), `nginx` (1.27), `coturn`.

### Chiqarish oqimi

```bash
# Serverda
git pull
docker compose up -d --build

# Baza: yangi jadval create_all bilan o'zi yaratiladi.
# Alembic ishlatsangiz — §7 dagi ogohlantirishni o'qing.
```

Yordamchi skriptlar `scripts/` da: `deploy-backend.sh`,
`deploy-production.sh`, `setup-nginx.sh`, `setup-ssl.sh`, `seed-demo.sh`,
`start-local.sh`.

### APK yig'ish

```bash
./build-apk.sh
```

> **Xarita kaliti majburiy:** `--dart-define=MAPTILER_KEY=...`.
> Kalitsiz xarita ishlamaydi. Kodga yozmang.

### Chiqarishdan oldingi tekshiruv

```bash
flutter analyze && flutter test                    # 268 test
PYTHON=backend/.venv/bin/python bash tests/run.sh  # backend integratsiya
cd backend && .venv/bin/alembic check              # modellar mos
python3 scripts/check_3d_map.py                    # 3D xarita (Chrome kerak)
```

Backend integratsiya testlari haqiqiy PostgreSQL talab qiladi; bazasiz
**SKIP** bo'ladi (yiqilmaydi):

```bash
export SUPERAPP_TEST_DB="postgresql+asyncpg://postgres@127.0.0.1:5435/superapp_test"
```

> Diqqat: test bazasi `drop_all` qiladi. Ishchi bazani KO'RSATMANG.

---

## 16. Masshtab va unumdorlik

> **Bu bo'lim 2026-09-06 da o'lchov asosida yozildi.** Vaqtinchalik bazada
> **500 000 e'lon + 200 000 provayder** yaratilib (modellardagi indekslarning
> aynan o'zi bilan), kodning haqiqiy so'rovlari `EXPLAIN ANALYZE` bilan
> o'lchandi.

### 16.1 Eski yuklama tahlili nega yetarli emas

Ilgari `YUKLAMA_TAHLILI.md` "arxitektura to'g'ri, muammo resursda" degan
xulosa chiqargan edi. Bu xulosa **chalg'ituvchi**, chunki
`tests/load_test.py` faqat `/health`, `/config/features`,
`/auth/otp/verify` ni uradi — **qidiruvga umuman tegmaydi**. O'lchov paytida
bazada 121 provayder va 39 e'lon bor edi. Shu hajmda hamma narsa tez ishlaydi.

**Xulosa:** infratuzilma bo'yicha o'sha hujjatning tavsiyalari (read replica,
alohida WS server, S3) to'g'ri. Lekin u **so'rov mantig'idagi** muammolarni
ko'rmagan.

### 16.2 Eng jiddiy muammo: qidiruv natijani YO'QOTADI

`services/marketplace/search.py` da:

```python
rows = (await db.execute(stmt.limit(200))).scalars().all()   # ORDER BY YO'Q
# ... keyin narx va masofa Python'da filtrlanadi
```

Baza mos keluvchi 34 000 e'londan **tartibsiz 200 tasini** qaytaradi
(`ORDER BY` yo'q), narx/masofa filtri esa **shundan keyin** Python'da ishlaydi.

**O'lchangan natija (500K e'lon):**

| So'rov | Matnga mos | Haqiqatan mos | Kod topdi | Qamrov |
|---|---|---|---|---|
| "noutbuk", ≤3 mln, 5 km | 34 004 | 22 | **0** | **0%** |
| "iphone", ≤3 mln, 5 km | 16 872 | 8 | **0** | **0%** |
| "gilam", ≤3 mln, 5 km | 16 927 | 7 | **0** | **0%** |

Qamrov ≈ `200 / (matnga mos qatorlar)`. Buzilish mos qatorlar 200 dan oshishi
bilan boshlanadi — ommabop so'z uchun taxminan **3 000 e'londan**.

**Bu xato hozirgi 39 ta e'londa KO'RINMAYDI** va monitoring ogohlantirmaydi:
so'rov tez va xatosiz qaytadi — shunchaki **bo'sh**.

**Xuddi shu naqsh yana ikki joyda:**

- `api/v1/jobs.py` — usta lentasi: eng yangi 50 ta e'lon olinadi, **keyin**
  `filter_jobs_for_provider()` Python'da masofa bo'yicha filtrlaydi. Boshqa
  viloyatdagi usta deyarli doim bo'sh lenta ko'radi.
- `core/schedulers.py` — §16.3.

### 16.3 Scheduler'ning to'liq skani

`plan_reminder_scheduler` **har 15 soniyada**:

```python
select(Plan, User).join(User).where(Plan.is_completed == False, Plan.is_notified == False)
# ... keyin vaqt Python'da tekshiriladi
```

SQL'da sana filtri **yo'q** — barcha bajarilmagan rejalar RAM'ga tortiladi.
`plans` jadvalida `is_completed`/`is_notified`/`due_date` bo'yicha indeks
**yo'q**. 1 mln foydalanuvchida bu har 15 soniyada millionlab qator.

### 16.4 O'lchangan tuzatish natijalari

| Amal | Hozir | Tuzatilgach | Farq |
|---|---|---|---|
| Provayder qidiruvi (`ILIKE`) | 155.9 ms (Seq Scan) | **13.9 ms** (trigram GIN) | 11× |
| Chuqur sahifalash (`OFFSET 100000`) | 71.1 ms | **0.4 ms** (keyset) | 175× |
| Toifa lentasi | 15.7 ms | **0.4 ms** (qisman indeks) | 39× |
| Geo filtr | *SQL'da imkonsiz* | **14.1 ms** (bounding box) | — |

### 16.5 Tavsiya qilinadigan tartib

**1-bosqich — qidiruvni SQL'ga ko'chirish** (eng muhimi)

- `LIMIT 200 + Python filtr` naqshini butunlay olib tashlang
- Narx solishtiruvi uchun `price_uzs` ni **yozish paytida** hisoblab saqlang
  (denormalizatsiya) — SQL'da valyuta konvertatsiyasi kerak bo'lmaydi
- Geo: avval `lat/lng BETWEEN` bounding box, keyin aniq masofa — ikkalasi SQL'da

**2-bosqich — indekslar**

```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ILIKE '%...%' uchun
CREATE INDEX ix_listings_title_trgm  ON listings  USING gin (title gin_trgm_ops);
CREATE INDEX ix_listings_desc_trgm   ON listings  USING gin (description gin_trgm_ops);
CREATE INDEX ix_providers_name_trgm  ON providers USING gin (name gin_trgm_ops);
CREATE INDEX ix_providers_addr_trgm  ON providers USING gin (address gin_trgm_ops);

-- faqat faol yozuvlar uchun qisman indeks
CREATE INDEX ix_listings_active_created ON listings (created_at DESC, id DESC) WHERE status='active';
CREATE INDEX ix_listings_active_geo     ON listings (lat, lng)                 WHERE status='active';
CREATE INDEX ix_providers_active_rating ON providers (rating DESC, id DESC)    WHERE is_active;

-- scheduler uchun
CREATE INDEX ix_plans_pending ON plans (due_date) WHERE is_completed = false AND is_notified = false;
```

> Indekslarni **modellarga ham** `__table_args__` bilan yozing, aks holda
> `alembic --autogenerate` ularni o'chirmoqchi bo'ladi (§7).

**3-bosqich — keyset sahifalash**

`OFFSET` o'rniga kursor: `WHERE (created_at, id) < (:last_created, :last_id)`.
Chuqurlikdan qat'i nazar bir xil tez (o'lchangan: 0.4 ms).

**4-bosqich — model tuzatishlari**

`models/provider.py` da `Provider.orders` va `Provider.reviews` —
`lazy="selectin"`. Provayder ro'yxatini yuklaganda har bir provayderning
**barcha** buyurtma va sharhlari RAM'ga tortiladi. `Category.providers` da bu
xato allaqachon topilib `lazy="raise"` ga o'tkazilgan; shu ikkitasi qolgan.

**5-bosqich — o'sish boshqaruvi**

`notifications` — hozir 140 foydalanuvchiga 21 661 qator (~155 ta/kishi),
1 mln da ~150 mln qator. 30 kunlik tozalash bor, lekin bunday hajmda `DELETE`
uzoq lock va bloat beradi. **Oyma-oy partitsiyalash** va eski partitsiyani
`DROP` qilish kerak.

**6-bosqich — infratuzilma**

- **PgBouncer majburiy:** `pool_size=10 + overflow=5` har worker uchun,
  `WEB_CONCURRENCY=3`. 4 ta backend × 3 worker × 15 = **180 ulanish**,
  PostgreSQL standarti esa 100.
- Read replica, alohida WebSocket server, rasm uchun S3/Spaces.

### 16.6 Elasticsearch kerakmi?

**Hozircha yo'q.** Postgres + trigram GIN 500K e'londa 14 ms beradi.
Alohida qidiruv tizimini faqat ~5 mln e'londan keyin yoki morfologik qidiruv
(o'zbekcha so'z shakllari) kerak bo'lganda o'ylang.

---

## 17. Ma'lum muammolar

| # | Muammo | Joyi | Og'irlik |
|---|---|---|---|
| 1 | Qidiruv natijani yo'qotadi (200 qator + Python filtr) | `services/marketplace/search.py` | 🔴 Kritik (masshtabda) |
| 2 | Usta lentasi geo filtri `LIMIT` dan keyin | `api/v1/jobs.py` | 🔴 Kritik (masshtabda) |
| 3 | `plan_reminder_scheduler` to'liq skan, indekssiz | `core/schedulers.py` | 🟠 Yuqori |
| 4 | `Provider.orders` / `Provider.reviews` `lazy="selectin"` | `models/provider.py` | 🟠 Yuqori |
| 5 | `OFFSET` sahifalash chuqurlikda sekinlashadi | `services/provider_service.py` | 🟡 O'rta |
| 6 | `notifications` partitsiyalanmagan | — | 🟡 O'rta (kelajakda) |
| 7 | `finance_groups` ↔ `users` aylanma FK | modellar | 🟢 Past (ogohlantirish) |
| 8 | `barber_service.py` / `salon_service.py` ~58 qator nusxa | servislar | 🟢 Past |
| 9 | Flutter SDK CI'da yo'q — `flutter analyze` qo'lda | — | 🟢 Past |

---

## 18. Ishlash qoidalari

Bu qoidalar **majburiy**. Har biri haqiqiy xatodan keyin yozilgan.

### Kod

- **Izohlar o'zbekcha** va "nima uchun" ni tushuntiradi, "nima" ni emas.
- **Sirlar kodga yozilmaydi.** `.env` (backend), `--dart-define` (Flutter).
- Har mazmunli o'zgarishdan keyin commit qiling, izoh o'zbekcha.

### Biznes

- **Ustaning/sotuvchining haqiqiy telefon raqami BERILMAYDI.** Aloqa faqat
  ilova ichida. Biznes modeli shunga bog'liq.
- **`marketplace` (buyum savdosi) va `jobs` (xizmat e'loni) — BOSHQA narsa.**
  Birlashtirmang, alohida papkada turadi.

### Texnik

- **Baza:** yangi o'zgarish uchun **Alembic** (§7). Mavjud bazada
  `upgrade head` ishlatmang — `stamp head` qiling.
- **`alembic/env.py` da `import app.models` ni buzmang** — aks holda
  autogenerate 37 jadvalni o'chirmoqchi bo'ladi.
- **Xarita:** tile manzili faqat `lib/config/map_config.dart` da.
- **3D xarita — soxta 3D qilmang** (§12).
- **AI:** `confirm` darvozasi va `user_id` filtri majburiy (§10).
- **Qidiruv:** natijani `LIMIT` dan **keyin** Python'da filtrlamang (§16.2).

### Ishni boshlashdan oldin

`git log` va `git status` ni tekshiring — loyihada bir nechta agent parallel
ishlashi mumkin. `docs/qilingan_ishlar/` — **arxiv**, "todo" emas.

---

## 19. O'zgarishlar jurnali

> Har o'zgarishdan keyin shu yerga bir qator qo'shing.
> Format: `sana — nima o'zgardi — qaysi § yangilandi`

| Sana | O'zgarish | Bo'lim |
|---|---|---|
| 2026-09-06 | Yagona arxitektura hujjati yaratildi; 8 ta tarqoq `.md` birlashtirildi | Hammasi |
| 2026-09-06 | Masshtab tahlili o'lchov bilan qo'shildi (500K e'lon benchmark) | §16 |
| 2026-09-06 | Alembic tiklandi: `env.py` to'liq model importi, 37 jadval migratsiyaga tushdi | §7 |
| 2026-09-06 | `User.providers` ↔ `Provider.owner` `back_populates` bilan bog'landi | §6 |
| 2026-09-06 | Flutter: 39 o'lik fayl, 3 ortiqcha asset (~15.8 MB), `google_fonts` olib tashlandi | §12 |
| 2026-09-06 | Backend: 20 buzuq skript, 9 o'lik simvol, 37 ishlatilmaydigan import tozalandi | §5 |
