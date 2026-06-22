import re

path = "/home/devops/super-app/lib/config/provider_category_config.dart"

with open(path, "r") as f:
    content = f.read()

updates = {
    'salon': "['Soch turmagi', 'Makiyaj', 'Manikyur', 'Kosmetologiya']",
    'plumber': "['Quvurlar', 'Kran va vanna', 'Issiqlik tizimi', 'Shoshilinch']",
    'electrician': "['Montaj', 'Rozetka va chiroq', 'Diagnostika', 'Shoshilinch']",
    'cleaner': "['Uy tozalash', 'Ofis tozalash', 'Gilam yuvish', 'Deraza yuvish']",
    'auto': "['Evakuator', 'Shina montaj', 'Diagnostika', 'Mator ustasi', 'Xodovoy']",
    'futbol': "['Yopiq maydon', 'Ochiq maydon', 'Mini futbol']",
    'education': "['Maktab fanlari', 'Tillar', 'IT', 'Musiqa']",
    'worker': "['Yuk tashuvchi', 'Qurilish yordamchisi', 'Bog\\'bon', 'Qorovul']",
    'ac': "['O\\'rnatish', 'Ta\\'mirlash', 'Tozalash', 'Freon quyish']",
    'nanny': "['Kunduzgi', 'Tungi', 'Soatbay', 'Chaqaloqlar uchun']",
    'tutor': "['Maktab fanlari', 'Tillar', 'IT', 'Musiqa']",
    'disinfection': "['Hasharotlar', 'Kemeruvchilar', 'Viruslar']",
    'appliance': "['Katta texnika', 'Mayda texnika', 'Oshxona texnikasi']",
    'courier': "['Hujjatlar', 'Yuk', 'Piyoda kuryer', 'Avto kuryer']",
    'nurse': "['Ukol', 'Kapelnitsa', 'Qariyalar parvarishi']",
    'dental': "['Terapiya', 'Jarrohlik', 'Ortodontiya', 'Bolalar stomatologi']",
    'events': "['To\\'y', 'Tug\\'ilgan kun', 'Korporativ', 'Fotosessiya']",
    'kompUsta': "['Dasturiy ta\\'minot', 'Qurilma ta\\'miri', 'Tarmoq', 'Noutbuk ta\\'miri']"
}

for key, subcats in updates.items():
    # Find the block starting with `static const key = ProviderCategoryConfig(`
    pattern = r'(static const ' + key + r' = ProviderCategoryConfig\([\s\S]*?\n\s+accentColor:[^\n]+)(?=\n\s+\);)'
    
    # If it already has subCategories, we don't need to add it (or we replace it)
    def replacer(m):
        block = m.group(1)
        if "subCategories" not in block:
            return block + ",\n    subCategories: " + subcats
        return block

    content = re.sub(pattern, replacer, content)

with open(path, "w") as f:
    f.write(content)

print("Updated config")
