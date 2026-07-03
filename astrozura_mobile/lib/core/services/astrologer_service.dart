import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/astrologer/astrologer_booking_model.dart';
import '../models/astrologer/dashboard_stats_model.dart';
import 'auth_services.dart';
import '../contants/api_constants.dart';
import 'api_client.dart';

class AstrologerService {
  static String get _baseUrl => ApiConstants.baseUrl;
  static final ApiClient _api = ApiClient();

  static const Map<String, String> _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // =========================================================
  // SAFE JSON DECODER
  // =========================================================

  static dynamic _safeDecode(http.Response response) {
    final body = response.body;

    debugPrint("🌐 URL: ${response.request?.url}");
    debugPrint("📦 RESPONSE: $body");

    if (body.trim().startsWith('<')) {
      debugPrint("❌ HTML response detected");
      return {"data": [], "astrologers": []};
    }

    try {
      return json.decode(body);
    } catch (e) {
      debugPrint("❌ JSON Parse Error: $e");
      return {"data": [], "astrologers": []};
    }
  }

  // =========================================================
  // COMMON GET REQUEST
  // =========================================================

  static Future<dynamic> _get(String endpoint, {String? token}) async {
    try {
      final url = '$_baseUrl$endpoint';
      debugPrint('======================');
      debugPrint('CALLING URL => $url');
      debugPrint('======================');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          ..._headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('STATUS => ${response.statusCode}');
      debugPrint('BODY => ${response.body}');

      if (response.statusCode == 200) {
        return _safeDecode(response);
      }

      return {};
    } catch (e) {
      debugPrint('GET ERROR => $e');
      return {};
    }
  }

  // =========================================================
  // COMMON POST REQUEST
  // =========================================================

