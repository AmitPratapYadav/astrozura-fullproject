import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/astrology_service.dart';
import '../../mainwidgets/header.dart';
import '../../shared/widgets/astrology_result_renderer.dart';
import '../../shared/widgets/location_search_field.dart';

class LiveVedicCalculatorScreen extends StatefulWidget {
  final String toolKey;
  final String title;
  final String description;
  final bool supportsAdvanced;
  final bool requiresYear;
  final bool requiresPlanet;
  final bool requiresChartStyle;
  final List<String> additionalToolKeys;

  const LiveVedicCalculatorScreen({
    super.key,
    required this.toolKey,
    required this.title,
    required this.description,
    this.supportsAdvanced = false,
    this.requiresYear = false,
    this.requiresPlanet = false,
    this.requiresChartStyle = false,
    this.additionalToolKeys = const [],
  });

  @override
  State<LiveVedicCalculatorScreen> createState() =>
      _LiveVedicCalculatorScreenState();
}

class _LiveVedicCalculatorScreenState extends State<LiveVedicCalculatorScreen> {
  static const _gold = Color(0xFFD4A017);
  static const _bg = Color(0xFFFFF8E5);
  static const _text = Color(0xFF1A1A2E);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);

  final _service = AstrologyService();
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();

  LocationSelection? _location;
  DateTime? _date;
  TimeOfDay? _time;
  String _language = 'English';
  String _ayanamsa = 'Lahiri';
  String _planet = 'Sun';
  String _chartStyle = 'North Indian';
  int _year = DateTime.now().year;
  bool _advanced = false;
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  static const _languageCodes = {
    'English': 'en',
    'Hindi': 'hi',
    'Tamil': 'ta',
    'Telugu': 'te',
    'Malayalam': 'ml',
  };

  static const _ayanamsaCodes = {
    'Lahiri': 1,
    'Raman': 3,
    'Krishnamurti': 5,
  };

  static const _planetCodes = {
    'Sun': 0,
    'Moon': 1,
    'Mars': 2,
    'Mercury': 3,
    'Jupiter': 4,
    'Venus': 5,
    'Saturn': 6,
  };

  static const _chartStyleCodes = {
    'North Indian': 'north-indian',
    'South Indian': 'south-indian',
    'East Indian': 'east-indian',
  };

  @override
  void initState() {
    super.initState();
    _loadSavedBirthDetails();
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedBirthDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final dob =
        prefs.getString('user_dob') ?? prefs.getString('date_of_birth') ?? '';
    final tob =
        prefs.getString('user_tob') ?? prefs.getString('time_of_birth') ?? '';
    final pob =
        prefs.getString('user_pob') ?? prefs.getString('place_of_birth') ?? '';
    final lat = prefs.getDouble('user_pob_lat');
    final lng = prefs.getDouble('user_pob_lng');

    setState(() {
      if (dob.isNotEmpty) {
        _date = DateTime.tryParse(dob);
        _dateCtrl.text = _formatDate(_date);
      }
      if (tob.isNotEmpty) {
        _time = _parseTime(tob);
        _timeCtrl.text = _formatTime(_time);
      }
      if (pob.isNotEmpty && lat != null && lng != null) {
        _location = LocationSelection(name: pob, latitude: lat, longitude: lng);
        _placeCtrl.text = pob;
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(1995),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context)
            .copyWith(colorScheme: const ColorScheme.light(primary: _gold)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateCtrl.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _time = picked;
        _timeCtrl.text = _formatTime(picked);
      });
    }
  }

  Future<void> _run() async {
    final date = _date;
    final time = _time;
    final location = _location;
    if (date == null || time == null || location == null) {
      setState(
          () => _error = 'Date, time, and a selected birthplace are required.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final payload = <String, dynamic>{
        'datetime': _kolkataDateTime(date, time),
        'coordinates': location.coordinates,
        'ayanamsa': _ayanamsaCodes[_ayanamsa] ?? 1,
        'la': _languageCodes[_language] ?? 'en',
        if (widget.supportsAdvanced) 'detailed_report': _advanced,
        if (widget.requiresYear) 'year': _year,
        if (widget.requiresPlanet) 'planet': _planetCodes[_planet] ?? 0,
        if (widget.requiresChartStyle)
          'chart_style': _chartStyleCodes[_chartStyle] ?? 'north-indian',
      };
      final Map<String, dynamic> response;
      if (widget.toolKey == '__kundli__') {
        response = await _service.kundli(payload);
      } else if (widget.additionalToolKeys.isNotEmpty) {
        final keys = [widget.toolKey, ...widget.additionalToolKeys];
        final results = await Future.wait(
          keys.map((key) => _service.vedicCalculator(key, payload)),
        );
        response = {
          'status': 'success',
          'data': {
            'provider_sections': [
              {
                'id': 'combined-report',
                'title': widget.title,
                'summary': widget.description,
                'items': {
                  for (var index = 0; index < keys.length; index++)
                    keys[index]: results[index],
                },
              },
            ],
          },
        };
      } else {
        response = await _service.vedicCalculator(widget.toolKey, payload);
      }
      if (!mounted) return;
      setState(() {
        if (response['status'] == 'success') {
          _result = response;
        } else {
          _error =
              response['message']?.toString() ?? 'Unable to generate result.';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Colors.white, _bg],
                begin: Alignment.topCenter,
                end: Alignment.center),
          ),
          child: Column(
            children: [
              const HeaderWidget(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _backBar(),
                      const SizedBox(height: 12),
                      _hero(),
                      const SizedBox(height: 16),
                      _form(),
                      const SizedBox(height: 18),
                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_error != null)
                        _errorCard()
                      else if (_result != null)
                        AstrologyResultRenderer(response: _result!)
                      else
                        _readyCard(),
                    ],
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
          icon: const Icon(Icons.chevron_left, color: _text),
        ),
        Expanded(
          child: Text(
            widget.title.toUpperCase(),
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.4),
          ),
        ),
      ],
    );
  }

  Widget _hero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3557),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Astrology API Calculator',
              style: TextStyle(color: _gold, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(widget.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(widget.description,
              style: const TextStyle(color: Colors.white70, height: 1.35)),
        ],
      ),
    );
  }

  Widget _form() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Date of Birth'),
          _readonlyField(_dateCtrl, 'Select date',
              Icons.calendar_month_outlined, _pickDate),
          const SizedBox(height: 12),
          _label('Time of Birth'),
          _readonlyField(
              _timeCtrl, 'Select time', Icons.access_time, _pickTime),
          const SizedBox(height: 12),
          _label('Birth Place'),
          LocationSearchField(
            controller: _placeCtrl,
            initialSelection: _location,
            onSelected: (selection) => setState(() => _location = selection),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _dropdown(
                      'Ayanamsa',
                      _ayanamsa,
                      _ayanamsaCodes.keys.toList(),
                      (v) => setState(() => _ayanamsa = v))),
              const SizedBox(width: 10),
              Expanded(
                  child: _dropdown(
                      'Language',
                      _language,
                      _languageCodes.keys.toList(),
                      (v) => setState(() => _language = v))),
            ],
          ),
          if (widget.requiresYear ||
              widget.requiresPlanet ||
              widget.requiresChartStyle) ...[
            const SizedBox(height: 12),
            if (widget.requiresYear)
              _numberField('Reference Year', _year,
                  (value) => setState(() => _year = value)),
            if (widget.requiresPlanet)
              _dropdown('Planet', _planet, _planetCodes.keys.toList(),
                  (v) => setState(() => _planet = v)),
            if (widget.requiresChartStyle)
              _dropdown(
                  'Chart Style',
                  _chartStyle,
                  _chartStyleCodes.keys.toList(),
                  (v) => setState(() => _chartStyle = v)),
          ],
          if (widget.supportsAdvanced) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _advanced,
              title: const Text('Use advanced detailed report',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              activeThumbColor: _gold,
              onChanged: (value) => setState(() => _advanced = value),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _run,
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: const Color(0xFF1E3557),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(_loading ? 'Calculating...' : 'Run ${widget.title}',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readonlyField(TextEditingController controller, String hint,
      IconData icon, VoidCallback onTap) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _dropdown(String label, String value, List<String> items,
      ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: (next) {
                if (next != null) onChanged(next);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _numberField(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextFormField(
          initialValue: value.toString(),
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (text) =>
              onChanged(int.tryParse(text) ?? DateTime.now().year),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w900, color: _muted)),
    );
  }

  Widget _readyCard() {
    return _messageCard(
      icon: Icons.auto_awesome,
      title: 'Ready to Calculate',
      message:
          'Enter birth details and select a birthplace from live location search.',
    );
  }

  Widget _errorCard() {
    return _messageCard(
      icon: Icons.error_outline,
      title: 'Unable to Generate',
      message: _error ?? 'Unable to generate result.',
      action: ElevatedButton(onPressed: _run, child: const Text('Retry')),
    );
  }

  Widget _messageCard(
      {required IconData icon,
      required String title,
      required String message,
      Widget? action}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Icon(icon, color: _gold, size: 34),
          const SizedBox(height: 8),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _muted, height: 1.35)),
          if (action != null) ...[
            const SizedBox(height: 12),
            action,
          ],
        ],
      ),
    );
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  static String _formatTime(TimeOfDay? time) {
    if (time == null) return '';
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  static TimeOfDay? _parseTime(String text) {
    final match = RegExp(r'(\d{1,2}):(\d{2})\s*(AM|PM)?', caseSensitive: false)
        .firstMatch(text);
    if (match == null) return null;
    var hour = int.tryParse(match.group(1) ?? '') ?? 0;
    final minute = int.tryParse(match.group(2) ?? '') ?? 0;
    final period = match.group(3)?.toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

  static String _kolkataDateTime(DateTime date, TimeOfDay time) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = time.hour.toString().padLeft(2, '0');
    final min = time.minute.toString().padLeft(2, '0');
    return '$y-$m-${d}T$h:$min:00+05:30';
  }
}
