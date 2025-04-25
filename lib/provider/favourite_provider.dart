// Favorites provider with enhanced functionality
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:developer' as developer;

// Making a provider
class FavoriteProvider with ChangeNotifier {
  final Set<String> _favoriteIds = {};

  Set<String> get favoriteIds => _favoriteIds;

  bool isFavorite(String productId) => _favoriteIds.contains(productId);

  void toggleFavorite(String productId) {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }
    notifyListeners();
    _saveFavorites();
  }

  void removeFromFavorites(String productId) {
    _favoriteIds.remove(productId);
    notifyListeners();
    _saveFavorites();
  }

  List<String> favoriteProductIds() {
    return _favoriteIds.toList();
  }

  void clear() {
    _favoriteIds.clear();
    notifyListeners();
    _saveFavorites();
  }

  // Load favorites from SharedPreferences
  Future<void> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString('favorites');
      if (favoritesJson != null) {
        final List<dynamic> favoritesList = jsonDecode(favoritesJson);
        _favoriteIds.clear();
        _favoriteIds.addAll(favoritesList.cast<String>());
        notifyListeners();
      }
    } catch (e) {
      developer.log('Error loading favorites: $e');
    }
  }

  // Save favorites to SharedPreferences
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String favoritesJson = jsonEncode(List<String>.from(_favoriteIds));
      await prefs.setString('favorites', favoritesJson);
    } catch (e) {
      developer.log('Error saving favorites: $e');
    }
  }

  // Helper method to get the favorites provider from context
  static FavoriteProvider of(BuildContext context) {
    return Provider.of<FavoriteProvider>(context, listen: false);
  }
}
