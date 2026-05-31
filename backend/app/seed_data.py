"""Seed ma'lumotlar — PostgreSQL ga yuklash uchun."""

from datetime import datetime, timedelta, timezone

# ── Foydalanuvchilar (seed) ─────────────────────────────────────────────
USERS = [
    {"name": "Kudratulloh", "surname": "Rahimov", "phone": "+998901112233", "balance": 250000, "cashback": 18500, "is_premium": True, "password": "demo1234"},
    {"name": "Abdulloh", "surname": "Karimov", "phone": "+998901234567", "balance": 150000, "cashback": 12500, "is_premium": True, "password": "demo1234"},
    {"name": "Nilufar", "surname": "Rustamova", "phone": "+998912345678", "balance": 85000, "cashback": 7200, "is_premium": False, "password": "demo1234"},
    {"name": "Sardor", "surname": "Aliyev", "phone": "+998933456789", "balance": 230000, "cashback": 18900, "is_premium": True, "password": "demo1234"},
    {"name": "Dilnoza", "surname": "Hakimova", "phone": "+998944567890", "balance": 45000, "cashback": 3200, "is_premium": False, "password": "demo1234"},
    {"name": "Jasur", "surname": "Bekmurodov", "phone": "+998955678901", "balance": 320000, "cashback": 25600, "is_premium": True, "password": "demo1234"},
    {"name": "Malika", "surname": "Tursunova", "phone": "+998976789012", "balance": 67000, "cashback": 5400, "is_premium": False, "password": "demo1234"},
    {"name": "Bobur", "surname": "Normurodov", "phone": "+998997890123", "balance": 190000, "cashback": 14300, "is_premium": True, "password": "demo1234"},
]

