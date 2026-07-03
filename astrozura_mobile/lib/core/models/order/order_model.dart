// lib/models/order/order_model.dart

class OrderModel {
  final int id;
  final String orderNumber;
  final double totalAmount;
  final String status;         // pending | processing | shipped | delivered | cancelled
  final String paymentStatus;  // pending | paid | failed
  final String paymentMethod;  // upi | card | cod
  final String shippingAddress;
  final String phone;
  final String? notes;
  final String createdAt;
  final List<OrderItemModel> items;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.shippingAddress,
    required this.phone,
    this.notes,
    required this.createdAt,
    required this.items,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsList = json['items'] as List<dynamic>? ?? [];
    return OrderModel(
      id: json['id'] as int,
      orderNumber: json['order_number']?.toString() ?? '#${json['id']}',
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      status: json['status']?.toString() ?? 'pending',
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
      paymentMethod: json['payment_method']?.toString() ?? 'cod',
      shippingAddress: json['shipping_address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      items: itemsList.map((e) => OrderItemModel.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order_number': orderNumber,
        'total_amount': totalAmount,
        'status': status,
        'payment_status': paymentStatus,
        'payment_method': paymentMethod,
        'shipping_address': shippingAddress,
        'phone': phone,
        'notes': notes,
        'created_at': createdAt,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

class OrderItemModel {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final String? category;
  final int quantity;
  final double price;

  const OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    this.category,
    required this.quantity,
    required this.price,
  });

  double get totalPrice => price * quantity;

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    // product may be nested under 'product' key
    final product = json['product'] as Map<String, dynamic>?;
    return OrderItemModel(
      id: json['id'] as int,
      productId: json['product_id'] as int,
      productName: product?['name']?.toString() ??
          json['product_name']?.toString() ??
          'Product',
      productImage: product?['images']?.toString() ??
          product?['image']?.toString() ??
          json['product_image']?.toString(),
      category: product?['category']?['name']?.toString() ??
          json['category']?.toString(),
      quantity: json['quantity'] as int,
      price: double.tryParse(json['price'].toString()) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'product_name': productName,
        'quantity': quantity,
        'price': price,
      };
}