import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String _defaultBaseUrl =
      'https://astrozura.com/apigateway/index.php/api';
  static const String _defaultWebBaseUrl = 'https://astrozura.com';
  static const String developmentBaseUrl = 'http://192.168.1.3:8000/api';

  static const String _baseUrlOverride = String.fromEnvironment(
    'ASTROZURA_API_BASE_URL',
    defaultValue: '',
  );
  static const String _webBaseUrlOverride = String.fromEnvironment(
    'ASTROZURA_WEB_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    final override = _baseUrlOverride.trim();
    if (override.isNotEmpty) return _withoutTrailingSlash(override);
    return _defaultBaseUrl;
  }

  static String get webBaseUrl {
    final override = _webBaseUrlOverride.trim();
    if (override.isNotEmpty) return _withoutTrailingSlash(override);
    return _defaultWebBaseUrl;
  }

  static String storageUrl(String path) {
    final raw = path.trim();
    if (raw.isEmpty) return raw;
    if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
    if (raw.startsWith('//')) return 'https:$raw';

    final normalized = raw.startsWith('/') ? raw : '/$raw';
    if (normalized.startsWith('/uploads/') ||
        normalized.startsWith('/storage/')) {
      return '$webBaseUrl$normalized';
    }
    final relative = normalized.substring(1);
    return '$webBaseUrl/storage/$relative';
  }

  static String _withoutTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static String endpoint(String path) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    return '$baseUrl/$normalized';
  }

  static String get sendOtp => endpoint('send-otp');
  static String get login => endpoint('login');
  static String get register => endpoint('register');
  static String get loginPassword => endpoint('login-password');
  static String get astrologerLogin => endpoint('astrologer/login');
  static String get adminLogin => endpoint('admin/login');
  static String get googleMobileAuth => endpoint('auth/google/mobile');
  static String get googleAuth => endpoint('auth/google');
  static String get getUser => endpoint('user');
  static String get logout => endpoint('logout');

  static String get getProfile => endpoint('dashboard/profile');
  static String get updateProfile => endpoint('dashboard/profile/update');
  static String get recentProfiles => endpoint('dashboard/recent-profiles');
  static String recentProfile(int id) =>
      endpoint('dashboard/recent-profiles/$id');
  static String get getOrders => endpoint('dashboard/orders');
  static String get storeOrder => endpoint('dashboard/orders/store');
  static String orderDetail(int id) => endpoint('dashboard/orders/$id');
  static String get getWishlist => endpoint('dashboard/wishlist');
  static String get toggleWishlist => endpoint('dashboard/wishlist/toggle');
  static String get notifications => endpoint('notifications');
  static String notificationRead(int id) => endpoint('notifications/$id/read');
  static String get notificationsReadAll => endpoint('notifications/read-all');

  static String get getAstrologers => endpoint('astrologers');
  static String astrologerProfile(int id) => endpoint('astrologer/$id');
  static String get updateAstrologerProfile =>
      endpoint('astrologer/profile/update');

  static String get createBooking => endpoint('bookings');
  static String get myBookings => endpoint('my-bookings');
  static String get bookingAvailability => endpoint('bookings/availability');
  static String bookingReview(int bookingId) =>
      endpoint('bookings/$bookingId/review');
  static String bookingSession(int id) => endpoint('bookings/$id/session');
  static String bookingSessionStart(int id) =>
      endpoint('bookings/$id/session/start');
  static String bookingSessionEnd(int id) =>
      endpoint('bookings/$id/session/end');
  static String bookingSessionPing(int id) =>
      endpoint('bookings/$id/session/ping');
  static String bookingSessionExtend(int id) =>
      endpoint('bookings/$id/session/extend');
  static String bookingMessages(int id) => endpoint('bookings/$id/messages');
  static String sendBookingMessage(int id) => endpoint('bookings/$id/messages');
  static String get chatAttachment => endpoint('media/chat-attachment');
  static String bookingTyping(int id) => endpoint('bookings/$id/typing');
  static String bookingTypingStatus(int id) =>
      endpoint('bookings/$id/typing-status');
  static String bookingMessagesRead(int id) =>
      endpoint('bookings/$id/messages/read');

  static String get getProducts => endpoint('ecomm/products');
  static String productDetail(int id) => endpoint('ecomm/products/$id');
  static String get getTrendingProducts => endpoint('ecomm/products/trending');
  static String get getCategories => endpoint('ecomm/categories');

  static String get razorpayConfig => endpoint('payments/razorpay/config');
  static String get razorpayOrder => endpoint('payments/razorpay/order');
  static String get razorpayVerify => endpoint('payments/razorpay/verify');

  static String dailyHoroscope(String sign) =>
      endpoint('prokerala/horoscope/$sign');
  static String weeklyHoroscope(String sign) =>
      endpoint('prokerala/horoscope-weekly/$sign');
  static String monthlyHoroscope(String sign) =>
      endpoint('prokerala/horoscope-monthly/$sign');
  static String get generateKundli => endpoint('prokerala/kundli');
  static String kundliDetailSection(String section) =>
      endpoint('prokerala/kundli/detail-section/$section');
  static String get freeKundliPdf => endpoint('prokerala/kundli/free-pdf');
  static String get getPanchang => endpoint('prokerala/panchang');
  static String get panchangExtras => endpoint('prokerala/panchang/extras');
  static String get matchMaking => endpoint('prokerala/matching');
  static String get matchMakingPdf => endpoint('prokerala/matching/pdf');
  static String get locationSearch => endpoint('prokerala/location/search');
  static String get divisionalCharts => endpoint('prokerala/divisional-charts');
  static String get predictions => endpoint('prokerala/predictions');
  static String vedicCalculator(String calculator) =>
      endpoint('prokerala/vedic-calculators/$calculator');
  static String matchingCalculator(String calculator) =>
      endpoint('prokerala/matching-calculators/$calculator');
  static String get numerology => endpoint('prokerala/numerology');
  static String get sadesati => endpoint('prokerala/sadesati');
  static String get lalKitab => endpoint('prokerala/lal-kitab');
  static String get tarot => endpoint('prokerala/tarot');

  static String get getRituals => endpoint('rituals?per_page=100');
  static String ritualDetail(String slug) => endpoint('rituals/$slug');
  static String ritualBook(String slugOrId) =>
      endpoint('rituals/$slugOrId/book');
  static String get myRitualBookings => endpoint('my-ritual-bookings');
  static String get blogs => endpoint('blogs');
  static String blog(String slug) => endpoint('blogs/$slug');

  static void debugPrintBaseUrl() {
    if (kDebugMode) debugPrint('Astrozura API base URL: $baseUrl');
  }
}
