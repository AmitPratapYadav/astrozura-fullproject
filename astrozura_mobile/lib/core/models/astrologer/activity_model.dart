class ActivityModel {

  final String title;
  final String time;
  final String type;

  ActivityModel({
    required this.title,
    required this.time,
    required this.type,
  });

  factory ActivityModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return ActivityModel(
      title: json['title'] ?? '',
      time: json['time'] ?? '',
      type: json['type'] ?? 'general',
    );
  }
}