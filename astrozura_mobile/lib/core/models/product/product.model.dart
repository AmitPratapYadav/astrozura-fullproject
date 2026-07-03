// lib/models/product/product.model.dart

import '../../contants/api_constants.dart';

class ProductModel {
  final int id;
  final String name;
  final String? description;
  final double price;
  final double? oldPrice; // maps from sale_price
  final String? image; // single image from API
  final String? category;
  final int? categoryId;
  final bool isTrending;
  final bool isNew;
  final double rating;
  final int reviews;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
    this.oldPrice,
    this.image,
    this.category,
    this.categoryId,
    this.isTrending = false,
    this.isNew = false,
    this.rating = 0.0,
    this.reviews = 0,
  });

  /// Convenience getter — ProductCard uses product.images[0]
  /// This wraps the single image in a list so existing UI code works without changes.
  List<String> get images {
    if (image != null && image!.isNotEmpty) return [image!];
    return [''];
  }

  /// Laravel API returns:
  /// {
  ///   "id": 1,
  ///   "name": "Crystal Ball",
  ///   "description": "...",
  ///   "price": "499.00",
  ///   "sale_price": "399.00",        ← optional
  ///   "image": "http://...",
  ///   "category": { "id": 2, "name": "Crystals" },  ← nested OR flat
  ///   "category_id": 2,
  ///   "is_trending": 1,
  ///   "is_new": 0,
  ///   "rating": 4.5,                 ← optional, default 0
  ///   "reviews_count": 12            ← optional, default 0
  /// }
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Safely parse price to double
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    return ProductModel(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: parseDouble(json['price']),
      oldPrice:
          json['sale_price'] != null ? parseDouble(json['sale_price']) : null,
      image: _imageUrl(json['image']?.toString()),
      category: json['category'] is Map
          ? json['category']['name']?.toString()
          : json['category_name']?.toString() ?? json['category']?.toString(),
      categoryId: json['category_id'] as int?,
      isTrending: json['is_trending'] == 1 || json['is_trending'] == true,
      isNew: json['is_new'] == 1 || json['is_new'] == true,
      rating: parseDouble(json['rating']),
      reviews: (json['reviews_count'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'price': price,
        'sale_price': oldPrice,
        'image': image,
        'category': category,
        'category_id': categoryId,
        'is_trending': isTrending,
        'is_new': isNew,
        'rating': rating,
        'reviews_count': reviews,
      };

  static String? _imageUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return ApiConstants.storageUrl(value);
  }
}
