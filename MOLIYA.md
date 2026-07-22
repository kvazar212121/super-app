# 💰 HubServis — Moliya Modeli (To'lov va Pul Aylanmasi)

> **Maqsad:** Platformadagi pul mantig'ini bir joyda tushuntirish, kelajakdagi
> tuzatishlarda adashmaslik uchun. Har qanday moliyaviy o'zgarish shu hujjatga
> mos bo'lishi kerak.
>
> **Oxirgi yangilanish:** 2026-07-22

---

## 1. Asosiy tamoyil

**Biz to'lov tizimi EMASMIZ.** Biz mijoz bilan ustani (provayder) bog'lovchi
platformamiz. Pul ikki manbadan keladi:

1. **Lead fee (komissiya)** — provayderdan, biz unga mijoz topib berganimiz uchun.
2. **Premium obuna** — oddiy foydalanuvchidan, ilovaning to'liq funksiyasi uchun.

**Provayder ↔ mijoz o'rtasidagi xizmat puliga umuman aralashmaymiz.** Ular o'zaro
qanday hisob-kitob qilishни o'zlari hal qiladi (naqd, karta, kelishuv — bizga
ahamiyatsiz). Biz bu pulni ushlamaymiz, ko'rmaymiz, kafolatlamaymiz.

**Keshbek YO'Q.** Keshbek tizimi butunlay olib tashlandi (biz pul saqlamaymiz).

---

## 2. Yagona hamyon — `user.balance` (B-model)

Har bir foydalanuvchining bitta hamyoni bor: **`users.balance`**.

- Bir odam ham oddiy user, ham provayder (soha egasi) bo'lishi mumkin. Baribir
  hamyon **bitta** — `user.balance`.
- `providers.balance` ustuni **ISHLATILMAYDI** (eski, deprecated). Hamma pul
  operatsiyasi `user.balance` ustida.

### Balans nima uchun?
Balans — **provayderning lead-fee hamyoni**. Provayder shu hisobga oldindan pul
soladi (top-up), biz undan mijoz topilганда komissiya yechamiz.

### Balansni to'ldirish (top-up)
- Endpoint: `POST /api/v1/users/top-up` (`UserService.top_up`)
- `user.balance += amount`
- Maksimal bir martalik: 10 000 000 so'm.
- (Kelajakda Payme/Click orqali real to'lov bilan bog'lanadi.)

---

## 3. Lead fee (komissiya) — provayderdan

### Qachon olinadi?
**FAQAT ish YAKUNLANGANDA** (`Order.status = completed`). Buyurtma yaratilганда
YOKI bron qilinганда **OLINMAYDI**.

> Sabab: bekor qilingan, amalga oshmagan yoki soxta buyurtmalar uchun provayderdan
> pul olmaslik. Pul faqat real bajarilgan ish uchun olinadi.

### Qayerda?
Markazlashtirilган funksiya: **`OrderService.process_commission(db, order)`**
(`backend/app/services/order_service.py`).

Bu funksiya buyurtma `completed` bo'lган barcha nuqtalardan chaqiriladi:
- `orders.py` — mijoz ishни tasdiqlaganda (`confirm_completion`)
- `provider_portal.py` — provayder ishни yakunlaganда
- `admin/orders.py` — admin statusни `completed` qilganда
- `order_service.py` — avto-yakunlash (24 soatdan keyin `run_completion_checks`)

### Fee miqdori (ustuvorlik tartibi)
1. `provider.lead_fee` (provayderга alohida belgilangan) — agar bor bo'lsa
2. `category.lead_fee` (kategoriya uchun) — agar bor bo'lsa
3. `default_lead_fee` (PlatformSetting, admin paneldан) — standart **5000 so'm**

### Qanday yechiladi?
```
owner_user.balance -= actual_fee          # provayder egasining user.balance'idan
Transaction(type="lead_fee", amount=-fee, order_id=..., status="completed")
```

### Muhim xususiyatlar
- **IDEMPOTENT:** bitta buyurtma uchun lead fee faqat **bir marta** olinadi.
  `process_commission` avval shu `order_id` uchun `lead_fee` tranzaksiyasi
  borligini tekshiradi — bo'lsa, hech narsa qilmaydi. Shунday qilib takroriy
  `completed` o'tishlar yoki turli yakunlash yo'llari ikki marta yechmaydi.
- **Manfiy balans** mumkin: agar provayder balansi yetmasa, balans minusга ketadi
  (qarz). Bu ataylab — ish bo'lди, komissiya qarzга yozilади, provayder keyin
  to'ldiradi. (Kelajakda: manfiy balansда yangi lead ko'rsatmaslik mumkin.)

### Test
`backend/tests/test_lead_fee.py` — 4 holatni tekshiradi:
1. Order yaratishда fee olinmaydi
2. Yakunlanганда default fee (yoki provider fee) yechiladi
3. Idempotentlik (ikki marta yechilmaydi)
4. `provider.lead_fee` default'dan ustun

