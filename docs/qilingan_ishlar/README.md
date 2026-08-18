# ✅ Qilingan ishlar (arxiv)

> **Bu papkadagi rejalar BAJARILGAN. Qayta qilish shart emas.**
>
> Boshqa agent yoki dasturchi bu papkani ochsa: shu yerdagi hujjatlar
> tarix uchun saqlangan. Ular bo'yicha kod allaqachon yozilgan, test
> qilingan va `main` shoxiga commit qilingan. **Qaytadan yozmang.**

Sana: 2026-08-17

---

## Nima uchun bu papka bor

Rejalar loyiha ildizida yotganda, yangi agent ularni "qilinishi kerak
bo'lgan ish" deb tushunib, allaqachon ishlab turgan narsani qaytadan
yozib qo'yishi mumkin edi. Shuning uchun bajarilganlari shu yerga
ko'chirildi.

---

## Fayllar va holati

| Fayl | Nima edi | Holati |
|---|---|---|
| `REJA_AI_ELON.md` | AI chat orqali ish e'loni berish (8 bosqich) | ✅ **BAJARILDI** |
| `REJA_SAVDO_AI.md` | AI chat orqali OLX uslubidagi savdo (12 bosqich) | ✅ **BAJARILDI** |
| `super_app_plan.md` | Loyihaning dastlabki umumiy rejasi (2026-05-19) | ✅ Tarixiy, bajarilgan |
| `clean_translation_report.md` | Tarjima kalitlari hisoboti | ✅ Ishlatilgan, arxiv |

---

## REJA_AI_ELON.md — bandma-band hisobot

Reja 8 bosqichdan iborat edi. Har biri kod bilan solishtirib tekshirildi.

| # | Bosqich | Holat | Qayerda |
|---|---|---|---|
| 1 | AI chatga rasm yuborish | ✅ | `POST /ai/job-photo`, `ai_job/vision.py`, `lib/screens/chat_screen.dart` |
| 2 | AI'da e'lon berish tool'lari | ✅ | `ai_agent/job_tools.py` (`start_job_draft`, `update_job_draft`, `publish_job`) |
| 3 | Yetishmagan ma'lumotni so'rash | ✅ | `ai_job/validator.py`, `ai_job/draft.py` |
| 4 | Chatni e'longa bog'lash | ✅ | `DirectMessage.job_id`, `startup.py` dagi `ALTER TABLE` |
| 5 | Real vaqtda yetkazish | ✅ | `messages.py` → `call_manager.send_personal_message` |
| 6 | Usta tomoni (rasm, yozish tugmasi) | ✅ | `lib/screens/jobs_feed_screen.dart` |
| 7 | Xavfsizlik va chegaralar | ✅ | `ai_job/limits.py` + `POST /jobs` |
| 8 | Ikki tillilik (uz/ru) | ✅ | `ai_agent/prompt.py` |
| 9 | Hudud bo'yicha filtr (50 km) | ✅ | `ai_job/geo.py`, `GET /jobs/feed?provider_id=` |

### Yakuniy tekshiruvda topilgan va tuzatilgan 3 ta kamchilik

Reja "bajarildi" deb belgilangan bo'lsa ham, kod o'qilganda uchta band
aslida to'liq bajarilmagani aniqlandi (commit `c609c9d7`):

1. **Ustaning haqiqiy telefon raqami mijozga qaytardi.**
   `JobOffer.to_dict()` `provider_phone` maydonini berardi. Talab qat'iy
   edi: aloqa faqat ilova ichida. Raqam tarqalsa biz o'rtadan chiqib
   qolamiz va lead fee yo'qoladi. Backend model, Pydantic sxema va Dart
   modelidan olib tashlandi.

2. **E'lon chegaralarini chetlab o'tish mumkin edi.** 3 ta ochiq e'lon /
   5 kun muddat tekshiruvi faqat AI tool'ida edi. Ilovadagi oddiy forma
   (`POST /jobs`) hech narsa tekshirmasdi. Endi ikkala yo'l bir xil.

3. **Usta e'lon kartasida rasmni ko'rmasdi** (reja 6-bosqichi). Rasm
   lentasi qo'shildi, bosilganda to'liq ekranda ochiladi.

Tekshiruv: `tests/test_jobs_limits_privacy.py` (14 ta tekshiruv).

---

## REJA_SAVDO_AI.md — bandma-band hisobot

