// lib/models/product/product.model.dart

import '../../contants/api_constants.dart';

class ProductModel {
  final int id;
  final String name;
  final String? description;
  final String? benefits;
  final String? specifications;
  final String? warningsPrecautions;
  final String? unit;
  final double price;
  final double? oldPrice; // maps from sale_price
  final String? image; // single image from API
  final String? category;
  final int? categoryId;
  final String? createdAt;
  final bool isTrending;
  final bool isNew;
  final double rating;
  final int reviews;
  final List<ProductVariantModel> variants;
  final ProductGuideBlog? guideBlog;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.benefits,
    this.specifications,
    this.warningsPrecautions,
    this.unit,
    required this.price,
    this.oldPrice,
    this.image,
    this.category,
    this.categoryId,
    this.createdAt,
    this.isTrending = false,
    this.isNew = false,
    this.rating = 0.0,
    this.reviews = 0,
    this.variants = const [],
    this.guideBlog,
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

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    final variantsRaw = json['active_variants'] ?? json['variants'];
    final guideRaw = json['guide_blog'];

    return ProductModel(
      id: parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      benefits: json['benefits']?.toString(),
      specifications: json['specifications']?.toString(),
      warningsPrecautions: json['warnings_precautions']?.toString(),
      unit: json['unit']?.toString(),
      price: parseDouble(json['price']),
      oldPrice:
          json['sale_price'] != null ? parseDouble(json['sale_price']) : null,
      image: _imageUrl(json['image']?.toString()),
      category: json['category'] is Map
          ? json['category']['name']?.toString()
          : json['category_name']?.toString() ?? json['category']?.toString(),
      categoryId: parseInt(json['category_id']) == 0
          ? null
          : parseInt(json['category_id']),
      createdAt: json['created_at']?.toString(),
      isTrending: json['is_trending'] == 1 || json['is_trending'] == true,
      isNew: json['is_new'] == 1 ||
          json['is_new'] == true ||
          json['is_new_arrival'] == 1 ||
          json['is_new_arrival'] == true,
      rating: parseDouble(json['rating'] ?? json['reviews_avg_rating']),
      reviews: parseInt(json['reviews_count']),
      variants: variantsRaw is List
          ? variantsRaw
              .whereType<Map>()
              .map((item) =>
                  ProductVariantModel.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      guideBlog: guideRaw is Map
          ? ProductGuideBlog.fromJson(Map<String, dynamic>.from(guideRaw))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'benefits': benefits,
        'specifications': specifications,
        'warnings_precautions': warningsPrecautions,
        'unit': unit,
        'price': price,
        'sale_price': oldPrice,
        'image': image,
        'category': category,
        'category_id': categoryId,
        'created_at': createdAt,
        'is_trending': isTrending,
        'is_new': isNew,
        'rating': rating,
        'reviews_count': reviews,
        'active_variants': variants.map((e) => e.toJson()).toList(),
        'guide_blog': guideBlog?.toJson(),
      };

  static String? _imageUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return ApiConstants.storageUrl(value);
  }
}

class ProductVariantModel {
  final int id;
  final String title;
  final String? sku;
  final double price;
  final double? compareAtPrice;
  final int stockQuantity;
  final String? image;

  const ProductVariantModel({
    required this.id,
    required this.title,
    this.sku,
    required this.price,
    this.compareAtPrice,
    required this.stockQuantity,
    this.image,
  });

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    return ProductVariantModel(
      id: parseInt(json['id']),
      title: (json['title'] ?? 'Default').toString(),
      sku: json['sku']?.toString(),
      price: parseDouble(json['price']),
      compareAtPrice: json['compare_at_price'] == null
          ? null
          : parseDouble(json['compare_at_price']),
      stockQuantity: parseInt(json['stock_quantity']),
      image: ProductModel._imageUrl(json['image']?.toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'sku': sku,
        'price': price,
        'compare_at_price': compareAtPrice,
        'stock_quantity': stockQuantity,
        'image': image,
      };
}

class ProductGuideBlog {
  final int id;
  final String title;
  final String? excerpt;
  final String? slug;

  const ProductGuideBlog({
    required this.id,
    required this.title,
    this.excerpt,
    this.slug,
  });

  factory ProductGuideBlog.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    return ProductGuideBlog(
      id: parseInt(json['id']),
      title: (json['title'] ?? json['name'] ?? 'Guide Book').toString(),
      excerpt:
          (json['excerpt'] ?? json['summary'] ?? json['seo_description'])
              ?.toString(),
      slug: json['slug']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'excerpt': excerpt,
        'slug': slug,
      };
}
