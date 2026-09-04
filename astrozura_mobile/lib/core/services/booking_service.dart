// lib/services/booking_service.dart
//
// Connects Flutter to Laravel BookingController & BookingSessionController.
//
// Endpoints used:
//   GET  /api/bookings/availability       → getAvailability()
//   POST /api/bookings                    → createBooking()
//   GET  /api/my-bookings                 → getMyBookings()
//   GET  /api/bookings/{id}/session       → getSession()
//   POST /api/bookings/{id}/session/start → startSession()
//   POST /api/bookings/{id}/session/end   → endSession()
//   POST /api/bookings/{id}/session/ping  → pingSession()

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../contants/api_constants.dart';

int _asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString()) ??
      double.tryParse(value.toString())?.round() ??
      fallback;
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final raw = value.toString().toLowerCase().trim();
  if (raw == 'true' || raw == '1' || raw == 'yes') return true;
  if (raw == 'false' || raw == '0' || raw == 'no') return false;
  return fallback;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

// ── Models ────────────────────────────────────────────────────────────────────

class SlotModel {
  final String label; // e.g. "10:00 AM"
  final String start; // ISO8601 string
  final String end; // ISO8601 string
  final bool isAvailable;

  SlotModel({
    required this.label,
    required this.start,
    required this.end,
    required this.isAvailable,
  });

  factory SlotModel.fromJson(Map<String, dynamic> json) {
    return SlotModel(
      label: json['label'] as String? ?? '',
      start: json['start'] as String? ?? '',
      end: json['end'] as String? ?? '',
      isAvailable: _asBool(json['is_available']),
    );
  }
}

class BookingModel {
  final int id;

  // Backend booking reference
  final String bookingReference;

  // Session room id from backend
  final String? sessionRoomId;

  final String consultationType;
  final int duration;

  final String bookingDate;
  final String bookingTime;

  final String scheduledAt;
  final String endsAt;

  final double amount;

  final String status;
  final String paymentStatus;

  final String astrologerName;

  final String? notes;

  final Map<String, dynamic>? birthDetails;

  BookingModel({
    required this.id,
    required this.bookingReference,
    required this.consultationType,
    required this.duration,
    required this.bookingDate,
    required this.bookingTime,
    required this.scheduledAt,
    required this.endsAt,
    required this.amount,
    required this.status,
    required this.paymentStatus,
    required this.astrologerName,
    this.notes,
    this.birthDetails,
    this.sessionRoomId,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: _asInt(json['id']),
      bookingReference: json['booking_reference']?.toString() ?? '',
      sessionRoomId: json['session_room_id']?.toString(),
      consultationType: json['consultation_type']?.toString() ?? 'chat',
      duration: _asInt(json['duration'], fallback: 15),
      bookingDate: json['booking_date']?.toString() ?? '',
      bookingTime: json['booking_time']?.toString() ?? '',
      scheduledAt: json['scheduled_at']?.toString() ?? '',
      endsAt: json['ends_at']?.toString() ?? '',
      amount: _asDouble(json['amount']),
      status: json['status']?.toString() ?? 'confirmed',
      paymentStatus: json['payment_status']?.toString() ?? 'paid',
      astrologerName: json['astrologer_name']?.toString() ?? '',
      notes: json['notes']?.toString(),
      birthDetails:
          json['birth_details'] == null ? null : _asMap(json['birth_details']),
    );
  }

  // Used by UI cards
  String get bookingId => bookingReference;
}

class SessionPayload {
  final String state; // 'scheduled' | 'ready' | 'live' | 'closed'
  final bool isLive;
  final bool canStart;
  final bool canJoin;
  final bool canEnd;
  final int remainingSeconds;
  final bool needsLowTimeWarning;
  final Map<String, dynamic> rooms;
  final Map<String, dynamic> viewer;
  final Map<String, dynamic> chat;
  final Map<String, dynamic>? zegoChat;
  final Map<String, dynamic>? zegoCall;

  SessionPayload({
    required this.state,
    required this.isLive,
    required this.canStart,
    required this.canJoin,
    required this.canEnd,
    required this.remainingSeconds,
    required this.needsLowTimeWarning,
    required this.rooms,
    required this.viewer,
    required this.chat,
    this.zegoChat,
    this.zegoCall,
  });

