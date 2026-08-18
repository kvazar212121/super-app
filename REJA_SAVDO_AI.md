# Reja: AI chat orqali OLX uslubidagi savdo (bozor)

> **Holat:** tasdiqlash uchun. Kod yozilmagan, faqat reja.
> **Sana:** 2026-08-18

---

## 1. Siz so'ragan oqim

Ikki tomon, ikkalasi ham AI chat orqali ishlaydi.

```mermaid
flowchart TB
    subgraph SOT["SOTUVCHI"]
        A1["'Telefonimni sotmoqchiman'"] --> A2{"AI: nima yetishmayapti?"}
        A2 -->|"yetishmayapti"| A3["AI ro'yxat beradi:<br/>model, narx, holat, xotira..."]
        A3 --> A4["Odam bir nechtasini yozadi"]
        A4 --> A2
        A2 -->|"to'liq"| A5["AI rasm so'raydi<br/>(3-6 ta)"]
        A5 --> A6["Xulosa + tasdiq"]
        A6 --> A7["E'lon saqlanadi<br/>muddat: premium/oddiy"]
    end

    subgraph XAR["XARIDOR"]
        B1["'Telefon olmoqchiman'"] --> B2["AI so'raydi:<br/>model? narx? holat?"]
        B2 --> B3["Qidiruv"]
        B3 --> B4["Chatda 20 tagacha<br/>KARTA (grid)"]
        B4 --> B5["Kartani bosish"]
        B5 --> B6["Modal oyna:<br/>rasmlar, to'liq tavsif"]
        B6 --> B7["Sotuvchiga yozish"]
    end

    A7 -.->|"bazaga tushadi"| B3
```

---

## 2. Hozir nima bor, nima yo'q

Kodni o'qib chiqdim.

