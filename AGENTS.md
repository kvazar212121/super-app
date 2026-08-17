# AGENTS.md — bu loyihada ishlaydigan agentlar uchun

O'qing, keyin ishni boshlang. Bu fayl vaqt yo'qotmaslik uchun.

## 1. Bajarilgan ishni QAYTA qilmang

`docs/qilingan_ishlar/` — **arxiv**. U yerdagi rejalar allaqachon
bajarilgan, test qilingan va commit qilingan. Ular "todo" emas.
Ishni boshlashdan oldin `docs/qilingan_ishlar/README.md` ni o'qing.

Loyihada bir nechta agent parallel ishlashi mumkin. `git log` va
`git status` ni doim tekshiring: kimdir shu ishni qilib qo'ygan
bo'lishi mumkin.

## 2. Loyiha nima

HubServis (`super_app`) — O'zbekiston uchun xizmatlar super-app'i.

- **Backend:** FastAPI + PostgreSQL 16 + Redis 7, Docker Compose
- **Ilova:** Flutter (`lib/`)
- **Admin panel:** vanilla HTML/JS (`backend/app/static/admin/`)
- **To'liq tavsif:** `ARXITEKTURA.md`
- **Serverga chiqarish:** `DEPLOY.md`

## 3. Tekshiruv (ishni tugatgach MAJBURIY)

```bash
flutter analyze && flutter test          # 203 test, 0 error bo'lishi kerak
PYTHON=backend/.venv/bin/python bash tests/run.sh
```

Backend integratsiya testlari haqiqiy PostgreSQL talab qiladi. Bazasiz
ular **SKIP** bo'ladi (yiqilmaydi). Jiddiy o'zgarish kiritsangiz baza
bilan bir marta ishlating:

```bash
export SUPERAPP_TEST_DB="postgresql+asyncpg://postgres@127.0.0.1:5435/superapp_test"
```

> Diqqat: test bazasi `drop_all` qiladi. Ishchi bazani KO'RSATMANG.

## 4. Bu loyihaning qoidalari

- **Izohlar o'zbekcha** va "nima uchun" ni tushuntiradi, "nima" ni emas.
- **Sirlar kodga yozilmaydi.** `.env` (backend), `--dart-define`
  (Flutter, masalan `MAPTILER_KEY`).
- **Baza:** Alembic ishlatilmaydi. Yangi jadval `create_all` bilan
  o'zi yaratiladi; mavjud jadvalga ustun qo'shish uchun
  `app/core/startup.py` dagi `ALTER TABLE ... IF NOT EXISTS` uslubi.
- **Ustaning haqiqiy telefon raqami mijozga BERILMAYDI.** Aloqa faqat
  ilova ichida (chat / WebRTC). Buni buzmang, biznes modeli shunga
  bog'liq.
- **Xarita:** tile manzilini hech qayerga qo'lda yozmang, faqat
  `lib/config/map_config.dart`. Buni test qo'riqlaydi.
- Har mazmunli o'zgarishdan keyin commit qiling, izoh o'zbekcha.

## 5. AI agent (`backend/app/services/ai_agent/`)

37 ta tool bor. Yangi tool qo'shish = `tools_schema.py` ga sxema +
mos modulga handler + `dispatcher.py` ga ulash. Sxema va handler soni
MOS bo'lishi kerak, buni test tekshiradi.

- **O'zgartiruvchi har amal `confirm` darvozasidan o'tadi**: avval
  xulosa qaytariladi, foydalanuvchi tasdiqlagach bajariladi. AI xato
  tushunsa, haqiqiy bronni buzib qo'ymasin.
- **Har amal faqat so'rovchining o'z ma'lumotiga tegadi**
  (`user_id` bo'yicha filtr majburiy). Buni test qo'riqlaydi.
- LLM ba'zan buzuq JSON qaytaradi — `dispatcher._parse_args` uni
  tiklaydi. Bu joyni soddalashtirmang, u haqiqiy 500 xatosini
  tuzatgan.