# category_key, name, address, phone, lat, lng, rating, review_count, metadata
PROVIDERS = [
    # Sartarosh
    {"category_key": "sartarosh", "name": "Style Barbershop", "address": "Amir Temur ko'chasi, 15", "phone": "+998901234567", "lat": 41.3115, "lng": 69.2495, "rating": 4.8, "review_count": 124, "metadata": {"type": "barber_shop", "services": ["Erkaklar kesimi", "Soqol olish", "Bolalar kesimi"], "barbers": [{"name": "Aziz", "rating": 4.9}, {"name": "Jahongir", "rating": 4.7}]}},
    {"category_key": "sartarosh", "name": "Premium Cut", "address": "Chilonzor tumani, 5-mavze", "phone": "+998939876543", "lat": 41.2995, "lng": 69.2205, "rating": 4.9, "review_count": 89, "metadata": {"type": "barber_shop", "services": ["Erkaklar kesimi", "Soqol olish", "Styling"]}},
    {"category_key": "sartarosh", "name": "Classic Barber", "address": "Yunusobod tumani, Katta Halqa yo'li", "phone": "+998945554433", "lat": 41.3355, "lng": 69.2675, "rating": 4.6, "review_count": 56, "metadata": {"type": "barber_shop"}},
    # Salon
    {"category_key": "salon", "name": "Belleza Salon", "address": "Navoiy ko'chasi, 21", "phone": "+998904443322", "lat": 41.3155, "lng": 69.2555, "rating": 4.9, "review_count": 210, "metadata": {"type": "beauty_salon", "services": ["Fen", "Manikyur", "Makiyaj"]}},
    {"category_key": "salon", "name": "Glow Up Studio", "address": "Shota Rustaveli ko'chasi", "phone": "+998931112233", "lat": 41.2855, "lng": 69.2455, "rating": 4.7, "review_count": 156, "metadata": {"type": "beauty_salon"}},
    # Futbol
    {"category_key": "futbol", "name": "Lokomotiv Stadium", "address": "Mirzo Ulug'bek tumani", "phone": "+998712001010", "lat": 41.3115, "lng": 69.2495, "rating": 4.8, "review_count": 234, "metadata": {"type": "football_field", "size": "large", "surface": "natural", "base_price_per_hour": 450000}},
    {"category_key": "futbol", "name": "Bunyodkor Stadioni", "address": "Chilanzar tumani", "phone": "+998712302020", "lat": 41.302, "lng": 69.235, "rating": 4.9, "review_count": 512, "metadata": {"type": "football_field", "size": "large", "surface": "natural", "base_price_per_hour": 550000}},
    {"category_key": "futbol", "name": "Champion's Field", "address": "Bobur ko'chasi", "phone": "+998903003030", "lat": 41.318, "lng": 69.262, "rating": 4.6, "review_count": 187, "metadata": {"type": "football_field", "size": "medium", "surface": "artificial", "base_price_per_hour": 280000}},
    {"category_key": "futbol", "name": "Mini Arena Tashkent", "address": "Sergeli tumani", "phone": "+998904004040", "lat": 41.285, "lng": 69.220, "rating": 4.4, "review_count": 95, "metadata": {"type": "football_field", "size": "small", "surface": "artificial", "base_price_per_hour": 180000}},
    # Ustalar (santexnik, elektrik, tozalash, avto, konditsioner, enaga, repetitor)
    {"category_key": "santexnik", "name": "Usta Ali", "address": "Toshkent", "phone": "+998903332211", "lat": 41.3215, "lng": 69.2595, "rating": 4.9, "review_count": 45, "metadata": {"type": "master", "specialty": "Santexnik", "services": ["Kran tuzatish", "Quvur almashtirish"]}},
    {"category_key": "elektrik", "name": "Usta Vali", "address": "Toshkent", "phone": "+998911112233", "lat": 41.3055, "lng": 69.2305, "rating": 4.7, "review_count": 32, "metadata": {"type": "master", "specialty": "Elektrik"}},
    {"category_key": "elektrik", "name": "Usta Elektrik Pro", "address": "Toshkent", "phone": "+998901112233", "lat": 41.31, "lng": 69.25, "rating": 4.8, "review_count": 156, "metadata": {"type": "master", "specialty": "Elektrik"}},
    {"category_key": "tozalash", "name": "Gulnora Tozalash", "address": "Toshkent", "phone": "+998935554433", "lat": 41.33, "lng": 69.27, "rating": 4.8, "review_count": 56, "metadata": {"type": "master", "specialty": "Tozalash"}},
    {"category_key": "tozalash", "name": "Toza Klaster", "address": "Toshkent", "phone": "+998912223344", "lat": 41.30, "lng": 69.24, "rating": 4.5, "review_count": 89, "metadata": {"type": "master", "specialty": "Tozalash"}},
    {"category_key": "santexnik", "name": "Santexnik Master", "address": "Toshkent", "phone": "+998933334455", "lat": 41.305, "lng": 69.245, "rating": 4.9, "review_count": 203, "metadata": {"type": "master", "specialty": "Santexnik"}},
    {"category_key": "avtoYordam", "name": "Auto-SOS Jamoasi", "address": "Toshkent", "phone": "+998997778899", "lat": 41.29, "lng": 69.21, "rating": 4.9, "review_count": 128, "metadata": {"type": "master", "specialty": "Avto-yordam"}},
    {"category_key": "avtoYordam", "name": "Quick Move", "address": "Toshkent", "phone": "+998955556677", "lat": 41.308, "lng": 69.238, "rating": 4.2, "review_count": 67, "metadata": {"type": "master", "specialty": "Ko'chirish"}},
    {"category_key": "konditsioner", "name": "Akmal Konditsioner", "address": "Toshkent", "phone": "+998902223344", "lat": 41.34, "lng": 69.25, "rating": 4.8, "review_count": 42, "metadata": {"type": "master", "specialty": "Konditsioner"}},
    {"category_key": "enaga", "name": "Zuhra opa", "address": "Toshkent", "phone": "+998904445566", "lat": 41.315, "lng": 69.265, "rating": 5.0, "review_count": 84, "metadata": {"type": "master", "specialty": "Enaga"}},
    {"category_key": "repetitor", "name": "Jasur Tutor", "address": "Toshkent", "phone": "+998908887766", "lat": 41.30, "lng": 69.24, "rating": 4.9, "review_count": 38, "metadata": {"type": "master", "specialty": "Repetitor"}},
    {"category_key": "repetitor", "name": "Najot Ta'lim", "address": "Chilonzor 9-kvartal", "phone": "+998712006906", "lat": 41.285, "lng": 69.205, "rating": 4.9, "review_count": 120, "metadata": {"type": "education_center", "courses": ["Programmalash", "Grafik Dizayn"]}},
    {"category_key": "repetitor", "name": "Cambridge Learning Center", "address": "Abdulla Qodiriy ko'chasi", "phone": "+998712001122", "lat": 41.325, "lng": 69.285, "rating": 4.7, "review_count": 85, "metadata": {"type": "education_center"}},
    # Ishchi
    {"category_key": "ishchi", "name": "Eshmat", "address": "Toshkent", "phone": "+998900000001", "lat": 41.315, "lng": 69.245, "rating": 4.5, "review_count": 20, "metadata": {"type": "worker", "worker_type": "Yuk tashuvchi"}},
    {"category_key": "ishchi", "name": "Toshmat", "address": "Toshkent", "phone": "+998900000002", "lat": 41.31, "lng": 69.255, "rating": 4.2, "review_count": 15, "metadata": {"type": "worker", "worker_type": "Yordamchi ishchi"}},
    # Avto ustaxona
    {"category_key": "avtoYordam", "name": "Grand Auto Service", "address": "Yunusobod, 19-kvartal", "phone": "+998712000001", "lat": 41.35, "lng": 69.29, "rating": 4.8, "review_count": 95, "metadata": {"type": "auto_workshop"}},
    {"category_key": "avtoYordam", "name": "Express Tuning", "address": "Sergeli moshina bozori", "phone": "+998901234567", "lat": 41.22, "lng": 69.20, "rating": 4.6, "review_count": 60, "metadata": {"type": "auto_workshop"}},
    # Dezinfeksiya
    {"category_key": "dezinfeksiya", "name": "Uy Tozalash Dez", "address": "Toshkent", "phone": "+998901112233", "lat": 41.3115, "lng": 69.2495, "rating": 4.8, "review_count": 142, "metadata": {"type": "disinfection"}},
    {"category_key": "dezinfeksiya", "name": "Ofis Pro", "address": "Toshkent", "phone": "+998934445566", "lat": 41.3055, "lng": 69.2625, "rating": 4.6, "review_count": 89, "metadata": {"type": "disinfection"}},
    {"category_key": "dezinfeksiya", "name": "Saniter Xizmat", "address": "Toshkent", "phone": "+998970001122", "lat": 41.3225, "lng": 69.2785, "rating": 4.9, "review_count": 203, "metadata": {"type": "disinfection"}},
    # Kuryerlik
    {"category_key": "kuryerlik", "name": "Tezkor Kuryer", "address": "Toshkent", "phone": "+998903334455", "lat": 41.3115, "lng": 69.2495, "rating": 4.7, "review_count": 231, "metadata": {"type": "courier"}},
    {"category_key": "kuryerlik", "name": "Express Post", "address": "Toshkent", "phone": "+998949990011", "lat": 41.3225, "lng": 69.2685, "rating": 4.8, "review_count": 198, "metadata": {"type": "courier"}},
    # Texnika ustasi
    {"category_key": "texnikaUstasi", "name": "Texnika Pro", "address": "Toshkent", "phone": "+998902223344", "lat": 41.3145, "lng": 69.2515, "rating": 4.7, "review_count": 178, "metadata": {"type": "appliance_repair"}},
    {"category_key": "texnikaUstasi", "name": "Master Fix", "address": "Toshkent", "phone": "+998935556677", "lat": 41.2955, "lng": 69.2405, "rating": 4.9, "review_count": 245, "metadata": {"type": "appliance_repair"}},
    # Massaj
    {"category_key": "massajHijoma", "name": "Shifo Massaj", "address": "Toshkent", "phone": "+998904445566", "lat": 41.3155, "lng": 69.2545, "rating": 4.8, "review_count": 189, "metadata": {"type": "massage"}},
    {"category_key": "massajHijoma", "name": "Hijoma Markazi", "address": "Toshkent", "phone": "+998937778899", "lat": 41.2975, "lng": 69.2415, "rating": 4.9, "review_count": 267, "metadata": {"type": "massage"}},
    # Hamshira
    {"category_key": "hamshira", "name": "Tibbiyot Uyda", "address": "Toshkent", "phone": "+998905556677", "lat": 41.3125, "lng": 69.2505, "rating": 4.7, "review_count": 156, "metadata": {"type": "nurse"}},
    {"category_key": "hamshira", "name": "Sog'liq Xizmat", "address": "Toshkent", "phone": "+998974445566", "lat": 41.3095, "lng": 69.2825, "rating": 4.9, "review_count": 278, "metadata": {"type": "nurse"}},
    # Tadbirlar
    {"category_key": "tadbirlar", "name": "To'y Rejissyor", "address": "Toshkent", "phone": "+998906667788", "lat": 41.3165, "lng": 69.2565, "rating": 4.9, "review_count": 312, "metadata": {"type": "event"}},
    {"category_key": "tadbirlar", "name": "Event Pro", "address": "Toshkent", "phone": "+998939990011", "lat": 41.3015, "lng": 69.2445, "rating": 4.7, "review_count": 198, "metadata": {"type": "event"}},
    # Usta (umumiy)
    {"category_key": "usta", "name": "Repair Plus", "address": "Toshkent", "phone": "+998944445566", "lat": 41.298, "lng": 69.252, "rating": 3.8, "review_count": 45, "metadata": {"type": "master", "specialty": "Taqmirlash"}},
    {"category_key": "salon", "name": "Beauty Salon Lux", "address": "Toshkent", "phone": "+998976667788", "lat": 41.312, "lng": 69.258, "rating": 4.7, "review_count": 134, "metadata": {"type": "beauty_salon"}},
]