  factory SessionPayload.fromJson(Map<String, dynamic> json) {
    return SessionPayload(
      state: json['state']?.toString() ?? 'scheduled',
      isLive: _asBool(json['is_live']),
      canStart: _asBool(json['can_start']),
      canJoin: _asBool(json['can_join']),
      canEnd: _asBool(json['can_end']),
      remainingSeconds: _asInt(json['remaining_seconds']),
      needsLowTimeWarning: _asBool(json['needs_low_time_warning']),
      rooms: _asMap(json['rooms']),
      viewer: _asMap(json['viewer']),
      chat: _asMap(json['chat']),
      zegoChat: _asMap(json['zego'])['chat'] == null
          ? null
          : _asMap(_asMap(json['zego'])['chat']),
      zegoCall: _asMap(json['zego'])['call'] == null
          ? null
          : _asMap(_asMap(json['zego'])['call']),
    );
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class BookingService {
  // !! Replace with your actual base URL (no trailing slash)
  static String get _baseUrl => ApiConstants.baseUrl; // e.g. 'http://

  // ── Auth token ─────────────────────────────────────────────────────────────

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── GET /api/bookings/availability ─────────────────────────────────────────
  // Returns:
  //   {
  //     'slots': List<SlotModel>,       // all slots (including unavailable)
  //     'amount': double,               // total cost for selected duration
  //     'ratePerMinute': double,
  //     'timezone': String,
  //   }
  static Future<Map<String, dynamic>> getAvailability({
    required int astrologerId,
    required String consultationType, // 'chat' | 'call'
    required int duration, // must be in [10, 15, 20, 30]
    required String bookingDate, // 'YYYY-MM-DD'
  }) async {
    final uri = Uri.parse('$_baseUrl/bookings/availability').replace(
      queryParameters: {
        'astrologer_id': astrologerId.toString(),
        'consultation_type': consultationType,
        'duration': duration.toString(),
        'booking_date': bookingDate,
      },
    );

    final response = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && body['success'] == true) {
      final rawSlots = (body['slots'] as List<dynamic>?) ?? [];
      final slots = rawSlots
          .map((s) => SlotModel.fromJson(s as Map<String, dynamic>))
          .toList();

      return {
        'slots': slots,
        'amount': double.tryParse(body['amount'].toString()) ?? 0.0,
        'ratePerMinute':
            double.tryParse(body['rate_per_minute'].toString()) ?? 0.0,
        'timezone': body['timezone'] as String? ?? 'Asia/Kolkata',
      };
    }

    // Backend validation errors come in body['errors'] or body['message']
    final message = _extractError(body, response.statusCode);
    throw Exception(message);
  }

  // ── POST /api/bookings ─────────────────────────────────────────────────────
  // Requires auth. Creates a booking and returns BookingModel.
  //
  // birthDetails (optional):
  //   { date_of_birth, time_of_birth, place_of_birth, gender }
  static Future<BookingModel> createBooking({
    required int astrologerId,
    required String consultationType,
    required int duration,
    required String bookingDate, // 'YYYY-MM-DD'
    required String bookingTime, // 'HH:MM' or 'g:i A' — backend handles both
    String? notes,
    Map<String, dynamic>? birthDetails,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('Please log in to book a consultation.');
    }

    // FIX: was `'birth_details': ?birthDetails` — invalid Dart syntax.
    // Use a conditional entry instead.
    final payload = <String, dynamic>{
      'astrologer_id': astrologerId,
      'consultation_type': consultationType,
      'duration': duration,
      'booking_date': bookingDate,
      'booking_time': bookingTime,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'birth_details': birthDetails,
    };

    final response = await http
        .post(
          Uri.parse('$_baseUrl/bookings'),
          headers: _headers(token: token),
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        body['success'] == true) {
      return BookingModel.fromJson(body['booking'] as Map<String, dynamic>);
    }

    throw Exception(_extractError(body, response.statusCode));
  }

  // ── GET /api/astrologer/bookings ──────────────────────────────────────────
  // For astrologer-role users: fetch their incoming bookings from users.
  // Returns upcoming and history lists.
  static Future<Map<String, List<BookingModel>>> getAstrologerBookings() async {
    final token = await _getToken();
    if (token == null) throw Exception('Please log in to view bookings.');

    final response = await http
        .get(
          Uri.parse('$_baseUrl/astrologer/bookings'),
          headers: _headers(token: token),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      throw Exception('Session expired. Please log in again.');
    }
    if (response.statusCode == 403) {
      throw Exception('Access denied. Astrologer role required.');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && body['success'] == true) {
      List<BookingModel> parseList(dynamic raw) {
        if (raw == null) return [];
        return (raw as List<dynamic>)
            .map((b) => BookingModel.fromJson(b as Map<String, dynamic>))
            .toList();
      }

      return {
        'upcoming': parseList(body['upcoming']),
        'history': parseList(body['history']),
      };
    }

    throw Exception(_extractError(body, response.statusCode));
  }

  // ── GET /api/my-bookings ──────────────────────────────────────────────────
  // Returns upcoming and history lists.
  static Future<Map<String, List<BookingModel>>> getMyBookings() async {
    final token = await _getToken();
    if (token == null) throw Exception('Please log in to view bookings.');

    final response = await http
        .get(
          Uri.parse('$_baseUrl/my-bookings'),
          headers: _headers(token: token),
        )
        .timeout(const Duration(seconds: 8));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && body['success'] == true) {
      List<BookingModel> parseList(dynamic raw) {
        if (raw == null) return [];
        return (raw as List<dynamic>)
            .map((b) => BookingModel.fromJson(b as Map<String, dynamic>))
            .toList();
      }

      return {
        'upcoming': parseList(body['upcoming']),
        'history': parseList(body['history']),
      };
    }

    throw Exception(_extractError(body, response.statusCode));
  }

