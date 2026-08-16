import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Simlash (wiring) tekshiruvi — statik tahlil.
///
/// Yangi dizayn ekrani `_catalogEntries` dagi `data.X` maydonlaridan o'qiydi,
/// `HubDataService.loadFor` esa `d.X` maydonlarini to'ldiradi. Agar ular mos
/// kelmasa ekran DOIM BO'SH chiqadi — kompilyatsiya xatosi bermaydi va oddiy
/// widget testda ham sezilmaydi (chunki test ma'lumotni o'zi beradi).
///
/// Shuning uchun bu moslikni manba kodidan tekshiramiz.
void main() {
  late Map<String, Set<String>> filled; // loadFor to'ldiradigan maydonlar
  late Map<String, Set<String>> read; // _catalogEntries o'qiydigan maydonlar
  late List<String> newDesignKinds;

  setUpAll(() {
    final svc =
        File('lib/services/hub_data_service.dart').readAsStringSync();
    final act = File('lib/screens/service_hub/service_hub_action_list.dart')
        .readAsStringSync();
    final scr = File('lib/screens/service_hub_screen.dart').readAsStringSync();

    // ── loadFor: har kind uchun to'ldiriladigan maydonlar ──
    final svcBlock = svc.substring(
      svc.indexOf('case ServiceHubKind.sartarosh:'),
      svc.indexOf('    }\n    return d;'),
    );
    filled = _parseCases(
      svcBlock,
      RegExp(r'\bd\.(\w+)\s*='),
      fallThroughShares: true,
    );

    // Dart'da `default:` — yuqorida sanalmagan BARCHA kindlar uchun.
    final defaultIdx = svcBlock.indexOf('default:');
    final defaultFields = defaultIdx == -1
        ? <String>{}
        : RegExp(r'\bd\.(\w+)\s*=')
            .allMatches(svcBlock.substring(defaultIdx))
            .map((m) => m.group(1)!)
            .toSet();

    // ── _catalogEntries: har kind uchun o'qiladigan maydonlar ──
    final actBlock = act.substring(
      act.indexOf('List<CatalogEntry> _catalogEntries(BuildContext context) {'),
      act.indexOf('/// Turli xil'),
    );
    read = _parseCases(actBlock, RegExp(r'\bdata\.(\w+)'));

    // ── Yangi dizayn yoqilgan kindlar ──
    final start = scr.indexOf('kNewHubDesignKinds = {');
    final block = scr.substring(start, scr.indexOf('};', start));
    newDesignKinds = RegExp(r'ServiceHubKind\.(\w+)')
        .allMatches(block)
        .map((m) => m.group(1)!)
        .toList();

    // default'ga tushadigan kindlarga default maydonlarini beramiz.
    for (final k in newDesignKinds) {
      filled.putIfAbsent(k, () => defaultFields);
    }
  });

  test('Yangi dizayndagi har xizmat _catalogEntries da case ga ega', () {
    final missing =
        newDesignKinds.where((k) => !read.containsKey(k)).toList();
    expect(missing, isEmpty,
        reason: 'bu xizmatlarda katalog yo\'q — ekran bo\'sh chiqadi: $missing');
  });

  test('Har xizmat O\'QIYDIGAN maydon TO\'LDIRILADIGAN maydon bilan mos', () {
    final broken = <String>[];
    for (final kind in newDesignKinds) {
      final r = read[kind] ?? <String>{};
      final f = filled[kind] ?? <String>{};
      if (r.isEmpty) continue;
      // Kamida bitta o'qiladigan maydon to'ldirilishi shart.
      if (r.intersection(f).isEmpty) {
        broken.add('$kind: o\'qiydi=$r, to\'ldiriladi=$f');
      }
    }
    expect(broken, isEmpty,
        reason: 'quyidagi xizmatlarda ro\'yxat DOIM BO\'SH bo\'ladi:\n'
            '${broken.join('\n')}');
  });

  test('kNewHubDesignKinds da takror yo\'q', () {
    expect(newDesignKinds.length, newDesignKinds.toSet().length);
  });
}

/// `case ServiceHubKind.x:` bloklarini ajratib, har biridagi mos keluvchi
/// maydon nomlarini yig'adi.
///
/// Dart'da bo'sh case keyingi to'liq case tanasiga tushadi
/// (`case a: case b: TANA` — a ham, b ham TANA ni bajaradi).
/// [fallThroughShares] shu qoidani hisobga oladi.
///
/// MUHIM: case tanasi keyingi `case` YOKI `default:` gacha davom etadi —
/// `default:` ni hisobga olmaslik tanani noto'g'ri uzaytirib yuboradi.
Map<String, Set<String>> _parseCases(
  String source,
  RegExp fieldPattern, {
  bool fallThroughShares = false,
}) {
  final result = <String, Set<String>>{};
  final caseRe = RegExp(r'case ServiceHubKind\.(\w+):');
  final matches = caseRe.allMatches(source).toList();
  final defaultIdx = source.indexOf(RegExp(r'^\s*default:', multiLine: true));
  final pending = <String>[];

  for (var i = 0; i < matches.length; i++) {
    final kind = matches[i].group(1)!;
    final from = matches[i].end;
    var to = i + 1 < matches.length ? matches[i + 1].start : source.length;
    // Tana `default:` dan oshib ketmasin.
    if (defaultIdx > from && defaultIdx < to) to = defaultIdx;
    final body = source.substring(from, to);
    final fields =
        fieldPattern.allMatches(body).map((m) => m.group(1)!).toSet();

    if (fields.isEmpty && fallThroughShares) {
      pending.add(kind); // keyingi to'liq case tanasini baham ko'radi
      continue;
    }
    for (final p in pending) {
      result[p] = fields;
    }
    pending.clear();
    result[kind] = fields;
  }
  // Oxirida tanasiz qolgan case'lar (masalan default'ga tushadiganlar).
  for (final p in pending) {
    result[p] = <String>{};
  }
  return result;
}
