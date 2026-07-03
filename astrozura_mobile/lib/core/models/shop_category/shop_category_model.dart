// lib/models/shop_category/shop_category_model.dart

class ShopCategoryModel {
  final int id;
  final String name;
  final String? image;

  const ShopCategoryModel({
    required this.id,
    required this.name,
    this.image,
  });

  /// Laravel API returns:
  /// { "id": 1, "name": "All", "image": "http://..." }
  factory ShopCategoryModel.fromJson(Map<String, dynamic> json) {
    return ShopCategoryModel(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '',
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
      };
}