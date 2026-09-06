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
| [20](#20-ai-agentni-kengaytirish-konsepsiyasi) | **AI agentni kengaytirish konsepsiyasi** |

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
grep -c '"name":' backend/app/services/ai_agent/tools_schema.py   # 46 AI tool
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

`backend/app/services/ai_agent/` — **46 ta tool**.

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

### 16.5 Bajarilgan tuzatishlar (2026-09-06)

✅ **Qidiruv SQL'ga ko'chirildi** (`services/marketplace/search.py`)

`LIMIT 200 + Python filtr` naqshi olib tashlandi. Endi narx, masofa va matn
filtri — hammasi SQL'da. Valyuta `CASE` bilan joriy kursda hisoblanadi
(ustunda saqlanmaydi, chunki kurs har kuni o'zgaradi). Narxi yoki
koordinatasi yo'q e'lonlar avvalgidek **yo'qolmaydi**.

Xuddi shu 500K e'lonli bazada qayta o'lchandi: **15/15, 11/11, 9/9**
natija qaytdi (ilgari 0/22, 0/8, 0/7), issiq holatda 24-26 ms.

✅ **Usta lentasi geo filtri** (`api/v1/jobs.py`, `services/job_service.py`)

Koordinata bo'yicha masofa filtri endi `LIMIT` dan **oldin**, SQL'da.
Manzil MATNI bo'yicha hudud qoidasi Python'da qoldi — u faqat qo'shimcha
filtrlaydi, natija qo'shmaydi, shuning uchun yo'qotish bermaydi.

✅ **Scheduler to'liq skani** (`core/schedulers.py`)

`plan_reminder_scheduler` endi `due_date <= now() + offset` shartini SQL'da
tekshiradi va bir siklda ko'pi bilan 500 ta rejani oladi.

✅ **Indekslar** — modellarda `__table_args__` bilan e'lon qilingan, ya'ni
`alembic --autogenerate` ularni o'chirmoqchi bo'lmaydi. Migratsiya:
`ece5f1b1b853`.

| Indeks | Turi |
|---|---|
| `ix_listings_title_trgm`, `ix_listings_description_trgm` | GIN trigram |
| `ix_providers_name_trgm`, `ix_providers_address_trgm` | GIN trigram |
| `ix_listings_active_created`, `ix_listings_active_cat_created` | qisman (`status='active'`) |
| `ix_listings_active_geo` | qisman, bounding box uchun |
| `ix_providers_active_rating` | qisman (`is_active`) |
| `ix_plans_pending_due` | qisman (bajarilmagan rejalar) |

`pg_trgm` kengaytmasi `db/base.py` dagi `before_create` hook orqali
yaratiladi — `startup.py` da emas. Sabab: `create_all` ni chaqiradigan har
yo'l (testlar, seed skriptlari, yangi muhit) o'zi ishlashi kerak.

✅ **`lazy="selectin"` tuzatildi** — `Provider.orders` va `Provider.reviews`
`lazy="raise"` ga o'tkazildi (`Category.providers` uslubi). Ular kodda
hech qayerda o'qilmasdi, lekin har provayder yuklanganda uning barcha
buyurtma va sharhlari tortilardi.

✅ **Provayder ro'yxatidagi `metadata_json` filtri SQL'ga ko'chirildi**
(`services/provider_service.py`). Ilgari salon xodimi va to'xtatilgan
provayder `LIMIT` dan **keyin** Python'da olib tashlanardi — natijada har
sahifa `per_page` dan kam element qaytarardi va `total` filtrlanmagan
sondan hisoblanib, sahifalar soni noto'g'ri chiqardi.

✅ **Tozalash bo'laklab ishlaydi** (`core/schedulers.py`). Bitta katta
`DELETE` o'rniga 10 000 talik bo'laklar, orasida 1 soniya tanaffus —
uzoq lock, bloat va replikatsiya kechikishini oldini oladi.

### 16.6 Ataylab BAJARILMAGAN va sababi

**Keyset sahifalash** — `OFFSET` o'z holicha qoldirildi.

O'lchovda `OFFSET 100000` 71 ms bergan edi, lekin bu **5000-sahifa**.
Flutter tomonini tekshirganda ma'lum bo'ldi: chuqur sahifalash faqat
`top_providers` "yana yuklash" da bor va u bir necha sahifadan oshmaydi.
`OFFSET 10000` (500-sahifa) esa 37 ms — muammo emas. Keyset kursorga
o'tish API shartnomasini buzadi (`page` → `cursor`, `total` yo'qoladi) va
Flutter tomonini ham o'zgartirishni talab qiladi. Foyda xarajatga
arzimaydi.

**Qachon qaytib ko'rish kerak:** ro'yxatda cheksiz skroll paydo bo'lsa yoki
foydalanuvchilar 1000-sahifadan nariga chiqa boshlasa.

**`notifications` partitsiyalash** — bajarilmadi, o'rniga bo'laklab
o'chirish qilindi.

Jadval hozir **21 697 qator / 5.7 MB**. Partitsiyalash 10 mln+ qatorli
jadvallar uchun. Mavjud jadvalni partitsiyalanganga aylantirib bo'lmaydi:
yangi jadval + nusxa + almashtirish kerak, ya'ni jonli bazada texnik
tanaffus. Bundan tashqari PK `id` dan `(id, created_at)` ga o'zgaradi va
kimdir har oy yangi partitsiya yaratib turishi shart — aks holda `INSERT`
yiqiladi.

**Qachon qilish kerak:** jadval ~10 mln qatordan oshganda. Tartib:
1. `notifications_new` ni `PARTITION BY RANGE (created_at)` bilan yaratish
2. Oylik partitsiyalar + keyingi oy uchun avtomatik yaratuvchi scheduler
3. Ma'lumotni bo'laklab ko'chirish
4. Tranzaksiya ichida nomlarni almashtirish
5. Retention `DELETE` o'rniga `DROP PARTITION` ga o'tadi

### 16.7 Qolgan ish — infratuzilma

- **PgBouncer majburiy:** `pool_size=10 + overflow=5` har worker uchun,
  `WEB_CONCURRENCY=3`. 4 ta backend × 3 worker × 15 = **180 ulanish**,
  PostgreSQL standarti esa 100.
- Read replica, alohida WebSocket server, rasm uchun S3/Spaces.
- **Katta jadvalda indeks yaratish:** migratsiya `CREATE INDEX` bloklaydi.
  Jadval yirik bo'lsa qo'lda `CREATE INDEX CONCURRENTLY` qilib, keyin
  `alembic stamp ece5f1b1b853` qiling (migratsiya faylida ham yozilgan).

### 16.6 Elasticsearch kerakmi?

**Hozircha yo'q.** Postgres + trigram GIN 500K e'londa 14 ms beradi.
Alohida qidiruv tizimini faqat ~5 mln e'londan keyin yoki morfologik qidiruv
(o'zbekcha so'z shakllari) kerak bo'lganda o'ylang.

---

## 17. Ma'lum muammolar

| # | Muammo | Joyi | Og'irlik |
|---|---|---|---|
| 1 | `OFFSET` sahifalash chuqurlikda sekinlashadi (hozir muammo emas — §16.6) | `services/provider_service.py` | 🟡 O'rta |
| 2 | `notifications` partitsiyalanmagan (10 mln qatordan keyin — §16.6) | — | 🟡 O'rta (kelajakda) |
| 3 | PgBouncer yo'q — ulanishlar soni Postgres limitidan oshadi | infratuzilma | 🟡 O'rta |
| 4 | `finance_groups` ↔ `users` aylanma FK | modellar | 🟢 Past (ogohlantirish) |
| 5 | `barber_service.py` / `salon_service.py` ~58 qator nusxa | servislar | 🟢 Past |
| 6 | Flutter SDK CI'da yo'q — `flutter analyze` qo'lda | — | 🟢 Past |

**2026-09-06 da hal qilinganlar:** qidiruvning natija yo'qotishi, usta
lentasi geo filtri, scheduler to'liq skani, `lazy="selectin"`, provayder
ro'yxatidagi `metadata_json` filtri, tozalashning uzoq `DELETE` i — §16.5.

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
| 2026-09-06 | Qidiruv SQL'ga ko'chirildi (0% → 100% qamrov), 9 ta indeks, `lazy="raise"`, bo'laklab tozalash | §16.5 |
| 2026-09-06 | Keyset sahifalash va partitsiyalash ataylab qoldirildi — sabab yozildi | §16.6 |
| 2026-09-06 | AI agent kengaytirish konsepsiyasi: qamrov tahlili, shikoyat/jazo tizimi, aldashdan himoya | §20 |

---

## 20. AI agentni kengaytirish konsepsiyasi

> **Holat:** loyihalash bosqichi (2026-09-06). Hali qurilmagan.
> Bu bo'lim maqsad va qarorlarni yozib qo'yadi — kod yozilgach §10 yangilanadi.

### 20.1 Bugungi qamrov — o'lchangan

Agent **46 ta tool** bilan ishlaydi va ular **faqat mijoz tomonini** qoplaydi.

**Agent qila oladi:** reja, vazifa, budilnik, moliya, bozorlik, xizmat qidirish va
bron, ish e'loni, savdo e'loni, ob-havo/valyuta/namoz, qadam soni.

**Agentga umuman ulanmagan bo'limlar (10 ta):**
`calls`, `calories`, `campaigns`, `checkin`, `disputes`, `messages`,
`notifications`, `support`, `promos`, `app_config`.

**Eng katta bo'shliq — usta kabineti.** Loyihada **18 ta provayder portali
moduli** bor (sartarosh, salon, kuryer, enaga, hamshira, stomatolog…), lekin
ular uchun bironta ham tool yo'q. Ya'ni usta AI'dan hech qanday yordam
ololmaydi: buyurtmani qabul qila olmaydi, jadvalini boshqara olmaydi, ish
e'loniga taklif bera olmaydi, hisobotini so'rayolmaydi.

Bu ikki tomonlama bozor, lekin AI faqat bir tomoniga xizmat qiladi.

### 20.2 Universal agent — qamrovni yopish

Maqsad: **ilovadagi har bir amal agent orqali ham bajarilishi kerak.**

Tartib (foyda / mehnat nisbatiga ko'ra):

| Bosqich | Nima qo'shiladi | Nega |
|---|---|---|
| 1 | **Usta tomoni tool'lari** — taklif berish, buyurtmani qabul/rad, jadval, bo'sh vaqt, hisobot, balans ko'rish | Butun bir foydalanuvchi toifasi AI'siz qolgan |
| 2 | **Chat va aloqa** — `messages`, `calls` tarixi, "ustaga yoz" | Bitim shu yerda pishadi |
| 3 | **Shikoyat va nizo** — `disputes`, `support` (§20.3) | Xavfsizlik uchun poydevor |
| 4 | **Bildirishnoma va aksiya** — `notifications`, `campaigns`, `promos` | Qaytarish (retention) |
| 5 | **Kaloriya, check-in** | Qolgan mini-ilovalar |

**Qoida:** har yangi tool `user_id` filtri va (o'zgartiruvchi bo'lsa) `confirm`
darvozasi bilan keladi — §10 dagi mavjud qoida yangi tool'larga ham tegishli.

⚠️ **Tool soni oshgani sayin token yuki oshadi.** Hozir 46 tool = 6 837 token
har chaqiruvda (§20.6). 100 toolga chiqsa prompt bilan birga ~20 000 token
bo'ladi. Shuning uchun **tool'larni guruhlash** universal agentga o'tishning
SHARTI: avval niyat aniqlanadi, keyin faqat mos guruh yuboriladi.

### 20.3 Shikoyat va javobgarlik tizimi

#### Bugun nima bor

| Jadval | Vazifasi | Holati |
|---|---|---|
| `disputes` | Buyurtma bo'yicha nizo, qaytarish summasi, admin yechimi | ✅ Ishlaydi |
| `provider_fraud_stats` | Oylik: `no_show_count`, `disputed_count`, `flag_level` | ⚠️ Muammoli |
| `blocked_users` | Provayder mijozni bloklaydi | ✅ Ishlaydi (lokal) |
| `support_tickets` | Foydalanuvchi ↔ admin yozishmasi | ✅ Ishlaydi |
| `audit_logs` | Admin amallari jurnali | ✅ Ishlaydi |

Eskalatsiya narvoni ham bor (`services/checkin_service.py`):
5+ no_show → `warning`, 10+ → `alert`, 3+ nizo → `suspended`.

#### Uchta jiddiy kamchilik

**1. `suspended` hech narsani to'xtatmaydi.** Flag qo'yiladi va provayderga
«🔴 Faoliyat to'xtatildi... Profilingiz tekshiruv tugagunicha to'xtatildi»
degan xabar ketadi. Lekin `flag_level` butun kodda faqat **admin
monitoringida ko'rsatish uchun** o'qiladi. Qidiruv esa `is_blocked` ni
tekshiradi — bu **alohida**, admin qo'lda qo'yadigan maydon.
**Ya'ni tizim provayderga yolg'on aytadi:** u to'xtatilmagan, ishlayveradi.

**2. Hisob har oy nolga tushadi.** `provider_fraud_stats.month = "2026-09"` —
har oy yangi qator. Har oyda 2 ta nizo qiladigan odam **hech qachon**
`suspended` ga yetmaydi. Doimiy tarix yo'q.

**3. Foydalanuvchi shikoyati tizimga kirmaydi.** Hisob faqat check-in'dagi
`no_show` va `disputed` dan o'sadi. Mijoz AI chatda «bu usta meni aldadi»
desa — bu hech qayerga yozilmaydi.

#### Loyihalanayotgan tizim

**Asosiy qaror: AI jazo TAYINLAMAYDI.**

AI shikoyatni qabul qiladi, tasniflaydi, dalil yig'adi va **taklif** qiladi.
Qaror — deterministik qoidalar mexanizmi, og'ir holatlarda esa **inson**.

Nega bu shunchalik muhim:
- LLM ni gap bilan aldash mumkin (§20.4)
- LLM bir xil kirishga har xil javob beradi
- Umrbod bloklash va militsiyaga xabar — **qaytarib bo'lmaydigan** amallar
- Aybsiz odamning biznesini yopish, aybdorni qo'yib yuborishdan qimmatroq

```
Shikoyat (chat / tugma / nizo)
   ↓
[AI]  tasniflaydi: tur, og'irlik, dalil havolalari
      → yozadi: complaints (append-only)
      → jazo tayinlamaydi, hech narsa o'chirmaydi
   ↓
[QOIDALAR MEXANIZMI]  deterministik, LLM emas
      → offence_ledger ga voqea qo'shadi
      → doimiy trust_score qayta hisoblanadi
   ↓
   ├─ yengil   → ogohlantirish            (avtomatik)
   ├─ o'rta    → vaqtincha cheklov        (avtomatik, apellyatsiya bilan)
   ├─ og'ir    → to'xtatish               (avtomatik + inson 24 soatda ko'rib chiqadi)
   └─ o'ta og'ir → umrbod / huquqiy       (FAQAT inson qarori)
```

#### Jazo narvoni

| Daraja | Sabab (misol) | Chora | Kim qaror qiladi |
|---|---|---|---|
| 1 | Kechikish, javob bermaslik | Ogohlantirish + ball | Avtomatik |
| 2 | Takroriy no-show | 7 kun qidiruvda past o'rin | Avtomatik |
| 3 | Tasdiqlangan nizo (pul) | 30 kun to'xtatish | Avtomatik + inson tekshiruvi |
| 4 | Firibgarlik namunasi | Doimiy to'xtatish | **Inson** |
| 5 | Jinoyat alomati | Huquqiy jarayon | **Inson + yurist** |

**Har daraja uchun shart:** apellyatsiya yo'li va dalil. Dalilsiz jazo yo'q.

#### Ma'lumot modeli (yangi jadvallar)

```
complaints              kim, kimga, tur, matn, dalil havolalari, AI tasnifi,
                        holati (yangi/tekshiruvda/asosli/asossiz)

offence_ledger          APPEND-ONLY. Har voqea: sabab, daraja, dalil,
                        kim/nima qo'ygan (qoida yoki admin id), vaqt.
                        HECH QACHON UPDATE/DELETE qilinmaydi.

trust_profile           Joriy holat — ledger'dan HISOBLANADI, qo'lda yozilmaydi.
                        Doimiy (oyma-oy tushmaydi): umumiy ball, joriy cheklov,
                        cheklov tugash vaqti.

identity_links          Bir odamning bir necha akkaunti: telefon, qurilma
                        (device_token), to'lov kartasi, manzil — HASH holida.
                        Bloklangan odam yangi raqam bilan qaytmasin.

appeals                 Shikoyat ustidan shikoyat: kim, qaysi jazoga, sabab,
                        natija.
```

**Nega `offence_ledger` append-only:** joriy holatni o'chirib bo'lmaydi, chunki
u saqlanmaydi — hisoblanadi. Kimdir (yoki biror xato) `trust_profile` ni
o'zgartirsa ham, keyingi qayta hisobda tarix qaytadi.

#### Umrbod ro'yxat va huquqiy jarayon

Siz aytgan «nomini spam qilish» va «militsiyaga berish» qismiga alohida
e'tibor kerak:

- **Ichki qora ro'yxat — ha.** Bloklangan odam yangi akkaunt ochsa,
  `identity_links` orqali tanilib, ro'yxatdan o'tolmaydi. Bu qonuniy va
  to'g'ri.
- **Ismni OMMAGA e'lon qilish — tavsiya etilmaydi.** Bu tuhmat (defamation)
  bo'yicha da'vo xavfini tug'diradi, ayniqsa keyinchalik xato aniqlansa.
  Bunda platforma javobgar bo'ladi, firibgar emas. Ichki ro'yxat bir xil
  himoyani beradi, xavfsiz.
- **Militsiyaga xabar — hech qachon avtomatik emas.** Tizim *dosye* tayyorlaydi
  (buyurtmalar, yozishmalar, to'lovlar, dalillar), lekin uni **inson** ko'rib
  chiqib, yurist bilan tasdiqlaydi. AI tasnifiga asoslanib odamni militsiyaga
  berish — noto'g'ri aniqlashda og'ir oqibat.

### 20.4 AI ni aldashdan himoya

Siz to'g'ri xavotir bildirdingiz: kimdir AI ni gap bilan ko'ndirib o'z
yozuvini o'chirtirishi mumkin. Yechim — **AI ga bunday imkoniyat umuman
bermaslik.**

| Qoida | Qanday amalga oshadi |
|---|---|
| AI jazo yozuviga **yoza olmaydi** | `offence_ledger` uchun tool YO'Q. Faqat qoidalar mexanizmi yozadi |
| AI o'z holatini **o'zgartira olmaydi** | Har tool `user_id` bo'yicha filtrlaydi (mavjud qoida) — o'zining jazo yozuviga ham tegolmaydi |
| Yozuvlar **o'chmaydi** | Append-only jadval; `DELETE` huquqi ilova roliga berilmaydi |
| Prompt bilan boshqarib bo'lmaydi | Chegara promptda emas, **kodda va DB huquqlarida**. Prompt "iltimos qilma" deydi — bu himoya emas |
| Shikoyat matni **buyruq emas** | Foydalanuvchi matni tool argumenti sifatida keladi, prompt sifatida emas |

**Asosiy tamoyil:** LLM ga aytilgan qoida — maslahat. Kodda qo'yilgan chegara —
qoida. Xavfsizlik faqat ikkinchisiga tayanadi.

### 20.5 Admin panelda prompt boshqaruvi

Bugun: `settings_service.get("ai_chat_prompt")` — bitta matn maydoni,
to'g'ridan-to'g'ri almashtiriladi. Xato yozilsa agent darhol buziladi va
qaytarish yo'li yo'q.

Kerak bo'lgan minimal tizim:

| Imkoniyat | Nega |
|---|---|
| **Versiyalash** | Har saqlash yangi versiya. Buzilsa bir bosishda qaytariladi |
| **Eval bilan darvoza** | Yangi prompt §20.6 dagi to'plamda sinaladi. Ball tushsa — ogohlantirish |
| **Bo'laklarga bo'lish** | Bitta 240 qatorli matn emas: asosiy qoidalar / bron / savdo / format — alohida bloklar. Bittasini o'zgartirish boshqasini buzmaydi |
| **A/B** | Ikki versiyani foydalanuvchilarning bir qismida solishtirish |
| **Kim o'zgartirdi** | `audit_logs` ga yozish (mexanizm allaqachon bor) |

### 20.6 Poydevor: eval to'plami

**Bularning hammasidan OLDIN shu kerak.** Hozir agentning tool tanlashini
o'lchaydigan hech narsa yo'q — barcha AI testlari deterministik (handler
ishlaydimi, promptda falon so'z bormi).

Ya'ni promptga har tegish — qimor. Prompt'ning o'zida «bu eng ko'p uchraydigan
xato» deb belgilangan joylar bor (savdo/ish e'lonini aralashtirish), lekin
ular haqiqatan tuzalganini hech kim o'lchamaydi.

To'plam shakli: `{foydalanuvchi gapi → kutilgan tool(lar)}`, haqiqiy model
ustida yurgiziladi, ball chiqadi.

Boshlang'ich to'plamga majburiy kiradigan holatlar:
- Savdo ↔ ish e'loni farqi (prompt o'zi "eng ko'p xato" deb belgilagan)
- Reja ↔ bron farqi
- Tasdiq talab qiladigan amallar tasdiqsiz bajarilmasligi
- Boshqa foydalanuvchining ma'lumotiga urinish → rad etilishi
- Til almashuvi (o'zbekcha/ruscha)

### 20.7 Qolib ketgan, e'tibor talab qiladigan nuqtalar

Siz so'ragan "yana nima qoldi" savoliga:

1. **Yolg'on shikoyat.** Raqib usta bir-biriga shikoyat yozib, halol odamni
   yopib qo'yishi mumkin. Shikoyat beruvchining ham `trust_score` i bo'lishi
   kerak — asossiz shikoyat o'zi jazoga sabab.
2. **Xarid tarixisiz shikoyat.** Faqat haqiqiy buyurtma qilgan odam o'sha
   buyurtma bo'yicha shikoyat qila olsin.
3. **Ikki tomonlama baho.** Hozir faqat mijoz ustani baholaydi. Usta ham
   mijozni baholay olsa, yomon mijoz ham ko'rinadi.
4. **Apellyatsiya muddati.** Jazo qo'yilgach necha kun ichida shikoyat qilish
   mumkin — belgilanmasa, ish hech qachon yopilmaydi.
5. **Ma'lumot saqlash muddati.** Jazo yozuvlari qancha saqlanadi? Umrbod
   saqlash shaxsiy ma'lumot qonunchiligi bilan to'qnashishi mumkin.
6. **Monitoring va maslahat** (siz aytgan). Bu foydali, lekin chegarasi bor:
   foydalanuvchi xatti-harakatini kuzatib maslahat berish — u **rozilik**
   bergandagina. Aks holda bu kuzatuv bo'lib qoladi.
7. **Agent xatosi kimning javobgarligi.** AI noto'g'ri bron qilsa yoki
   noto'g'ri e'lon joylasa — kim javob beradi? `confirm` darvozasi shuning
   uchun bor, lekin qoida yozilishi kerak.
8. **Xarajat chegarasi.** Universal agent har so'rovда ko'p token yeydi.
   Foydalanuvchi boshiga kunlik chegara kerak, aks holda bitta odam
   hisobni bo'shatishi mumkin.
