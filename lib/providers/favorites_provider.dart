import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FavoritesProvider with ChangeNotifier {
  List<Map<String, dynamic>> _favoriteItems = [];

  List<Map<String, dynamic>> get favoriteItems => _favoriteItems;

  bool isFavorite(String productId) {
    return _favoriteItems.any((item) => item['id'] == productId);
  }

  void toggleFavorite(Map<String, dynamic> product) {
    final isExist = _favoriteItems.any((item) => item['id'] == product['id']);

    if (isExist) {
      _favoriteItems.removeWhere((item) => item['id'] == product['id']);
    } else {
      _favoriteItems.add(product);
    }

    _saveFavoritesToPrefs();
    notifyListeners();
  }

  void removeFavorite(String productId) {
    _favoriteItems.removeWhere((item) => item['id'] == productId);
    _saveFavoritesToPrefs();
    notifyListeners();
  }

  // Load favorites from SharedPreferences
  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString('favorites');

      if (favoritesJson != null) {
        final List<dynamic> decodedData = json.decode(favoritesJson);
        _favoriteItems =
            decodedData.map((item) => Map<String, dynamic>.from(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  // Save favorites to SharedPreferences
  Future<void> _saveFavoritesToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encodedData = json.encode(_favoriteItems);
      await prefs.setString('favorites', encodedData);
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }
}