  static Future<dynamic> _post(
    String endpoint, {
    required Map<String, dynamic> body,
    String? token,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl$endpoint'),
            headers: {
              ..._headers,
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: json.encode(body),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('📦 POST ${response.statusCode} => ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return _safeDecode(response);
      }

      debugPrint("❌ POST Failed: ${response.statusCode}");
      return {};
    } catch (e) {
      debugPrint("❌ POST Error: $e");
      return {};
    }
  }

  // =========================================================
  // GET ALL ASTROLOGERS
  // Route: GET /api/astrologers  (public)
  // =========================================================

  static Future<List<Map<String, dynamic>>> getAllAstrologers() async {
    final data = await _api.get(ApiConstants.getAstrologers);

    debugPrint('ASTRO RESPONSE => $data');

    final nested = data['data'];
    final dynamic raw = data['astrologers'] ??
        (nested is Map ? nested['astrologers'] : null) ??
        nested ??
        data['results'] ??
        const [];
    final astrologers = raw is List ? raw : const <dynamic>[];

    return astrologers
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // =========================================================
  // GET ASTROLOGER PROFILE BY ID
  // Route: GET /api/astrologer/{id}  (public)
  // =========================================================

  static Future<Map<String, dynamic>?> getAstrologerProfile(int id) async {
    final data = await _get('/astrologer/$id');

    if (data is Map<String, dynamic>) {
      return data['astrologer'] ?? data['data'] ?? data;
    }
    return null;
  }

  // =========================================================
  // GET FEATURED ASTROLOGERS
  // =========================================================

  static Future<List<Map<String, dynamic>>> getFeaturedAstrologers() async {
    final all = await getAllAstrologers();

    return all.where((a) {
      final detail = a['astrologer_detail'];
      if (detail == null || detail is! Map<String, dynamic>) return false;

      final featured = detail['is_featured'];
      return featured == true || featured == 1 || featured.toString() == '1';
    }).toList();
  }

  // =========================================================
  // GET WISHLIST IDS
  // Route: GET /api/dashboard/wishlist  (auth)
  // =========================================================

  static Future<Set<int>> getWishlistedIds(String token) async {
    final data = await _get('/dashboard/wishlist', token: token);

    final List<dynamic> wishlist =
        data is List ? data : (data['wishlist'] ?? data['data'] ?? []);

    return wishlist
        .map<int>((item) => (item['astrologer_id'] ?? item['id'] ?? 0) as int)
        .toSet();
  }

  // =========================================================
  // TOGGLE WISHLIST
  // Route: POST /api/dashboard/wishlist/toggle  (auth)
  // =========================================================

  static Future<bool> toggleWishlist({
    required String token,
    required int astrologerId,
  }) async {
    final data = await _post(
      '/dashboard/wishlist/toggle',
      token: token,
      body: {'astrologer_id': astrologerId},
    );

    if (data == null || (data is Map && data.isEmpty)) return false;

    if (data.containsKey('wishlisted')) return data['wishlisted'] == true;
    if (data.containsKey('status')) return data['status'] == 'added';

    return false;
  }

  // =========================================================
  // GET ASTROLOGER BOOKINGS
  // Route: GET /api/astrologer/bookings  (auth — astrologer)
  // Returns: { upcoming, history, stats }
  // =========================================================

  static Future<Map<String, dynamic>> getBookings() async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated. Please log in again.');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/astrologer/bookings'),
      headers: {
        ..._headers,
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    debugPrint('🌐 astrologer/bookings → ${response.statusCode}');
    debugPrint('📦 body: ${response.body}');

    if (response.statusCode == 401) {
      throw Exception('Session expired. Please log in again.');
    }
    if (response.statusCode == 403) {
      throw Exception('Access denied. Astrologer role required.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to load bookings (HTTP ${response.statusCode}).');
    }

    final decoded = _safeDecode(response);
    final data = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{};

    List<AstrologerBookingModel> parseList(dynamic raw) {
      if (raw == null || raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((item) =>
              AstrologerBookingModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    final upcoming = parseList(data['upcoming']);
    final history = parseList(data['history']);

    final rawStats = data['stats'];
    final statsMap = rawStats is Map
        ? Map<String, dynamic>.from(rawStats)
        : <String, dynamic>{};

    final stats = DashboardStats.fromJson({
      'today_bookings': statsMap['today_bookings'] ?? 0,
      'yesterday_bookings': 0,
      'monthly_revenue': statsMap['monthly_revenue'] ?? 0,
      'last_month_revenue': 0,
      'completed_bookings': statsMap['completed_sessions'] ?? 0,
      'total_reviews': 0,
      'average_rating': 0,
    });

    return {
      'upcoming': upcoming,
      'history': history,
      'stats': stats,
    };
  }

  // =========================================================
  // MARK BOOKING COMPLETE
  // Route: POST /api/astrologer/bookings/{id}/complete  (auth)
  // =========================================================

  static Future<void> markComplete(int bookingId) async {
    final token = await AuthService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated.');
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/astrologer/bookings/$bookingId/complete'),
      headers: {
        ..._headers,
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 15));

    debugPrint('📦 markComplete → ${response.statusCode}: ${response.body}');

    if (response.statusCode == 401) {
      throw Exception('Session expired. Please log in again.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'Unable to complete booking (HTTP ${response.statusCode}).');
    }
  }

  // =========================================================
  // GET MY BOOKINGS (user side)
  // Route: GET /api/my-bookings  (auth)
  // =========================================================

  static Future<List<AstrologerBookingModel>> getMyBookings() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated.');
    }

    final data = await _get('/my-bookings', token: token);

    final List<dynamic> raw =
        data is List ? data : (data['bookings'] ?? data['data'] ?? []);

    return raw
        .whereType<Map>()
        .map((item) =>
            AstrologerBookingModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // =========================================================
  // GET BOOKING AVAILABILITY
  // Route: GET /api/bookings/availability  (public)
  // =========================================================

  static Future<Map<String, dynamic>> getAvailability({
    required int astrologerId,
    String? date,
  }) async {
    final query =
        StringBuffer('/bookings/availability?astrologer_id=$astrologerId');
    if (date != null) query.write('&date=$date');

    final data = await _get(query.toString());

    if (data is Map<String, dynamic>) return data;
    return {};
  }

  // =========================================================
  // STORE BOOKING
  // Route: POST /api/bookings  (auth)
  // =========================================================

  static Future<Map<String, dynamic>> storeBooking(
      Map<String, dynamic> payload) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Not authenticated.');
    }

    final data = await _post('/bookings', token: token, body: payload);

    if (data is Map<String, dynamic>) return data;
    return {};
  }

  // =========================================================
  // BOOKING SESSION – SHOW
  // Route: GET /api/bookings/{booking}/session  (auth)
  // =========================================================

  static Future<Map<String, dynamic>> getSession(int bookingId) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    final data = await _get('/bookings/$bookingId/session', token: token);
    return data is Map<String, dynamic> ? data : {};
  }

  // =========================================================
  // BOOKING SESSION – START
  // Route: POST /api/bookings/{booking}/session/start  (auth)
  // =========================================================

  static Future<Map<String, dynamic>> startSession(int bookingId) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    final data = await _post(
      '/bookings/$bookingId/session/start',
      token: token,
      body: {},
    );
    return data is Map<String, dynamic> ? data : {};
  }

