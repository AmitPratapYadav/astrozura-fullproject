import '../contants/api_constants.dart';
import '../models/ritual_booking_model.dart';
import 'api_client.dart';

class RitualBookingCollection {
  final List<RitualBookingModel> upcoming;
  final List<RitualBookingModel> history;

  const RitualBookingCollection({
    required this.upcoming,
    required this.history,
  });
}

class RitualBookingService {
  RitualBookingService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<RitualBookingCollection> getMine() async {
    final response = await _api.get(
      ApiConstants.myRitualBookings,
      auth: true,
    );
    return RitualBookingCollection(
      upcoming: _parse(response['upcoming']),
      history: _parse(response['history']),
    );
  }

  List<RitualBookingModel> _parse(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => RitualBookingModel.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }
}
