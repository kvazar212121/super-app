"""AI javobini mobil ilova uchun tozalash.

Ilova markdown'ni RENDER QILMAYDI — `**qalin**` yoki `| jadval |` xuddi
yozilganidek ko'rinadi va tor ekranda buziladi. Promptда taqiqlagan bo'lsak-da,
model ba'zan (ayniqsa uzun suhbatда) baribir markdown ishlatadi. Shuning uchun
javobni serverда kafolatli tozalaymiz.
"""
import re

# | a | b | c |  ko'rinishidagi jadval qatori
_TABLE_ROW = re.compile(r"^\s*\|(.+)\|\s*$")
# |---|:---:|---| ko'rinishidagi ajratgich qatori
_TABLE_SEP = re.compile(r"^\s*\|[\s:\-|]+\|\s*$")


def _table_row_to_text(line: str) -> str | None:
    """Jadval qatorini " · " bilan ajratilgan oddiy matnga aylantiradi."""
    m = _TABLE_ROW.match(line)
    if not m:
        return None
    cells = [c.strip() for c in m.group(1).split("|")]
    cells = [c for c in cells if c and c not in {"-", "—"}]
    return " · ".join(cells) if cells else ""


def clean_for_mobile(text: str) -> str:
    """Markdown belgilarini olib tashlaydi va jadvallarni tik matnga aylantiradi."""
    if not text:
        return text

    out_lines: list[str] = []
    for line in text.split("\n"):
        if _TABLE_SEP.match(line):
            continue  # |---|---| ajratgichi — butunlay tashlanadi
        converted = _table_row_to_text(line)
        out_lines.append(converted if converted is not None else line)
    text = "\n".join(out_lines)

    # Qalin/kursiv/kod belgilari (matnning o'zi qoladi)
    text = re.sub(r"\*\*(.+?)\*\*", r"\1", text, flags=re.DOTALL)
    text = re.sub(r"__(.+?)__", r"\1", text, flags=re.DOTALL)
    text = re.sub(r"`{1,3}([^`]*)`{1,3}", r"\1", text, flags=re.DOTALL)
    # Qolgan yolg'iz belgilar
    text = text.replace("**", "").replace("__", "")
    # Sarlavha (# ...) va sitata (> ...) belgilari qator boshida
    text = re.sub(r"^\s{0,3}#{1,6}\s*", "", text, flags=re.MULTILINE)
    text = re.sub(r"^\s{0,3}>\s?", "", text, flags=re.MULTILINE)
    # Markdown ajratgich chizig'i (--- yoki ***)
    text = re.sub(r"^\s*([-*_])\1{2,}\s*$", "", text, flags=re.MULTILINE)
    # Ketma-ket bo'sh qatorlarni ikkitagacha qisqartiramiz
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()
