class PlaceOrderRequest {
  final List<OrderItemRequest> items;
  final double totalAmount;
  final String paymentMethod; // razorpay | cod
  final String shippingAddress;
  final String phone;
  final String? promoCode;
  final double? promoDiscount;
  final double shippingCharge;
  final double gstAmount;
  final String? notes;

  const PlaceOrderRequest({
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.shippingAddress,
    required this.phone,
    this.promoCode,
    this.promoDiscount,
    required this.shippingCharge,
    required this.gstAmount,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
        // Backend validator keys: items.*.id, items.*.qty, items.*.price
        'items': items.map((e) => e.toJson()).toList(),
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
        'shipping_address': shippingAddress,
        'phone': phone,
        'shipping_charge': shippingCharge,
        'gst_amount': gstAmount,
        if (promoCode != null) 'promo_code': promoCode,
        if (promoDiscount != null) 'promo_discount': promoDiscount,
        if (notes != null) 'notes': notes,
      };
}

class OrderItemRequest {
  final int productId;
  final int quantity;
  final double price;

  const OrderItemRequest({
    required this.productId,
    required this.quantity,
    required this.price,
  });

  // Backend expects 'id' and 'qty' (not product_id / quantity)
  Map<String, dynamic> toJson() => {
        'id': productId,
        'qty': quantity,
        'price': price,
      };
}
