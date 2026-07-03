import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/astrology_service.dart';
import '../../mainwidgets/header.dart';
import '../../shared/widgets/location_search_field.dart';
import '../widgets/ayana_navigation.dart';

enum PanchangMode { daily, chaughadiya, hora }

class LivePanchangScreen extends StatefulWidget {
  final PanchangMode mode;

  const LivePanchangScreen({super.key, required this.mode});

  @override
  State<LivePanchangScreen> createState() => _LivePanchangScreenState();
}

class _LivePanchangScreenState extends State<LivePanchangScreen> {
  static const _gold = Color(0xFFD4A017);
  static const _goldLight = Color(0xFFFFF3CD);
  static const _textDark = Color(0xFF1A1A2E);
  static const _textGrey = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  final _service = AstrologyService();
  final _locationCtrl = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  LocationSelection? _location;
  String _language = 'English';
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};

  static const _languageCodes = {
    'English': 'en',
    'Hindi': 'hi',
    'Tamil': 'ta',
    'Telugu': 'te',
    'Malayalam': 'ml',
    'Marathi': 'ma',
  };

  static const _languages = [
    'English',
    'Hindi',
    'Tamil',
    'Telugu',
    'Malayalam',
    'Marathi',
  ];

  String get _modeKey => switch (widget.mode) {
        PanchangMode.daily => 'daily',
        PanchangMode.chaughadiya => 'chaughadiya',
        PanchangMode.hora => 'hora',
      };

  String get _title => switch (widget.mode) {
        PanchangMode.daily => 'Daily Panchang',
        PanchangMode.chaughadiya => 'Chaughadiya Panchang',
        PanchangMode.hora => 'Hora Panchang',
      };

  int get _ayanaIndex => switch (widget.mode) {
        PanchangMode.daily => 0,
        PanchangMode.chaughadiya => 1,
        PanchangMode.hora => 2,
      };

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final name = (prefs.getString('user_pob') ?? '').trim();
    final lat = prefs.getDouble('user_pob_lat');
    final lng = prefs.getDouble('user_pob_lng');
    if (name.isNotEmpty && lat != null && lng != null) {
      _location = LocationSelection(name: name, latitude: lat, longitude: lng);
      _locationCtrl.text = _location!.name;
      await _fetch();
      return;
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = 'Select a location to load Panchang.';
    });
  }

  Future<void> _fetch() async {
    final location = _location;
    if (location == null) {
      setState(() => _error = 'Select a location from search results.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _service.panchang({
        'datetime': _kolkataDateTime(_selectedDate, 6, 0),
        'coordinates': location.coordinates,
        'ayanamsa': 1,
        'mode': _modeKey,
        'la': _languageCodes[_language] ?? 'en',
      });

      final data = _asMap(response['data']);
      final providerMessage = _providerMessage(data);
      if (!mounted) return;

      setState(() {
        _data = data;
        _error = _hasUsefulData(data)
            ? null
            : providerMessage ?? 'Panchang data is unavailable right now.';
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

  bool _hasUsefulData(Map<String, dynamic> data) {
    final panchang = _asMap(data['panchang']);
    if (widget.mode == PanchangMode.daily) {
      return _asMap(data['summary']).isNotEmpty ||
          _asMap(panchang['advanced']).isNotEmpty ||
          _asMap(panchang['basic']).isNotEmpty;
    }
    final key = widget.mode == PanchangMode.hora ? 'hora' : 'chaughadiya';
    final rows = _splitPeriodRows(panchang[key], widget.mode);
    return rows.day.isNotEmpty || rows.night.isNotEmpty;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _gold),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, _goldLight],
              begin: Alignment.topCenter,
              end: Alignment.center,
            ),
          ),
          child: Column(
            children: [
              const HeaderWidget(),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _fetch,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _backBar(),
                        const SizedBox(height: 12),
                        AyanaCard(currentIndex: _ayanaIndex),
                        const SizedBox(height: 16),
                        _filters(),
                        const SizedBox(height: 22),
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.all(36),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_error != null)
                          _errorCard()
                        else if (widget.mode == PanchangMode.daily)
                          _dailyContent()
                        else
                          _muhurtaContent(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backBar() {
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.chevron_left, color: _textDark),
        ),
        Text(
          _title.toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: _textDark,
          ),
        ),
      ],
    );
  }

  Widget _filters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('SELECT DATE', Icons.calendar_today_outlined),
        const SizedBox(height: 6),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(10),
          child: _fieldShell(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formattedDate,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const Icon(Icons.calendar_month_outlined,
                    size: 18, color: _textGrey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        _label('LOCATION', Icons.location_on_outlined),
        const SizedBox(height: 6),
        LocationSearchField(
          controller: _locationCtrl,
          initialSelection: _location,
          hintText: 'Search city for Panchang',
          onSelected: (selection) async {
            setState(() => _location = selection);
            if (selection != null) await _fetch();
          },
        ),
        const SizedBox(height: 14),
        _label('LANGUAGE', Icons.translate_outlined),
        const SizedBox(height: 6),
        _fieldShell(
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _language,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, color: _textGrey),
              items: _languages
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (value) async {
                if (value == null) return;
                setState(() => _language = value);
                await _fetch();
              },
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        ),
      ],
    );
  }

  Widget _dailyContent() {
    final summary = _asMap(_data['summary']);
    final panchang = _asMap(_data['panchang']);
    final advanced = _asMap(panchang['advanced']);
    final basic = _asMap(panchang['basic']);

    return Column(
      children: [
        _section('Sun & Moon Information', Icons.wb_sunny_outlined, [
          _row(
              'Sunrise',
              _formatDateTime(summary['sunrise'] ??
                  advanced['sunrise'] ??
                  basic['sunrise'])),
          _row(
              'Sunset',
              _formatDateTime(
                  summary['sunset'] ?? advanced['sunset'] ?? basic['sunset'])),
          _row(
              'Moonrise',
              _formatDateTime(summary['moonrise'] ??
                  advanced['moonrise'] ??
                  basic['moonrise'])),
          _row(
              'Moonset',
              _formatDateTime(summary['moonset'] ??
                  advanced['moonset'] ??
                  basic['moonset'])),
          _row('Vaara', _value(summary['vaara'] ?? advanced['day'])),
        ]),
        _section('Panchang Elements', Icons.blur_circular_outlined, [
          _row(
              'Tithi', _entryName(summary['current_tithi'], advanced['tithi'])),
          _row('Nakshatra',
              _entryName(summary['current_nakshatra'], advanced['nakshatra'])),
          _row('Yoga', _entryName(summary['current_yoga'], advanced['yog'])),
          _row('Karana',
              _entryName(summary['current_karana'], advanced['karan'])),
        ]),
        _section('Hindu Month & Year', Icons.auto_awesome_outlined, [
          _row('Vikram Samvat',
              _value(advanced['vikram_samvat'] ?? basic['vikram_samvat'])),
          _row('Shaka Samvat',
              _value(advanced['shaka_samvat'] ?? basic['shaka_samvat'])),
          _row('Paksha',
              _value(_asMap(advanced['tithi'])['paksha'] ?? basic['paksha'])),
          _row('Ayana',
              _value(advanced['ayan'] ?? advanced['ayana'] ?? basic['ayana'])),
          _row('Purnimanta',
              _value(advanced['purnimanta'] ?? basic['purnimanta'])),
          _row('Amanta', _value(advanced['amanta'])),
        ]),
        _section('Auspicious Timings', Icons.check_circle_outline, [
          _row('Abhijit Muhurta', _range(_asMap(advanced['abhijit_muhurta']))),
          _row('Amrit Kalam', _range(_asMap(advanced['amrit_kalam']))),
        ]),
        _section('Inauspicious Timings', Icons.cancel_outlined, [
          _row('Rahu Kalam', _range(_asMap(advanced['rahukaal']))),
          _row('Gulika Kalam', _range(_asMap(advanced['guliKaal']))),
          _row('Yamghant Kalam', _range(_asMap(advanced['yamghant_kaal']))),
          _row('Dur Muhurtam', _range(_asMap(advanced['dur_muhurat']))),
          _row('Varjyam', _range(_asMap(advanced['varjyam']))),
        ]),
        _section('Other Yoga & Nivas', Icons.self_improvement_outlined, [
          _row('Anandadi Yog',
              _value(advanced['anandadi_yog'] ?? advanced['anandadi_yoga'])),
          _row('Disha Shool', _value(advanced['disha_shool'])),
          _row('Nakshatra Shool', _value(advanced['nakshatra_shool'])),
          _row('Moon Nivas',
              _value(advanced['moon_nivas'] ?? advanced['moon_nivash'])),
        ]),
      ],
    );
  }

  Widget _muhurtaContent() {
    final panchang = _asMap(_data['panchang']);
    final key = widget.mode == PanchangMode.hora ? 'hora' : 'chaughadiya';
    final rows = _splitPeriodRows(panchang[key], widget.mode);
    final dayTitle =
        widget.mode == PanchangMode.hora ? 'Day Hora' : 'Day Chaughadiya';
    final nightTitle =
        widget.mode == PanchangMode.hora ? 'Night Hora' : 'Night Chaughadiya';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(dayTitle, Icons.wb_sunny_outlined),
        ...rows.day.map(_periodCard),
        const SizedBox(height: 18),
        _sectionHeader(nightTitle, Icons.nightlight_round),
        ...rows.night.map(_periodCard),
        if (rows.day.isEmpty && rows.night.isEmpty)
          _errorCard(
              message:
                  'No periods returned for the selected date and location.'),
      ],
    );
  }

  Widget _section(String title, IconData icon, List<_DisplayRow> rows) {
    final visible = rows.where((item) => item.value != '--').toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        _sectionHeader(title, icon),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Column(
            children: visible
                .map((item) => ListTile(
                      dense: true,
                      title: Text(item.label,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      trailing: SizedBox(
                        width: 150,
                        child: Text(
                          item.value,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: _textGrey, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _periodCard(_PeriodRow row) {
    final color = _periodColor(row.name);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(Icons.access_time, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(row.time,
                    style: const TextStyle(
                        color: _textGrey, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _gold, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w900, color: _textDark),
          ),
        ),
      ],
    );
  }

  Widget _label(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 13, color: _textGrey),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: _textGrey),
        ),
      ],
    );
  }

  Widget _fieldShell(Widget child,
      {EdgeInsetsGeometry padding =
          const EdgeInsets.symmetric(horizontal: 14, vertical: 13)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }

  Widget _errorCard({String? message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Text(message ?? _error ?? 'Unable to load Panchang.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textGrey)),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _fetch, child: const Text('Retry')),
        ],
      ),
    );
  }

  String get _formattedDate {
    final y = _selectedDate.year.toString().padLeft(4, '0');
    final m = _selectedDate.month.toString().padLeft(2, '0');
    final d = _selectedDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _kolkataDateTime(DateTime date, int hour, int minute) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = hour.toString().padLeft(2, '0');
    final min = minute.toString().padLeft(2, '0');
    return '$y-$m-${d}T$h:$min:00+05:30';
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  static String _value(dynamic value) {
    if (value == null || value == '') return '--';
    if (value is Map) {
      return _value(value['name'] ??
          value['full_name'] ??
          value['title'] ??
          value['value']);
    }
    if (value is List) {
      final parts = value.map(_value).where((item) => item != '--').toList();
      return parts.isEmpty ? '--' : parts.join(', ');
    }
    return value.toString().trim().isEmpty ? '--' : value.toString();
  }

  static String _entryName(dynamic summaryValue, dynamic advancedValue) {
    final summary = _asMap(summaryValue);
    final advanced = _asMap(advancedValue);
    final details = _asMap(advanced['details']);
    final name = summary['name'] ??
        summary['value'] ??
        details['tithi_name'] ??
        details['nak_name'] ??
        details['yog_name'] ??
        details['karan_name'];
    final end = summary['end'];
    final label = _value(name);
    if (label == '--') return '--';
    return end == null ? label : '$label upto ${_formatDateTime(end)}';
  }

  static String _range(Map<String, dynamic> map) {
    final start = _value(map['start']);
    final end = _value(map['end']);
    if (start == '--' || end == '--') return '--';
    return '$start - $end';
  }

  static String _formatDateTime(dynamic value) {
    if (value == null || value == '') return '--';
    final text = value.toString();
    if (RegExp(r'^\d{1,2}:\d{2}').hasMatch(text.trim())) return text.trim();
    final parsed = DateTime.tryParse(text);
    if (parsed == null) return text;
    final local = parsed.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  static String? _providerMessage(Map<String, dynamic> data) {
    final sections = data['provider_sections'];
    if (sections is! List) return null;
    for (final section in sections) {
      final items = _asMap(_asMap(section)['items']);
      for (final item in items.values) {
        final map = _asMap(item);
        final message = map['message']?.toString();
        if (message != null && message.trim().isNotEmpty) return message;
      }
    }
    return null;
  }

  static _SplitRows _splitPeriodRows(dynamic payload, PanchangMode mode) {
    final source = _asMap(payload);
    final direct = payload is List ? payload : null;
    final nestedKey = mode == PanchangMode.hora ? 'hora' : 'chaughadiya';
    final nested = source[nestedKey];

    List<_PeriodRow> normalize(dynamic value) {
      final list = value is List ? value : const [];
      return list
          .map((item) {
            final map = _asMap(item);
            final name = _value(
                map['muhurta'] ?? map['hora'] ?? map['planet'] ?? map['name']);
            final time =
                _value(map['time'] ?? map['period'] ?? map['duration']);
            return _PeriodRow(name == '--' ? 'Period' : name, time);
          })
          .where((item) => item.time != '--')
          .toList();
    }

    if (source['day'] is List || source['night'] is List) {
      return _SplitRows(normalize(source['day']), normalize(source['night']));
    }
    if (nested is Map || nested is List) {
      return _splitPeriodRows(nested, mode);
    }
    if (direct != null) {
      final rows = normalize(direct);
      final midpoint = (rows.length / 2).ceil();
      return _SplitRows(
          rows.take(midpoint).toList(), rows.skip(midpoint).toList());
    }
    return const _SplitRows([], []);
  }

  static Color _periodColor(String name) {
    final text = name.toLowerCase();
    if (text.contains('amrit') ||
        text.contains('shubh') ||
        text.contains('labh')) {
      return Colors.green;
    }
    if (text.contains('rog') ||
        text.contains('kaal') ||
        text.contains('udveg')) {
      return Colors.red;
    }
    return _gold;
  }

  static _DisplayRow _row(String label, String value) =>
      _DisplayRow(label, value);
}

class _DisplayRow {
  final String label;
  final String value;

  const _DisplayRow(this.label, this.value);
}

class _PeriodRow {
  final String name;
  final String time;

  const _PeriodRow(this.name, this.time);
}

class _SplitRows {
  final List<_PeriodRow> day;
  final List<_PeriodRow> night;

  const _SplitRows(this.day, this.night);
}