  // ── GET /api/bookings/{id}/session ────────────────────────────────────────
  static Future<Map<String, dynamic>> getSession(int bookingId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated.');

    final response = await http
        .get(
          Uri.parse('$_baseUrl/bookings/$bookingId/session'),
          headers: _headers(token: token),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && body['success'] == true) {
      return {
        'booking':
            BookingModel.fromJson(body['booking'] as Map<String, dynamic>),
        'session':
            SessionPayload.fromJson(body['session'] as Map<String, dynamic>),
      };
    }

    throw Exception(_extractError(body, response.statusCode));
  }

  // ── POST /api/bookings/{id}/session/start ─────────────────────────────────
  static Future<Map<String, dynamic>> startSession(int bookingId) async {
    return _sessionAction(bookingId, 'start');
  }

  // ── POST /api/bookings/{id}/session/end ──────────────────────────────────
  static Future<Map<String, dynamic>> endSession(int bookingId) async {
    return _sessionAction(bookingId, 'end');
  }

  // ── POST /api/bookings/{id}/session/ping ─────────────────────────────────
  static Future<void> pingSession(int bookingId) async {
    final token = await _getToken();
    if (token == null) return;

    await http
        .post(
          Uri.parse('$_baseUrl/bookings/$bookingId/session/ping'),
          headers: _headers(token: token),
        )
        .timeout(const Duration(seconds: 10));
  }

  // ── Shared session action helper ──────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getMessages(int bookingId) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated.');

    final response = await http
        .get(
          Uri.parse('$_baseUrl/bookings/$bookingId/messages'),
          headers: _headers(token: token),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && body['success'] == true) {
      final messages = (body['messages'] as List<dynamic>?) ?? [];
      return messages
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    throw Exception(_extractError(body, response.statusCode));
  }

  static Future<Map<String, dynamic>> sendTextMessage(
    int bookingId,
    String text,
  ) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated.');

    final response = await http
        .post(
          Uri.parse('$_baseUrl/bookings/$bookingId/messages'),
          headers: _headers(token: token),
          body: jsonEncode({
            'message_type': 'text',
            'text': text,
            'client_uuid': DateTime.now().microsecondsSinceEpoch.toString(),
            'sent_at': DateTime.now().toIso8601String(),
          }),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        body['success'] == true) {
      return Map<String, dynamic>.from(body['message'] as Map);
    }

