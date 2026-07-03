// lib/models/cart/cart_item.model.dart

import '../product/product.model.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  /// price is already a double in the updated ProductModel
  double get unitPrice => product.price;

  /// total for this line item
  double get totalPrice => unitPrice * quantity;
}