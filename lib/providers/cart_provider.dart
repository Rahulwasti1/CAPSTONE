import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CartItem {
  final String id;
  final String title;
  final double price;
  final String imageUrl;
  final String size;
  final String color;
  int quantity;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.imageUrl,
    required this.size,
    required this.color,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'imageUrl': imageUrl,
      'size': size,
      'color': color,
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      title: json['title'],
      price: json['price'],
      imageUrl: json['imageUrl'],
      size: json['size'],
      color: json['color'],
      quantity: json['quantity'],
    );
  }
}

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  double _deliveryFee = 140.0;
  double _discount = 0.0;

  List<CartItem> get items => _items;

  double get deliveryFee => _deliveryFee;
  double get discount => _discount;

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    for (var item in _items) {
      total += item.price * item.quantity;
    }
    return total;
  }

  double get subTotal => totalAmount;
  double get finalAmount => totalAmount + deliveryFee - discount;

  void addItem({
    required String productId,
    required String title,
    required double price,
    required String imageUrl,
    required String size,
    required String color,
  }) {
    // Check if the item already exists in the cart
    final existingIndex = _items.indexWhere((item) =>
        item.id == productId && item.size == size && item.color == color);

    if (existingIndex >= 0) {
      // Just increase the quantity
      _items[existingIndex].quantity += 1;
    } else {
      // Add new item
      _items.add(
        CartItem(
          id: productId,
          title: title,
          price: price,
          imageUrl: imageUrl,
          size: size,
          color: color,
        ),
      );
    }

    _saveCartToPrefs();
    notifyListeners();
  }

  void removeItem(String productId, String size, String color) {
    _items.removeWhere((item) =>
        item.id == productId && item.size == size && item.color == color);
    _saveCartToPrefs();
    notifyListeners();
  }

  void incrementQuantity(String productId, String size, String color) {
    final index = _items.indexWhere((item) =>
        item.id == productId && item.size == size && item.color == color);

    if (index >= 0) {
      _items[index].quantity += 1;
      _saveCartToPrefs();
      notifyListeners();
    }
  }

  void decrementQuantity(String productId, String size, String color) {
    final index = _items.indexWhere((item) =>
        item.id == productId && item.size == size && item.color == color);

    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity -= 1;
      } else {
        // If quantity becomes 0, remove the item
        removeItem(productId, size, color);
        return; // Already notified listeners in removeItem
      }
      _saveCartToPrefs();
      notifyListeners();
    }
  }

  void clearCart() {
    _items = [];
    _saveCartToPrefs();
    notifyListeners();
  }

  void applyDiscount(double amount) {
    _discount = amount;
    notifyListeners();
  }

  // Load cart from SharedPreferences
  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cartJson = prefs.getString('cart');

      if (cartJson != null) {
        final List<dynamic> decodedData = json.decode(cartJson);
        _items = decodedData
            .map((item) => CartItem.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        // Also load discount and delivery fee if stored
        _discount = prefs.getDouble('discount') ?? 0.0;
        _deliveryFee = prefs.getDouble('deliveryFee') ?? 140.0;

        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  // Save cart to SharedPreferences
  Future<void> _saveCartToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> itemsJson =
          _items.map((item) => item.toJson()).toList();
      final String encodedData = json.encode(itemsJson);
      await prefs.setString('cart', encodedData);

      // Save discount and delivery fee too
      await prefs.setDouble('discount', _discount);
      await prefs.setDouble('deliveryFee', _deliveryFee);
    } catch (e) {
      print('Error saving cart: $e');
    }
  }
}
