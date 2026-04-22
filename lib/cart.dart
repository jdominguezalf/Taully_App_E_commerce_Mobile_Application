import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Cart with ChangeNotifier {
  final Map<String, Map<String, dynamic>> _cartItems = {};

  Cart() {
    _loadFromStorage();
  }

  List<Map<String, dynamic>> get items => _cartItems.values.toList();

  int get itemCount => _cartItems.length;

  int get totalQuantity {
    int total = 0;
    _cartItems.forEach((_, item) {
      total += item['quantity'] as int;
    });
    return total;
  }

  double get totalAmount {
    double total = 0;
    _cartItems.forEach((_, item) {
      total += (item['price'] as double) * (item['quantity'] as int);
    });
    return total;
  }

  void addToCart(Map<String, dynamic> product) {
    final productId = product['name'] as String;
    if (_cartItems.containsKey(productId)) {
      _cartItems.update(
        productId,
        (existingItem) => {
          ...existingItem,
          'quantity': (existingItem['quantity'] as int) + 1,
        },
      );
    } else {
      _cartItems[productId] = {...product, 'quantity': 1};
    }
    _saveToStorage();
    notifyListeners();
  }

  void removeFromCart(Map<String, dynamic> product) {
    final productId = product['name'] as String;
    if (!_cartItems.containsKey(productId)) return;

    if (_cartItems[productId]!['quantity'] > 1) {
      _cartItems.update(
        productId,
        (existingItem) => {
          ...existingItem,
          'quantity': (existingItem['quantity'] as int) - 1,
        },
      );
    } else {
      _cartItems.remove(productId);
    }
    _saveToStorage();
    notifyListeners();
  }

  void removeCompleteItem(String productId) {
    if (_cartItems.containsKey(productId)) {
      _cartItems.remove(productId);
      _saveToStorage();
      notifyListeners();
    }
  }

  void clear() {
    _cartItems.clear();
    _saveToStorage();
    notifyListeners();
  }

  /// 🔄 Guardar en SharedPreferences
  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _cartItems.map((key, value) => MapEntry(key, value)),
    );
    await prefs.setString('cart_data', encoded);
  }

  /// 🔄 Cargar desde SharedPreferences
  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonData = prefs.getString('cart_data');
    if (jsonData != null) {
      final decoded = jsonDecode(jsonData) as Map<String, dynamic>;
      _cartItems.clear();
      decoded.forEach((key, value) {
        _cartItems[key] = Map<String, dynamic>.from(value);
      });
      notifyListeners();
    }
  }
}
