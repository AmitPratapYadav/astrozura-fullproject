import 'package:flutter/foundation.dart';

import '../contants/api_constants.dart';
import '../models/product/product.model.dart';
import 'api_client.dart';
import 'auth_services.dart';

class ProductWishlistService extends ChangeNotifier {
  ProductWishlistService._();

  static final ProductWishlistService _instance = ProductWishlistService._();
  factory ProductWishlistService() => _instance;

  final ApiClient _api = ApiClient();
  final Set<int> _ids = {};
  List<ProductModel> _products = const [];
  bool _loaded = false;
  bool _loading = false;

  bool get isLoaded => _loaded;
  bool get isLoading => _loading;
  int get count => _ids.length;
  List<ProductModel> get products => List.unmodifiable(_products);

  bool isWishlisted(int productId) => _ids.contains(productId);

  Future<void> load({bool force = false}) async {
    if (_loading || (_loaded && !force)) return;
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      _ids.clear();
      _products = const [];
      _loaded = true;
      notifyListeners();
      return;
    }

    _loading = true;
    notifyListeners();
    try {
      final data = await _api.get(ApiConstants.getWishlist, auth: true);
      final raw = data['data'] ?? data['wishlist'] ?? const [];
      final products = raw is List
          ? raw
              .whereType<Map>()
              .map((item) =>
                  ProductModel.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : <ProductModel>[];
      _products = products;
      _ids
        ..clear()
        ..addAll(products.map((product) => product.id));
      _loaded = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> toggle(ProductModel product) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('Please login to use wishlist.',
          statusCode: 401);
    }

    final wasWishlisted = _ids.contains(product.id);
    if (wasWishlisted) {
      _ids.remove(product.id);
      _products = _products.where((item) => item.id != product.id).toList();
    } else {
      _ids.add(product.id);
      _products = [
        product,
        ..._products.where((item) => item.id != product.id)
      ];
    }
    notifyListeners();

    try {
      final data = await _api.post(
        ApiConstants.toggleWishlist,
        auth: true,
        body: {'product_id': product.id},
      );
      final inWishlist = data['in_wishlist'] == true ||
          data['wishlisted'] == true ||
          data['status']?.toString().toLowerCase() == 'added';

      if (inWishlist) {
        _ids.add(product.id);
        _products = [
          product,
          ..._products.where((item) => item.id != product.id),
        ];
      } else {
        _ids.remove(product.id);
        _products = _products.where((item) => item.id != product.id).toList();
      }
      notifyListeners();
      return inWishlist;
    } catch (_) {
      if (wasWishlisted) {
        _ids.add(product.id);
        _products = [
          product,
          ..._products.where((item) => item.id != product.id),
        ];
      } else {
        _ids.remove(product.id);
        _products = _products.where((item) => item.id != product.id).toList();
      }
      notifyListeners();
      rethrow;
    }
  }
}