# Buyurtmalar — user_phone, provider_name, category_key, service_name, price, status, days_ago
ORDERS = [
    {"user_phone": "+998901234567", "provider_name": "Usta Elektrik Pro", "category_key": "elektrik", "service_name": "Elektrik ta'mirlash", "price": 250000, "status": "completed", "days_ago": 16},
    {"user_phone": "+998912345678", "provider_name": "Toza Klaster", "category_key": "tozalash", "service_name": "Uy tozalash", "price": 180000, "status": "in_progress", "days_ago": 15},
    {"user_phone": "+998933456789", "provider_name": "Santexnik Master", "category_key": "santexnik", "service_name": "Santexnik xizmati", "price": 320000, "status": "confirmed", "days_ago": 15},
    {"user_phone": "+998944567890", "provider_name": "Repair Plus", "category_key": "usta", "service_name": "Telefon ta'mirlash", "price": 95000, "status": "pending", "days_ago": 15},
    {"user_phone": "+998955678901", "provider_name": "Quick Move", "category_key": "avtoYordam", "service_name": "Ko'chirish xizmati", "price": 450000, "status": "completed", "days_ago": 17},
    {"user_phone": "+998976789012", "provider_name": "Beauty Salon Lux", "category_key": "salon", "service_name": "Soch turmagi", "price": 75000, "status": "completed", "days_ago": 18},
    {"user_phone": "+998997890123", "provider_name": "Usta Elektrik Pro", "category_key": "elektrik", "service_name": "Konditsioner o'rnatish", "price": 380000, "status": "cancelled", "days_ago": 19},
    {"user_phone": "+998901112233", "provider_name": "Style Barbershop", "category_key": "sartarosh", "service_name": "Erkaklar kesimi", "price": 50000, "status": "completed", "days_ago": 1},
    {"user_phone": "+998901112233", "provider_name": "Usta Vali", "category_key": "elektrik", "service_name": "Rozetka o'rnatish", "price": 120000, "status": "in_progress", "days_ago": 0},
]

