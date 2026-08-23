class UserNotificationModel {
  final int id;
  final String surface;
  final String type;
  final String title;
  final String message;
  final String? actionUrl;
  final Map<String, dynamic> data;
  final DateTime? readAt;
  final DateTime? createdAt;

  const UserNotificationModel({
    required this.id,
    required this.surface,
    required this.type,
    required this.title,
    required this.message,
    required this.actionUrl,
    required this.data,
    required this.readAt,
    required this.createdAt,
  });

  bool get isUnread => readAt == null;

  factory UserNotificationModel.fromJson(Map<String, dynamic> json) {
    return UserNotificationModel(
      id: _asInt(json['id']),
      surface: json['surface']?.toString() ?? 'main',
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? 'AstroZura update',
      message: json['message']?.toString() ?? '',
      actionUrl: _nullableString(json['action_url']),
      data: _asMap(json['data']),
      readAt: _asDate(json['read_at']),
      createdAt: _asDate(json['created_at']),
    );
  }
}

class UserNotificationCollection {
  final List<UserNotificationModel> items;
  final int unreadCount;

  const UserNotificationCollection({
    required this.items,
    required this.unreadCount,
  });
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return text;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

DateTime? _asDate(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return DateTime.tryParse(text)?.toLocal();
}