Buyum savdosi (marketplace). `jobs` (ish e'lonlari) dan BUTUNLAY
alohida: u yerda xizmat, bu yerda narsa sotiladi.

| # | Bosqich | Holat | Qayerda |
|---|---|---|---|
| 1 | Baza + modellar | ✅ | `models/marketplace/listing.py`, `listing_photo.py` |
| 2 | Maydonlar + validator | ✅ | `services/marketplace/fields.py`, `validator.py` |
| 3 | Sotuvchi tool'lari | ✅ | `ai_agent/market_tools.py` (8 tool, jami 45) |
| 4 | Rasmlar (3-6 ta) | ✅ | `marketplace/photos.py`, `POST /marketplace/photo` |
| 5 | Chegaralar + adminka | ✅ | `marketplace/limits.py`, `FEATURE_DEFS` + `/admin/marketplace-settings` |
| 6 | Qidiruv | ✅ | `marketplace/search.py` (RAG YO'Q — foydalanuvchi qarori) |
| 7 | Chatda GRID (20 ta) | ✅ | `lib/widgets/marketplace/listing_grid.dart`, `chat_screen.dart` |
| 8 | Modal oyna | ✅ | `lib/widgets/marketplace/listing_modal.dart` |
| 9 | Xavfsizlik (begona e'lon) | ✅ | `marketplace/publisher.py` `own_listing()` + test |
| 10 | Valyuta (doim so'mda) | ✅ | `marketplace/currency.py` |
| 11 | Mening e'lonlarim + uzaytirish | ✅ | `marketplace/extend.py`, `lib/screens/marketplace/my_listings_screen.dart` |
| 12 | Firibgarlik ogohlantirishi + shikoyat | ✅ | `marketplace/safety.py`, `safety_warning_dialog.dart` |

Qabul qilingan qarorlar (foydalanuvchi tasdiqlagan):

- **Telefon raqami hech qachon berilmaydi** — `to_dict()` da ham,
  API javobida ham. Test bilan qo'riqlanadi.
- **Narx doim so'mda ko'rsatiladi.** Dollarda saqlansa ham xaridor
  so'mda ko'radi, asli qavsda: `4 410 000 so'm (350 $)`.
- **"Kelishamiz"** — narxsiz e'lon ham bo'ladi.
- **Muddat tugagach e'lon o'chmaydi**, "Mening e'lonlarim" da
  uzaytiriladi (premium bepul, boshqasi balansdan).
- **RAG ishlatilmadi** — filtrlar aniq, SQL tezroq va arzonroq.
- **Chegaralar:** oddiy 7 kun / 5 e'lon / 6 rasm, premium 30 kun /
  50 e'lon / 10 rasm. Hammasi adminkadan sozlanadi.

Tekshiruv: `tests/test_marketplace_flow.py` (39), `_search.py` (27),
`_limits.py` (45), `_contract.py` (52) + Flutter `marketplace_grid_test.dart`
va `marketplace_modal_test.dart` (14). Jami Flutter testi 205 → 219.

> Eslatma: savdo testlari PostgreSQL bo'lmasa SKIP bo'lmaydi —
> vaqtincha SQLite faylida ishlaydi, chunki bu mantiq Postgres'ga xos
> narsa ishlatmaydi. Baza berilsa (`SUPERAPP_TEST_DB`) o'shanda ishlaydi.

---

## Shu bilan birga qilingan xarita ishi

Rejadan tashqari, yarim qolgan xarita ishi ham yakunlandi
(commit `ce843af6`):

- 6 ta xarita ekranida tile manzili qo'lda yozilgan edi (CartoDB va OSM
  demo serverlari). Ikkalasi ham ommaviy ilovada **taqiqlangan**
  (OSM Tile Usage Policy) — foydalanuvchi ko'paysa xarita oq bo'lib
  qolardi.
- `lib/config/map_config.dart` — yagona manba. MapTiler kaliti
  `--dart-define=MAPTILER_KEY` orqali, kodga yozilmaydi.
- Litsenziya atributi (ODbL talabi) qo'shildi.
- `test/map_config_test.dart` — qo'lda yozilgan manzil qaytib kelsa test
  yiqiladi.

---

## Bu ishlarga qaytish kerak bo'lsa

Tegishli commitlar:

```
c609c9d7  fix(jobs): raqam maxfiyligi, chegaralar formaga ham, ustaga rasm
ce843af6  feat(xarita): tile provayderi bitta joyda (MapConfig)
0c683243  feat(ai-job): chatga rasm, ikki tillilik, adminkada premium
1dddc6d6  feat(chat): xabarni e'longa bog'lash, real vaqt, usta reytingi
2808a5f7  feat(jobs): e'lon faqat SHU HUDUDDAGI ustalarga ko'rinadi
9f71af2e  feat(ai-job): AI chat orqali ish e'loni berish (1-3 bosqich)
```

Hali qilinmagan ishlar loyiha ildizidagi hujjatlarda turadi
(`ARXITEKTURA.md`, `DEPLOY.md`).
