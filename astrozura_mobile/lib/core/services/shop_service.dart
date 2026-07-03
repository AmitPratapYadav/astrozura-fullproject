import '../contants/api_constants.dart';
import '../models/product/product.model.dart';
import '../models/shop_category/shop_category_model.dart';
import 'api_client.dart';

class ShopService {
  ShopService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<ProductModel>> getAllProducts() async {
    final data = await _api.get(ApiConstants.getProducts);
    return _extractList(data)
        .whereType<Map>()
        .map((item) => ProductModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<List<ProductModel>> getTrendingProducts() async {
    final data = await _api.get(ApiConstants.getTrendingProducts);
    return _extractList(data)
        .whereType<Map>()
        .map((item) => ProductModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<List<ShopCategoryModel>> getCategories() async {
    final data = await _api.get(ApiConstants.getCategories);
    return _extractList(data, keys: const ['data', 'categories'])
        .whereType<Map>()
        .map((item) => ShopCategoryModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  List<dynamic> _extractList(
    dynamic data, {
    List<String> keys = const ['data', 'products', 'categories'],
  }) {
    if (data is List) return data;
    if (data is! Map) return const [];

    for (final key in keys) {
      final value = data[key];
      if (value is List) return value;
      if (value is Map && value['data'] is List) {
        return value['data'] as List;
      }
    }
    return const [];
  }
}
