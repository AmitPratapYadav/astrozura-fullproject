// lib/models/astrologer/astrologer_booking_model.dart

class AstrologerBookingModel {
  final int id;
  final String bookingId;
  final String userName;
  final String userImage;
  final String userEmail;
  final String serviceName;
  final String bookingDate;
  final String bookingTime;
  final String status;
  final String consultationType;
  final int duration;
  final double amount;
  final String? notes;

  AstrologerBookingModel({
    required this.id,
    required this.bookingId,
    required this.userName,
    required this.userImage,
    required this.userEmail,
    required this.serviceName,
    required this.bookingDate,
    required this.bookingTime,
    required this.status,
    required this.consultationType,
    required this.duration,
    required this.amount,
    this.notes,
  });

  factory AstrologerBookingModel.fromJson(Map<String, dynamic> json) {
    // Derive a human-readable service name from consultation_type + duration
    final type = json['consultation_type']?.toString() ?? 'chat';
    final dur = int.tryParse(json['duration'].toString()) ?? 0;
    final rawService = json['service_name']?.toString() ?? '';
    final serviceName = rawService.isNotEmpty
        ? rawService
        : _buildServiceName(type, dur);

    // Prefer booking_reference (from BookingController) over booking_id
    final bookingRef =
        json['booking_reference']?.toString() ??
        json['bookingReference']?.toString() ??
        json['booking_id']?.toString() ??
        '';

    return AstrologerBookingModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      bookingId: bookingRef,
      userName: json['user_name']?.toString() ?? '',
      userImage: json['user_image']?.toString() ??
          json['user']?['profile_image']?.toString() ??
          '',
      userEmail: json['user_email']?.toString() ??
          json['user']?['email']?.toString() ??
          '',
      serviceName: serviceName,
      bookingDate: json['booking_date']?.toString() ?? '',
      bookingTime: json['booking_time']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      consultationType: type,
      duration: dur,
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      notes: json['notes']?.toString(),
    );
  }

  static String _buildServiceName(String type, int duration) {
    final label = type == 'call' ? 'Call Consultation' : 'Chat Consultation';
    return duration > 0 ? '$label for $duration mins' : label;
  }
}