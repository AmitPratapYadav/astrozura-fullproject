import 'package:flutter/material.dart';

import '../../../core/contants/api_constants.dart';
import '../../../core/models/app_content_catalog.dart';
import '../../../core/services/api_client.dart';
import '../../main_navigation.dart';
import '../../mainwidgets/header.dart';

class LiveHoroscopeScreen extends StatefulWidget {
  final String initialSign;

  const LiveHoroscopeScreen({super.key, this.initialSign = 'aries'});

  @override
  State<LiveHoroscopeScreen> createState() => _LiveHoroscopeScreenState();
}

class _LiveHoroscopeScreenState extends State<LiveHoroscopeScreen> {
  final ApiClient _api = ApiClient();
  late String _sign;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _sign = zodiacSigns.any(
      (sign) => sign.key == widget.initialSign.toLowerCase(),
    )
        ? widget.initialSign.toLowerCase()
        : 'aries';
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final response = await _api.get(ApiConstants.dailyHoroscope(_sign));
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (response['status'] == 'success') {
          _result = response;
        } else {
          _error =
              response['message']?.toString() ?? 'Horoscope is unavailable.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: _goBack,
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                        const Expanded(
                          child: Text(
                            'Daily Horoscope',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E3557),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 104,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: zodiacSigns.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final sign = zodiacSigns[index];
                          final selected = sign.key == _sign;
                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              setState(() => _sign = sign.key);
                              _load();
                            },
                            child: Container(
                              width: 78,
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFFE8E6FF)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selected
                                      ? const Color(0xFF8B88E6)
                                      : const Color(0xFFE6E6E6),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: Image.asset(
                                      sign.assetPath,
                                    ),
                                  ),
                                  Text(
                                    sign.name,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      _ErrorCard(message: _error!, onRetry: _load)
                    else if (_result != null)
                      _HoroscopeResult(
                        response: _result!,
                        sign: zodiacSigns.firstWhere(
                          (item) => item.key == _sign,
                          orElse: () => zodiacSigns.first,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goBack() {
    MainNavigationState.returnHome(context);
  }
}

class _HoroscopeResult extends StatelessWidget {
  final Map<String, dynamic> response;
  final ZodiacSignInfo sign;

  const _HoroscopeResult({required this.response, required this.sign});

  @override
  Widget build(BuildContext context) {
    final payload = _payload(response);
    final prediction = _predictionMap(payload);
    final date = _text(
      payload['prediction_date'] ??
          payload['date'] ??
          payload['horoscope_date'] ??
          payload['daily_date'],
      fallback: _todayLabel(),
    );
    final status = _text(payload['status'], fallback: 'Daily Reading');

    return Column(
      children: [
        _topCard(date: date, status: status),
        const SizedBox(height: 14),
        if (prediction.isEmpty)
          _predictionCard(
            title: 'Forecast',
            value: _text(
              payload['prediction'] ??
                  payload['bot_response'] ??
                  payload['response'] ??
                  payload['description'],
              fallback: 'Horoscope guidance is unavailable right now.',
            ),
            icon: Icons.auto_awesome,
            tone: _toneFor('forecast'),
          )
        else
          ...prediction.entries.map((entry) {
            return _predictionCard(
              title: _titleize(entry.key),
              value: _text(entry.value, fallback: '-'),
              icon: _iconFor(entry.key),
              tone: _toneFor(entry.key),
            );
          }),
      ],
    );
  }

  Widget _topCard({required String date, required String status}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8D7A7)),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8D7A7)),
            ),
            child: Image.asset(sign.assetPath),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${sign.name} Horoscope',
                  style: const TextStyle(
                    color: Color(0xFF1E3557),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sign.vedicName,
                  style: const TextStyle(
                    color: Color(0xFFD4A017),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _pill(Icons.calendar_today_outlined, date),
                    _pill(Icons.check_circle_outline, status),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _predictionCard({
    required String title,
    required String value,
    required IconData icon,
    required _HoroscopeTone tone,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tone.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tone.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: tone.iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: tone.icon, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1E3557),
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _stripHtml(value),
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  static _HoroscopeTone _toneFor(String key) {
    final lower = key.toLowerCase();
    if (lower.contains('health')) {
      return const _HoroscopeTone(
        background: Color(0xFFEAF8F0),
        border: Color(0xFFBFE6CE),
        iconBackground: Color(0xFFCDEED9),
        icon: Color(0xFF15803D),
      );
    }
    if (lower.contains('career') || lower.contains('profession')) {
      return const _HoroscopeTone(
        background: Color(0xFFEAF2FF),
        border: Color(0xFFC7DAFF),
        iconBackground: Color(0xFFD7E6FF),
        icon: Color(0xFF1D4ED8),
      );
    }
    if (lower.contains('love') ||
        lower.contains('relationship') ||
        lower.contains('personal')) {
      return const _HoroscopeTone(
        background: Color(0xFFFFEEF3),
        border: Color(0xFFFFC9D8),
        iconBackground: Color(0xFFFFD9E4),
        icon: Color(0xFFBE123C),
      );
    }
    if (lower.contains('travel')) {
      return const _HoroscopeTone(
        background: Color(0xFFFFF4E6),
        border: Color(0xFFFFDCB1),
        iconBackground: Color(0xFFFFE4C2),
        icon: Color(0xFFC2410C),
      );
    }
    if (lower.contains('luck')) {
      return const _HoroscopeTone(
        background: Color(0xFFFFF8DB),
        border: Color(0xFFEFD88C),
        iconBackground: Color(0xFFF4D56B),
        icon: Color(0xFF854D0E),
      );
    }
    if (lower.contains('emotion')) {
      return const _HoroscopeTone(
        background: Color(0xFFF0ECFF),
        border: Color(0xFFD8CEFF),
        iconBackground: Color(0xFFE4DCFF),
        icon: Color(0xFF6D28D9),
      );
    }
    return const _HoroscopeTone(
      background: Color(0xFFFFFCF4),
      border: Color(0xFFE8D7A7),
      iconBackground: Color(0xFFD7AF4B),
      icon: Color(0xFF1E3557),
    );
  }

  Widget _pill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8D7A7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFD4A017)),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF1E3557),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  static Map<String, dynamic> _payload(Map<String, dynamic> response) {
    var current = response['data'] ?? response;
    for (var i = 0; i < 5; i++) {
      final map = _asMap(current);
      if (map.containsKey('provider_payload')) {
        current = map['provider_payload'];
        continue;
      }
      if (map.containsKey('data') && map.length <= 4) {
        current = map['data'];
        continue;
      }
      return map;
    }
    return _asMap(current);
  }

  static Map<String, dynamic> _predictionMap(Map<String, dynamic> payload) {
    final direct = _asMap(payload['prediction']);
    if (direct.isNotEmpty) return direct;
    final predictions = _asMap(payload['predictions']);
    if (predictions.isNotEmpty) return predictions;
    const keys = [
      'health',
      'emotions',
      'profession',
      'career',
      'finance',
      'luck',
      'personal_life',
      'love',
      'relationship',
      'travel',
    ];
    return {
      for (final key in keys)
        if (payload[key] != null) key: payload[key],
    };
  }

  static IconData _iconFor(String key) {
    final lower = key.toLowerCase();
    if (lower.contains('health')) return Icons.favorite_border;
    if (lower.contains('career') || lower.contains('profession')) {
      return Icons.work_outline;
    }
    if (lower.contains('finance') || lower.contains('wealth')) {
      return Icons.savings_outlined;
    }
    if (lower.contains('love') || lower.contains('relationship')) {
      return Icons.favorite_outline;
    }
    if (lower.contains('travel')) return Icons.flight_takeoff;
    return Icons.auto_awesome;
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  static String _text(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String _stripHtml(String value) {
    return value.replaceAll(RegExp(r'<[^>]+>'), '').trim();
  }

  static String _titleize(String value) {
    final spaced = value.replaceAll('_', ' ').replaceAll('-', ' ');
    return spaced
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  static String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${now.day} ${months[now.month - 1]} ${now.year}';
  }
}

class _HoroscopeTone {
  final Color background;
  final Color border;
  final Color iconBackground;
  final Color icon;

  const _HoroscopeTone({
    required this.background,
    required this.border,
    required this.iconBackground,
    required this.icon,
  });
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
