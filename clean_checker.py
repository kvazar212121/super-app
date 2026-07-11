import os
import re

def parse_dart_strings(content):
    # Match strings:
    # 1. '''...''' or """..."""
    # 2. '...' (handling escaped \')
    # 3. "..." (handling escaped \")
    strings = []
    # We will find string literals and their start/end positions, also return the raw value
    # Let's use a state machine or a regex.
    # A robust regex for single line strings with escapes:
    # Single quoted: ' ( [^'\\] | \\. )* '
    # Double quoted: " ( [^"\\] | \\. )* "
    pattern = re.compile(r"'(?:[^'\\]|\\.)*'|\"(?:[^\"]|\\.)*\"")
    
    for match in pattern.finditer(content):
        raw = match.group(0)
        # Strip quotes and unescape
        val = raw[1:-1]
        # Unescape common sequences
        val = val.replace("\\'", "'").replace('\\"', '"').replace('\\n', '\n').replace('\\t', '\t').replace('\\\\', '\\')
        strings.append((val, match.start(), match.end()))
    return strings

# Load translations
translations_path = 'lib/l10n/translations.dart'
translation_keys = set()
with open(translations_path, 'r', encoding='utf-8') as f:
    content = f.read()
    # Find the Map inside kTranslationsRu
    map_match = re.search(r"const Map<String, String> kTranslationsRu = \{(.*?)\};", content, re.DOTALL)
    if map_match:
        map_content = map_match.group(1)
        # Parse the map entries
        # Format is typically: key : value,
        # We can find all string literals in map_content. Every odd literal is key, even is value.
        all_strs = [s[0] for s in parse_dart_strings(map_content)]
        for i in range(0, len(all_strs), 2):
            if i + 1 < len(all_strs):
                translation_keys.add(all_strs[i])

print(f"Loaded {len(translation_keys)} keys from translations.dart")

# Let's also extract Category titles and variants from service_hub_kind.dart
kind_path = 'lib/models/service_hub_kind.dart'
kind_strings = set()
if os.path.exists(kind_path):
    with open(kind_path, 'r', encoding='utf-8') as f:
        kind_content = f.read()
        for val, _, _ in parse_dart_strings(kind_content):
            # We want to check if it's a category title or variant label
            # If it's a variant label (from label: '...') or Category title/subtitle
            # Let's just collect all user-facing-looking strings from service_hub_kind.dart
            # To be precise, let's filter:
            if not val.strip():
                continue
            if '/' in val or val.startswith('package:') or val.startswith('dart:'):
                continue
            # Filter out known keys
            if val in ['game_zona', 'sport_maydon', 'kompyuter_usta', 'boshqa_xizmatlar']:
                continue
            # If it has Uzbek/Russian letters
            if any(c.isalpha() for c in val):
                kind_strings.add(val)

print(f"Extracted {len(kind_strings)} strings from service_hub_kind.dart")

missing_kind_translations = []
for ks in kind_strings:
    if ks not in translation_keys:
        missing_kind_translations.append(ks)

print(f"\nActual missing category/variant translations ({len(missing_kind_translations)}):")
for m in sorted(missing_kind_translations):
    print(f"  - {m}")

# Now scan all Dart files for strings that have .tr but are missing from translations.dart
missing_keys_in_files = {}
missing_tr_in_files = {}

def is_user_facing(s):
    if not s:
        return False
    if '/' in s or '.' in s or '_' in s or s.startswith('package:') or s.startswith('dart:'):
        return False
    if s.lower() in ['uz', 'ru', 'id', 'name', 'key', 'value', 'type', 'status', 'pending', 'active', 'inactive', 'true', 'false', 'null']:
        return False
    if not any(c.isalpha() for c in s):
        return False
    if len(s.strip()) < 2:
        return False
    return True

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart') and file != 'translations.dart':
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                file_content = f.read()
                
                parsed = parse_dart_strings(file_content)
                for val, start, end in parsed:
                    # Check if followed by .tr
                    rest = file_content[end:end+10]
                    has_tr = rest.strip().startswith('.tr')
                    
                    if is_user_facing(val):
                        line_num = file_content[:start].count('\n') + 1
                        if has_tr:
                            if val not in translation_keys:
                                if path not in missing_keys_in_files:
                                    missing_keys_in_files[path] = []
                                missing_keys_in_files[path].append((val, line_num))
                        else:
                            # Check if it needs .tr (human readable)
                            # To avoid false positives on config keys, let's be careful
                            if path not in missing_tr_in_files:
                                missing_tr_in_files[path] = []
                            missing_tr_in_files[path].append((val, line_num))

# Print clean report
print(f"\nFiles with actual .tr but missing key in translations.dart: {len(missing_keys_in_files)}")
for path, items in sorted(missing_keys_in_files.items()):
    print(f"\n{path}:")
    seen = set()
    for val, line in items:
        if val not in seen:
            print(f"  Line {line}: '{val}'")
            seen.add(val)
            
# Let's save a clean report
with open('clean_translation_report.md', 'w', encoding='utf-8') as f:
    f.write("# Clean Translation Report\n\n")
    f.write("## Missing Category/Variant/Subtitle keys in translations.dart\n")
    for m in sorted(missing_kind_translations):
        f.write(f"- `{m}`\n")
        
    f.write("\n## Actual .tr keys missing in translations.dart\n")
    for path, items in sorted(missing_keys_in_files.items()):
        f.write(f"### {path}\n")
        seen = set()
        for val, line in items:
            if val not in seen:
                f.write(f"- Line {line}: `{val}`\n")
                seen.add(val)
                
    f.write("\n## Missing .tr suffix in UI files (potential)\n")
    for path, items in sorted(missing_tr_in_files.items()):
        f.write(f"### {path}\n")
        seen = set()
        for val, line in items:
            if val not in seen:
                f.write(f"- Line {line}: `{val}`\n")
                seen.add(val)
