// If the cart does not contains product then add otherwise increase the quantity if same product consiste
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Making a provider
class FavoriteProvider with ChangeNotifier {
  final Map<String, bool> _favoriteItems = {};

  Map<String, bool> get items {
    return {..._favoriteItems};
  }

  int get favoriteCount {
    return _favoriteItems.values.where((isFavorite) => isFavorite).length;
  }

  bool isFavorite(String productId) {
    return _favoriteItems[productId] ?? false;
  }

  void toggleFavorite(String productId) {
    final currentStatus = _favoriteItems[productId] ?? false;
    _favoriteItems[productId] = !currentStatus;
    notifyListeners();
  }

  void removeFromFavorites(String productId) {
    _favoriteItems.remove(productId);
    notifyListeners();
  }

  List<String> get favoriteProductIds {
    return _favoriteItems.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  void clear() {
    _favoriteItems.clear();
    notifyListeners();
  }

  // Helper method to get the favorites provider from context
  static FavoriteProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<FavoriteProvider>(context, listen: listen);
  }
}
