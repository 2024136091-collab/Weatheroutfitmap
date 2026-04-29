import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteItem {
  final String city;
  final String displayName;

  const FavoriteItem({required this.city, required this.displayName});

  Map<String, dynamic> toJson() => {'city': city, 'displayName': displayName};
  factory FavoriteItem.fromJson(Map<String, dynamic> j) =>
      FavoriteItem(city: j['city'] as String, displayName: j['displayName'] as String);
}

class StorageProvider extends ChangeNotifier {
  List<String> history = [];
  List<FavoriteItem> favorites = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    history = prefs.getStringList('history') ?? [];
    final favJson = prefs.getStringList('favorites') ?? [];
    favorites = favJson
        .map((s) => FavoriteItem.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    notifyListeners();
  }

  Future<void> saveHistory(String city) async {
    history.remove(city);
    history.insert(0, city);
    if (history.length > 10) history = history.sublist(0, 10);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('history', history);
    notifyListeners();
  }

  Future<void> deleteHistoryOne(String city) async {
    history.remove(city);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('history', history);
    notifyListeners();
  }

  Future<void> clearHistory() async {
    history = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('history', history);
    notifyListeners();
  }

  bool isFavorite(String city) => favorites.any((f) => f.city == city);

  Future<void> toggleFavorite(String city, String displayName) async {
    if (isFavorite(city)) {
      favorites.removeWhere((f) => f.city == city);
    } else {
      favorites.add(FavoriteItem(city: city, displayName: displayName));
    }
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> deleteFavorite(String city) async {
    favorites.removeWhere((f) => f.city == city);
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> clearFavorites() async {
    favorites = [];
    await _saveFavorites();
    notifyListeners();
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'favorites',
      favorites.map((f) => jsonEncode(f.toJson())).toList(),
    );
  }
}