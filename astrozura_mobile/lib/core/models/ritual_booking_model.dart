class RitualBookingModel {
  final int id;
  final String reference;
  final String ritualName;
  final String scheduledDate;
  final String scheduledTime;
  final int? consultationBookingId;
  final double amount;
  final String status;
  final String paymentStatus;

  const RitualBookingModel({
    required this.id,
    required this.reference,
    required this.ritualName,
    required this.scheduledDate,
    required this.scheduledTime,
    this.consultationBookingId,
    required this.amount,
    required this.status,
    required this.paymentStatus,
  });

  factory RitualBookingModel.fromJson(Map<String, dynamic> json) {
    final ritual = json['ritual'] is Map
        ? Map<String, dynamic>.from(json['ritual'] as Map)
        : const <String, dynamic>{};
    return RitualBookingModel(
      id: _int(json['id']),
      reference: json['booking_reference']?.toString() ?? '',
      ritualName: ritual['name']?.toString() ??
          json['ritual_name']?.toString() ??
          'Pooja Anusthan',
      scheduledDate:
          (json['confirmed_date'] ?? json['preferred_date'])?.toString() ?? '',
      scheduledTime:
          (json['confirmed_time'] ?? json['preferred_time'])?.toString() ?? '',
      consultationBookingId: _optionalInt(
        json['consultation_booking_id'] ??
            json['consultation_booking']?['id'] ??
            json['booking']?['id'],
      ),
      amount: _double(json['amount']),
      status: json['status']?.toString() ?? 'pending',
      paymentStatus: json['payment_status']?.toString() ?? 'pending',
    );
  }

  static int _int(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  static int? _optionalInt(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }

  static double _double(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}
