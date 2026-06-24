import 'dart:convert';
import 'dart:io';
import 'lib/models/massage_hijoma.dart';

void main() async {
  final file = File('test_json.json');
  final String jsonStr = await file.readAsString();
  final Map<String, dynamic> data = json.decode(jsonStr);
  final items = data['items'] as List;

  for (var item in items) {
    try {
      final mh = MassageHijoma.fromProviderJson(item);
      print('Parsed: ${mh.name}');
    } catch (e, stack) {
      print('Error parsing item: $e\n$stack');
    }
  }
}
