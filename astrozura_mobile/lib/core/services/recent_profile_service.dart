import '../contants/api_constants.dart';
import 'api_client.dart';

class RecentProfileService {
  RecentProfileService({ApiClient? apiClient})
      : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> list({String? relationRole}) async {
    final query = <String, String>{};
    if (relationRole != null && relationRole.trim().isNotEmpty) {
      query['relation_role'] = relationRole.trim();
    }

    final response = await _api.get(
      ApiConstants.recentProfiles,
      query: query,
      auth: true,
    );
    final raw = response['data'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> store(Map<String, dynamic> payload) {
    return _api.post(ApiConstants.recentProfiles, body: payload, auth: true);
  }

  Future<Map<String, dynamic>> update(int id, Map<String, dynamic> payload) {
    return _api.put(ApiConstants.recentProfile(id), body: payload, auth: true);
  }
}
