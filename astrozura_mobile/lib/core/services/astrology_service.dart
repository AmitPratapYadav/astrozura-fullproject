import '../contants/api_constants.dart';
import 'api_client.dart';

class AstrologyService {
  AstrologyService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    if (query.trim().length < 2) return [];

    final data = await _api.get(
      ApiConstants.locationSearch,
      query: {'q': query.trim()},
    );

    final raw = data['data'] ?? data['locations'] ?? data['results'] ?? [];
    if (raw is! List) return [];
    return raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  Future<Map<String, dynamic>> kundli(Map<String, dynamic> payload) {
    return _api.post(ApiConstants.generateKundli, body: payload);
  }

  Future<Map<String, dynamic>> panchang(Map<String, dynamic> payload) {
    return _api.post(ApiConstants.getPanchang, body: payload);
  }

  Future<Map<String, dynamic>> matchMaking(Map<String, dynamic> payload) {
    return _api.post(ApiConstants.matchMaking, body: payload);
  }

  Future<Map<String, dynamic>> sadesati(Map<String, dynamic> payload) {
    return _api.post(ApiConstants.sadesati, body: payload);
  }

  Future<Map<String, dynamic>> numerology(Map<String, dynamic> payload) {
    return _api.post(ApiConstants.numerology, body: payload);
  }

  Future<Map<String, dynamic>> lalKitab(Map<String, dynamic> payload) {
    return _api.post(ApiConstants.lalKitab, body: payload);
  }

  Future<Map<String, dynamic>> tarot(Map<String, dynamic> payload) {
    return _api.post(ApiConstants.tarot, body: payload);
  }

  Future<Map<String, dynamic>> vedicCalculator(
    String calculator,
    Map<String, dynamic> payload,
  ) {
    return _api.post(ApiConstants.vedicCalculator(calculator), body: payload);
  }

  Future<Map<String, dynamic>> matchingCalculator(
    String calculator,
    Map<String, dynamic> payload,
  ) {
    return _api.post(
      ApiConstants.matchingCalculator(calculator),
      body: payload,
    );
  }
}
