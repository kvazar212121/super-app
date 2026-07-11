import os
import re

# Load translations
translations_path = 'lib/l10n/translations.dart'
translation_keys = set()
with open(translations_path, 'r', encoding='utf-8') as f:
    content = f.read()
    # Simple regex to extract keys: 'key': 'value' or "key": "value"
    # Matches: 'key': or "key":
    matches = re.findall(r"(?:'([^']+)'|\"([^\"]+)\")\s*:\s*(?:'|\")", content)
    for m in matches:
        key = m[0] if m[0] else m[1]
        translation_keys.add(key)

print(f"Loaded {len(translation_keys)} keys from translations.dart")

# Let's also extract Category titles, subtitles, and variants from service_hub_kind.dart
kind_path = 'lib/models/service_hub_kind.dart'
kind_strings = set()
if os.path.exists(kind_path):
    with open(kind_path, 'r', encoding='utf-8') as f:
        kind_content = f.read()
        # Find titles
        titles = re.findall(r"ServiceHubKind\.\w+\s*=>\s*'([^']+)'", kind_content)
        # Find subtitles
        subtitles = re.findall(r"ServiceHubKind\.\w+\s*=>\s*'([^']+)'", kind_content)
        # Find variant labels
        variants = re.findall(r"label:\s*'([^']+)'", kind_content)
        kind_strings.update(titles)
        kind_strings.update(subtitles)
        kind_strings.update(variants)

print(f"Extracted {len(kind_strings)} strings from service_hub_kind.dart")

# Let's check which kind strings are missing in translations.dart
missing_kind_translations = []
for ks in kind_strings:
    if ks not in translation_keys:
        missing_kind_translations.append(ks)

if missing_kind_translations:
    print(f"\nMissing category/variant translations in translations.dart ({len(missing_kind_translations)}):")
    for m in sorted(missing_kind_translations):
        print(f"  - {m}")
else:
    print("\nAll category/variant strings from service_hub_kind.dart are in translations.dart!")

# Now let's scan all Dart files in lib/ for hardcoded strings that might need translation (.tr)
uzbek_chars = re.compile(r"[a-zA-Z'`‘’“”ʻ\s]+", re.IGNORECASE)
# Check for letters specific to Uzbek / Cyrillic or words
cyrillic_chars = re.compile(r"[\u0400-\u04FF]")

def is_user_facing(s):
    if not s:
        return False
    # Filter out paths, assets, keys, etc.
    if '/' in s or '.' in s or '_' in s or s.startswith('package:') or s.startswith('dart:'):
        return False
    if s.lower() in ['uz', 'ru', 'id', 'name', 'key', 'value', 'type', 'status', 'pending', 'active', 'inactive', 'true', 'false', 'null']:
        return False
    # Check if it has letters
    has_letters = any(c.isalpha() for c in s)
    if not has_letters:
        return False
    # Check length
    if len(s.strip()) < 2:
        return False
    return True

missing_tr_in_files = {}
missing_keys_in_files = {}

for root, _, files in os.walk('lib'):
    # Skip translations.dart itself
    for file in files:
        if file.endswith('.dart') and file != 'translations.dart':
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                file_content = f.read()
                
                # Let's find all string literals using regex
                # Single quotes: '...'
                # Double quotes: "..."
                # We want to check if they are followed by .tr
                
                # A regex that finds 'something' and checks if it has .tr after it
                # We can find all single-quoted and double-quoted strings
                # For each match, we check its index and whether the next non-whitespace characters are `.tr`
                
                # Let's do it using a simpler regex approach:
                # Find all '...'
                single_matches = re.finditer(r"'([^']+)'", file_content)
                for m in single_matches:
                    start, end = m.span()
                    literal = m.group(1)
                    # Check if followed by .tr
                    rest = file_content[end:end+10]
                    has_tr = rest.strip().startswith('.tr')
                    
                    if is_user_facing(literal):
                        if not has_tr:
                            if path not in missing_tr_in_files:
                                missing_tr_in_files[path] = []
                            missing_tr_in_files[path].append((literal, file_content[:start].count('\n') + 1))
                        else:
                            # It has .tr, let's check if it's in translation_keys
                            if literal not in translation_keys:
                                if path not in missing_keys_in_files:
                                    missing_keys_in_files[path] = []
                                missing_keys_in_files[path].append((literal, file_content[:start].count('\n') + 1))
                                
                # Double quotes: "..."
                double_matches = re.finditer(r'"([^"]+)"', file_content)
                for m in double_matches:
                    start, end = m.span()
                    literal = m.group(1)
                    # Check if followed by .tr
                    rest = file_content[end:end+10]
                    has_tr = rest.strip().startswith('.tr')
                    
                    if is_user_facing(literal):
                        if not has_tr:
                            if path not in missing_tr_in_files:
                                missing_tr_in_files[path] = []
                            missing_tr_in_files[path].append((literal, file_content[:start].count('\n') + 1))
                        else:
                            # It has .tr, let's check if it's in translation_keys
                            if literal not in translation_keys:
                                if path not in missing_keys_in_files:
                                    missing_keys_in_files[path] = []
                                missing_keys_in_files[path].append((literal, file_content[:start].count('\n') + 1))

print(f"\nScanning finished.")
print(f"Files with missing .tr suffix on user-facing strings: {len(missing_tr_in_files)}")
print(f"Files with .tr suffix but missing key in translations.dart: {len(missing_keys_in_files)}")

# Let's write the report to an artifact
report_content = "# Translation Analysis Report\n\n"

report_content += "## Missing Category/Variant Translations in `translations.dart`\n"
if missing_kind_translations:
    for m in sorted(missing_kind_translations):
        report_content += f"- `{m}`\n"
else:
    report_content += "None!\n"

report_content += "\n## Strings with `.tr` but missing in `translations.dart`\n"
if missing_keys_in_files:
    for path, items in sorted(missing_keys_in_files.items()):
        report_content += f"### {path}\n"
        for lit, line in items:
            report_content += f"- Line {line}: `{lit}`\n"
else:
    report_content += "None!\n"

report_content += "\n## Human-facing Strings missing `.tr` suffix\n"
if missing_tr_in_files:
    for path, items in sorted(missing_tr_in_files.items()):
        report_content += f"### {path}\n"
        # deduplicate
        seen = set()
        for lit, line in items:
            if lit not in seen:
                report_content += f"- Line {line}: `{lit}`\n"
                seen.add(lit)
else:
    report_content += "None!\n"

with open('translation_analysis_report.md', 'w', encoding='utf-8') as f:
    f.write(report_content)

print("Saved report to translation_analysis_report.md")
