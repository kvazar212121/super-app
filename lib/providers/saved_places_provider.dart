import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_place_model.dart';

class SavedPlacesProvider extends ChangeNotifier {
  final List<SavedPlace> _savedPlaces = [];

  List<SavedPlace> get savedPlaces => List.unmodifiable(_savedPlaces);

  Future<void> loadSavedPlaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('saved_places_list');
      if (list != null) {
        _savedPlaces.clear();
        for (final item in list) {
          try {
            _savedPlaces.add(SavedPlace.fromJson(jsonDecode(item)));
          } catch (e) {
            debugPrint('Error decoding saved place: $e');
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved places: $e');
    }
  }

  bool isSaved(String id) {
    return _savedPlaces.any((p) => p.id == id);
  }

  Future<void> toggleSave(SavedPlace item) async {
    final index = _savedPlaces.indexWhere((p) => p.id == item.id);
    if (index != -1) {
      _savedPlaces.removeAt(index);
    } else {
      _savedPlaces.add(item);
    }
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _savedPlaces.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList('saved_places_list', list);
    } catch (e) {
      debugPrint('Error saving saved places: $e');
    }
  }

  List<SavedPlace> getSavedPlacesForCategory(String categoryKey) {
    return _savedPlaces.where((p) => p.categoryKey == categoryKey).toList();
  }
}
