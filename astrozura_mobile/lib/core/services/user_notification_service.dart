import '../contants/api_constants.dart';
import '../models/user_notification_model.dart';
import 'api_client.dart';

class UserNotificationService {
  UserNotificationService({ApiClient? api}) : _api = api ?? ApiClient();

  final ApiClient _api;

  Future<UserNotificationCollection> getNotifications({
    bool unreadOnly = false,
    int perPage = 50,
  }) async {
    final response = await _api.get(
      ApiConstants.notifications,
      auth: true,
      query: {
        'surface': 'main',
        'unread': unreadOnly ? '1' : '0',
        'per_page': perPage.toString(),
      },
    );

    final page = response['data'];
    final rawItems = page is Map ? page['data'] : page;
    final items = rawItems is List
        ? rawItems
            .whereType<Map>()
            .map((item) => UserNotificationModel.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList()
        : <UserNotificationModel>[];

    return UserNotificationCollection(
      items: items,
      unreadCount: _asInt(response['unread_count']),
    );
  }

  Future<void> markRead(int id) async {
    await _api.post(ApiConstants.notificationRead(id), auth: true);
  }

  Future<void> markAllRead() async {
    await _api.post(
      ApiConstants.notificationsReadAll,
      auth: true,
      body: const {'surface': 'main'},
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
