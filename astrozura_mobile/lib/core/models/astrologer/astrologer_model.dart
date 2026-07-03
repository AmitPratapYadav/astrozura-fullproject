// lib/models/astrologer/astrologer_model.dart
import '../../contants/api_constants.dart';
//
// Laravel GET /api/astrologers returns:
// {
//   "success": true,
//   "astrologers": [
//     {
//       "id": 1,
//       "name": "Pandit Sharma",        ← on User model
//       "email": "...",
//       "astrologer_detail": {          ← NESTED relation
//         "user_id": 1,
//         "experience_years": 10,
//         "languages": "Hindi, English",
//         "specialities": "Vedic, Tarot",
//         "about_bio": "...",
//         "chat_price": "200.00",
//         "call_price": "300.00",
//         "rating": "4.5",
//         "total_reviews": 120,
//         "profile_image": "astrologers/abc.jpg",
//         "is_featured": true
//       }
//     }
//   ]
// }

class ConsultationPlan {
  final int duration; // minutes
  final double price;
  final String type; // 'chat' or 'call'

  const ConsultationPlan({
    required this.duration,
    required this.price,
    required this.type,
  });
}

class AstrologerReview {
  final String userName;
  final double rating;
  final String comment;

  const AstrologerReview({
    required this.userName,
    required this.rating,
    required this.comment,
  });
}

class AstrologerModel {
  // ── From User table ───────────────────────────────────────────────────────
  final int id;
  final String name;
  final String? email;

  final double rating;
  final int totalReviews;

  // ── From AstrologerDetail table (nested) ──────────────────────────────────
  final int experienceYears;
  final String languages;
  final String specialities;
  final String aboutBio;
  final double chatPrice;
  final double callPrice;

  final String profileImage;
  final bool isFeatured;
  final List<AstrologerReview> receivedReviews;

  const AstrologerModel({
    required this.id,
    required this.name,
    this.email,
    this.experienceYears = 0,
    this.languages = '',
    this.specialities = '',
    this.aboutBio = '',
    this.chatPrice = 0,
    this.callPrice = 0,
    this.rating = 0,
    this.totalReviews = 0,
    this.profileImage = '',
    this.isFeatured = false,
    this.receivedReviews = const [],
  });

  // ── Safe parsers ──────────────────────────────────────────────────────────

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  // ── fromJson ──────────────────────────────────────────────────────────────
  factory AstrologerModel.fromJson(Map<String, dynamic> json) {
    // Laravel returns astrologer_detail as a nested object
    // But also handle flat shape (just in case)
    final detail = json['astrologer_detail'] as Map<String, dynamic>?;

    // Image URL helper — handle both absolute and relative paths
    String resolveImage(String? raw) {
      if (raw == null || raw.isEmpty) return '';
      if (raw.startsWith('http')) return raw;
      return ApiConstants.storageUrl(raw);
    }

    return AstrologerModel(
      // ── User fields ───────────────────────────────────────────
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? 'Astrologer ${json['id']}',
      email: json['email']?.toString(),

      // ── Detail fields — prefer nested, fall back to flat ──────
      experienceYears:
          _toInt(detail?['experience_years'] ?? json['experience_years']),
      languages: (detail?['languages'] ?? json['languages'] ?? '').toString(),
      specialities:
          (detail?['specialities'] ?? json['specialities'] ?? '').toString(),
      aboutBio: (detail?['about_bio'] ?? json['about_bio'] ?? '').toString(),
      chatPrice: _toDouble(detail?['chat_price'] ?? json['chat_price']),
      callPrice: _toDouble(detail?['call_price'] ?? json['call_price']),
      rating: _toDouble(detail?['rating'] ?? json['rating']),
      totalReviews: _toInt(detail?['total_reviews'] ?? json['total_reviews']),
      profileImage: resolveImage(
        (detail?['profile_image'] ?? json['profile_image'])?.toString(),
      ),
      isFeatured: detail?['is_featured'] == true ||
          detail?['is_featured'] == 1 ||
          json['is_featured'] == true ||
          json['is_featured'] == 1,
      receivedReviews: (json['received_reviews'] is List
              ? json['received_reviews'] as List
              : const [])
          .whereType<Map>()
          .map(
            (review) => AstrologerReview(
              userName: review['user'] is Map
                  ? (review['user']['name']?.toString() ?? 'User')
                  : 'User',
              rating: _toDouble(review['rating']),
              comment: review['comment']?.toString() ?? '',
            ),
          )
          .toList(),
    );
  }

  // ── Convenience getters ───────────────────────────────────────────────────

  /// Split comma-separated specialities into a clean list
  List<String> get specialityList => specialities
      .split(',')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  /// Split comma-separated languages into a clean list
  List<String> get languageList => languages
      .split(',')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  /// Used by old widgets that reference astrologer.categories
  List<String> get categories => specialityList;

  /// Full image URL (already resolved in fromJson)
  String get fullImageUrl => profileImage;

  /// Consultation plans derived from chat/call price × duration
  List<ConsultationPlan> get consultationPlans => [
        ConsultationPlan(duration: 10, price: chatPrice * 10, type: 'chat'),
        ConsultationPlan(duration: 15, price: chatPrice * 15, type: 'chat'),
        ConsultationPlan(duration: 20, price: chatPrice * 20, type: 'chat'),
        ConsultationPlan(duration: 30, price: chatPrice * 30, type: 'chat'),
      ];

  /// Placeholder reviews — replace when API has reviews endpoint
  List<AstrologerReview> get reviewsList => receivedReviews;

  /// Legacy getters used by existing widgets
  List<Map<String, dynamic>> get plans => consultationPlans
      .map((p) => {
            'duration': p.duration,
            'price': p.price.toInt(),
            'type': p.type,
          })
      .toList();

  String get fullDescription =>
      aboutBio.isNotEmpty ? aboutBio : 'No description available.';
}
