"""
Exercises dataset enum qiymatlarining o'zbekcha (lotin) tarjimalari.

Qiymatlar oz va sifat muhim bo'lgani uchun qo'lda yozilgan
(AI batch tarjimaga ishonilmagan).
"""

BODY_PART_UZ = {
    "back": "Orqa",
    "cardio": "Kardio",
    "chest": "Ko'krak",
    "lower arms": "Bilaklar",
    "lower legs": "Boldirlar",
    "neck": "Bo'yin",
    "shoulders": "Yelkalar",
    "upper arms": "Qo'llar (biseps/triseps)",
    "upper legs": "Sonlar",
    "waist": "Bel va press",
}

# category qiymatlari body_part bilan bir xil to'plam
CATEGORY_UZ = dict(BODY_PART_UZ)

EQUIPMENT_UZ = {
    "assisted": "Yordam bilan",
    "band": "Rezina lenta",
    "barbell": "Shtanga",
    "body weight": "O'z vazni bilan",
    "bosu ball": "Bosu to'pi",
    "cable": "Trosli trenajyor",
    "dumbbell": "Gantel",
    "elliptical machine": "Ellips trenajyori",
    "ez barbell": "EZ shtanga",
    "hammer": "Hammer trenajyori",
    "kettlebell": "Girya",
    "leverage machine": "Richagli trenajyor",
    "medicine ball": "Meditsinbol",
    "olympic barbell": "Olimpiya shtangasi",
    "resistance band": "Qarshilik lentasi",
    "roller": "Rolik",
    "rope": "Arqon",
    "skierg machine": "SkiErg trenajyori",
    "sled machine": "Sled trenajyori",
    "smith machine": "Smit trenajyori",
    "stability ball": "Fitbol",
    "stationary bike": "Velotrenajyor",
    "stepmill machine": "Step trenajyori",
    "tire": "Shina",
    "trap bar": "Trap shtanga",
    "upper body ergometer": "Qo'l ergometri",
    "weighted": "Og'irlik bilan",
    "wheel roller": "G'ildirakli rolik",
}

TARGET_UZ = {
    "abductors": "Son tashqi mushaklari",
    "abs": "Press",
    "adductors": "Son ichki mushaklari",
    "biceps": "Biseps",
    "calves": "Boldir mushaklari",
    "cardiovascular system": "Yurak-qon tomir tizimi",
    "delts": "Yelka (delta) mushaklari",
    "forearms": "Bilak mushaklari",
    "glutes": "Dumba mushaklari",
    "hamstrings": "Son orqa mushaklari",
    "lats": "Keng orqa mushaklari",
    "levator scapulae": "Kurak ko'taruvchi mushak",
    "pectorals": "Ko'krak mushaklari",
    "quads": "Kvadriseps (son oldi)",
    "serratus anterior": "Oldingi tishsimon mushak",
    "spine": "Umurtqa mushaklari",
    "traps": "Trapetsiya",
    "triceps": "Triseps",
    "upper back": "Yuqori orqa",
}
