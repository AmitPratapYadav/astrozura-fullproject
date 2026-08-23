import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/contants/app_colors.dart';
import '../../../core/services/astrology_service.dart';
import '../../main_navigation.dart';

class PanchangSection extends StatefulWidget {
  final VoidCallback? onTap;

  const PanchangSection({super.key, this.onTap});

  @override
  State<PanchangSection> createState() => _PanchangSectionState();
}

class _PanchangSectionState extends State<PanchangSection> {
  final AstrologyService _service = AstrologyService();
  final PageController _metricController = PageController();
  Timer? _metricTimer;
  bool _loading = true;
  String? _error;
  String _locationName = 'Saved birth place';
  String _dateLabel = '--';
  String _vaar = '--';
  String _tithi = '--';
  String _nakshatra = '--';
  String _yoga = '--';
  int _metricIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadPanchang();
    _startMetricTimer();
  }

  @override
  void dispose() {
    _metricTimer?.cancel();
    _metricController.dispose();
    super.dispose();
  }

  void _startMetricTimer() {
    _metricTimer?.cancel();
    _metricTimer = Timer.periodic(const Duration(milliseconds: 2400), (_) {
      if (!_metricController.hasClients || _loading || _error != null) return;
      final next = (_metricIndex + 1) % _metricCount;
      _metricController.animateToPage(
        next,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _loadPanchang() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final place = (prefs.getString('user_pob') ?? '').trim();
      var lat = prefs.getDouble('user_pob_lat');
      var lng = prefs.getDouble('user_pob_lng');

      if ((lat == null || lng == null) && place.isNotEmpty) {
        final locations = await _service.searchLocations(place);
        final first = locations.isNotEmpty ? locations.first : null;
        final coordinates = first?['coordinates'];
        lat = _toDouble(first?['latitude'] ??
            first?['lat'] ??
            (coordinates is Map
                ? coordinates['latitude'] ?? coordinates['lat']
                : null));
        lng = _toDouble(first?['longitude'] ??
            first?['lng'] ??
            first?['lon'] ??
            (coordinates is Map
                ? coordinates['longitude'] ??
                    coordinates['lng'] ??
                    coordinates['lon']
                : null));
        if (lat != null && lng != null) {
          await prefs.setDouble('user_pob_lat', lat);
          await prefs.setDouble('user_pob_lng', lng);
        }
      }

      if (lat == null || lng == null) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Add your birthplace in Profile to load Panchang.';
        });
        return;
      }

      final now = DateTime.now();
      final cacheKey = _cacheKey(now, lat, lng);
      if (_restoreCachedPanchang(prefs, cacheKey, place, now)) return;

      final response = await _service.panchang({
        'datetime': now.toIso8601String(),
        'coordinates': '$lat,$lng',
        'ayanamsa': 1,
        'mode': 'daily',
        'la': 'en',
      });
      final data = _asMap(response['data']);
      final summary = _asMap(data['summary']);
      final providerMessage = _providerMessage(data);

      if (!mounted) return;
      setState(() {
        _locationName = place.isEmpty ? 'Default location' : place;
        _dateLabel = _formatDate(now);
        _vaar = _entryName(summary['vaara']);
        if (_vaar == '--') {
          _vaar = _entryName(data['vaara']);
        }
        if (_vaar == '--') {
          _vaar = _weekdayName(now);
        }
        _tithi = _entryName(summary['current_tithi']);
        _nakshatra = _entryName(summary['current_nakshatra']);
        _yoga = _entryName(summary['current_yoga']);
        if (_tithi == '--' && _nakshatra == '--' && _yoga == '--') {
          _error = providerMessage ?? 'Panchang data is unavailable right now.';
        }
        _loading = false;
      });
      await _storeCachedPanchang(
        prefs,
        cacheKey: cacheKey,
        locationName: place.isEmpty ? 'Default location' : place,
        dateLabel: _formatDate(now),
        vaar: _vaar,
        tithi: _tithi,
        nakshatra: _nakshatra,
        yoga: _yoga,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static String _entryName(dynamic value) {
    final map = _asMap(value);
    return (map['name'] ??
            map['value'] ??
            map['tithi_name'] ??
            map['nak_name'] ??
            map['yog_name'] ??
            '--')
        .toString();
  }

  static const int _metricCount = 5;

  static String _cacheKey(DateTime date, double lat, double lng) {
    final day =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$day:${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
  }

  bool _restoreCachedPanchang(
    SharedPreferences prefs,
    String cacheKey,
    String place,
    DateTime now,
  ) {
    if (prefs.getString('home_panchang_cache_key') != cacheKey) return false;
    final tithi = prefs.getString('home_panchang_tithi') ?? '';
    final nakshatra = prefs.getString('home_panchang_nakshatra') ?? '';
    final yoga = prefs.getString('home_panchang_yoga') ?? '';
    if (tithi.isEmpty && nakshatra.isEmpty && yoga.isEmpty) return false;
    if (!mounted) return false;
    setState(() {
      _locationName = prefs.getString('home_panchang_location') ??
          (place.isEmpty ? 'Default location' : place);
      _dateLabel =
          prefs.getString('home_panchang_date_label') ?? _formatDate(now);
      _vaar = prefs.getString('home_panchang_vaar') ?? _weekdayName(now);
      _tithi = tithi.isEmpty ? '--' : tithi;
      _nakshatra = nakshatra.isEmpty ? '--' : nakshatra;
      _yoga = yoga.isEmpty ? '--' : yoga;
      _loading = false;
      _error = null;
    });
    return true;
  }

  Future<void> _storeCachedPanchang(
    SharedPreferences prefs, {
    required String cacheKey,
    required String locationName,
    required String dateLabel,
    required String vaar,
    required String tithi,
    required String nakshatra,
    required String yoga,
  }) async {
    await prefs.setString('home_panchang_cache_key', cacheKey);
    await prefs.setString('home_panchang_location', locationName);
    await prefs.setString('home_panchang_date_label', dateLabel);
    await prefs.setString('home_panchang_vaar', vaar);
    await prefs.setString('home_panchang_tithi', tithi);
    await prefs.setString('home_panchang_nakshatra', nakshatra);
    await prefs.setString('home_panchang_yoga', yoga);
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  static String _weekdayName(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[date.weekday - 1];
  }

  static String? _providerMessage(Map<String, dynamic> data) {
    final sections = data['provider_sections'];
    if (sections is! List) return null;
    for (final section in sections) {
      final items = _asMap(_asMap(section)['items']);
      for (final item in items.values) {
        final map = _asMap(item);
        final message = map['message']?.toString();
        if (message != null && message.isNotEmpty) return message;
      }
    }
    return null;
  }

  void _openFullPanchang() {
    if (MainNavigationState.activateIndex(8)) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigation(initialIndex: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFFDFDEFF), Color(0xFF8B88E6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .08),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: widget.onTap ?? _openFullPanchang,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .7),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(
                            'assets/images/services/panchang.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Panchang',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _loading
                                  ? 'Loading today Panchang...'
                                  : _locationName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color.fromARGB(255, 52, 52, 52),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(height: 1, color: Colors.black12),
                  const SizedBox(height: 18),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: CircularProgressIndicator(),
                    )
                  else if (_error != null)
                    _ErrorState(message: _error!, onRetry: _loadPanchang)
                  else
                    _MetricCarousel(
                      controller: _metricController,
                      index: _metricIndex,
                      onChanged: (index) => setState(() {
                        _metricIndex = index;
                      }),
                      cards: [
                        _InfoCard(title: 'Date', value: _dateLabel),
                        _InfoCard(title: 'Vaar', value: _vaar),
                        _InfoCard(title: 'Tithi', value: _tithi),
                        _InfoCard(title: 'Nakshatra', value: _nakshatra),
                        _InfoCard(title: 'Yoga', value: _yoga),
                      ],
                    ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _openFullPanchang,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'View Full Panchang',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          message,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _MetricCarousel extends StatelessWidget {
  final PageController controller;
  final int index;
  final ValueChanged<int> onChanged;
  final List<Widget> cards;

  const _MetricCarousel({
    required this.controller,
    required this.index,
    required this.onChanged,
    required this.cards,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 78,
          child: PageView.builder(
            controller: controller,
            itemCount: cards.length,
            onPageChanged: onChanged,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: cards[index],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cards.length, (dotIndex) {
            final active = dotIndex == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: active ? 16 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.accentGold
                    : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const _InfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 9,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
