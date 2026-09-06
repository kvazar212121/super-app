# AGENTS.md — bu loyihada ishlaydigan agentlar uchun

## Avval shuni o'qing

**[`ARXITEKTURA.md`](ARXITEKTURA.md)** — loyihaning **yagona** arxitektura
hujjati. Loyiha nima, qanday tuzilgan, qanday qoidalar bor, qanday muammolar
ma'lum — hammasi o'sha yerda, mundarija bilan.

Boshqa arxitektura hujjati **yaratmang**. O'zgarish kiritsangiz —
`ARXITEKTURA.md` ning tegishli bo'limini yangilang va §19 "O'zgarishlar
jurnali" ga bir qator qo'shing.

## Ishni boshlashdan oldin

```bash
git log --oneline -10 && git status
```

Loyihada bir nechta agent parallel ishlashi mumkin — kimdir shu ishni qilib
qo'ygan bo'lishi mumkin.

`docs/qilingan_ishlar/` — **arxiv**. U yerdagi rejalar allaqachon bajarilgan,
ular "todo" emas.

## Ishni tugatgach — tekshiruv

```bash
flutter analyze && flutter test                    # 268 test
PYTHON=backend/.venv/bin/python bash tests/run.sh  # backend integratsiya
cd backend && .venv/bin/alembic check              # modellar migratsiyaga mos
```

Backend integratsiya testlari haqiqiy PostgreSQL talab qiladi; bazasiz
**SKIP** bo'ladi (yiqilmaydi).

## Eng ko'p buziladigan uchta qoida

1. **Baza:** yangi o'zgarish uchun Alembic. Mavjud bazada `upgrade head`
   ISHLATMANG — `stamp head` qiling (`ARXITEKTURA.md` §7).
2. **Qidiruv:** natijani `LIMIT` dan keyin Python'da filtrlamang — natija
   yo'qoladi (§16.2).
3. **Telefon raqam:** ustaning haqiqiy raqami hech qachon berilmaydi, aloqa
   faqat ilova ichida (§9).

Qolgan qoidalar: `ARXITEKTURA.md` §18.