  // =========================================================
  // BOOKING SESSION – END
  // Route: POST /api/bookings/{booking}/session/end  (auth)
  // =========================================================

  static Future<Map<String, dynamic>> endSession(int bookingId) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    final data = await _post(
      '/bookings/$bookingId/session/end',
      token: token,
      body: {},
    );
    return data is Map<String, dynamic> ? data : {};
  }

  // =========================================================
  // BOOKING SESSION – PING
  // Route: POST /api/bookings/{booking}/session/ping  (auth)
  // =========================================================

  static Future<void> pingSession(int bookingId) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    await _post('/bookings/$bookingId/session/ping', token: token, body: {});
  }

  // =========================================================
  // BOOKING SESSION – EXTEND
  // Route: POST /api/bookings/{booking}/session/extend  (auth)
  // =========================================================

  static Future<Map<String, dynamic>> extendSession(
      int bookingId, int extraMinutes) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    final data = await _post(
      '/bookings/$bookingId/session/extend',
      token: token,
      body: {'extra_minutes': extraMinutes},
    );
    return data is Map<String, dynamic> ? data : {};
  }

  // =========================================================
  // BOOKING MESSAGES – LIST
  // Route: GET /api/bookings/{booking}/messages  (auth)
  // =========================================================

  static Future<List<Map<String, dynamic>>> getMessages(int bookingId) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    final data = await _get('/bookings/$bookingId/messages', token: token);

    final List<dynamic> raw =
        data is List ? data : (data['messages'] ?? data['data'] ?? []);

    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // =========================================================
  // BOOKING MESSAGES – SEND
  // Route: POST /api/bookings/{booking}/messages  (auth)
  // =========================================================

  static Future<Map<String, dynamic>> sendMessage(
      int bookingId, Map<String, dynamic> payload) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    final data = await _post(
      '/bookings/$bookingId/messages',
      token: token,
      body: payload,
    );
    return data is Map<String, dynamic> ? data : {};
  }

  // =========================================================
  // SUBMIT REVIEW FOR ASTROLOGER
  // Route: POST /api/bookings/{booking}/review  (auth)
  // =========================================================

  static Future<Map<String, dynamic>> submitReview({
    required int bookingId,
    required int rating,
    String? comment,
  }) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    final data = await _post(
      '/bookings/$bookingId/review',
      token: token,
      body: {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
    return data is Map<String, dynamic> ? data : {};
  }

  // =========================================================
  // GET LIVE SESSION (current)
  // Route: GET /api/live-sessions/current  (public)
  // =========================================================

  static Future<Map<String, dynamic>> getCurrentLiveSession() async {
    final data = await _get('/live-sessions/current');
    return data is Map<String, dynamic> ? data : {};
  }

  // =========================================================
  // GET LIVE SESSION (viewer — auth)
  // Route: GET /api/live-sessions/current/viewer  (auth)
  // =========================================================

  static Future<Map<String, dynamic>> getLiveSessionViewer() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    final data = await _get('/live-sessions/current/viewer', token: token);
    return data is Map<String, dynamic> ? data : {};
  }

  // =========================================================
  // START LIVE SESSION
  // Route: POST /api/live-sessions/start  (auth — astrologer)
  // =========================================================

  static Future<Map<String, dynamic>> startLiveSession(
      Map<String, dynamic> payload) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    final data =
        await _post('/live-sessions/start', token: token, body: payload);
    return data is Map<String, dynamic> ? data : {};
  }

  // =========================================================
  // STOP LIVE SESSION
  // Route: POST /api/live-sessions/{liveSession}/stop  (auth)
  // =========================================================

  static Future<void> stopLiveSession(int liveSessionId) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    await _post(
      '/live-sessions/$liveSessionId/stop',
      token: token,
      body: {},
    );
  }

  // =========================================================
  // LIVE SESSION COMMENTS – LIST
  // Route: GET /api/live-sessions/{liveSession}/comments  (public)
  // =========================================================

  static Future<List<Map<String, dynamic>>> getLiveComments(
      int liveSessionId) async {
    final data = await _get('/live-sessions/$liveSessionId/comments');

    final List<dynamic> raw =
        data is List ? data : (data['comments'] ?? data['data'] ?? []);

    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // =========================================================
  // LIVE SESSION COMMENTS – POST
  // Route: POST /api/live-sessions/{liveSession}/comments  (auth)
  // =========================================================

  static Future<Map<String, dynamic>> postLiveComment(
      int liveSessionId, String comment) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    final data = await _post(
      '/live-sessions/$liveSessionId/comments',
      token: token,
      body: {'comment': comment},
    );
    return data is Map<String, dynamic> ? data : {};
  }

  // =========================================================
  // ASTROLOGER PROFILE UPDATE
  // Route: POST /api/astrologer/profile/update  (auth)
  // =========================================================

  static Future<Map<String, dynamic>> updateAstrologerProfile(
      Map<String, dynamic> payload) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    final data = await _post(
      '/astrologer/profile/update',
      token: token,
      body: payload,
    );
    return data is Map<String, dynamic> ? data : {};
  }

  // =========================================================
  // USER DASHBOARD – GET PROFILE
  // Route: GET /api/dashboard/profile  (auth)
  // =========================================================

  static Future<Map<String, dynamic>> getUserProfile() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    final data = await _get('/dashboard/profile', token: token);
    return data is Map<String, dynamic>
        ? (data['profile'] ?? data['data'] ?? data)
        : {};
  }

  // =========================================================
  // USER DASHBOARD – UPDATE PROFILE
  // Route: POST /api/dashboard/profile/update  (auth)
  // =========================================================

  static Future<Map<String, dynamic>> updateUserProfile(
      Map<String, dynamic> payload) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    final data = await _post(
      '/dashboard/profile/update',
      token: token,
      body: payload,
    );
    return data is Map<String, dynamic> ? data : {};
  }

  // =========================================================
  // USER DASHBOARD – GET ORDERS
  // Route: GET /api/dashboard/orders  (auth)
  // =========================================================

  static Future<List<Map<String, dynamic>>> getUserOrders() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    final data = await _get('/dashboard/orders', token: token);

    final List<dynamic> raw =
        data is List ? data : (data['orders'] ?? data['data'] ?? []);

    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // =========================================================
  // RITUAL BOOKINGS – MY LIST
  // Route: GET /api/my-ritual-bookings  (auth)
  // =========================================================

  static Future<List<Map<String, dynamic>>> getMyRitualBookings() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    final data = await _get('/my-ritual-bookings', token: token);

    final List<dynamic> raw =
        data is List ? data : (data['bookings'] ?? data['data'] ?? []);

    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // =========================================================
  // RITUAL BOOKINGS – BOOK A RITUAL
  // Route: POST /api/rituals/{ritual}/book  (auth)
  // =========================================================

  static Future<Map<String, dynamic>> bookRitual(
      int ritualId, Map<String, dynamic> payload) async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    final data = await _post(
      '/rituals/$ritualId/book',
      token: token,
      body: payload,
    );
    return data is Map<String, dynamic> ? data : {};
  }

  // =========================================================
  // MY SUBSCRIPTIONS
  // Route: GET /api/my-subscriptions  (auth)
  // =========================================================

  static Future<List<Map<String, dynamic>>> getMySubscriptions() async {
    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) throw Exception('Not authenticated.');

    final data = await _get('/my-subscriptions', token: token);

    final List<dynamic> raw =
        data is List ? data : (data['subscriptions'] ?? data['data'] ?? []);

    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  // =========================================================
  // SUBSCRIPTION PLANS (public)
  // Route: GET /api/subscriptions/plans
  // =========================================================

  static Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    final data = await _get('/subscriptions/plans');

    final List<dynamic> raw =
        data is List ? data : (data['plans'] ?? data['data'] ?? []);

    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
}