REVIEWS = [
    {"user_phone": "+998901234567", "provider_name": "Usta Elektrik Pro", "rating": 5, "comment": "Juda yaxshi ish qildi, tavsiya qilaman!"},
    {"user_phone": "+998912345678", "provider_name": "Toza Klaster", "rating": 4, "comment": "Toza va tez ishlashdi, lekin kechikib kelishdi."},
    {"user_phone": "+998933456789", "provider_name": "Santexnik Master", "rating": 5, "comment": "Professional usta, muammoni tez hal qildi."},
    {"user_phone": "+998955678901", "provider_name": "Quick Move", "rating": 3, "comment": "O'rtacha, ba'zi narsalar shikastlangan."},
    {"user_phone": "+998976789012", "provider_name": "Beauty Salon Lux", "rating": 5, "comment": "Ajoyib natija, albatta qayta boraman!"},
]

PLATFORM_SETTINGS = [
    {"key": "commission_rate", "value": "10", "description": "Platforma komissiyasi (%)"},
    {"key": "cashback_rate", "value": "1", "description": "Cashback foizi (%)"},
    {"key": "currency", "value": "UZS", "description": "Asosiy valyuta"},
]

PAYMENT_CARDS = [
    {"user_phone": "+998901112233", "masked_number": "**** **** **** 4242", "bank": "Kapitalbank", "card_type": "uzcard", "exp_month": 12, "exp_year": 2027, "is_default": True},
    {"user_phone": "+998901112233", "masked_number": "**** **** **** 8888", "bank": "Humo", "card_type": "humo", "exp_month": 6, "exp_year": 2026, "is_default": False},
]

NOTIFICATIONS = [
    {"user_phone": "+998901112233", "type": "push", "title": "Buyurtma qabul qilindi", "message": "Elektrik xizmati buyurtmangiz tasdiqlandi"},
    {"user_phone": "+998901112233", "type": "push", "title": "Cashback qo'shildi", "message": "500 so'm cashback hisobingizga qo'shildi"},
]