    throw Exception(_extractError(body, response.statusCode));
  }

  static Future<Map<String, dynamic>> uploadChatAttachment({
    required String filePath,
    required String fileName,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated.');

    final request =
        http.MultipartRequest('POST', Uri.parse(ApiConstants.chatAttachment))
          ..headers.addAll({
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          })
          ..files.add(await http.MultipartFile.fromPath(
            'attachment',
            filePath,
            filename: fileName,
          ));

    final streamed = await request.send().timeout(const Duration(seconds: 45));
    final response = await http.Response.fromStream(streamed);
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        body['success'] == true) {
      final upload = body['attachment'] ?? body['file'] ?? body['data'] ?? body;
      return Map<String, dynamic>.from(upload as Map);
    }

    throw Exception(_extractError(body, response.statusCode));
  }

  static Future<Map<String, dynamic>> sendAttachmentMessage({
    required int bookingId,
    required String messageType,
    required Map<String, dynamic> attachment,
  }) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated.');

    final mediaUrl = attachment['media_url'] ??
        attachment['url'] ??
        attachment['path'] ??
        attachment['file_url'];
    if (mediaUrl == null || mediaUrl.toString().isEmpty) {
      throw Exception('Attachment upload response was invalid.');
    }

    final response = await http
        .post(
          Uri.parse(ApiConstants.sendBookingMessage(bookingId)),
          headers: _headers(token: token),
          body: jsonEncode({
            'message_type': messageType,
            'media_url': mediaUrl.toString(),
            'attachment_name': attachment['name']?.toString() ??
                attachment['file_name']?.toString(),
            'attachment_mime': attachment['mime_type']?.toString() ??
                attachment['mime']?.toString(),
            'attachment_size': attachment['size'],
            'client_uuid': DateTime.now().microsecondsSinceEpoch.toString(),
            'sent_at': DateTime.now().toIso8601String(),
          }),
        )
        .timeout(const Duration(seconds: 20));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        body['success'] == true) {
      return Map<String, dynamic>.from(body['message'] as Map);
    }

    throw Exception(_extractError(body, response.statusCode));
  }

  static Future<void> markMessagesRead(int bookingId) async {
    final token = await _getToken();
    if (token == null) return;
    await http
        .post(
          Uri.parse(ApiConstants.bookingMessagesRead(bookingId)),
          headers: _headers(token: token),
        )
        .timeout(const Duration(seconds: 8));
  }

  static Future<void> sendTyping(int bookingId, bool isTyping) async {
    final token = await _getToken();
    if (token == null) return;
    await http
        .post(
          Uri.parse(ApiConstants.bookingTyping(bookingId)),
          headers: _headers(token: token),
          body: jsonEncode({'is_typing': isTyping}),
        )
        .timeout(const Duration(seconds: 8));
  }

  static Future<Map<String, dynamic>> getTypingStatus(int bookingId) async {
    final token = await _getToken();
    if (token == null) return {};
    final response = await http
        .get(
          Uri.parse(ApiConstants.bookingTypingStatus(bookingId)),
          headers: _headers(token: token),
        )
        .timeout(const Duration(seconds: 8));
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200 && body['success'] == true) {
      return body;
    }
    return {};
  }

  static Future<Map<String, dynamic>> _sessionAction(
      int bookingId, String action) async {
    final token = await _getToken();
    if (token == null) throw Exception('Not authenticated.');

    final response = await http
        .post(
          Uri.parse(
              '$_baseUrl/bookings/$bookingId/session/$action'), // astrologer uses /astrologer/bookings/{id}/complete instead
          headers: _headers(token: token),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 && body['success'] == true) {
      return {
        'booking':
            BookingModel.fromJson(body['booking'] as Map<String, dynamic>),
        'session':
            SessionPayload.fromJson(body['session'] as Map<String, dynamic>),
      };
    }

    throw Exception(_extractError(body, response.statusCode));
  }

  // ── Error helper ──────────────────────────────────────────────────────────
  static String _extractError(Map<String, dynamic> body, int statusCode) {
    if (body.containsKey('message')) {
      return body['message'] as String;
    }
    if (body.containsKey('errors')) {
      final errors = body['errors'] as Map<String, dynamic>;
      return errors.values
          .expand(
              (v) => v is List ? v.map((e) => e.toString()) : [v.toString()])
          .join(', ');
    }
    return 'Request failed (HTTP $statusCode)';
  }
}
