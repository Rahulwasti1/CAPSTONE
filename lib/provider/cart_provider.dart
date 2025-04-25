// If the cart does not contains product then add otherwise increase the quantity if same product consiste
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class CartItem {
  final String id;
  final String title;
  final double price;
  final int quantity;
  final String imageUrl;
  final String color;
  final String size;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    required this.color,
    required this.size,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'color': color,
      'size': size,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      title: json['title'],
      price: json['price'].toDouble(),
      quantity: json['quantity'],
      imageUrl: json['imageUrl'],
      color: json['color'],
      size: json['size'],
    );
  }
}

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};
  double _deliveryFee = 140.0;
  double _discount = 0.0;

  Map<String, CartItem> get items => {..._items};
  int get itemCount => _items.length;
  double get deliveryFee => _deliveryFee;
  double get discount => _discount;

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  double get finalAmount => totalAmount + deliveryFee - discount;

  void addItem({
    required String productId,
    required String title,
    required double price,
    required String imageUrl,
    required String color,
    required String size,
    int quantity = 1,
  }) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          title: existingCartItem.title,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity + quantity,
          imageUrl: existingCartItem.imageUrl,
          color: existingCartItem.color,
          size: existingCartItem.size,
        ),
      );
    } else {
      _items.putIfAbsent(
        productId,
        () => CartItem(
          id: productId,
          title: title,
          price: price,
          quantity: quantity,
          imageUrl: imageUrl,
          color: color,
          size: size,
        ),
      );
    }
    notifyListeners();
    saveCartToPrefs();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
    saveCartToPrefs();
  }

  void incrementQuantity(String productId) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          id: existingCartItem.id,
          title: existingCartItem.title,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity + 1,
          imageUrl: existingCartItem.imageUrl,
          color: existingCartItem.color,
          size: existingCartItem.size,
        ),
      );
      notifyListeners();
      saveCartToPrefs();
    }
  }

  void decrementQuantity(String productId) {
    if (_items.containsKey(productId)) {
      if (_items[productId]!.quantity > 1) {
        _items.update(
          productId,
          (existingCartItem) => CartItem(
            id: existingCartItem.id,
            title: existingCartItem.title,
            price: existingCartItem.price,
            quantity: existingCartItem.quantity - 1,
            imageUrl: existingCartItem.imageUrl,
            color: existingCartItem.color,
            size: existingCartItem.size,
          ),
        );
      } else {
        _items.remove(productId);
      }
      notifyListeners();
      saveCartToPrefs();
    }
  }

  void clear() {
    _items = {};
    notifyListeners();
    saveCartToPrefs();
  }

  void setDeliveryFee(double fee) {
    _deliveryFee = fee;
    notifyListeners();
    saveCartToPrefs();
  }

  void setDiscount(double amount) {
    _discount = amount;
    notifyListeners();
    saveCartToPrefs();
  }

  Future<void> saveCartToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartData = _items.map((key, item) => MapEntry(key, item.toJson()));
    await prefs.setString('cart', json.encode(cartData));
    await prefs.setDouble('deliveryFee', _deliveryFee);
    await prefs.setDouble('discount', _discount);
  }

  Future<void> loadCartFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final cartString = prefs.getString('cart');
    if (cartString != null) {
      final cartData = json.decode(cartString) as Map<String, dynamic>;
      _items = cartData.map((key, value) => MapEntry(
            key,
            CartItem.fromJson(value as Map<String, dynamic>),
          ));
      _deliveryFee = prefs.getDouble('deliveryFee') ?? 140.0;
      _discount = prefs.getDouble('discount') ?? 0.0;
      notifyListeners();
    }
  }
}
