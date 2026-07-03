class PujaItem {
  final String id;
  final String slug;
  final String title;
  final String tag;
  final String tagColor;
  final String aacharyaName;
  final double rating;
  final int price;
  final int originalPrice;
  final String imageAsset;
  final String shortDescription;
  final String description;
  final String benefits;
  final String idealTiming;
  final String durationLabel;
  final String mode;
  final List<String> steps;
  final List<String> materials;
  final List<Map<String, String>> faqs;

  const PujaItem({
    required this.id,
    this.slug = '',
    required this.title,
    required this.tag,
    required this.tagColor,
    required this.aacharyaName,
    required this.rating,
    required this.price,
    required this.originalPrice,
    required this.imageAsset,
    this.shortDescription = '',
    this.description = '',
    this.benefits = '',
    this.idealTiming = '',
    this.durationLabel = '',
    this.mode = '',
    this.steps = const [],
    this.materials = const [],
    this.faqs = const [],
  });

  factory PujaItem.fromJson(Map<String, dynamic> json) {
    final price = _toInt(json['price']);
    final originalPrice =
        _toInt(json['original_price'] ?? json['mrp'] ?? json['price']);
    final assigned = json['assigned_astrologer'];
    final detail = assigned is Map ? assigned['astrologer_detail'] : null;

    return PujaItem(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      title: json['name']?.toString() ?? json['title']?.toString() ?? '',
      tag: _firstNonEmpty([
        json['category'],
        json['service_type'],
      ]),
      tagColor: _tagColor(json['category']?.toString()),
      aacharyaName: assigned is Map ? assigned['name']?.toString() ?? '' : '',
      rating: _toDouble(detail is Map ? detail['rating'] : json['rating']),
      price: price,
      originalPrice: originalPrice > price ? originalPrice : price,
      imageAsset: json['image']?.toString() ?? '',
      shortDescription: json['short_description']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      benefits: json['benefits']?.toString() ?? '',
      idealTiming: json['ideal_timing']?.toString() ?? '',
      durationLabel: json['duration_label']?.toString() ?? '',
      mode: json['mode']?.toString() ?? '',
      steps: _stringList(json['steps']),
      materials: _stringList(json['materials']),
      faqs: _faqList(json['faqs']),
    );
  }
}

String _firstNonEmpty(List<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty) return text;
  }
  return 'Pooja';
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return double.tryParse(value?.toString() ?? '')?.round() ?? 0;
}

double _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
}

List<Map<String, String>> _faqList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<Map>().map((item) {
    return {
      'question': item['question']?.toString() ?? '',
      'answer': item['answer']?.toString() ?? '',
    };
  }).where((item) {
    return item['question']!.isNotEmpty || item['answer']!.isNotEmpty;
  }).toList();
}

String _tagColor(String? category) {
  final raw = category?.toLowerCase() ?? '';
  if (raw.contains('health')) return '#4CAF50';
  if (raw.contains('education') || raw.contains('growth')) return '#2196F3';
  if (raw.contains('protection') || raw.contains('victory')) return '#607D8B';
  if (raw.contains('prosperity') || raw.contains('wealth')) return '#FF5722';
  if (raw.contains('beginning')) return '#FF9800';
  return '#D4A84F';
}
