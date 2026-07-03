// lib/services/order_service.dart
//
// All order API calls mapped to UserDashboardController routes:
//   POST /api/dashboard/orders/store  → placeOrder()
//   GET  /api/dashboard/orders        → getMyOrders()

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../contants/api_constants.dart';
import '../models/order/order_model.dart';
import '../models/order/place_order_request.dart';

class OrderService {
  static const Map<String, String> _baseHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // ── Auth headers ──────────────────────────────────────────────────────────
  Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';
    return {
      ..._baseHeaders,
      if (token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ── Place Order ────────────────────────────────────────────────────────────
  // Route: POST /api/dashboard/orders/store  (auth:sanctum)
  // Controller: UserDashboardController@storeOrder
  Future<OrderModel> placeOrder(PlaceOrderRequest request) async {
    final uri = Uri.parse(ApiConstants.storeOrder);
    final headers = await _authHeaders();

    try {
      final response = await http
          .post(uri, headers: headers, body: jsonEncode(request.toJson()))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Controller returns: { status, message, order: { ...order, items: [...] } }
        final orderData = data['order'] ?? data['data'] ?? data;
        return OrderModel.fromJson(orderData);
      }

      final err = jsonDecode(response.body);
      throw Exception(
          err['message'] ?? 'Failed to place order (${response.statusCode})');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error placing order: $e');
    }
  }

  // ── Get My Orders ──────────────────────────────────────────────────────────
  // Route: GET /api/dashboard/orders  (auth:sanctum)
  // Controller: UserDashboardController@getOrders
  Future<List<OrderModel>> getMyOrders() async {
    final uri = Uri.parse(ApiConstants.getOrders);
    final headers = await _authHeaders();

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['data'] ?? data['orders'] ?? [];
        return list.map((e) => OrderModel.fromJson(e)).toList();
      }

      throw Exception('Failed to load orders (${response.statusCode})');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error fetching orders: $e');
    }
  }

  // ── Get Order By ID ────────────────────────────────────────────────────────
  Future<OrderModel> getOrderById(int id) async {
    final uri = Uri.parse(ApiConstants.orderDetail(id));
    final headers = await _authHeaders();

    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return OrderModel.fromJson(data['data'] ?? data);
      }

      throw Exception('Failed to load order (${response.statusCode})');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error fetching order: $e');
    }
  }

  // ── Cancel Order ───────────────────────────────────────────────────────────
  Future<void> cancelOrder(int id) async {
    final uri = Uri.parse(ApiConstants.endpoint('orders/$id/cancel'));
    final headers = await _authHeaders();

    try {
      final response = await http
          .post(uri, headers: headers)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to cancel order (${response.statusCode})');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error cancelling order: $e');
    }
  }
}