| Qism | Holat |
|---|---|
| AI agent + 37 tool | ✅ Tayyor |
| Ma'lumot yig'ish uslubi (`ai_job/draft.py`, `validator.py`) | ✅ Tayyor, **namuna sifatida ishlatiladi** |
| Rasm yuklash (`UploadService`) | ✅ Tayyor |
| Chatga rasm yuborish | ✅ Tayyor |
| Adminkada yoqish/o'chirish (`FEATURE_DEFS`) | ✅ Tayyor, bitta qator qo'shiladi |
| Premium tekshiruvi (`premium_service.is_active`) | ✅ Tayyor |
| Chatda tugmalar (`_actionButtons`) | ✅ Tayyor, lekin **faqat tugma** |
| **Mahsulot modeli (e'lon)** | ❌ Yo'q |
| **Bir nechta rasm (3-6 ta)** | ❌ Yo'q — hozir bittadan |
| **Chatda GRID karta** | ❌ Yo'q — hozir vertikal tugmalar |
| **Modal oyna (to'liq ma'lumot)** | ❌ Yo'q |
| **Qidiruv (model/narx/holat)** | ❌ Yo'q |

Ya'ni poydevor kuchli, 6 ta bo'shliq to'ldiriladi.

---

## 3. Fayllar tuzilishi (siz so'ragan alohida papkalar)

```
backend/app/
├── models/
│   └── marketplace/                    ← YANGI papka
│       ├── __init__.py
│       ├── listing.py                  # E'lon (mahsulot)
│       ├── listing_photo.py            # Rasmlar (3-6 ta)
│       └── listing_category.py         # Toifa (telefon, mashina...)
│
├── services/
│   └── marketplace/                    ← YANGI papka
│       ├── __init__.py
│       ├── draft.py                    # Suhbat qoralamasi
│       ├── fields.py                   # Toifa uchun MAYDONLAR ro'yxati
│       ├── validator.py                # Nima yetishmayapti + savol
│       ├── photos.py                   # Rasm qoidalari (3-6 ta)
│       ├── limits.py                   # Muddat/soni: premium va oddiy
│       ├── search.py                   # Xaridor qidiruvi + saralash
│       └── publisher.py                # Qoralama -> haqiqiy e'lon
│
├── services/ai_agent/
│   └── market_tools.py                 ← YANGI: 8 ta tool
│
└── api/v1/
    └── marketplace.py                  ← YANGI: REST endpointlar

lib/
├── models/marketplace/                 ← YANGI papka
│   ├── listing.dart
│   └── listing_filter.dart
│
├── screens/marketplace/                ← YANGI papka
│   ├── listing_detail_screen.dart      # To'liq sahifa
│   ├── my_listings_screen.dart         # "Mening e'lonlarim"
│   └── listing_photos_screen.dart      # Rasmlarni ko'rish
│
├── widgets/marketplace/                ← YANGI papka
│   ├── listing_grid.dart               # Chatdagi GRID (20 tagacha)
│   ├── listing_card.dart               # Bitta karta
│   ├── listing_modal.dart              # Bosilganda MODAL oyna
│   └── photo_carousel.dart             # Rasmlar aylanmasi
│
└── services/
    └── marketplace_service.dart        ← YANGI: API chaqiruvlari

tests/
├── test_marketplace_flow.py            # Sotuvchi oqimi (uchdan-uchgacha)
├── test_marketplace_search.py          # Xaridor qidiruvi
└── test_marketplace_limits.py          # Premium/muddat/adminka

test/
├── marketplace_grid_test.dart          # Grid va karta
└── marketplace_modal_test.dart         # Modal oyna
```

**Nega alohida papka:** `jobs` (ish e'lonlari) allaqachon bor va bu
boshqa narsa. Aralashtirsak, ikkalasi ham chalkashadi. Alohida papka
kelajakda bu bo'limni butunlay o'chirib tashlashni ham osonlashtiradi.

---

## 4. Ma'lumotlar bazasi

### `listings` (e'lon)

| Ustun | Turi | Izoh |
|---|---|---|
| `id` | int | |
| `user_id` | int | Sotuvchi |
| `category_key` | str | `telefon`, `mashina`, `mebel`... |
| `title` | str | "iPhone 13 Pro 256GB" |
| `description` | text | To'liq tavsif |
| `price` | float | Narx |
| `currency` | str | `UZS` / `USD` |
| `condition` | str | `new` / `like_new` / `good` / `used` |
| `attributes` | JSON | Toifaga xos: xotira, rang, yil, probeg |
| `address` | str | Manzil matni |
| `lat` / `lng` | float? | Hudud filtri uchun |
| `status` | enum | `active`, `sold`, `expired`, `hidden` |
| `views` | int | Ko'rilgan soni |
| `expires_at` | datetime | **Premium/oddiyga qarab** |
| `created_at` | datetime | |

### `listing_photos`

| Ustun | Izoh |
|---|---|
| `listing_id` | |
| `url` | Yuklangan rasm |
| `sort_order` | Tartib (birinchisi — asosiy) |

> **Migratsiya:** yangi jadvallar, `create_all` o'zi yaratadi
> (`startup.py`). Mavjud jadvalga tegilmaydi.

---

## 5. Sotuvchi oqimi — bosqichma-bosqich

### 5.1 Toifaga qarab MAYDONLAR (`fields.py`)

Har toifa uchun nima so'ralishi oldindan yozilgan:

| Toifa | Majburiy | Ixtiyoriy |
|---|---|---|
| Telefon | model, narx, holat, xotira | rang, quti/hujjat, kafolat |
| Mashina | model, yil, narx, probeg, holat | rang, karobka, yoqilg'i |
| Mebel | nomi, narx, holat | o'lcham, material |
| Kiyim | nomi, narx, o'lcham, holat | rang, brend |
| Boshqa | nomi, narx, holat | — |

AI **bir vaqtda hammasini** ro'yxat qilib beradi (siz shuni so'radingiz):

> "Yaxshi, telefon sotasiz. Menga quyidagilar kerak:
> • Model (masalan iPhone 13 Pro)
> • Xotira (128/256 GB)
> • Holati (yangi / ideal / yaxshi / ishlatilgan)
> • Narxi
> Bir yozuvda hammasini yozsangiz ham bo'ladi."

Odam qismini yozsa, AI **faqat qolganini** so'raydi.

### 5.2 Rasmlar (`photos.py`)

- **Kamida 3 ta, ko'pi 6 ta** (siz aytgan chegara)
- Yetmasa AI aniq aytadi: "Yana 2 ta rasm kerak (hozir 1 ta)"
- Har rasm mavjud `UploadService` orqali saqlanadi
- Chatdagi rasm oqimi allaqachon bor (yaqinda tuzatilgan)

### 5.3 Tasdiq va saqlash

`publish_job` dagi kabi **ikki qadamli**: avval xulosa, keyin tasdiq.

**Muddat (`limits.py`), adminkadan sozlanadi:**

| | Oddiy | Premium |
|---|---|---|
| E'lon muddati | 7 kun | 30 kun |
| Bir vaqtda e'lon | 5 ta | 50 ta |
| Rasm soni | 6 ta | 10 ta |

---

## 6. Xaridor oqimi

### 6.1 AI savol beradi

> "Telefon olmoqchiman" →
> "Qanday telefon qidiryapsiz? Model, taxminiy narx va holati
> (yangi/ishlatilgan) ni ayting."

### 6.2 Qidiruv (`search.py`)

- Matn bo'yicha (`title`, `description`)
- Narx oralig'i, holat, toifa
- Hudud (koordinata bo'lsa, masofa bo'yicha)
- **Saralash:** yaqinlik → yangilik → narx

### 6.3 Chatda GRID (siz so'ragan asosiy yangilik)

Hozir chatda faqat **vertikal tugmalar** bor. Yangi ko'rinish:

```
┌──────────┬──────────┐
│ [rasm]   │ [rasm]   │
│ iPhone13 │ Redmi 12 │
│ 4 500 000│ 1 800 000│
│ Ideal·2km│ Yaxshi·5km│
├──────────┼──────────┤
│ ...      │ ...      │
```

- 2 ustunli grid, **20 tagacha** karta
- Har kartada: asosiy rasm, nom, narx, holat, masofa
- Yangi action turi: `{"type": "listing_grid", "listings": [...]}`

### 6.4 Modal oyna

Karta bosilganda **modal** ochiladi (yangi ekran emas, siz shunday
so'radingiz):

- Rasmlar aylanmasi (3-6 ta, surib ko'riladi)
- To'liq tavsif va barcha maydonlar
- Narx, holat, joylashuv
- **"Sotuvchiga yozish"** → mavjud chat (`DirectMessage`)
- "Batafsil" → to'liq ekran

> ⚠️ **Telefon raqami berilmaydi.** Loyihaning qat'iy qoidasi: aloqa
> faqat ilova ichida. Bu yerda ham shunday.

---

## 7. AI tool'lari (`market_tools.py`)

| Tool | Vazifasi |
|---|---|
| `start_listing_draft` | Sotuv suhbatini boshlash, maydonlar ro'yxatini berish |
| `update_listing_draft` | Yangi ma'lumot qo'shish, qolganini aytish |
| `add_listing_photos` | Rasm qo'shish, yetarli/yetarsizligini aytish |
| `publish_listing` | Tasdiq bilan e'lon qilish |
| `search_listings` | Xaridor uchun qidiruv → grid |
| `get_listing` | Bitta e'lon to'liq ma'lumoti |
| `my_listings` | "Mening e'lonlarim" |
| `close_listing` | "Sotildi" yoki o'chirish |

Jami: 37 → **45 tool**.

---

## 8. Adminka (siz so'ragan boshqaruv)

`FEATURE_DEFS` ga bitta qator:

```python
("marketplace", "Savdo (e'lonlar)"),
```

Shundan keyin adminkada **avtomatik** paydo bo'ladi:

- ✅ Bo'limni **yoqish/o'chirish** (butun tizim ishlashi)
- ✅ **Premium talab qilish** (e'lon berish pullik bo'lsinmi)
- ✅ Ishlamayotganda ko'rsatiladigan xabar

Qo'shimcha sozlamalar (`settings_service`):

| Kalit | Nima |
|---|---|
| `market_free_days` | Oddiy e'lon muddati (7) |
| `market_premium_days` | Premium muddati (30) |
| `market_free_limit` | Oddiy: bir vaqtda nechta (5) |
| `market_premium_limit` | Premium (50) |
| `market_min_photos` | Kamida rasm (3) |
| `market_max_photos` | Ko'pi (6) |

---

## 9. Siz eslatgan RAG haqida

Siz "rag tizimi bilan ham ishlashim mumkin" dedingiz.

**Mening tavsiyam: birinchi bosqichda RAG shart emas.**

Sabab: RAG (vektor qidiruv) o'xshash ma'noli matnlarni topish uchun
kerak. E'lonlar qidiruvida esa asosiy filtrlar **aniq**: toifa, narx
oralig'i, holat, hudud. Buni oddiy SQL tezroq va arzonroq bajaradi.

**RAG qachon foydali bo'ladi:** e'lonlar soni ko'payib, odamlar
"arzonroq va yaxshi kamerali telefon" kabi noaniq so'rov bersa.
O'shanda `search.py` ichiga qo'shiladi va tashqi qism o'zgarmaydi —
shuning uchun uni alohida modul qilib yozaman.

Xohlasangiz birinchi bosqichdayoq qilaman, ayting.

---

## 10. Ish bosqichlari

| # | Bosqich | Nima bo'ladi | Tekshiruv |
|---|---|---|---|
| 1 | Baza + modellar | `listings`, `listing_photos` | Jadvallar yaratiladi, eski ma'lumot buzilmaydi |
| 2 | Maydonlar + validator | Toifaga qarab savollar | Har toifa uchun to'g'ri ro'yxat |
| 3 | Sotuvchi tool'lari | Qoralama → e'lon | Uchdan-uchgacha: suhbatdan bazagacha |
| 4 | Rasmlar | 3-6 ta chegara | 2 ta bo'lsa rad etadi, 7 ta bo'lsa kesadi |
| 5 | Chegaralar + adminka | Premium/muddat/yoqish | O'chirilganda tool ishlamaydi |
| 6 | Qidiruv | Filtr va saralash | Narx/holat/hudud to'g'ri ishlaydi |
| 7 | Chatda GRID | 20 tagacha karta | Widget testi: 20 karta, rasm, narx |
| 8 | Modal oyna | To'liq ma'lumot | Bosilganda ochiladi, raqam yo'q |
| 9 | Xavfsizlik | Begona e'lonni o'chira olmasligi | Test bilan qo'riqlanadi |

Har bosqichdan keyin test yozib, commit qilaman.

---

## 11. Ehtiyot choralari

- **Telefon raqami berilmaydi** — loyihaning qat'iy qoidasi.
- **Begona e'longa tegib bo'lmaydi** — har amalda `user_id` filtri.
- **Rasm hajmi** — chegaralanadi (`flutter_image_compress` bor).
- **Muddati o'tgan e'lon** — qidiruvda ko'rinmaydi (mavjud
  scheduler'ga qo'shiladi).
- **Adminkadan o'chirilsa** — tool'lar ham, ekranlar ham to'xtaydi.
- **Narx validatsiyasi** — manfiy yoki bo'lmagan qiymat rad etiladi.

---

## 12. Sizdan so'raladigan qaror

Kod yozishdan oldin javob bering:

1. **Toifalar:** telefon, mashina, mebel, kiyim, texnika, boshqa —
   shu yetarlimi yoki qo'shamizmi?
2. **Valyuta:** so'm va dollar ikkalasi kerakmi, yoki faqat so'm?
3. **Narx kelishuvi:** "Kelishamiz" varianti bo'lsinmi (narxsiz e'lon)?
4. **Muddat tugagach:** e'lon o'chsinmi yoki "muddati tugagan" bo'lib
   tursinmi (uzaytirish tugmasi bilan)?
5. **RAG:** hozir kerakmi yoki keyinroq?
6. **Sotuvchi bilan aloqa:** faqat chat, yoki qo'ng'iroq ham
   (ilova ichida, WebRTC allaqachon bor)?
