// lib/core/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/contants/api_constants.dart';
import 'api_client.dart';

class ApiService {
  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static Map<String, String> _authHeaders(String token) => {
        ..._headers,
        'Authorization': 'Bearer $token',
      };

  // ── E-COMMERCE ────────────────────────────────────────────────────────────

  /// GET /api/ecomm/products
  /// Returns: { success, products: [...] }
  static Future<List<dynamic>> getProducts() async {
    final response = await http
        .get(Uri.parse(ApiConstants.getProducts), headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Laravel returns { success: true, products: [...] }
      return data['products'] ?? data['data'] ?? [];
    }
    throw Exception('Failed to load products (${response.statusCode})');
  }

  /// GET /api/ecomm/products/trending
  static Future<List<dynamic>> getTrendingProducts() async {
    final response = await http
        .get(Uri.parse(ApiConstants.getTrendingProducts), headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['products'] ?? data['data'] ?? [];
    }
    throw Exception(
        'Failed to load trending products (${response.statusCode})');
  }

  /// GET /api/ecomm/categories
  /// Returns: { success, categories: [...] }
  static Future<List<dynamic>> getCategories() async {
    final response = await http
        .get(Uri.parse(ApiConstants.getCategories), headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Handles both { categories: [...] } and a bare array
      if (data is List) return data;
      return data['categories'] ?? data['data'] ?? [];
    }
    throw Exception('Failed to load categories (${response.statusCode})');
  }

  // ── ASTROLOGERS ───────────────────────────────────────────────────────────

  /// GET /api/astrologers?q=term
  static Future<List<dynamic>> getAstrologers({String query = ''}) async {
    final uri = Uri.parse(ApiConstants.getAstrologers)
        .replace(queryParameters: query.isNotEmpty ? {'q': query} : null);

    final response = await http
        .get(uri, headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['astrologers'] ?? [];
    }
    throw Exception('Failed to load astrologers (${response.statusCode})');
  }

  /// GET /api/astrologer/{id}
  static Future<Map<String, dynamic>> getAstrologerProfile(int id) async {
    final response = await http
        .get(Uri.parse(ApiConstants.astrologerProfile(id)), headers: _headers)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['astrologer'] ?? {};
    }
    throw Exception('Astrologer not found (${response.statusCode})');
  }

  // ── RITUALS ───────────────────────────────────────────────────────────────

  /// GET /api/rituals
  static Future<List<dynamic>> getRituals() async {
    final data = await ApiClient().get(ApiConstants.getRituals);
    final rituals = data['rituals'];
    if (rituals is List) return rituals;
    if (rituals is Map && rituals['data'] is List) return rituals['data'];
    return data['data'] is List ? data['data'] as List : const [];
  }

  // ── SUBSCRIPTIONS ─────────────────────────────────────────────────────────

  // ── PROTECTED: USER DASHBOARD ─────────────────────────────────────────────

  /// GET /api/dashboard/profile   (requires token)
  static Future<Map<String, dynamic>> getUserProfile(String token) async {
    final response = await http
        .get(Uri.parse(ApiConstants.getProfile), headers: _authHeaders(token))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['user'] ?? data['data'] ?? {};
    }
    throw Exception('Failed to fetch profile (${response.statusCode})');
  }

  /// GET /api/dashboard/orders   (requires token)
  static Future<List<dynamic>> getOrders(String token) async {
    final response = await http
        .get(Uri.parse(ApiConstants.getOrders), headers: _authHeaders(token))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['orders'] ?? data['data'] ?? [];
    }
    throw Exception('Failed to fetch orders (${response.statusCode})');
  }

  /// GET /api/dashboard/wishlist  (requires token)
  static Future<List<dynamic>> getWishlist(String token) async {
    final response = await http
        .get(Uri.parse(ApiConstants.getWishlist), headers: _authHeaders(token))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['wishlist'] ?? data['data'] ?? [];
    }
    throw Exception('Failed to fetch wishlist (${response.statusCode})');
  }

  /// POST /api/dashboard/wishlist/toggle  (requires token)
  static Future<Map<String, dynamic>> toggleWishlist(
      String token, int productId) async {
    final response = await http
        .post(
          Uri.parse(ApiConstants.toggleWishlist),
          headers: _authHeaders(token),
          body: jsonEncode({'product_id': productId}),
        )
        .timeout(const Duration(seconds: 15));

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// GET /api/my-bookings   (requires token)
  static Future<List<dynamic>> getMyBookings(String token) async {
    final response = await http
        .get(Uri.parse(ApiConstants.myBookings), headers: _authHeaders(token))
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['bookings'] ?? data['data'] ?? [];
    }
    throw Exception('Failed to fetch bookings (${response.statusCode})');
  }
}