Ishga tushirish: `cd backend && PYTHONPATH=. python tests/test_lead_fee.py`

---

## 4. Premium obuna — oddiy foydalanuvchidan

### Model
Premium **FAQAT onlayn to'lov (Payme/Click)** orqali sotib olinadi. To'lov
provayderining **webhook'i premiumni AVTOMATIK ochadi** — admin tasdig'i SHART EMAS.

> **Balansdan premium sotib olinMAYDI.** Balans — bu provayder lead-fee hamyoni;
> premium uni hech qachon ishlatmaydi. (Bir odam ham provayder, ham user bo'lsa,
> uning lead-fee puli premiumга ketib qolmasligi kerak.)

### Oqim
1. `POST /api/v1/premium/subscribe` `{method: "payme"|"click"}`
   → `PremiumPayment(status="pending")` yaratiladi + checkout URL qaytadi.
2. Foydalanuvchi Payme/Click sahifasида to'laydi.
3. To'lov provayderi **webhook** yuboradi:
   - Payme: `POST /api/v1/payments/payme` (JSON-RPC)
   - Click: `POST /api/v1/payments/click` (Prepare/Complete)
4. Webhook imzoни tekshiради va `premium_service.activate_premium()` ni chaqiради.
   → `user.is_premium = True`, `user.premium_until` uzaytiriladi,
     `Transaction(type="premium_subscription", amount=+price)` yoziladi.

### Konfiguratsiya (admin panel → Premium)
- `premium_price` — narx (so'm)
- `premium_duration_days` — muddat (kun)
- Feature flag'lar — qaysi bo'limlar premium talab qiladi (`feature_<key>_premium`)

### Merchant sozlamalari (admin panel → to'lov)
`payme_merchant_id`, `payme_key`, `click_service_id`, `click_merchant_id`,
`click_secret_key`. Sozlanmaган bo'lsa webhook'lar 404 qaytaradi (hali ulanmaган).

### Admin qo'l-tasdiqlash (favqulodda)
`admin/premium.py` da `confirm_payment` bor, lekin bu **faqat favqulodda** holat
uchun (masalan webhook kelmay qolsa). Balansга tegmaydi. Odatiy holatda premium
webhook orqali avtomatik ochiladi.

---

## 5. Admin panelning roli (moliyada)

Admin **pul aylanmasiga aralashmaydi**. Admin:

- ✅ **Provayder ro'yxatdan o'tishini (KYC) tasdiqlaydi** — `is_verified`,
  `verification_status`. Bu yagona majburiy admin tasdig'i.
- ✅ Lead fee stavkalarини sozlaydi (`default_lead_fee`, kategoriya/provayder fee).
- ✅ Premium narx/muddatини sozlaydi.
- ✅ Moliya hisobotlarини ko'radi (tushum, lead fee, premium).
- ✅ Kerak bo'lsa provayder balansини qo'lда to'ldiради (`admin/finance topup`).
- ❌ Premium sotib olishni tasdiqlamaydi (avtomatik).
- ❌ Xizmat puliga (mijoz↔provayder) aralashmaydi.

---

## 6. Tranzaksiya turlari (`transactions.type`)

| type                    | amount | Ma'no |
|-------------------------|--------|-------|
| `topup`                 | +      | Provayder balansни to'ldirди |
| `lead_fee`              | −      | Mijoz topilганда olinган komissiya |
| `premium_subscription`  | +      | Premium obuna tushumи |
| `admin_withdraw`        | −      | Platforma xarajati (admin yechди) |
| `topup_bonus`           | +      | To'ldirishга bonus (admin qoidasи) |

**Sof foyda** = lead_fee jami + premium jami − admin_withdraw jami.

---

## 7. Deprecated (eski, ishlatilmaydi)

Bu maydonlar DB'da qoldi (migratsiya xavfli), lekin API/UI/logikada
**ishlatilmaydi**. Yangi kod ularга tayanmasин:

- `users.cashback` — keshbek olib tashlandi
- `orders.cashback_earned` — keshbek olib tashlandi
- `providers.balance` — B-model'da `user.balance` ishlatiladi
- `commission_rate`, `cashback_rate` (foizli) — biz qat'iy `default_lead_fee`
  ishlatamiz, foizli komissiya emas.

---

## 8. Xavfsizlik eslatmalari

- Webhook imzolari (`payme_key`, `click_secret_key`) faqat serverда, imzo
  tekshirish uchun. Mijozга hech qachon yuborilmaydi.
- Premium `subscribe` da narx serverдан olinади (mijoz yubormaydi) — narxни
  o'zgartirib bo'lmaydi.
- Lead fee idempotentligi dublikat yechishдан himoya qiladi.
- Balans operatsiyalari `user.balance` ustida — parallel so'rovlar uchun
  kerak bo'lsa `SELECT ... FOR UPDATE` (qatorни qulflash) ishlatilади.
