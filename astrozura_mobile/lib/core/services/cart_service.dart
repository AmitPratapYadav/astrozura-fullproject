// lib/core/services/cart_services.dart

import 'package:flutter/foundation.dart';
import '../models/product/product.model.dart';
import 'cart_service.dart';

export '../models/cart/cart_item.dart';

class CartService extends ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────────────────────────
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  // ── State ──────────────────────────────────────────────────────────────────
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalItems => _items.fold(0, (sum, i) => sum + i.quantity);

  double get totalPrice => _items.fold(0.0, (sum, i) => sum + i.totalPrice);

  bool isInCart(int productId) =>
      _items.any((i) => i.product.id == productId);

  // ── Actions ────────────────────────────────────────────────────────────────

  void addToCart(ProductModel product, {int quantity = 1}) {
    final index = _items.indexWhere((i) => i.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void removeItem(ProductModel product) {
    _items.removeWhere((i) => i.product.id == product.id);
    notifyListeners();
  }

  void incrementQuantity(int productId) {
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      _items[index].quantity++;
      notifyListeners();
    }
  }

  void decrementQuantity(int productId) {
    final index = _items.indexWhere((i) => i.product.id == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}