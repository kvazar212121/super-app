"""AI tool (function-calling) sxemalari — OpenAI-mos format.

Har tool'ning bajaruvchisi handler modullarida (personal/read/manage/info/provider).
"""

TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "add_plan",
            "description": "Foydalanuvchining SHAXSIY kun tartibiga eslatma/vazifa qo'shish (masalan 'ertaga majlis', 'soat 3da shifokorga borish', 'onamga qo'ng'iroq qilish'). DIQQAT: bu FAQAT o'zi uchun eslatma. Agar foydalanuvchi biror USTA/XIZMATNI bron qilishni so'rasa (sartarosh, tozalash, santexnik, salon, massaj va h.k.) — bu add_plan EMAS, balki search_providers→create_booking ishlatiladi.",
            "parameters": {
                "type": "object",
                "properties": {
                    "title": {"type": "string", "description": "Reja nomi yoki qisqacha tavsifi (masalan, 'Majlis', 'Shifokor qabuli')"},
                    "due_date": {"type": "string", "description": "ISO 8601 formatidagi sana va vaqt (masalan, '2026-06-19T10:00:00Z')"},
                    "description": {"type": "string", "description": "Reja bo'yicha qo'shimcha izoh yoki tafsilotlar"}
                },
                "required": ["title", "due_date"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "add_todo",
            "description": "Foydalanuvchining SHAXSIY vazifalar (todo) ro'yxatiga yangi vazifa qo'shish (masalan 'kir yuvish', 'kitob o'qish', 'hisobotni yakunlash'). Sana/vaqt shart emas. DIQQAT: bu FAQAT o'zi uchun vazifa — biror USTA/XIZMATNI bron qilish EMAS (buning uchun search_providers→create_booking).",
            "parameters": {
                "type": "object",
                "properties": {
                    "title": {"type": "string", "description": "Vazifa nomi yoki qisqacha tavsifi (masalan, 'Kir yuvish')"},
                    "due_date": {"type": "string", "description": "Ixtiyoriy: ISO 8601 formatidagi muddat (masalan, '2026-06-19T10:00:00Z')"},
                    "description": {"type": "string", "description": "Vazifa bo'yicha qo'shimcha izoh"}
                },
                "required": ["title"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "add_finance_record",
            "description": "Foydalanuvchi uchun moliyaviy kirim (daromad) yoki chiqim (xarajat) qayd etish.",
            "parameters": {
                "type": "object",
                "properties": {
                    "type": {"type": "string", "enum": ["income", "expense"], "description": "Tranzaksiya turi: kirim (income) yoki chiqim (expense)"},
                    "amount": {"type": "number", "description": "Pul miqdori (masalan, 50000)"},
                    "category": {"type": "string", "description": "Toifa nomi (masalan, 'Ovqatlanish', 'Transport', 'Maosh')"},
                    "description": {"type": "string", "description": "Tranzaksiya izohi"}
                },
                "required": ["type", "amount", "category"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "add_shopping_item",
            "description": "Bozorlik ro'yxatiga yangi mahsulot qo'shish.",
            "parameters": {
                "type": "object",
                "properties": {
                    "name": {"type": "string", "description": "Mahsulot nomi (masalan, 'Go\\'sht', 'Kartoshka')"},
                    "qty": {"type": "number", "description": "Miqdori (masalan, 2)"},
                    "unit": {"type": "string", "description": "O'lchov birligi (masalan, 'kg', 'dona', 'litr')"},
                    "estimated_price": {"type": "number", "description": "Kutilayotgan taxminiy narxi (so'mda)"}
                },
                "required": ["name", "qty", "unit"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "set_alarm",
            "description": "Foydalanuvchi uchun majburlovchi budilnik qo'shish. 'ertalab 7 da budilnik qo'y', '6:30 ga uyg'ot' kabi so'rovlarda chaqiring.",
            "parameters": {
                "type": "object",
                "properties": {
                    "hour": {"type": "integer", "description": "Soat (0-23)"},
                    "minute": {"type": "integer", "description": "Daqiqa (0-59)"},
                    "label": {"type": "string", "description": "Budilnik nomi (masalan 'Ishga uyg'onish')"},
                    "repeat_days": {"type": "string", "description": "Takror kunlar ISO CSV (1=Dushanba..7=Yakshanba). Har kuni uchun '1,2,3,4,5,6,7', ish kunlari '1,2,3,4,5'. Bir martalik uchun bo'sh."},
                    "mission_type": {"type": "string", "enum": ["math", "photo", "speech"], "description": "O'chirish vazifasi: matematik misol (math), rasmga olish (photo) yoki matn o'qish (speech). Default: math."}
                },
                "required": ["hour", "minute"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "search_providers",
            "description": "Xizmat ustalari/joylarini (sartarosh, sartaroshxona, salon, santexnik, tozalash, massaj, repetitor, avto-yordam va h.k.) qidirish. Foydalanuvchi 'bron qil', 'band qil', 'rezerv qil', 'buyurtma ber', 'chaqir', 'topib ber' desa — ENG BIRINCHI shu tool chaqiriladi (create_booking'дан oldin). Bu reja/eslatma EMAS.",
            "parameters": {
                "type": "object",
                "properties": {
                    "category_key": {"type": "string", "description": "System promptdagi XIZMAT KATEGORIYALARI ro'yxatidan ANIQ key (masalan 'sartarosh', 'santexnik', 'tozalash'). Xizmat turi so'ralganda HAR DOIM shu paramni bering — natija faqat shu kategoriyadan chiqadi."},
                    "service_query": {"type": "string", "description": "Xizmat turi yoki usta NOMI (masalan 'sartarosh' yoki 'Premium Cut'). category_key berilgan bo'lsa bu faqat qo'shimcha kontekst."},
                    "location": {"type": "string", "description": "Ixtiyoriy: hudud/tuman/manzil (masalan 'Chilonzor', 'Yunusobod'). Foydalanuvchi 'shu hududдан', 'Chilonzordagi' desa shu yerга yoziladi."},
                    "sort_by": {"type": "string", "enum": ["distance", "rating"], "description": "Saralash tartibi. Foydalanuvchi 'eng yaqin', 'yaqin oradagi', 'yonimdagi', 'atrofimdagi' desa — 'distance' (masofa bo'yicha, foydalanuvchi joylashuvidan). Aks holda 'rating' (default)."},
                    "limit": {"type": "integer", "description": "Nechta natija (default 10, maksimum 15). Foydalanuvchi 'eng yaqin 5 ta' desa 5."}
                },
                "required": ["service_query"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "create_booking",
            "description": "Tanlangan ustaga xizmat buyurtmasini (bron) rasmiylashtirish. search_providers'дан keyin, manzil va vaqt aniqlangач chaqiriladi. IKKI QADAMLI: avval confirm=false (yoki confirmsiz) chaqiring — tool bron xulosasini qaytaradi; foydalanuvchiga tafsilotlarni ko'rsatib tasdiq oling; SO'NGRA confirm=true bilan qayta chaqiring (aynan shundagina buyurtma yaratiladi).",
            "parameters": {
                "type": "object",
                "properties": {
                    "provider_id": {"type": "integer", "description": "search_providers qaytargan usta id'si"},
                    "service_name": {"type": "string", "description": "Xizmat nomi (masalan 'Soch olish', 'Uy tozalash')"},
                    "date": {"type": "string", "description": "ISO 8601 sana va vaqt (masalan '2026-07-07T15:00:00Z')"},
                    "address": {"type": "string", "description": "Xizmat ko'rsatiladigan manzil"},
                    "price": {"type": "number", "description": "Kelishilган narx (so'mda). Noma'lum bo'lsa search natijasidagi taxminiy narx."},
                    "confirm": {"type": "boolean", "description": "Foydalanuvchi bron tafsilotlarini (usta, xizmat, sana, narx, manzil) ko'rib aniq tasdiqlaganда true. Aks holда false (yoki bermang) — tool tasdiq so'rash uchun xulosa qaytaradi."}
                },
                "required": ["provider_id", "service_name", "date", "address", "price"]
            }
        }
    },
    # ── O'QISH (READ) toollari — foydalanuvchi "nima bor / qancha" deb so'raganda ──
    {
        "type": "function",
        "function": {
            "name": "list_orders",
            "description": "Foydalanuvchining buyurtmalari (bronlari) ro'yxati. 'buyurtmalarim', 'qanaqa bronlarim bor' kabi so'rovlarда, shuningdek bekor qilishдан OLDIN id topish uchun chaqiring.",
            "parameters": {
                "type": "object",
                "properties": {
                    "only_active": {"type": "boolean", "description": "true bo'lsa faqat faol (bekor/yakunlanmagan) buyurtmalar. Default true."}
                },
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "list_plans",
            "description": "Foydalanuvchining rejalari ro'yxati. 'rejalarim', 'bugun nima rejam bor' kabi so'rovlarда yoki reja bekor/bajarilgan qilishдан oldin id topish uchun.",
            "parameters": {"type": "object", "properties": {
                "only_pending": {"type": "boolean", "description": "true bo'lsa faqat bajarilmagan rejalar. Default true."}
            }}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "list_todos",
            "description": "Foydalanuvchining vazifalari (todo) ro'yxati.",
            "parameters": {"type": "object", "properties": {
                "only_pending": {"type": "boolean", "description": "true bo'lsa faqat bajarilmagan vazifalar. Default true."}
            }}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "list_alarms",
            "description": "Foydalanuvchining budilniklari ro'yxati. Budilnik o'chirish/yoqishдан oldin id topish uchun.",
            "parameters": {"type": "object", "properties": {}}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "list_shopping",
            "description": "Foydalanuvchining joriy bozorlik (xarid) ro'yxati mahsulotlari.",
            "parameters": {"type": "object", "properties": {}}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_finance_summary",
            "description": "Joriy oy uchun moliya xulosasi: jami daromad, jami xarajat, balans va toifalar bo'yicha. 'bu oy qancha sarfladim', 'balansim' kabi so'rovlarда.",
            "parameters": {"type": "object", "properties": {}}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_account_info",
            "description": "Foydalanuvchi hisobi haqida: ism, hamyon balansi (so'm), premium holati. 'balansim qancha', 'premiumim bormi' kabi so'rovlarда.",
            "parameters": {"type": "object", "properties": {}}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_steps_today",
            "description": "Bugungi qadamlar soni va yoqilған kaloriya (fitnes). 'bugun necha qadam yurdim' kabi so'rovlarда.",
            "parameters": {"type": "object", "properties": {}}
        }
    },
    # ── BEKOR / O'CHIRISH / TAHRIRLASH — HAMISHA confirm bilan (2-qadamli) ──
    {
        "type": "function",
        "function": {
            "name": "cancel_order",
            "description": "Foydalanuvchining buyurtmasini (bronini) bekor qilish. FAQAT foydalanuvchi aniq tasdiqlaganда confirm=true bilan chaqiring. Avval confirm=false bilan chaqirib, foydalanuvchiдан tasdiq so'rang.",
            "parameters": {
                "type": "object",
                "properties": {
                    "order_id": {"type": "integer", "description": "Bekor qilinadigan buyurtma id'si (list_orders'дан)"},
                    "confirm": {"type": "boolean", "description": "Foydalanuvchi 'ha, bekor qil' deb aniq tasdiqlaganда true. Aks holda false."}
                },
                "required": ["order_id", "confirm"]
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "complete_plan",
            "description": "Rejani 'bajarildi' deb belgilash. confirm shart emas (zararsiz amal).",
            "parameters": {"type": "object", "properties": {
                "plan_id": {"type": "integer", "description": "Reja id'si (list_plans'дан)"}
            }, "required": ["plan_id"]}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "delete_plan",
            "description": "Rejani butunlay o'chirish. FAQAT foydalanuvchi tasdiqlaganда confirm=true.",
            "parameters": {"type": "object", "properties": {
                "plan_id": {"type": "integer", "description": "Reja id'si"},
                "confirm": {"type": "boolean", "description": "Tasdiqlanганда true"}
            }, "required": ["plan_id", "confirm"]}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "complete_todo",
            "description": "Vazifani (todo) bajarildi deb belgilash.",
            "parameters": {"type": "object", "properties": {
                "todo_id": {"type": "integer", "description": "Vazifa id'si (list_todos'дан)"}
            }, "required": ["todo_id"]}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "delete_todo",
            "description": "Vazifani o'chirish. FAQAT tasdiqlanганда confirm=true.",
            "parameters": {"type": "object", "properties": {
                "todo_id": {"type": "integer", "description": "Vazifa id'si"},
                "confirm": {"type": "boolean"}
            }, "required": ["todo_id", "confirm"]}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "toggle_alarm",
            "description": "Budilnikni yoqish yoki o'chirish (is_enabled). Bu zararsiz — confirm shart emas.",
            "parameters": {"type": "object", "properties": {
                "alarm_id": {"type": "integer", "description": "Budilnik id'si (list_alarms'дан)"},
                "enabled": {"type": "boolean", "description": "Yoqish uchun true, o'chirish uchun false"}
            }, "required": ["alarm_id", "enabled"]}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "delete_alarm",
            "description": "Budilnikni butunlay o'chirish. FAQAT tasdiqlanганда confirm=true.",
            "parameters": {"type": "object", "properties": {
                "alarm_id": {"type": "integer", "description": "Budilnik id'si"},
                "confirm": {"type": "boolean"}
            }, "required": ["alarm_id", "confirm"]}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "mark_shopping_bought",
            "description": "Bozorlik ro'yxatidagi mahsulotni 'sotib olindi' deb belgilash.",
            "parameters": {"type": "object", "properties": {
                "item_name": {"type": "string", "description": "Mahsulot nomi (list_shopping'дан)"}
            }, "required": ["item_name"]}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "delete_finance_record",
            "description": "Moliya yozuvini o'chirish. FAQAT tasdiqlanганда confirm=true.",
            "parameters": {"type": "object", "properties": {
                "record_id": {"type": "integer", "description": "Yozuv id'si"},
                "confirm": {"type": "boolean"}
            }, "required": ["record_id", "confirm"]}
        }
    },
    # ── NAVIGATSIYA — chatда ilova bo'limiga o'tish tugmasi ──
    {
        "type": "function",
        "function": {
            "name": "open_app_section",
            "description": "Javob ostiga ilova bo'limiga o'tish TUGMASI(lari)ni chiqaradi. Foydalanuvchi 'qayerдан ko'raman', 'ochib ber', 'qanday qo'shaman' desa yoki siz biror bo'limni tavsiya qilsangiz chaqiring. Bir nechta bo'lim bersangiz — bir nechta tugma chiqadi. DIQQAT: usta/xizmat tavsiya qilishда bu EMAS, search_providers ishlatiladi (u har usta uchun tugma chiqaradi).",
            "parameters": {
                "type": "object",
                "properties": {
                    "sections": {
                        "type": "array",
                        "items": {"type": "string", "enum": [
                            "plans", "todos", "finance", "shopping", "orders", "alarms",
                            "services", "calorie", "fitness", "calls", "profile", "premium"
                        ]},
                        "description": "Bo'limlar ro'yxati (ko'pi bilan 6 ta). Masalan ['finance'] yoki ['plans','alarms']."
                    }
                },
                "required": ["sections"]
            }
        }
    },
    # ── FOYDALI MA'LUMOTLAR (utility) — tashqi API'lar ──
    {
        "type": "function",
        "function": {
            "name": "get_weather",
            "description": "Ob-havo ma'lumoti (harorat, holat, shamol). 'ob-havo qanaqa', 'bugun sovuqmi' kabi so'rovlarда.",
            "parameters": {"type": "object", "properties": {
                "city": {"type": "string", "description": "Shahar nomi (default: Tashkent)"}
            }}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_currency",
            "description": "Valyuta kurslari (USD, EUR, RUB, GBP, KZT — CBU rasmiy). 'dollar kursi qancha' kabi so'rovlarда.",
            "parameters": {"type": "object", "properties": {}}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_prayer_times",
            "description": "Namoz vaqtlari. 'namoz vaqtlari', 'peshin qachon' kabi so'rovlarда.",
            "parameters": {"type": "object", "properties": {
                "city": {"type": "string", "description": "Shahar nomi (default: Tashkent)"}
            }}
        }
    },

    # ── ISH E'LONI (AI orqali) — TASDIQ MAJBURIY ────────────────────
    # Bron qilishdan FARQI: bronda mijoz aniq ustani tanlaydi. E'londa
    # esa mijoz muammosini aytadi, USTALAR o'zlari taklif beradi.
    # "kimdir kelib qilib bersa bo'ldi" holati uchun.
    {
        "type": "function",
        "function": {
            "name": "start_job_draft",
            "description": (
                "Ish E'LONI berishni boshlash. Foydalanuvchi muammosini "
                "aytganda ('kranim oqyapti', 'shu joyni tamirlash kerak', "
                "rasm yuborib 'buni tuzatish kerak') chaqiring. "
                "Aniq ustaga bron qilish EMAS — bu e'lon, ustalar o'zlari "
                "taklif beradi. Bilgan ma'lumotingizni darhol bering, "
                "qolganini tool aytadi."
            ),
            "parameters": {"type": "object", "properties": {
                "category": {"type": "string", "description": "Soha kaliti yoki nomi: electrician, plumber, cleaning, repair..."},
                "title": {"type": "string", "description": "Ish nomi, 3-200 belgi. Masalan: 'Rozetka almashtirish'"},
                "description": {"type": "string", "description": "Muammo tavsifi, kamida 5 belgi"},
                "address": {"type": "string", "description": "Manzil, kamida 3 belgi"},
                "budget": {"type": "number", "description": "Mijoz aytgan summa (so'm). Aytmasa bermang — 'narxni ustalar aytadi'"},
                "needed_at": {"type": "string", "description": "Qachon kerak, ISO sana. 'ertaga' desa hisoblab bering"},
                "photos": {"type": "array", "items": {"type": "string"}, "description": "Yuklangan rasm URL'lari"},
                "lang": {"type": "string", "description": "Foydalanuvchi tili: uz yoki ru"}
            }}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "update_job_draft",
            "description": (
                "E'lon qoralamasiga YANGI ma'lumot qo'shish. Tool "
                "'ask_user' savolini bergandan keyin foydalanuvchi javob "
                "bersa shuni chaqiring. Faqat YANGI maydonni yuboring — "
                "oldingilar saqlanadi."
            ),
            "parameters": {"type": "object", "properties": {
                "category": {"type": "string"},
                "title": {"type": "string"},
                "description": {"type": "string"},
                "address": {"type": "string"},
                "budget": {"type": "number"},
                "needed_at": {"type": "string"},
                "photos": {"type": "array", "items": {"type": "string"}},
                "lang": {"type": "string"}
            }}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "publish_job",
            "description": (
                "E'lonni CHOP ETISH. IKKI QADAMLI: avval confirm=false "
                "chaqiring — tool xulosa qaytaradi; xulosani "
                "foydalanuvchiga ko'rsatib «E'lon berilsinmi?» deb "
                "SO'RANG; u aniq 'ha' degandagina confirm=true bilan "
                "qayta chaqiring. Tasdiqsiz e'lon YARATILMAYDI."
            ),
            "parameters": {"type": "object", "properties": {
                "confirm": {"type": "boolean", "description": "Foydalanuvchi xulosani ko'rib aniq tasdiqlaganda true"},
                "lang": {"type": "string"}
            }}
        }
    },
    # ── BRON BOSHQARUVI (agentning "qo'li") ──────────────────────────
    {
        "type": "function",
        "function": {
            "name": "next_booking",
            "description": (
                "Foydalanuvchining ENG YAQIN kelayotgan broni. "
                "«Keyingi bronim qachon?», «Ertaga nima bor?», "
                "«Sartaroshga qachon boraman?» kabi savollarda ishlating."
            ),
            "parameters": {"type": "object", "properties": {}}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_booking_details",
            "description": (
                "Bitta bronning TO'LIQ ma'lumoti: usta, vaqt, manzil, "
                "narx, holat. Avval list_orders yoki next_booking bilan "
                "order_id ni toping."
            ),
            "parameters": {"type": "object", "properties": {
                "order_id": {"type": "integer", "description": "Buyurtma raqami"}
            }, "required": ["order_id"]}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "check_availability",
            "description": (
                "Ustaning ma'lum kundagi BO'SH vaqtlari. Bronni "
                "ko'chirishdan yoki yangi bron qilishdan OLDIN shuni "
                "chaqiring — aks holda band vaqtni taklif qilib qo'yasiz."
            ),
            "parameters": {"type": "object", "properties": {
                "provider_id": {"type": "integer", "description": "Usta ID si"},
                "date": {"type": "string", "description": "Kun, YYYY-MM-DD (bo'sh bo'lsa bugun)"}
            }, "required": ["provider_id"]}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "reschedule_booking",
            "description": (
                "Mavjud bron VAQTINI o'zgartirish (ko'chirish). "
                "IKKI QADAMLI: avval confirm=false — tool eski va yangi "
                "vaqtni qaytaradi; foydalanuvchiga ko'rsatib tasdiq "
                "so'rang; u 'ha' degandagina confirm=true bilan qayta "
                "chaqiring. Yangi vaqt band bo'lsa tool bo'sh vaqtlarni "
                "aytadi — o'shalardan tanlashni taklif qiling."
            ),
            "parameters": {"type": "object", "properties": {
                "order_id": {"type": "integer", "description": "Buyurtma raqami"},
                "new_date": {"type": "string", "description": "Yangi sana/vaqt, ISO 8601 (masalan '2026-08-20T15:00:00')"},
                "confirm": {"type": "boolean", "description": "Foydalanuvchi aniq tasdiqlaganda true"}
            }, "required": ["order_id", "new_date"]}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "update_booking",
            "description": (
                "Bron MANZILI yoki izohini o'zgartirish (vaqtdan "
                "tashqari). Vaqt uchun reschedule_booking ishlating. "
                "IKKI QADAMLI: confirm=false → tasdiq so'rang → confirm=true."
            ),
            "parameters": {"type": "object", "properties": {
                "order_id": {"type": "integer", "description": "Buyurtma raqami"},
                "address": {"type": "string", "description": "Yangi manzil"},
                "notes": {"type": "string", "description": "Ustaga izoh"},
                "confirm": {"type": "boolean", "description": "Tasdiqlanganda true"}
            }, "required": ["order_id"]}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_provider_info",
            "description": (
                "Usta/xizmat haqida ma'lumot: reyting, manzil, ish "
                "vaqtlari, xizmatlar. Foydalanuvchi «bu usta qanaqa?», "
                "«reytingi qancha?» deb so'raganda."
            ),
            "parameters": {"type": "object", "properties": {
                "provider_id": {"type": "integer", "description": "Usta ID si"}
            }, "required": ["provider_id"]}
        }
    },
    # ── SAVDO (marketplace): buyum sotish va sotib olish ──────────────
    {
        "type": "function",
        "function": {
            "name": "start_listing_draft",
            "description": (
                "BUYUM SOTISHNI boshlash. 'telefonimni sotmoqchiman', "
                "'mashinamni sotaman', 'divan sotiladi' kabi gaplarda "
                "chaqiring. Tool KERAKLI MAYDONLAR ro'yxatini qaytaradi "
                "— uni BITTA xabarda ko'rsating. Bu ish e'loni EMAS "
                "(usta qidirilmayapti), balki buyum savdosi."
            ),
            "parameters": {"type": "object", "properties": {
                "category": {"type": "string", "description": "Toifa: telefon, kompyuter, elektronika, maishiy, avto, qurilish, kiyim, hayvon, mebel, boshqa"},
                "title": {"type": "string", "description": "Buyum nomi, masalan 'iPhone 13 Pro 256GB'"},
                "description": {"type": "string"},
                "price": {"type": "number", "description": "Narx. 'kelishamiz' bo'lsa bermang, is_negotiable=true qiling"},
                "currency": {"type": "string", "description": "UZS yoki USD"},
                "is_negotiable": {"type": "boolean", "description": "Narx kelishiladi"},
                "condition": {"type": "string", "description": "yangi / ideal / yaxshi / ishlatilgan / ehtiyot qismga"},
                "address": {"type": "string"},
                "attributes": {"type": "object", "description": "Toifaga xos maydonlar: {'model': 'iPhone 13', 'xotira': '256GB'}"},
                "photos": {"type": "array", "items": {"type": "string"}},
                "lang": {"type": "string"}
            }}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "update_listing_draft",
            "description": (
                "Sotuv qoralamasiga YANGI ma'lumot qo'shish. Foydalanuvchi "
                "so'ralgan maydonlarni yozgach chaqiring. Faqat yangisini "
                "yuboring — oldingilar saqlanadi. Tool qolgan "
                "yetishmaganlarni aytadi."
            ),
            "parameters": {"type": "object", "properties": {
                "category": {"type": "string"},
                "title": {"type": "string"},
                "description": {"type": "string"},
                "price": {"type": "number"},
                "currency": {"type": "string"},
                "is_negotiable": {"type": "boolean"},
                "condition": {"type": "string"},
                "address": {"type": "string"},
                "attributes": {"type": "object"},
                "photos": {"type": "array", "items": {"type": "string"}},
                "lang": {"type": "string"}
            }}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "add_listing_photos",
            "description": (
                "E'longa rasm qo'shish. Foydalanuvchi rasm yuborganda "
                "URL'larini shu tool'ga bering. Kamida 3 ta rasm kerak — "
                "tool yana nechta kerakligini aytadi."
            ),
            "parameters": {"type": "object", "properties": {
                "photos": {"type": "array", "items": {"type": "string"}, "description": "Yuklangan rasm URL'lari"},
                "lang": {"type": "string"}
            }, "required": ["photos"]}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "publish_listing",
            "description": (
                "E'lonni CHOP ETISH. IKKI QADAMLI: avval confirm=false — "
                "tool xulosa qaytaradi; xulosani ko'rsatib «E'lon "
                "berilsinmi?» deb SO'RANG; foydalanuvchi 'ha' degandagina "
                "confirm=true bilan qayta chaqiring."
            ),
            "parameters": {"type": "object", "properties": {
                "confirm": {"type": "boolean"},
                "lang": {"type": "string"}
            }}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "search_listings",
            "description": (
                "Sotuvdagi buyumlarni qidirish. 'telefon olmoqchiman', "
                "'arzon divan bormi', 'mashina qidiryapman' kabi gaplarda. "
                "Avval model/narx/holat kabi shartlarni SO'RANG, keyin "
                "qidiring. Natija chatда KARTALAR bo'lib ko'rinadi — "
                "siz faqat nechta topilganini qisqa ayting."
            ),
            "parameters": {"type": "object", "properties": {
                "query": {"type": "string", "description": "Matn bo'yicha qidiruv, masalan 'iPhone 13'"},
                "category": {"type": "string", "description": "Toifa kaliti"},
                "price_min": {"type": "number", "description": "Eng kam narx (SO'MDA)"},
                "price_max": {"type": "number", "description": "Eng ko'p narx (SO'MDA)"},
                "condition": {"type": "string", "description": "new / like_new / good / used / parts"},
                "sort": {"type": "string", "description": "relevant (standart), price_asc, price_desc, new"},
                "lang": {"type": "string"}
            }}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "get_listing",
            "description": (
                "Bitta e'lonning to'liq ma'lumoti. Foydalanuvchi "
                "«birinchisi haqida batafsil ayt» desa chaqiring. "
                "Sotuvchi telefon raqami YO'Q va so'ralmaydi ham — "
                "aloqa faqat ilova ichida."
            ),
            "parameters": {"type": "object", "properties": {
                "listing_id": {"type": "integer"},
                "lang": {"type": "string"}
            }, "required": ["listing_id"]}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "my_listings",
            "description": (
                "Foydalanuvchining O'Z e'lonlari: holati, ko'rilgan soni, "
                "muddati. «E'lonlarim qalay?», «nechta e'lonim bor?» "
                "savollarida."
            ),
            "parameters": {"type": "object", "properties": {
                "lang": {"type": "string"}
            }}
        }
    },
    {
        "type": "function",
        "function": {
            "name": "close_listing",
            "description": (
                "E'lonni «sotildi» deb belgilash yoki yashirish. "
                "IKKI QADAMLI: confirm=false → tasdiq so'rang → "
                "confirm=true. listing_id ni bilmasangiz avval "
                "my_listings chaqiring."
            ),
            "parameters": {"type": "object", "properties": {
                "listing_id": {"type": "integer"},
                "sold": {"type": "boolean", "description": "true — sotildi, false — yashirish"},
                "confirm": {"type": "boolean"},
                "lang": {"type": "string"}
            }, "required": ["listing_id"]}
        }
    }
]
