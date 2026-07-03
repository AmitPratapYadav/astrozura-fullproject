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
  bool _loading = true;
  String? _error;
  String _locationName = 'Saved birth place';
  String _tithi = '--';
  String _nakshatra = '--';
  String _yoga = '--';

  @override
  void initState() {
    super.initState();
    _loadPanchang();
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
        _tithi = _entryName(summary['current_tithi']);
        _nakshatra = _entryName(summary['current_nakshatra']);
        _yoga = _entryName(summary['current_yoga']);
        if (_tithi == '--' && _nakshatra == '--' && _yoga == '--') {
          _error = providerMessage ?? 'Panchang data is unavailable right now.';
        }
        _loading = false;
      });
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
                    Row(
                      children: [
                        Expanded(
                            child: _InfoCard(title: 'Tithi', value: _tithi)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _InfoCard(
                                title: 'Nakshatra', value: _nakshatra)),
                        const SizedBox(width: 10),
                        Expanded(child: _InfoCard(title: 'Yoga', value: _yoga)),
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

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const _InfoCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
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
            maxLines: 1,
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
