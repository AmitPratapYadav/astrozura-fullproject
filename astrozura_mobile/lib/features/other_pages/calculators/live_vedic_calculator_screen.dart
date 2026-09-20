import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/astrology_service.dart';
import '../../../core/services/recent_profile_service.dart';
import '../../main_navigation.dart';
import '../../mainwidgets/header.dart';
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
  final _recentProfiles = RecentProfileService();
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
  final bool _advanced = false;
  bool _loading = false;
  String? _error;

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

  void _showRecentProfiles() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CalculatorRecentProfilesSheet(
        service: _recentProfiles,
        onSelected: _applyRecentProfile,
      ),
    );
  }

  void _applyRecentProfile(Map<String, dynamic> profile) {
    final dob = _profileString(profile['date_of_birth'] ?? profile['dob']);
    final tob = _profileString(profile['time_of_birth'] ?? profile['tob']);
    final location = _locationFromProfile(profile);
    final place = _profileString(
      profile['place_of_birth'] ?? profile['birth_place'] ?? profile['pob'],
    );
    setState(() {
      if (dob.isNotEmpty) {
        _date = _parseProfileDate(dob);
        _dateCtrl.text = _formatDate(_date);
      }
      if (tob.isNotEmpty) {
        _time = _parseTime(tob);
        _timeCtrl.text = _formatTime(_time);
      }
      if (place.isNotEmpty) _placeCtrl.text = place;
      if (location != null) _location = location;
      _error = null;
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
      if (response['status'] == 'success') {
        setState(() => _loading = false);
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _CalculatorResultScreen(
              toolKey: widget.toolKey,
              title: widget.title,
              description: widget.description,
              response: response,
              input: _CalculatorInput(
                date: date,
                time: time,
                place: location.name,
                coordinates: location.coordinates,
                language: _languageCodes[_language] ?? 'en',
              ),
            ),
          ),
        );
      } else {
        setState(() {
          _error =
              response['message']?.toString() ?? 'Unable to generate result.';
          _loading = false;
        });
      }
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
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
                        const SizedBox(height: 10),
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
                        else
                          const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_circle_left_rounded, color: _text),
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

  void _goBack() {
    MainNavigationState.returnHome(context);
  }

  Widget _form() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: _showRecentProfiles,
              icon: const Icon(Icons.history_rounded, size: 16),
              label: const Text('Choose Previous Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _text,
                minimumSize: const Size(0, 34),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                visualDensity: VisualDensity.compact,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
                side: const BorderSide(color: Color(0xFFE6D7BA)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _run,
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: const Color(0xFF1E3557),
                padding: const EdgeInsets.symmetric(vertical: 12),
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
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        prefixIcon: Icon(icon, size: 18),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 42, minHeight: 42),
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
          height: 44,
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
              fontSize: 12, fontWeight: FontWeight.w600, color: _muted)),
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

  static DateTime? _parseProfileDate(String text) {
    final trimmed = text.trim();
    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) return parsed;
    final match =
        RegExp(r'^(\d{1,2})[/-](\d{1,2})[/-](\d{4})$').firstMatch(trimmed);
    if (match == null) return null;
    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    final year = int.tryParse(match.group(3) ?? '');
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
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

class _CalculatorRecentProfilesSheet extends StatefulWidget {
  final RecentProfileService service;
  final ValueChanged<Map<String, dynamic>> onSelected;

  const _CalculatorRecentProfilesSheet({
    required this.service,
    required this.onSelected,
  });

  @override
  State<_CalculatorRecentProfilesSheet> createState() =>
      _CalculatorRecentProfilesSheetState();
}

class _CalculatorRecentProfilesSheetState
    extends State<_CalculatorRecentProfilesSheet> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final items = await widget.service.list();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.58,
      minChildSize: 0.34,
      maxChildSize: 0.86,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                height: 4,
                width: 46,
                decoration: BoxDecoration(
                  color: Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 16, 18, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose Recent Profile',
                    style: TextStyle(
                      color: Color(0xFF1E3557),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : _items.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(18),
                                  child: Text(
                                    'No recent profiles yet. Generate any report once and it will appear here.',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollController,
                                padding:
                                    const EdgeInsets.fromLTRB(18, 8, 18, 24),
                                itemCount: _items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final profile = _items[index];
                                  final title = _profileString(
                                    profile['profile_label'] ??
                                        profile['person_name'] ??
                                        profile['name'] ??
                                        'Saved Profile',
                                  );
                                  final subtitle = [
                                    profile['date_of_birth'] ?? profile['dob'],
                                    profile['time_of_birth'] ?? profile['tob'],
                                    profile['place_of_birth'] ??
                                        profile['birth_place'] ??
                                        profile['pob'],
                                  ]
                                      .where((item) =>
                                          item != null &&
                                          item.toString().trim().isNotEmpty)
                                      .join(' - ');
                                  return ListTile(
                                    dense: true,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: const BorderSide(
                                        color: Color(0xFFE6D7BA),
                                      ),
                                    ),
                                    leading: const CircleAvatar(
                                      backgroundColor: Color(0xFFFFF3D0),
                                      child: Icon(
                                        Icons.person_outline,
                                        color: Color(0xFFD7AF4B),
                                      ),
                                    ),
                                    title: Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    subtitle: subtitle.isEmpty
                                        ? null
                                        : Text(
                                            subtitle,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                    onTap: () {
                                      widget.onSelected(profile);
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CalculatorInput {
  final DateTime date;
  final TimeOfDay time;
  final String place;
  final String coordinates;
  final String language;

  const _CalculatorInput({
    required this.date,
    required this.time,
    required this.place,
    required this.coordinates,
    required this.language,
  });
}

class _CalculatorTab {
  final String id;
  final String label;
  final dynamic payload;

  const _CalculatorTab({
    required this.id,
    required this.label,
    required this.payload,
  });
}

String _assetForTool(String key) {
  const assets = {
    'daily-nakshatra-predictions':
        'assets/images/calculators/daily_nakshatra.png',
    'daily_nakshatra_prediction':
        'assets/images/calculators/daily_nakshatra.png',
    'mangal-dosha': 'assets/images/calculators/mangal_dosha.png',
    'mangal_dosha_report': 'assets/images/calculators/mangal_dosha.png',
    'kaal-sarp-dosha': 'assets/images/calculators/kaalsarp_dosha.png',
    'kaalsarp_dosha_report': 'assets/images/calculators/kaalsarp_dosha.png',
    'sade-sati': 'assets/images/calculators/sade_sati.png',
    'sadhesati_current_status': 'assets/images/calculators/sade_sati.png',
    'pitra-dosha': 'assets/images/calculators/pitra_dosha.png',
    'pitra_dosha_report': 'assets/images/calculators/pitra_dosha.png',
    'puja-suggestion': 'assets/images/calculators/pooja_suggestion.png',
    'puja_suggestion': 'assets/images/calculators/pooja_suggestion.png',
    'basic-gem-suggestion': 'assets/images/calculators/gemstone_suggestion.png',
    'basic_gem_suggestion': 'assets/images/calculators/gemstone_suggestion.png',
    'rudraksha-suggestion':
        'assets/images/calculators/rudraksha_suggestion.png',
    'rudraksha_suggestion':
        'assets/images/calculators/rudraksha_suggestion.png',
    'vimshottari-dasha': 'assets/images/calculators/vimshottari_dasha.png',
    'current_vdasha': 'assets/images/calculators/vimshottari_dasha.png',
    'char-dasha': 'assets/images/calculators/char_dasha.png',
    'major_chardasha': 'assets/images/calculators/char_dasha.png',
    'yogini-dasha': 'assets/images/calculators/yogini_dasha.png',
    'major_yogini_dasha': 'assets/images/calculators/yogini_dasha.png',
    'varshaphal': 'assets/images/calculators/varshaphal.png',
    'varshaphal_details': 'assets/images/calculators/varshaphal.png',
    'kp': 'assets/images/calculators/krishnamurti_paddhati.png',
    'kp_planets': 'assets/images/calculators/krishnamurti_paddhati.png',
    'sarvashtakavarga': 'assets/images/calculators/ashtakavarga.png',
    'planet_ashtak': 'assets/images/calculators/ashtakavarga.png',
    'biorhythm': 'assets/images/calculators/biorhythm.png',
    '__kundli__': 'assets/images/reports/report-detailed-kundali.png',
  };
  return assets[key] ?? 'assets/images/services/calculators.png';
}

Color _toolAccentColor(String key) {
  final normalized = _calcKey(key);
  if (normalized.contains('mangal')) return const Color(0xFFEF4444);
  if (normalized.contains('kaal') || normalized.contains('kalsarpa')) {
    return const Color(0xFF8B5CF6);
  }
  if (normalized.contains('sade')) return const Color(0xFF2563EB);
  if (normalized.contains('pitra')) return const Color(0xFFF97316);
  if (normalized.contains('gem')) return const Color(0xFF10B981);
  if (normalized.contains('rudraksha')) return const Color(0xFF7C2D12);
  if (normalized.contains('puja')) return const Color(0xFFD97706);
  if (normalized.contains('vimshottari')) return const Color(0xFF7C3AED);
  if (normalized.contains('char_dasha')) return const Color(0xFF0EA5E9);
  if (normalized.contains('yogini')) return const Color(0xFFDB2777);
  if (normalized.contains('varshaphal')) return const Color(0xFF5B21B6);
  if (normalized == 'kp') return const Color(0xFF0F766E);
  if (normalized.contains('ashtak')) return const Color(0xFF059669);
  if (normalized.contains('biorhythm')) return const Color(0xFFEC4899);
  if (normalized.contains('nakshatra')) return const Color(0xFF0284C7);
  return const Color(0xFFD7AF4B);
}

Color _toolSoftColor(String key) {
  final accent = _toolAccentColor(key);
  return Color.alphaBlend(accent.withValues(alpha: 0.13), Colors.white);
}

class _CalculatorResultScreen extends StatefulWidget {
  final String toolKey;
  final String title;
  final String description;
  final Map<String, dynamic> response;
  final _CalculatorInput input;

  const _CalculatorResultScreen({
    required this.toolKey,
    required this.title,
    required this.description,
    required this.response,
    required this.input,
  });

  @override
  State<_CalculatorResultScreen> createState() =>
      _CalculatorResultScreenState();
}

class _CalculatorResultScreenState extends State<_CalculatorResultScreen> {
  static const _navy = Color(0xFF1E3557);
  static const _bg = Color(0xFFFBF7F0);
  static const _border = Color(0xFFE6D7BA);
  static const _muted = Color(0xFF6B7280);

  late final PageController _pageController;
  final _tabScrollController = ScrollController();
  late final List<_CalculatorTab> _tabs;
  late final List<GlobalKey> _tabKeys;
  int _activeIndex = 0;

  bool get _compactResultLayout => _isCompactResultTool(widget.toolKey);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabs = _buildTabs();
    _tabKeys = List.generate(_tabs.length, (_) => GlobalKey());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  List<_CalculatorTab> _buildTabs() {
    final tabs = <_CalculatorTab>[];
    final data = _calcAsMap(widget.response['data']);
    final sections = _calcAsList(data['provider_sections']);

    if (sections.isNotEmpty) {
      for (final rawSection in sections) {
        final section = _calcAsMap(rawSection);
        final items = _calcAsMap(section['items']);
        if (items.isEmpty) {
          final payload = section['provider_payload'] ?? section['data'];
          if (!_calcIsMeaningfullyEmpty(_calcUnwrap(payload))) {
            final id =
                _calcKey(section['id'] ?? section['title'] ?? widget.toolKey);
            tabs.add(_CalculatorTab(
              id: id,
              label: _calcFriendlyTitle(section['title'] ?? id),
              payload: payload,
            ));
          }
          continue;
        }
        for (final entry in items.entries) {
          final payload = entry.value;
          if (_calcHasError(payload)) continue;
          final clean = _calcUnwrap(payload);
          if (_calcIsMeaningfullyEmpty(clean)) continue;
          tabs.add(_CalculatorTab(
            id: _calcKey(entry.key),
            label: _calcFriendlyTitle(entry.key),
            payload: payload,
          ));
        }
      }
    }

    if (tabs.isEmpty) {
      final payload = data['provider_payload'] ?? data;
      tabs.add(_CalculatorTab(
        id: _calcKey(widget.toolKey),
        label: _calcFriendlyTitle(widget.title),
        payload: payload,
      ));
    }
    if (_calcKey(widget.toolKey) == 'yogini_dasha') {
      return _mergeYoginiTabs(tabs);
    }
    if (_calcKey(widget.toolKey) == 'vimshottari_dasha') {
      return _normalizeVimshottariTabs(tabs);
    }
    return tabs;
  }

  List<_CalculatorTab> _normalizeVimshottariTabs(List<_CalculatorTab> tabs) {
    final byId = <String, _CalculatorTab>{};
    for (final tab in tabs) {
      if (tab.id == 'current_vdasha_all') {
        continue;
      }
      byId.putIfAbsent(tab.id, () => tab);
    }

    const order = [
      'current_vdasha',
      'major_vdasha',
      'sub_vdasha',
      'sub_sub_vdasha',
      'sub_sub_sub_vdasha',
      'sub_sub_sub_sub_vdasha',
      'current_vdasha_date',
    ];
    final ordered = <_CalculatorTab>[];
    for (final id in order) {
      final tab = byId.remove(id);
      if (tab != null) ordered.add(tab);
    }
    ordered.addAll(byId.values);
    return ordered.isEmpty ? tabs : ordered;
  }

  List<_CalculatorTab> _mergeYoginiTabs(List<_CalculatorTab> tabs) {
    _CalculatorTab? major;
    _CalculatorTab? current;
    _CalculatorTab? sub;
    final remaining = <_CalculatorTab>[];

    for (final tab in tabs) {
      switch (tab.id) {
        case 'major_yogini_dasha':
          major = tab;
          break;
        case 'current_yogini_dasha':
          current = tab;
          break;
        case 'sub_yogini_dasha':
          sub = tab;
          break;
        default:
          remaining.add(tab);
      }
    }

    final merged = <_CalculatorTab>[];
    if (major != null || current != null) {
      merged.add(_CalculatorTab(
        id: 'yogini_dasha_details',
        label: 'Yogini Dasha Details',
        payload: {
          if (major != null) 'major': _calcUnwrap(major.payload),
          if (current != null) 'current': _calcUnwrap(current.payload),
        },
      ));
    }
    if (sub != null) {
      merged.add(_CalculatorTab(
        id: 'sub_yogini_dasha',
        label: 'Sub Yogini Dasha',
        payload: sub.payload,
      ));
    }
    merged.addAll(remaining);
    return merged.isEmpty ? tabs : merged;
  }

  void _setActive(int index) {
    if (index < 0 || index >= _tabs.length) return;
    setState(() => _activeIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
    _ensureTabVisible(index);
  }

  void _onPageChanged(int index) {
    setState(() => _activeIndex = index);
    _ensureTabVisible(index);
  }

  void _ensureTabVisible(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _tabKeys[index].currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.45,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(),
            _resultHeader(),
            if (_tabs.length > 1) _tabBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: _tabs.length > 1
                    ? const PageScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                itemCount: _tabs.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final tab = _tabs[index];
                  final body = _bodyForTab(tab);
                  final flatTab = _isFlatSuggestionTab(tab.id);
                  return ListView(
                    padding: EdgeInsets.fromLTRB(
                      14,
                      _compactResultLayout || flatTab ? 4 : 12,
                      14,
                      30,
                    ),
                    children: [
                      if (_compactResultLayout || flatTab)
                        body
                      else
                        _ResultPanel(
                          title: tab.label,
                          subtitle: _calcSubtitleFor(tab.id, widget.toolKey),
                          child: body,
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isFlatSuggestionTab(String id) {
    final normalized = _calcKey(id);
    const flatTabs = {
      'biorhythm',
      'moon_biorhythm',
      'puja_suggestion',
      'basic_gem_suggestion',
      'rudraksha_suggestion',
      'current_vdasha',
      'current_vdasha_all',
      'major_vdasha',
      'current_vdasha_date',
      'sub_vdasha',
      'sub_sub_vdasha',
      'sub_sub_sub_vdasha',
      'sub_sub_sub_sub_vdasha',
      'yogini_dasha_details',
      'sub_yogini_dasha',
      'varshaphal_year_chart',
      'varshaphal_month_chart',
      'varshaphal_details',
      'varshaphal_planets',
      'varshaphal_muntha',
      'varshaphal_mudda_dasha',
      'varshaphal_panchavargeeya_bala',
      'varshaphal_harsha_bala',
      'varshaphal_saham_points',
      'varshaphal_yoga',
      'kp_planets',
      'kp_house_cusps',
      'kp_birth_chart',
      'kp_house_significator',
      'kp_planet_significator',
      'sarvashtak',
    };
    return flatTabs.contains(normalized) ||
        normalized.startsWith('planet_ashtak');
  }

  Widget _resultHeader() {
    final accent = _toolAccentColor(widget.toolKey);
    final soft = _toolSoftColor(widget.toolKey);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(14, 6, 14, _tabs.length > 1 ? 8 : 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [soft, Colors.white],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.36)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.arrow_back, color: accent),
          ),
          const SizedBox(width: 2),
          Container(
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Image.asset(
              _assetForTool(widget.toolKey),
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_calcFormatDate(widget.input.date)} • ${_calcFormatTime(widget.input.time)} • ${widget.input.place}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    final denseTabs = widget.toolKey == 'varshaphal' ||
        widget.toolKey == 'kp' ||
        widget.toolKey == 'sarvashtakavarga' ||
        widget.toolKey == 'yogini-dasha';
    return SizedBox(
      height: denseTabs ? 38 : 42,
      child: ListView.separated(
        controller: _tabScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => SizedBox(width: denseTabs ? 5 : 6),
        itemBuilder: (context, index) {
          final selected = index == _activeIndex;
          return KeyedSubtree(
            key: _tabKeys[index],
            child: ChoiceChip(
              selected: selected,
              onSelected: (_) => _setActive(index),
              selectedColor: _navy,
              backgroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelPadding: EdgeInsets.symmetric(horizontal: denseTabs ? 6 : 8),
              side: BorderSide(color: selected ? _navy : _border),
              label: Text(
                _tabs[index].label,
                style: TextStyle(
                  color: selected ? Colors.white : _navy,
                  fontSize: denseTabs ? 10.4 : 11.4,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _bodyForTab(_CalculatorTab tab) {
    if (_calcHasError(tab.payload)) {
      return _UnavailableCard(message: _calcErrorMessage(tab.payload));
    }
    final clean = _calcUnwrap(tab.payload);
    if (tab.id.startsWith('planet_ashtak')) {
      return _AshtakavargaBody(data: clean, isSarvashtak: false);
    }
    switch (tab.id) {
      case 'current_vdasha':
      case 'current_vdasha_all':
      case 'major_vdasha':
      case 'current_vdasha_date':
      case 'sub_vdasha':
      case 'sub_sub_vdasha':
      case 'sub_sub_sub_vdasha':
      case 'sub_sub_sub_sub_vdasha':
      case 'major_chardasha':
      case 'current_chardasha':
      case 'sub_chardasha':
      case 'sub_sub_chardasha':
      case 'major_yogini_dasha':
      case 'current_yogini_dasha':
        return _DashaResultBody(tabId: tab.id, data: clean);
      case 'sub_yogini_dasha':
        return _YoginiSubDashaBody(data: clean);
      case 'sub_yogini_dasha_by_cycle':
        return _NestedRecordResultBody(data: clean);
      case 'yogini_dasha_details':
        return _YoginiDashaDetailsBody(data: clean);
      case 'varshaphal_year_chart':
        return _VarshaYearChartBody(data: clean);
      case 'varshaphal_month_chart':
        return _VarshaMonthChartBody(data: clean);
      case 'varshaphal_details':
        return _VarshaDetailsBody(data: clean);
      case 'varshaphal_planets':
        return _VarshaPlanetsBody(data: clean);
      case 'varshaphal_muntha':
        return _VarshaMunthaBody(data: clean);
      case 'varshaphal_panchavargeeya_bala':
      case 'varshaphal_harsha_bala':
        return _VarshaBalaBody(data: clean);
      case 'varshaphal_saham_points':
        return _VarshaSahamBody(data: clean);
      case 'varshaphal_yoga':
        return _VarshaYogaBody(data: clean);
      case 'varshaphal_mudda_dasha':
        return _DashaResultBody(tabId: tab.id, data: clean);
      case 'kp_planets':
        return _KpPlanetsBody(data: clean);
      case 'kp_house_cusps':
        return _KpHouseCuspsBody(data: clean);
      case 'kp_birth_chart':
        return _KpBirthChartBody(data: clean);
      case 'kp_house_significator':
        return _KpHouseSignificatorBody(data: clean);
      case 'kp_planet_significator':
        return _KpPlanetSignificatorBody(data: clean);
      case 'sarvashtak':
        return _AshtakavargaBody(data: clean, isSarvashtak: true);
      case 'manglik':
        return _StandaloneMangalDoshaBody(data: clean);
      case 'kalsarpa_details':
      case 'kaal_sarp_dosha':
        return _StandaloneKaalSarpDoshaBody(data: clean);
      case 'basic_gem_suggestion':
        return _GemSuggestionBody(data: _calcAsMap(clean));
      case 'puja_suggestion':
        return _PujaSuggestionBody(data: clean);
      case 'rudraksha_suggestion':
        return _RudrakshaSuggestionBody(data: _calcAsMap(clean));
      case 'biorhythm':
        return _StandaloneBiorhythmBody(
          data: clean,
          birthDate: widget.input.date,
        );
      case 'moon_biorhythm':
        return _StandaloneMoonBiorhythmBody(data: clean);
      default:
        return _CleanResultBody(
          data: clean,
          compact: _compactResultLayout,
          tabId: tab.id,
        );
    }
  }
}

class _ResultPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ResultPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  static const _navy = Color(0xFF1E3557);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFD7AF4B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: _navy, height: 1.3),
                  ),
                ],
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }
}

class _CleanResultBody extends StatelessWidget {
  final dynamic data;
  final bool compact;
  final String tabId;

  const _CleanResultBody({
    required this.data,
    this.compact = false,
    this.tabId = '',
  });

  @override
  Widget build(BuildContext context) {
    if (compact) return _CompactResultBody(data: data, tabId: tabId);
    return Column(children: _widgetsFor(data, depth: 0));
  }

  List<Widget> _widgetsFor(dynamic value, {required int depth}) {
    final clean = _calcCleanValue(value);
    if (_calcIsMeaningfullyEmpty(clean)) {
      return const [
        _UnavailableCard(message: 'This section is not available right now.'),
      ];
    }
    if (_calcIsPrimitive(clean)) {
      return [_TextCard(text: _calcValue(clean))];
    }
    final records = _calcRecordList(clean);
    if (records.isNotEmpty) {
      return [_RecordTable(title: '', records: records)];
    }
    final map = _calcAsMap(clean);
    if (map.isNotEmpty) {
      final simpleRows = <MapEntry<String, dynamic>>[];
      final nestedRows = <MapEntry<String, dynamic>>[];
      for (final entry in map.entries) {
        if (_calcShouldHideKey(entry.key)) continue;
        if (_calcIsMeaningfullyEmpty(entry.value)) continue;
        if (_calcIsPrimitive(entry.value) ||
            entry.value is List && _calcListIsPrimitive(entry.value)) {
          simpleRows.add(entry);
        } else {
          nestedRows.add(entry);
        }
      }
      final widgets = <Widget>[];
      if (simpleRows.isNotEmpty) {
        widgets.add(_InfoGrid(rows: simpleRows));
      }
      for (final entry in nestedRows) {
        final nested = _calcCleanValue(entry.value);
        final nestedRecords = _calcRecordList(nested);
        if (nestedRecords.isNotEmpty) {
          widgets.add(_RecordTable(
            title: _calcFriendlyTitle(entry.key),
            records: nestedRecords,
          ));
        } else {
          widgets.add(_FlatDataSection(
            title: _calcFriendlyTitle(entry.key),
            value: nested,
          ));
        }
      }
      return widgets.isEmpty
          ? const [
              _UnavailableCard(
                  message: 'This section is not available right now.'),
            ]
          : widgets;
    }
    final list = _calcAsList(clean);
    if (list.isNotEmpty) {
      return list
          .asMap()
          .entries
          .map((entry) => _FlatDataSection(
                title: 'Entry ${entry.key + 1}',
                value: entry.value,
              ))
          .toList();
    }
    return [_TextCard(text: _calcValue(clean))];
  }
}

class _CompactResultBody extends StatelessWidget {
  final dynamic data;
  final String tabId;

  const _CompactResultBody({required this.data, required this.tabId});

  @override
  Widget build(BuildContext context) {
    final clean = _calcCleanValue(data);
    if (_calcIsMeaningfullyEmpty(clean)) {
      return const _UnavailableCard(
        message: 'This section is not available right now.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _widgetsFor(clean, depth: 0),
    );
  }

  List<Widget> _widgetsFor(dynamic value, {required int depth}) {
    final clean = _calcCleanValue(value);
    if (_calcIsMeaningfullyEmpty(clean)) return const [];

    if (_calcIsPrimitive(clean)) {
      return [_CompactPredictionCard(text: _calcValue(clean))];
    }

    final records = _calcRecordList(clean);
    if (records.isNotEmpty) {
      return [_CompactRecordTable(records: records)];
    }

    final map = _calcAsMap(clean);
    if (map.isNotEmpty) {
      final rows = <MapEntry<String, dynamic>>[];
      final textCards = <Widget>[];
      final sections = <Widget>[];

      for (final entry in map.entries) {
        if (_calcShouldHideKey(entry.key) ||
            _calcIsMeaningfullyEmpty(entry.value)) {
          continue;
        }
        final entryValue = _calcCleanValue(entry.value);
        final key = _calcKey(entry.key);
        final textValue = _calcCleanText(_calcValue(entryValue));
        final isLongText = _compactTextKey(key) || textValue.length > 120;

        if (_calcIsPrimitive(entryValue) || _calcListIsPrimitive(entryValue)) {
          if (isLongText) {
            textCards.add(_CompactPredictionCard(
              title: _compactCardTitle(entry.key),
              text: textValue,
            ));
          } else {
            rows.add(MapEntry(entry.key, entryValue));
          }
          continue;
        }

        final nestedRecords = _calcRecordList(entryValue);
        if (nestedRecords.isNotEmpty) {
          sections.add(_CompactInlineSection(
            title: _compactSectionTitle(entry.key, depth),
            child: _CompactRecordTable(records: nestedRecords),
          ));
          continue;
        }

        final nestedMap = _calcAsMap(entryValue);
        if (nestedMap.isNotEmpty) {
          final nestedRows = nestedMap.entries
              .where((nestedEntry) =>
                  !_calcShouldHideKey(nestedEntry.key) &&
                  !_calcIsMeaningfullyEmpty(nestedEntry.value) &&
                  (_calcIsPrimitive(nestedEntry.value) ||
                      _calcListIsPrimitive(nestedEntry.value)))
              .toList();
          if (nestedRows.length == nestedMap.length && nestedRows.isNotEmpty) {
            sections.add(_CompactInlineSection(
              title: _compactSectionTitle(entry.key, depth),
              child: _CompactKeyValueTable(rows: nestedRows),
            ));
          } else {
            sections.add(_CompactInlineSection(
              title: _compactSectionTitle(entry.key, depth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _widgetsFor(entryValue, depth: depth + 1),
              ),
            ));
          }
          continue;
        }

        textCards.add(_CompactPredictionCard(
          title: _compactCardTitle(entry.key),
          text: textValue,
        ));
      }

      final widgets = <Widget>[
        if (rows.isNotEmpty) _CompactKeyValueTable(rows: rows),
        ...textCards,
        ...sections,
      ];
      return widgets.isEmpty
          ? const [
              _UnavailableCard(
                  message: 'This section is not available right now.'),
            ]
          : widgets;
    }

    final list = _calcAsList(clean);
    if (list.isNotEmpty) {
      return list
          .asMap()
          .entries
          .expand(
            (entry) => _widgetsFor(entry.value, depth: depth + 1),
          )
          .toList();
    }

    return [_CompactPredictionCard(text: _calcValue(clean))];
  }

  bool _compactTextKey(String key) {
    return key.contains('prediction') ||
        key.contains('description') ||
        key.contains('conclusion') ||
        key.contains('remedy') ||
        key.contains('remedies') ||
        key.contains('report') ||
        key.contains('details') ||
        key.contains('effect') ||
        key.contains('impact') ||
        key.contains('summary');
  }

  String _compactCardTitle(String raw) {
    final key = _calcKey(raw);
    if (key == tabId ||
        key == 'prediction' ||
        key == 'description' ||
        key == 'details' ||
        key == 'report') {
      return '';
    }
    return _calcFriendlyTitle(raw);
  }

  String _compactSectionTitle(String raw, int depth) {
    final key = _calcKey(raw);
    if (depth == 0 && (key == tabId || key == 'data')) return '';
    return _calcFriendlyTitle(raw);
  }
}

class _CompactInlineSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _CompactInlineSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 7),
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1E3557),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
          child,
        ],
      ),
    );
  }
}

class _CompactKeyValueTable extends StatelessWidget {
  final List<MapEntry<String, dynamic>> rows;

  const _CompactKeyValueTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final visible = rows
        .where((entry) =>
            !_calcShouldHideKey(entry.key) &&
            !_calcIsImageKey(entry.key) &&
            !_calcIsMeaningfullyEmpty(entry.value))
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE6D7BA)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(0.9),
              1: FlexColumnWidth(1.35),
            },
            border: TableBorder.symmetric(
              inside: const BorderSide(color: Color(0xFFE8E0CF)),
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: visible.asMap().entries.map((entry) {
              final row = entry.value;
              return TableRow(
                decoration: BoxDecoration(
                  color:
                      entry.key.isEven ? Colors.white : const Color(0xFFFFFCF4),
                ),
                children: [
                  _CompactTableCell(
                    _calcFriendlyTitle(row.key),
                    attribute: true,
                  ),
                  _CompactTableCell(_calcCleanText(_calcValue(row.value))),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _CompactRecordTable extends StatelessWidget {
  final List<Map<String, dynamic>> records;

  const _CompactRecordTable({required this.records});

  @override
  Widget build(BuildContext context) {
    final cleaned = records
        .map((record) => _calcCleanMap(record))
        .where((record) => record.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return const SizedBox.shrink();

    if (cleaned.length == 1) {
      return _CompactKeyValueTable(rows: cleaned.first.entries.toList());
    }

    final columns = <String>[];
    for (final record in cleaned) {
      for (final key in record.keys) {
        if (!_calcShouldHideKey(key) &&
            !_calcIsImageKey(key) &&
            !columns.contains(key)) {
          columns.add(key);
        }
      }
    }
    if (columns.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE6D7BA)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFD7AF4B)),
              dataRowMinHeight: 36,
              dataRowMaxHeight: 82,
              columnSpacing: 9,
              horizontalMargin: 8,
              headingTextStyle: const TextStyle(
                color: Color(0xFF1E3557),
                fontWeight: FontWeight.w900,
                fontSize: 10.5,
                height: 1.08,
              ),
              dataTextStyle: const TextStyle(
                color: Color(0xFF102A52),
                fontWeight: FontWeight.w400,
                height: 1.18,
                fontSize: 11.5,
              ),
              columns: columns.map((column) {
                final width = _calcColumnWidth(column, '');
                return DataColumn(
                  label: SizedBox(
                    width: width,
                    child: Text(
                      _calcFriendlyTitle(column).toUpperCase(),
                      softWrap: true,
                      maxLines: 2,
                    ),
                  ),
                );
              }).toList(),
              rows: cleaned.map((record) {
                return DataRow(
                  cells: columns.map((column) {
                    final value = _calcCleanText(_calcValue(record[column]));
                    final width = _calcColumnWidth(column, value);
                    return DataCell(
                      SizedBox(
                        width: width,
                        child: Text(value, softWrap: true),
                      ),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactTableCell extends StatelessWidget {
  final String value;
  final bool attribute;

  const _CompactTableCell(this.value, {this.attribute = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        value.isEmpty ? '-' : value,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: const Color(0xFF102A52),
          fontSize: attribute ? 11.5 : 11.5,
          height: 1.18,
          fontWeight: attribute ? FontWeight.w900 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _CompactPredictionCard extends StatelessWidget {
  final String title;
  final String text;

  const _CompactPredictionCard({this.title = '', required this.text});

  @override
  Widget build(BuildContext context) {
    final cleaned = _calcCleanText(text);
    if (cleaned.isEmpty || cleaned == '-') return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6D7BA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1E3557),
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
            cleaned,
            style: const TextStyle(
              color: Color(0xFF102A52),
              fontSize: 13.5,
              height: 1.34,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _StandaloneMangalDoshaBody extends StatelessWidget {
  final dynamic data;

  const _StandaloneMangalDoshaBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final root = _calcAsMap(_calcCleanValue(data));
    if (root.isEmpty) {
      return const _UnavailableCard(
        message:
            'Mangal Dosha details are not available for this birth profile.',
      );
    }

    final present = _doshaBool(_bioLookup(root, const [
      'is_present',
      'present',
      'manglik_present',
      'is_manglik',
    ]));
    final status = _cleanDoshaStatus(_bioLookup(root, const [
      'manglik_status',
      'status',
      'mangal_status',
    ]));
    final beforePercent = _doshaNumber(_bioLookup(root, const [
      'percentage_manglik_present',
      'manglik_percentage',
      'percentage',
    ]));
    final afterPercent = _doshaNumber(_bioLookup(root, const [
      'percentage_manglik_after_cancellation',
      'percentage_after_cancellation',
    ]));
    final cancelled = _doshaBool(_bioLookup(root, const [
      'is_mars_manglik_cancelled',
      'is_manglik_cancelled',
      'manglik_cancelled',
    ]));
    final report = _doshaParagraphs(_bioLookup(root, const [
      'manglik_report',
      'report',
      'description',
    ]));

    final accent = present == true
        ? const Color(0xFFEF4444)
        : beforePercent != null && beforePercent > 0
            ? const Color(0xFFF59E0B)
            : const Color(0xFF10B981);
    final verdict = present == true
        ? 'Manglik Influence Present'
        : beforePercent != null && beforePercent > 0
            ? 'Weak Mangal Influence'
            : 'No Strong Mangal Dosha';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DoshaStatusBand(
          icon: Icons.local_fire_department_rounded,
          title: verdict,
          value: status == '-'
              ? (present == true ? 'PRESENT' : 'LOW RISK')
              : status,
          color: accent,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (beforePercent != null)
              _DoshaMetricChip(
                label: 'Mangal Strength',
                value: '${_varshaNumber(beforePercent)}%',
                color: accent,
              ),
            if (afterPercent != null)
              _DoshaMetricChip(
                label: 'After Cancellation',
                value: '${_varshaNumber(afterPercent)}%',
                color: cancelled == true
                    ? const Color(0xFF10B981)
                    : const Color(0xFF2563EB),
              ),
            if (cancelled != null)
              _DoshaMetricChip(
                label: 'Cancellation',
                value: cancelled ? 'Yes' : 'No',
                color: cancelled
                    ? const Color(0xFF10B981)
                    : const Color(0xFF64748B),
              ),
          ],
        ),
        if (report.isNotEmpty) ...[
          const SizedBox(height: 10),
          _DoshaParagraphCard(paragraphs: report),
        ],
        ..._mangalRuleCards(root),
      ],
    );
  }
}

class _StandaloneKaalSarpDoshaBody extends StatelessWidget {
  final dynamic data;

  const _StandaloneKaalSarpDoshaBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final root = _calcAsMap(_calcCleanValue(data));
    if (root.isEmpty) {
      return const _UnavailableCard(
        message:
            'Kaal Sarp Dosha details are not available for this birth profile.',
      );
    }

    final present = _doshaBool(_bioLookup(root, const [
      'present',
      'is_present',
      'kaal_sarp_present',
      'kalsarpa_present',
    ]));
    final name = _calcCleanText(_calcValue(_bioLookup(root, const ['name'])));
    final type = _calcCleanText(_calcValue(_bioLookup(root, const ['type'])));
    final oneLine = _calcCleanText(
      _calcValue(_bioLookup(root, const ['one_line', 'oneLine', 'summary'])),
    );
    final reportMap = _calcAsMap(root['report']);
    final report = _doshaParagraphs(
      reportMap['report'] ??
          _bioLookup(root, const ['report_text', 'description', 'details']),
    );
    final accent =
        present == true ? const Color(0xFFE11D48) : const Color(0xFF10B981);

    final details = <MapEntry<String, dynamic>>[
      if (name != '-') MapEntry('Dosha Name', name),
      if (type != '-') MapEntry('Type', type),
      if (present != null)
        MapEntry('Status', present ? 'Present' : 'Not Present'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (details.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: details
                .map((entry) => _DoshaMetricChip(
                      label: entry.key,
                      value: _calcValue(entry.value),
                      color: accent,
                    ))
                .toList(),
          ),
        if (oneLine.isNotEmpty && oneLine != '-') ...[
          const SizedBox(height: 10),
          _DoshaHighlight(text: oneLine, color: accent),
        ],
        if (report.isNotEmpty) ...[
          const SizedBox(height: 10),
          _DoshaParagraphCard(paragraphs: report),
        ],
      ],
    );
  }
}

class _DoshaStatusBand extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _DoshaStatusBand({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1E3557),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoshaMetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DoshaMetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11.5, height: 1.1),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: Color(0xFF1E3557),
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(
              text: value,
              style: TextStyle(color: color, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoshaHighlight extends StatelessWidget {
  final String text;
  final Color color;

  const _DoshaHighlight({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF102A52),
          fontSize: 13.5,
          height: 1.35,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DoshaParagraphCard extends StatelessWidget {
  final List<String> paragraphs;

  const _DoshaParagraphCard({required this.paragraphs});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: paragraphs
            .map(
              (paragraph) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  paragraph,
                  style: const TextStyle(
                    color: Color(0xFF102A52),
                    fontSize: 13,
                    height: 1.36,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

List<Widget> _mangalRuleCards(Map<String, dynamic> root) {
  final widgets = <Widget>[];
  for (final item in const [
    MapEntry('Presence Rules', 'manglik_present_rule'),
    MapEntry('Cancellation Rules', 'manglik_cancel_rule'),
  ]) {
    final value = _calcCleanValue(root[item.value]);
    if (_calcIsMeaningfullyEmpty(value)) continue;
    final rows = _calcAsMap(value)
        .entries
        .where((entry) =>
            !_calcShouldHideKey(entry.key) &&
            !_calcIsMeaningfullyEmpty(entry.value))
        .toList();
    if (rows.isEmpty) continue;
    widgets.add(const SizedBox(height: 10));
    widgets.add(_CompactInlineSection(
      title: item.key,
      child: _CompactKeyValueTable(rows: rows),
    ));
  }
  return widgets;
}

bool? _doshaBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = value?.toString().trim().toLowerCase();
  if (text == null || text.isEmpty || text == '-') return null;
  if (const {'true', 'yes', 'y', 'present', '1'}.contains(text)) return true;
  if (const {'false', 'no', 'n', 'not present', '0'}.contains(text)) {
    return false;
  }
  return null;
}

double? _doshaNumber(dynamic value) {
  if (value is num) return value.toDouble();
  final text = value?.toString().replaceAll('%', '').trim();
  if (text == null || text.isEmpty) return null;
  return double.tryParse(text);
}

String _cleanDoshaStatus(dynamic value) {
  final text = _calcCleanText(_calcValue(value));
  if (text == '-') return text;
  return text.toUpperCase();
}

List<String> _doshaParagraphs(dynamic value) {
  final text = _calcCleanText(_calcValue(value));
  if (text.isEmpty || text == '-') return const [];
  return text
      .split(RegExp(r'\.\s+'))
      .map((item) => item.endsWith('.') ? item : '$item.')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty && item != '.')
      .toList();
}

class _GemSuggestionBody extends StatelessWidget {
  final Map<String, dynamic> data;

  const _GemSuggestionBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final entries = data.entries
        .where((entry) => _calcAsMap(entry.value).isNotEmpty)
        .map((entry) =>
            MapEntry(_calcFriendlyTitle(entry.key), _calcAsMap(entry.value)))
        .toList();
    if (entries.isEmpty) return _CleanResultBody(data: data);
    return SizedBox(
      height: 468,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.96),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFFAEC), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE6D7BA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SuggestionBadge(
                    icon: Icons.diamond_outlined,
                    label: '${entry.key} Stone',
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _SuggestionCapsuleGrid(
                        rows: entry.value.entries.toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PujaSuggestionBody extends StatelessWidget {
  final dynamic data;

  const _PujaSuggestionBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final clean = _calcCleanValue(data);
    final summary = _pujaSummary(clean);
    final rows = _pujaSuggestionRows(clean);

    if (rows.isEmpty && _calcIsMeaningfullyEmpty(summary)) {
      return const _UnavailableCard(
        message: 'Pooja suggestions are not available right now.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_calcIsMeaningfullyEmpty(summary)) ...[
          _SuggestionTextBlock(text: _calcValue(summary)),
          const SizedBox(height: 10),
        ],
        if (rows.isNotEmpty)
          _SuggestionRecordTable(
            records: rows,
            hiddenKeys: const {
              'id',
              'puja_id',
              'pujaid',
              'priority',
            },
            preferredColumns: const [
              ['status'],
              ['title', 'name'],
              ['summary', 'description', 'details'],
              ['one_line', 'oneLine', 'report'],
            ],
          ),
      ],
    );
  }
}

class _DashaResultBody extends StatelessWidget {
  final String tabId;
  final dynamic data;

  const _DashaResultBody({required this.tabId, required this.data});

  @override
  Widget build(BuildContext context) {
    final clean = _calcCleanValue(data);
    if (_calcIsMeaningfullyEmpty(clean)) {
      return const _UnavailableCard(
        message: 'This Dasha section is not available right now.',
      );
    }

    final listRecords = _calcRecordList(clean);
    if (listRecords.isNotEmpty) {
      return _DashaFlatRecordTable(records: _compactDashaRows(listRecords));
    }

    final map = _calcAsMap(clean);
    if (map.isEmpty) return _CleanResultBody(data: clean);

    final widgets = <Widget>[];
    final scalarRows = <MapEntry<String, dynamic>>[];

    for (final entry in map.entries) {
      if (_dashaShouldHideKey(entry.key) ||
          _calcIsMeaningfullyEmpty(entry.value)) {
        continue;
      }
      final value = _calcCleanValue(entry.value);
      if (_calcIsPrimitive(value) || _calcListIsPrimitive(value)) {
        scalarRows.add(entry);
        continue;
      }
      widgets.addAll(_dashaWidgetsFor(value));
    }

    if (scalarRows.isNotEmpty) {
      widgets.insert(0, _DashaFlatKeyValueTable(rows: scalarRows));
    }

    if (widgets.isEmpty) return _CleanResultBody(data: clean);
    return _DashaTableStack(children: widgets);
  }
}

class _DashaTableStack extends StatelessWidget {
  final List<Widget> children;

  const _DashaTableStack({required this.children});

  @override
  Widget build(BuildContext context) {
    final visible = children
        .where((child) => child is! SizedBox || child.width != 0)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < visible.length; index++) ...[
          visible[index],
          if (index < visible.length - 1) const SizedBox(height: 9),
        ],
      ],
    );
  }
}

List<Widget> _dashaWidgetsFor(dynamic source) {
  final clean = _calcCleanValue(source);
  if (_calcIsMeaningfullyEmpty(clean)) return const [];

  final records = _calcRecordList(clean);
  if (records.isNotEmpty) {
    return [_DashaFlatRecordTable(records: _compactDashaRows(records))];
  }

  final map = _calcAsMap(clean);
  if (map.isNotEmpty) {
    final scalarRows = <MapEntry<String, dynamic>>[];
    final widgets = <Widget>[];
    for (final entry in map.entries) {
      if (_dashaShouldHideKey(entry.key) ||
          _calcIsMeaningfullyEmpty(entry.value)) {
        continue;
      }
      final value = _calcCleanValue(entry.value);
      if (_calcIsPrimitive(value) || _calcListIsPrimitive(value)) {
        scalarRows.add(entry);
      } else {
        widgets.addAll(_dashaWidgetsFor(value));
      }
    }
    return [
      if (scalarRows.isNotEmpty) _DashaFlatKeyValueTable(rows: scalarRows),
      ...widgets,
    ];
  }

  final list = _calcAsList(clean);
  if (list.isNotEmpty) {
    return list.expand(_dashaWidgetsFor).toList();
  }

  return [
    _DashaFlatKeyValueTable(rows: [MapEntry('Value', clean)])
  ];
}

class _DashaFlatKeyValueTable extends StatelessWidget {
  final List<MapEntry<String, dynamic>> rows;

  const _DashaFlatKeyValueTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final visible = rows
        .where((entry) =>
            !_dashaShouldHideKey(entry.key) &&
            !_calcIsImageKey(entry.key) &&
            !_calcIsMeaningfullyEmpty(entry.value))
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE6D7BA)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(0.86),
            1: FlexColumnWidth(1.24),
          },
          border: TableBorder.symmetric(
            inside: const BorderSide(color: Color(0xFFE8E0CF), width: 0.8),
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Color(0xFFD7AF4B)),
              children: [
                _DashaTableHeaderCell('Attribute'),
                _DashaTableHeaderCell('Value'),
              ],
            ),
            ...visible.asMap().entries.map((entry) {
              final row = entry.value;
              return TableRow(
                decoration: BoxDecoration(
                  color:
                      entry.key.isEven ? Colors.white : const Color(0xFFFFFCF4),
                ),
                children: [
                  _DashaTableCell(_calcFriendlyTitle(row.key), attribute: true),
                  _DashaTableCell(_calcCleanText(_calcValue(row.value))),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _DashaFlatRecordTable extends StatelessWidget {
  final List<Map<String, dynamic>> records;

  const _DashaFlatRecordTable({required this.records});

  @override
  Widget build(BuildContext context) {
    final cleaned = _compactDashaRows(records)
        .map((record) => Map<String, dynamic>.from(record)
          ..removeWhere((key, value) =>
              _dashaShouldHideKey(key) || _calcIsMeaningfullyEmpty(value)))
        .where((record) => record.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return const SizedBox.shrink();
    if (cleaned.length == 1) {
      return _DashaFlatKeyValueTable(rows: cleaned.first.entries.toList());
    }

    final columns = _dashaColumns(cleaned);
    if (columns.isEmpty) return const SizedBox.shrink();
    final tableWidth = columns.fold<double>(
        0, (sum, column) => sum + _dashaColumnWidth(column));

    return LayoutBuilder(builder: (context, constraints) {
      final effectiveWidth =
          tableWidth < constraints.maxWidth ? constraints.maxWidth : tableWidth;
      final needsHorizontalScroll = tableWidth > constraints.maxWidth;
      final table = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: effectiveWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE6D7BA)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Table(
              columnWidths: {
                for (var i = 0; i < columns.length; i++)
                  i: FixedColumnWidth(
                    effectiveWidth *
                        (_dashaColumnWidth(columns[i]) / tableWidth),
                  ),
              },
              border: TableBorder.symmetric(
                inside: const BorderSide(color: Color(0xFFE8E0CF), width: 0.8),
              ),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFD7AF4B)),
                  children: columns
                      .map((column) =>
                          _DashaTableHeaderCell(_calcFriendlyTitle(column)))
                      .toList(),
                ),
                ...cleaned.asMap().entries.map((entry) {
                  final record = entry.value;
                  return TableRow(
                    decoration: BoxDecoration(
                      color: entry.key.isEven
                          ? Colors.white
                          : const Color(0xFFFFFCF4),
                    ),
                    children: columns
                        .map((column) => _DashaTableCell(
                              _calcCleanText(_calcValue(record[column])),
                            ))
                        .toList(),
                  );
                }),
              ],
            ),
          ),
        ),
      );
      if (!needsHorizontalScroll) return table;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DashaScrollHint(),
          const SizedBox(height: 5),
          table,
        ],
      );
    });
  }
}

class _DashaScrollHint extends StatelessWidget {
  const _DashaScrollHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7DD),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.swipe_left_alt_rounded,
            size: 13,
            color: Color(0xFF8A5A00),
          ),
          SizedBox(width: 5),
          Text(
            'Scroll table left or right',
            style: TextStyle(
              color: Color(0xFF8A5A00),
              fontSize: 10.4,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashaTableHeaderCell extends StatelessWidget {
  final String text;

  const _DashaTableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF1E3557),
          fontSize: 10.3,
          height: 1.05,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DashaTableCell extends StatelessWidget {
  final String text;
  final bool attribute;

  const _DashaTableCell(this.text, {this.attribute = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: Text(
        text.isEmpty ? '-' : text,
        maxLines: attribute ? 3 : 4,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: const Color(0xFF102A52),
          fontSize: 10.7,
          height: 1.1,
          fontWeight: attribute ? FontWeight.w900 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _YoginiDashaDetailsBody extends StatefulWidget {
  final dynamic data;

  const _YoginiDashaDetailsBody({required this.data});

  @override
  State<_YoginiDashaDetailsBody> createState() =>
      _YoginiDashaDetailsBodyState();
}

class _YoginiDashaDetailsBodyState extends State<_YoginiDashaDetailsBody> {
  int _active = 0;

  @override
  Widget build(BuildContext context) {
    final map = _calcAsMap(_calcCleanValue(widget.data));
    final majorRows = _yoginiMajorRows(map['major']);
    final currentRows = _yoginiCurrentRows(map['current']);
    final labels = <String>[];
    final views = <Widget>[];

    if (majorRows.isNotEmpty) {
      labels.add('Mahadasha');
      views.add(_VarshaRecordTable(
        records: majorRows,
        preferredColumns: const ['dasha', 'start', 'end', 'duration'],
      ));
    }
    if (currentRows.isNotEmpty) {
      labels.add('Current Dasha');
      views.add(_VarshaRecordTable(
        records: currentRows,
        preferredColumns: const ['level', 'dasha', 'start', 'end', 'duration'],
      ));
    }

    if (views.isEmpty) {
      return const _UnavailableCard(
        message: 'Yogini Dasha details are not available right now.',
      );
    }
    final selected = _active.clamp(0, views.length - 1);
    if (selected != _active) _active = selected;

    return Column(
      children: [
        if (labels.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _YoginiSegmentedTabs(
              labels: labels,
              activeIndex: selected,
              onChanged: (index) => setState(() => _active = index),
            ),
          ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: KeyedSubtree(
            key: ValueKey(selected),
            child: views[selected],
          ),
        ),
      ],
    );
  }
}

class _YoginiSegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  const _YoginiSegmentedTabs({
    required this.labels,
    required this.activeIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Row(
        children: labels.asMap().entries.map((entry) {
          final selected = entry.key == activeIndex;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(entry.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF1E3557) : Colors.white,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  entry.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF1E3557),
                    fontSize: 11.2,
                    height: 1.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _YoginiSubDashaBody extends StatelessWidget {
  final dynamic data;

  const _YoginiSubDashaBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final groups = _calcRecordList(_calcCleanValue(data))
        .map(_yoginiSubGroup)
        .where((group) => group.rows.isNotEmpty)
        .toList();
    if (groups.isEmpty) {
      return const _UnavailableCard(
        message: 'Sub Yogini Dasha details are not available right now.',
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      const gap = 8.0;
      final columns = constraints.maxWidth < 360 ? 2 : 3;
      final width = (constraints.maxWidth - (gap * (columns - 1))) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: groups.map((group) {
          return SizedBox(
            width: width,
            child: _YoginiSubTile(
              group: group,
              onTap: () => _showYoginiSubDialog(context, group),
            ),
          );
        }).toList(),
      );
    });
  }
}

class _YoginiSubTile extends StatelessWidget {
  final _YoginiSubGroup group;
  final VoidCallback onTap;

  const _YoginiSubTile({
    required this.group,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6D7BA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1E3557),
                  fontSize: 11.8,
                  height: 1.08,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                '${group.rows.length} sub dasha',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'See Sub Dasha',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Color(0xFFD7AF4B),
                        fontSize: 10.4,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 17,
                    color: Color(0xFFD7AF4B),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YoginiSubGroup {
  final String name;
  final List<Map<String, dynamic>> rows;

  const _YoginiSubGroup({
    required this.name,
    required this.rows,
  });
}

void _showYoginiSubDialog(BuildContext context, _YoginiSubGroup group) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1E3557),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.68,
                ),
                child: SingleChildScrollView(
                  child: _VarshaRecordTable(
                    records: group.rows,
                    preferredColumns: const ['dasha', 'start', 'end'],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _VarshaYearChartBody extends StatelessWidget {
  final dynamic data;

  const _VarshaYearChartBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final map = _calcAsMap(_calcCleanValue(data));
    final chart = _varshaChartRows(map['chart']);
    final summary = <MapEntry<String, dynamic>>[
      if (!_calcIsMeaningfullyEmpty(map['year_lord']))
        MapEntry('Year Lord', map['year_lord']),
      if (!_calcIsMeaningfullyEmpty(map['varshaphal_date']))
        MapEntry('Varshaphal Date', map['varshaphal_date']),
    ];
    if (summary.isEmpty && chart.isEmpty) {
      return const _UnavailableCard(
        message: 'Varshaphal chart details are not available right now.',
      );
    }
    return Column(
      children: [
        if (summary.isNotEmpty) _VarshaKeyValueTable(rows: summary),
        if (chart.isNotEmpty)
          _VarshaRecordTable(
            records: chart,
            preferredColumns: const [
              'sign',
              'sign_name',
              'planets',
            ],
          ),
      ],
    );
  }
}

class _VarshaMonthChartBody extends StatelessWidget {
  final dynamic data;

  const _VarshaMonthChartBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final months = _calcRecordList(_calcCleanValue(data))
        .where((record) => _varshaChartRows(record['chart']).isNotEmpty)
        .toList();
    if (months.isEmpty) {
      return const _UnavailableCard(
        message: 'Monthly Varshaphal charts are not available right now.',
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      const gap = 8.0;
      final columns = constraints.maxWidth < 340 ? 2 : 3;
      final width = (constraints.maxWidth - (gap * (columns - 1))) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: months.map((record) {
          final month = _calcValue(record['month_id'] ?? record['month']);
          final rows = _varshaChartRows(record['chart']);
          final planetCount = rows.fold<int>(
            0,
            (sum, row) {
              final planets = _calcValue(row['planets']);
              if (planets == '-' || planets == 'None') return sum;
              return sum + planets.split(',').length;
            },
          );
          return SizedBox(
            width: width,
            child: _VarshaMonthTile(
              title: month == '-' ? 'Month' : 'Month $month',
              subtitle: '$planetCount planets',
              onTap: () => _showVarshaMonthDialog(context, month, rows),
            ),
          );
        }).toList(),
      );
    });
  }
}

class _VarshaMonthTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _VarshaMonthTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6D7BA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1E3557),
                  fontSize: 12.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFFD7AF4B),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showVarshaMonthDialog(
  BuildContext context,
  String month,
  List<Map<String, dynamic>> rows,
) {
  showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      month == '-' ? 'Month Chart' : 'Month $month Chart',
                      style: const TextStyle(
                        color: Color(0xFF1E3557),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.68,
                ),
                child: SingleChildScrollView(
                  child: _VarshaRecordTable(
                    records: rows,
                    preferredColumns: const ['sign', 'sign_name', 'planets'],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _VarshaDetailsBody extends StatelessWidget {
  final dynamic data;

  const _VarshaDetailsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final map = _calcAsMap(_calcCleanValue(data));
    if (map.isEmpty) {
      return const _UnavailableCard(
        message: 'Varshaphal details are not available right now.',
      );
    }

    final panchadhikari = _calcAsMap(map['panchadhikari']);
    final muntha = _calcAsMap(map['varshaphala_muntha']);
    final basicRows = <MapEntry<String, dynamic>>[];
    for (final key in const [
      'varshaphala_year',
      'age_of_native',
      'ayanamsha_name',
      'ayanamsha_degree',
      'native_birth_date',
      'varshaphala_date',
      'varshaphala_year_lord',
    ]) {
      if (!_calcIsMeaningfullyEmpty(map[key])) {
        basicRows.add(MapEntry(key, map[key]));
      }
    }
    final munthaRows = muntha.entries
        .where((entry) =>
            !_calcShouldHideKey(entry.key) &&
            !_calcIsMeaningfullyEmpty(entry.value))
        .toList();

    return Column(
      children: [
        if (basicRows.isNotEmpty) _VarshaKeyValueTable(rows: basicRows),
        if (panchadhikari.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _VarshaPanchadhikariGrid(data: panchadhikari),
          ),
        if (munthaRows.isNotEmpty) _VarshaKeyValueTable(rows: munthaRows),
      ],
    );
  }
}

class _VarshaPanchadhikariGrid extends StatelessWidget {
  final Map<String, dynamic> data;

  const _VarshaPanchadhikariGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final items = <_VarshaColorTileData>[
      _VarshaColorTileData(
        'Muntha Lord',
        _calcValue(data['muntha_lord']),
        const Color(0xFFFFF3C4),
      ),
      _VarshaColorTileData(
        'Birth Ascendant Lord',
        _calcValue(data['birth_ascendant_lord']),
        const Color(0xFFDDEBFF),
      ),
      _VarshaColorTileData(
        'Year Ascendant Lord',
        _calcValue(data['year_ascendant_lord']),
        const Color(0xFFFFE1E5),
      ),
      _VarshaColorTileData(
        'Dinratri Lord',
        _calcValue(data['dinratri_lord']),
        const Color(0xFFE3F8E8),
      ),
      _VarshaColorTileData(
        'Trirashi Lord',
        _calcValue(data['trirashi_lord']),
        const Color(0xFFE9E6FF),
      ),
    ].where((item) => item.value != '-').toList();
    if (items.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      const gap = 6.0;
      final width = (constraints.maxWidth - gap) / 2;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: items
            .map(
                (item) => SizedBox(width: width, child: _VarshaColorTile(item)))
            .toList(),
      );
    });
  }
}

class _VarshaColorTile extends StatelessWidget {
  final _VarshaColorTileData item;

  const _VarshaColorTile(this.item);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1.2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.label,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 11.2,
              height: 1.15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            item.value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _VarshaColorTileData {
  final String label;
  final String value;
  final Color color;

  const _VarshaColorTileData(this.label, this.value, this.color);
}

class _VarshaPlanetsBody extends StatelessWidget {
  final dynamic data;

  const _VarshaPlanetsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = _calcRecordList(_calcCleanValue(data))
        .map(_varshaPlanetRow)
        .where((row) => row.isNotEmpty)
        .toList();
    if (rows.isEmpty) {
      return const _UnavailableCard(
        message: 'Varshaphal planet positions are not available right now.',
      );
    }
    return _VarshaRecordTable(
      records: rows,
      preferredColumns: const [
        'name',
        'sign',
        'degree',
        'sign_lord',
        'nakshatra',
        'pada',
        'house',
        'retro',
        'combust',
        'state',
      ],
      forceScrollHint: true,
    );
  }
}

class _VarshaMunthaBody extends StatelessWidget {
  final dynamic data;

  const _VarshaMunthaBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final clean = _calcCleanValue(data);
    final records = _calcRecordList(clean);
    if (records.isNotEmpty) {
      return _VarshaRecordTable(records: records.map(_varshaCleanRow).toList());
    }
    final map = _calcAsMap(clean);
    if (map.isNotEmpty) {
      return _VarshaKeyValueTable(rows: _varshaVisibleEntries(map));
    }
    if (!_calcIsMeaningfullyEmpty(clean)) {
      return _CompactPredictionCard(text: _calcValue(clean));
    }
    return const _UnavailableCard(
      message: 'Varshaphal Muntha details are not available right now.',
    );
  }
}

class _VarshaBalaBody extends StatelessWidget {
  final dynamic data;

  const _VarshaBalaBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final map = _calcAsMap(_calcCleanValue(data));
    final rows = <Map<String, dynamic>>[];
    for (final entry in map.entries) {
      final values = _calcAsList(entry.value);
      if (values.isEmpty) continue;
      rows.add({
        'bala': _calcFriendlyTitle(entry.key),
        for (var i = 0;
            i < math.min(values.length, _varshaPlanetShort.length);
            i++)
          _varshaPlanetShort[i]: _varshaNumber(values[i]),
      });
    }
    if (rows.isEmpty) {
      return const _UnavailableCard(
        message: 'Varshaphal Bala details are not available right now.',
      );
    }
    return _VarshaRecordTable(
      records: rows,
      preferredColumns: const [
        'bala',
        'su',
        'mo',
        'ma',
        'me',
        'ju',
        've',
        'sa'
      ],
      highlightTotalRows: true,
    );
  }
}

class _VarshaSahamBody extends StatelessWidget {
  final dynamic data;

  const _VarshaSahamBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = _calcRecordList(_calcCleanValue(data))
        .map((record) => {
              'no': _calcValue(record['saham_id'] ?? record['id']),
              'name': _calcValue(record['saham_name'] ?? record['name']),
              'degree':
                  _varshaDegree(record['saham_degree'] ?? record['degree']),
            })
        .where((row) => row.values.any((value) => value != '-'))
        .toList();
    if (rows.isEmpty) {
      return const _UnavailableCard(
        message: 'Saham points are not available right now.',
      );
    }
    return _VarshaRecordTable(
      records: rows,
      preferredColumns: const ['no', 'name', 'degree'],
    );
  }
}

class _VarshaYogaBody extends StatelessWidget {
  final dynamic data;

  const _VarshaYogaBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = _calcRecordList(_calcCleanValue(data))
        .map((record) => {
              'yoga': _calcValue(record['yog_name'] ?? record['name']),
              'status': _calcValue(record['is_yog_happening']),
              if (!_calcIsMeaningfullyEmpty(record['powerfullness_percentage']))
                'power': _calcValue(record['powerfullness_percentage']),
              if (!_calcIsMeaningfullyEmpty(record['yog_prediction']))
                'prediction': _calcValue(record['yog_prediction']),
              if (!_calcIsMeaningfullyEmpty(record['planets']))
                'planets': _calcValue(record['planets']),
            })
        .where((row) => row.values.any((value) => value != '-'))
        .toList();
    if (rows.isEmpty) {
      return const _UnavailableCard(
        message: 'Varshaphal Yoga details are not available right now.',
      );
    }
    return _VarshaRecordTable(
      records: rows,
      preferredColumns: const [
        'yoga',
        'status',
        'power',
        'prediction',
        'planets'
      ],
      forceScrollHint: true,
    );
  }
}

class _KpPlanetsBody extends StatelessWidget {
  final dynamic data;

  const _KpPlanetsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = _calcRecordList(_calcCleanValue(data))
        .map(_kpPlanetRow)
        .where((row) => row.isNotEmpty)
        .toList();
    if (rows.isEmpty) {
      return const _UnavailableCard(
        message: 'KP planet details are not available right now.',
      );
    }
    return _VarshaRecordTable(
      records: rows,
      preferredColumns: const [
        'planet',
        'sign',
        'degree',
        'house',
        'sign_lord',
        'nakshatra',
        'nakshatra_lord',
        'charan',
        'sub_lord',
        'sub_sub_lord',
        'retro',
      ],
      forceScrollHint: true,
    );
  }
}

class _KpHouseCuspsBody extends StatelessWidget {
  final dynamic data;

  const _KpHouseCuspsBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = _calcRecordList(_calcCleanValue(data))
        .map(_kpHouseCuspRow)
        .where((row) => row.isNotEmpty)
        .toList();
    if (rows.isEmpty) {
      return const _UnavailableCard(
        message: 'KP house cusp details are not available right now.',
      );
    }
    return _VarshaRecordTable(
      records: rows,
      preferredColumns: const [
        'house',
        'sign',
        'degree',
        'sign_lord',
        'nakshatra',
        'nakshatra_lord',
        'sub_lord',
        'sub_sub_lord',
      ],
      forceScrollHint: true,
    );
  }
}

class _KpBirthChartBody extends StatelessWidget {
  final dynamic data;

  const _KpBirthChartBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final records = _calcRecordList(_calcCleanValue(data));
    final rows = records.asMap().entries.map((entry) {
      final record = entry.value;
      return {
        'house': entry.key + 1,
        'signs': _calcValue(record['signs']),
        'planets': _kpListValue(record['planets'], emptyText: 'None'),
        'planet_signs': _kpListValue(record['planet_signs']),
      };
    }).where((row) {
      return row.values.any((value) => _calcValue(value) != '-');
    }).toList();
    if (rows.isEmpty) {
      return const _UnavailableCard(
        message: 'KP birth chart details are not available right now.',
      );
    }
    return _VarshaRecordTable(
      records: rows,
      preferredColumns: const ['house', 'signs', 'planets', 'planet_signs'],
    );
  }
}

class _KpHouseSignificatorBody extends StatelessWidget {
  final dynamic data;

  const _KpHouseSignificatorBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = _calcRecordList(_calcCleanValue(data))
        .map((record) => {
              'house': record['house'] ?? record['house_id'],
              'significators': _kpListValue(record['significators']),
            })
        .where((row) => row.values.any((value) => _calcValue(value) != '-'))
        .toList();
    if (rows.isEmpty) {
      return const _UnavailableCard(
        message: 'KP house significators are not available right now.',
      );
    }
    return _VarshaRecordTable(
      records: rows,
      preferredColumns: const ['house', 'significators'],
    );
  }
}

class _KpPlanetSignificatorBody extends StatelessWidget {
  final dynamic data;

  const _KpPlanetSignificatorBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = _calcRecordList(_calcCleanValue(data))
        .map((record) => {
              'planet': record['planet'] ?? record['planet_name'],
              'significators': _kpListValue(record['significators']),
            })
        .where((row) => row.values.any((value) => _calcValue(value) != '-'))
        .toList();
    if (rows.isEmpty) {
      return const _UnavailableCard(
        message: 'KP planet significators are not available right now.',
      );
    }
    return _VarshaRecordTable(
      records: rows,
      preferredColumns: const ['planet', 'significators'],
    );
  }
}

class _AshtakavargaBody extends StatelessWidget {
  final dynamic data;
  final bool isSarvashtak;

  const _AshtakavargaBody({
    required this.data,
    required this.isSarvashtak,
  });

  @override
  Widget build(BuildContext context) {
    final rows = _ashtakRows(data);
    if (rows.isEmpty) {
      return _UnavailableCard(
        message: isSarvashtak
            ? 'Sarvashtakavarga points are not available right now.'
            : 'Ashtakavarga points are not available right now.',
      );
    }
    return _AshtakPointsTable(rows: rows, isSarvashtak: isSarvashtak);
  }
}

class _AshtakPointsTable extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final bool isSarvashtak;

  const _AshtakPointsTable({
    required this.rows,
    required this.isSarvashtak,
  });

  static const _columns = [
    'sign',
    'sun',
    'moon',
    'mars',
    'mercury',
    'jupiter',
    'venus',
    'saturn',
    'ascendant',
    'total',
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE6D7BA)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.05),
            1: FlexColumnWidth(0.58),
            2: FlexColumnWidth(0.58),
            3: FlexColumnWidth(0.58),
            4: FlexColumnWidth(0.58),
            5: FlexColumnWidth(0.58),
            6: FlexColumnWidth(0.58),
            7: FlexColumnWidth(0.58),
            8: FlexColumnWidth(0.7),
            9: FlexColumnWidth(0.9),
          },
          border: TableBorder.symmetric(
            inside: const BorderSide(color: Color(0xFFE8E0CF), width: 0.7),
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: const BoxDecoration(color: Color(0xFFD7AF4B)),
              children: _columns
                  .map((column) => _AshtakCell(
                        _ashtakColumnLabel(column),
                        header: true,
                      ))
                  .toList(),
            ),
            ...rows.asMap().entries.map((entry) {
              final row = entry.value;
              return TableRow(
                decoration: BoxDecoration(
                  color:
                      entry.key.isEven ? Colors.white : const Color(0xFFFFFCF4),
                ),
                children: _columns.map((column) {
                  final value = _calcValue(row[column]);
                  if (column == 'total') {
                    return _AshtakTotalCell(
                      value,
                      color: _ashtakTotalColor(value, isSarvashtak),
                    );
                  }
                  return _AshtakCell(
                    value,
                    attribute: column == 'sign',
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AshtakCell extends StatelessWidget {
  final String text;
  final bool header;
  final bool attribute;

  const _AshtakCell(
    this.text, {
    this.header = false,
    this.attribute = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: header ? 2 : 3,
        vertical: header ? 5 : 6,
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: const Color(0xFF102A52),
          fontSize: header ? 9.4 : 10.8,
          height: 1.0,
          fontWeight: header || attribute ? FontWeight.w900 : FontWeight.w500,
        ),
      ),
    );
  }
}

class _AshtakTotalCell extends StatelessWidget {
  final String text;
  final Color color;

  const _AshtakTotalCell(this.text, {required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      child: Align(
        alignment: Alignment.center,
        child: Container(
          constraints: const BoxConstraints(minWidth: 28),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.8,
              height: 1.0,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _VarshaKeyValueTable extends StatelessWidget {
  final List<MapEntry<String, dynamic>> rows;

  const _VarshaKeyValueTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final visible = rows
        .where((entry) =>
            !_calcShouldHideKey(entry.key) &&
            !_varshaShouldHideKey(entry.key) &&
            !_calcIsMeaningfullyEmpty(entry.value))
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE6D7BA)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(0.9),
              1: FlexColumnWidth(1.24),
            },
            border: TableBorder.symmetric(
              inside: const BorderSide(color: Color(0xFFE8E0CF), width: 0.8),
            ),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: visible.asMap().entries.map((entry) {
              final row = entry.value;
              return TableRow(
                decoration: BoxDecoration(
                  color:
                      entry.key.isEven ? Colors.white : const Color(0xFFFFFCF4),
                ),
                children: [
                  _VarshaTableCell(_calcFriendlyTitle(row.key),
                      attribute: true),
                  _VarshaTableCell(_varshaValue(row.value, key: row.key)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _VarshaRecordTable extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final List<String> preferredColumns;
  final bool forceScrollHint;
  final bool highlightTotalRows;

  const _VarshaRecordTable({
    required this.records,
    this.preferredColumns = const [],
    this.forceScrollHint = false,
    this.highlightTotalRows = false,
  });

  @override
  Widget build(BuildContext context) {
    final cleaned = records
        .map(_varshaCleanRow)
        .where((record) => record.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return const SizedBox.shrink();
    final columns = _varshaColumns(cleaned, preferredColumns);
    if (columns.isEmpty) return const SizedBox.shrink();
    final naturalWidth = columns.fold<double>(
      0,
      (sum, column) => sum + _varshaColumnWidth(column, cleaned),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: LayoutBuilder(builder: (context, constraints) {
        final tableWidth = naturalWidth < constraints.maxWidth
            ? constraints.maxWidth
            : naturalWidth;
        final needsScroll = naturalWidth > constraints.maxWidth + 1;
        final table = ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE6D7BA)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              width: tableWidth,
              child: Table(
                columnWidths: {
                  for (var i = 0; i < columns.length; i++)
                    i: FixedColumnWidth(
                      tableWidth *
                          (_varshaColumnWidth(columns[i], cleaned) /
                              naturalWidth),
                    ),
                },
                border: TableBorder.symmetric(
                  inside:
                      const BorderSide(color: Color(0xFFE8E0CF), width: 0.8),
                ),
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFD7AF4B)),
                    children: columns
                        .map((column) =>
                            _VarshaTableHeader(_calcFriendlyTitle(column)))
                        .toList(),
                  ),
                  ...cleaned.asMap().entries.map((entry) {
                    final row = entry.value;
                    final label = _calcKey(
                      _calcValue(row['bala'] ?? row['name'] ?? row['yoga']),
                    );
                    final special = highlightTotalRows &&
                        (label.contains('total') || label.contains('final'));
                    return TableRow(
                      decoration: BoxDecoration(
                        color: special
                            ? (label.contains('final')
                                ? const Color(0xFFE2F8E9)
                                : const Color(0xFFFFF4C7))
                            : (entry.key.isEven
                                ? Colors.white
                                : const Color(0xFFFFFCF4)),
                      ),
                      children: columns.map((column) {
                        return _VarshaTableCell(
                          _varshaValue(row[column], key: column),
                          attribute: column == columns.first || special,
                        );
                      }).toList(),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
        final wrapped = needsScroll
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal, child: table)
            : table;
        if (!needsScroll && !forceScrollHint) return wrapped;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (needsScroll || forceScrollHint) const _DashaScrollHint(),
            if (needsScroll || forceScrollHint) const SizedBox(height: 5),
            wrapped,
          ],
        );
      }),
    );
  }
}

class _VarshaTableHeader extends StatelessWidget {
  final String text;

  const _VarshaTableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Text(
        text.toUpperCase(),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF1E3557),
          fontSize: 10.2,
          height: 1.05,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _VarshaTableCell extends StatelessWidget {
  final String text;
  final bool attribute;

  const _VarshaTableCell(this.text, {this.attribute = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Text(
        text.isEmpty ? '-' : text,
        maxLines: attribute ? 3 : 4,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: const Color(0xFF102A52),
          fontSize: 10.8,
          height: 1.08,
          fontWeight: attribute ? FontWeight.w900 : FontWeight.w400,
        ),
      ),
    );
  }
}

const _varshaPlanetShort = ['su', 'mo', 'ma', 'me', 'ju', 've', 'sa'];

List<Map<String, dynamic>> _varshaChartRows(dynamic value) {
  return _calcRecordList(value).map((record) {
    final planets = _calcAsList(record['planet'])
        .map(_calcValue)
        .where((item) => item != '-')
        .join(', ');
    return {
      'sign': _calcValue(record['sign']),
      'sign_name': _calcValue(record['sign_name'] ?? record['rashi']),
      'planets': planets.isEmpty ? 'None' : planets,
    };
  }).toList();
}

Map<String, dynamic> _varshaPlanetRow(Map<String, dynamic> record) {
  return {
    'name': record['name'],
    'sign': record['sign'],
    'degree': _varshaDegree(
      record['normDegree'] ?? record['norm_degree'] ?? record['degree'],
    ),
    'sign_lord': record['signLord'] ?? record['sign_lord'],
    'nakshatra': record['nakshatra'],
    'pada': record['nakshatra_pad'] ?? record['pada'] ?? record['charan'],
    'house': record['house'],
    'retro': _varshaBool(record['isRetro'] ?? record['retro']),
    'combust': _varshaBool(record['is_planet_set'] ?? record['combust']),
    'state': record['planet_awastha'] ?? record['state'],
  }..removeWhere((key, value) => _calcIsMeaningfullyEmpty(value));
}

Map<String, dynamic> _kpPlanetRow(Map<String, dynamic> record) {
  return {
    'planet': record['planet'] ?? record['planet_name'] ?? record['name'],
    'sign': record['sign'],
    'degree': _kpDegree(
      record['formatted_norm_degree'] ??
          record['norm_degree'] ??
          record['formatted_degree'] ??
          record['degree'],
    ),
    'house': record['house'],
    'sign_lord': record['sign_lord'] ?? record['signLord'],
    'nakshatra': record['nakshatra'],
    'nakshatra_lord': record['nakshatra_lord'] ?? record['nakshatraLord'],
    'charan': record['charan'] ?? record['pada'] ?? record['nakshatra_pad'],
    'sub_lord': record['sub_lord'] ?? record['subLord'],
    'sub_sub_lord': record['sub_sub_lord'] ?? record['subSubLord'],
    'retro': _varshaBool(record['is_retro'] ?? record['isRetro']),
  }..removeWhere((key, value) => _calcIsMeaningfullyEmpty(value));
}

Map<String, dynamic> _kpHouseCuspRow(Map<String, dynamic> record) {
  return {
    'house': record['house'] ?? record['house_id'],
    'sign': record['sign'],
    'degree': _kpDegree(
      record['formatted_degree'] ??
          record['cusp_full_degree'] ??
          record['degree'],
    ),
    'sign_lord': record['sign_lord'] ?? record['signLord'],
    'nakshatra': record['nakshatra'],
    'nakshatra_lord': record['nakshatra_lord'] ?? record['nakshatraLord'],
    'sub_lord': record['sub_lord'] ?? record['subLord'],
    'sub_sub_lord': record['sub_sub_lord'] ?? record['subSubLord'],
  }..removeWhere((key, value) => _calcIsMeaningfullyEmpty(value));
}

String _kpListValue(dynamic value, {String emptyText = '-'}) {
  final items = _calcAsList(value)
      .map(_calcValue)
      .where((item) => item != '-' && item.trim().isNotEmpty)
      .toList();
  return items.isEmpty ? emptyText : items.join(', ');
}

String _kpDegree(dynamic value) {
  if (_calcIsMeaningfullyEmpty(value)) return '-';
  if (value is num) return _varshaDegree(value);
  final text = _calcValue(value);
  final parts = text.split(':');
  if (parts.length == 3 && parts.every((part) => int.tryParse(part) != null)) {
    return '${parts[0]}d${parts[1]}\'${parts[2]}"';
  }
  return _calcCleanText(text);
}

List<Map<String, dynamic>> _ashtakRows(dynamic value) {
  final map = _calcAsMap(_calcCleanValue(value));
  final points = _calcAsMap(map['ashtak_points'] ?? map['points']);
  if (points.isEmpty) return const [];

  const orderedSigns = [
    'aries',
    'taurus',
    'gemini',
    'cancer',
    'leo',
    'virgo',
    'libra',
    'scorpio',
    'sagittarius',
    'capricorn',
    'aquarius',
    'pisces',
  ];
  final rows = <Map<String, dynamic>>[];
  for (final sign in orderedSigns) {
    final values = _calcAsMap(points[sign]);
    if (values.isEmpty) continue;
    rows.add(_ashtakRow(sign, values));
  }
  for (final entry in points.entries) {
    final sign = _calcKey(entry.key);
    if (orderedSigns.contains(sign)) continue;
    final values = _calcAsMap(entry.value);
    if (values.isEmpty) continue;
    rows.add(_ashtakRow(sign, values));
  }
  return rows;
}

Map<String, dynamic> _ashtakRow(
  String sign,
  Map<String, dynamic> values,
) {
  return {
    'sign': _ashtakSignLabel(sign),
    'sun': values['sun'],
    'moon': values['moon'],
    'mars': values['mars'],
    'mercury': values['mercury'],
    'jupiter': values['jupiter'],
    'venus': values['venus'],
    'saturn': values['saturn'],
    'ascendant': values['ascendant'] ?? values['asc'],
    'total': values['total'],
  };
}

String _ashtakSignLabel(String sign) {
  const signs = {
    'aries': 'Ari',
    'taurus': 'Tau',
    'gemini': 'Gem',
    'cancer': 'Can',
    'leo': 'Leo',
    'virgo': 'Vir',
    'libra': 'Lib',
    'scorpio': 'Sco',
    'sagittarius': 'Sag',
    'capricorn': 'Cap',
    'aquarius': 'Aqu',
    'pisces': 'Pis',
  };
  final key = _calcKey(sign);
  return signs[key] ?? _calcFriendlyTitle(sign);
}

String _ashtakColumnLabel(String column) {
  const labels = {
    'sign': 'Sign',
    'sun': 'Su',
    'moon': 'Mo',
    'mars': 'Ma',
    'mercury': 'Me',
    'jupiter': 'Ju',
    'venus': 'Ve',
    'saturn': 'Sa',
    'ascendant': 'Asc',
    'total': 'Total',
  };
  return labels[column] ?? _calcFriendlyTitle(column);
}

Color _ashtakTotalColor(String value, bool isSarvashtak) {
  final total = num.tryParse(value);
  if (total == null) return const Color(0xFF0EA5E9);
  if (isSarvashtak) {
    if (total >= 28) return const Color(0xFF10B981);
    if (total >= 24) return const Color(0xFF0EA5E9);
    return const Color(0xFFF43F5E);
  }
  if (total >= 5) return const Color(0xFF10B981);
  if (total >= 4) return const Color(0xFF0EA5E9);
  return const Color(0xFFF43F5E);
}

Map<String, dynamic> _varshaCleanRow(Map<String, dynamic> record) {
  final cleaned = <String, dynamic>{};
  for (final entry in record.entries) {
    if (_calcShouldHideKey(entry.key) ||
        _varshaShouldHideKey(entry.key) ||
        _calcIsImageKey(entry.key) ||
        _calcIsMeaningfullyEmpty(entry.value)) {
      continue;
    }
    cleaned[entry.key] = _calcCleanValue(entry.value);
  }
  return cleaned;
}

List<MapEntry<String, dynamic>> _varshaVisibleEntries(
    Map<String, dynamic> map) {
  return map.entries
      .where((entry) =>
          !_calcShouldHideKey(entry.key) &&
          !_varshaShouldHideKey(entry.key) &&
          !_calcIsMeaningfullyEmpty(entry.value))
      .toList();
}

bool _varshaShouldHideKey(String key) {
  final compact = _calcKey(key);
  return compact == 'id' ||
      compact.endsWith('_id') ||
      compact == 'varshaphala_timestamp' ||
      compact == 'timestamp' ||
      compact == 'planet_degree' ||
      compact == 'planet_small' ||
      compact == 'fulldegree' ||
      compact == 'full_degree' ||
      compact == 'normdegree' ||
      compact == 'norm_degree';
}

List<String> _varshaColumns(
  List<Map<String, dynamic>> rows,
  List<String> preferred,
) {
  final discovered = <String>[];
  for (final row in rows) {
    for (final key in row.keys) {
      if (_varshaShouldHideKey(key) || discovered.contains(key)) continue;
      discovered.add(key);
    }
  }
  final ordered = <String>[];
  for (final key in preferred) {
    final actual = discovered.firstWhere(
      (candidate) => _calcKey(candidate) == _calcKey(key),
      orElse: () => '',
    );
    if (actual.isNotEmpty && !ordered.contains(actual)) ordered.add(actual);
  }
  for (final key in discovered) {
    if (!ordered.contains(key)) ordered.add(key);
  }
  return ordered;
}

double _varshaColumnWidth(
  String column,
  List<Map<String, dynamic>> rows,
) {
  final key = _calcKey(column);
  if (key == 'no' || key == 'sign' || key == 'house' || key == 'pada') {
    return 48;
  }
  if (_varshaPlanetShort.contains(key)) return 46;
  if (key == 'retro' || key == 'combust' || key == 'status') return 60;
  if (key == 'bala') return 98;
  if (key == 'name' || key == 'yoga') return 112;
  if (key == 'planets') return 118;
  if (key.contains('nakshatra')) return 118;
  if (key.contains('lord')) return 88;
  if (key.contains('degree')) return 96;
  if (key.contains('prediction')) return 180;
  final longest = rows
      .map((row) => _varshaValue(row[column], key: column).length)
      .fold<int>(0, math.max);
  if (longest <= 5) return 50;
  if (longest <= 12) return 76;
  if (longest <= 24) return 104;
  return 142;
}

String _varshaValue(dynamic value, {String key = ''}) {
  if (_calcIsMeaningfullyEmpty(value)) return '-';
  final compact = _calcKey(key);
  if (compact.contains('degree')) return _varshaDegree(value);
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is String &&
      (value.toLowerCase() == 'true' || value.toLowerCase() == 'false')) {
    return value.toLowerCase() == 'true' ? 'Yes' : 'No';
  }
  if (value is num) return _varshaNumber(value);
  return _calcCleanText(_calcValue(value));
}

String _varshaBool(dynamic value) {
  if (value is bool) return value ? 'Yes' : 'No';
  final text = value?.toString().trim().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes') return 'Yes';
  if (text == 'false' || text == '0' || text == 'no') return 'No';
  return _calcValue(value);
}

String _varshaNumber(dynamic value) {
  final number = value is num ? value.toDouble() : double.tryParse('$value');
  if (number == null) return _calcValue(value);
  final fixed = number.toStringAsFixed(2);
  return fixed.replaceAll(RegExp(r'\.?0+$'), '');
}

String _varshaDegree(dynamic value) {
  final number = value is num ? value.toDouble() : double.tryParse('$value');
  if (number == null) return _calcValue(value);
  final normalized = number < 0 ? (number % 360) + 360 : number % 360;
  final degrees = normalized.floor();
  final minutesFloat = (normalized - degrees) * 60;
  final minutes = minutesFloat.floor();
  final seconds = ((minutesFloat - minutes) * 60).round();
  return '${degrees}d${minutes.toString().padLeft(2, '0')}'
      '\'${seconds.toString().padLeft(2, '0')}"';
}

List<String> _dashaColumns(List<Map<String, dynamic>> records) {
  final discovered = <String>[];
  for (final record in records) {
    for (final key in record.keys) {
      if (!_dashaShouldHideKey(key) && !discovered.contains(key)) {
        discovered.add(key);
      }
    }
  }

  const preferred = [
    ['planet', 'name', 'dasha', 'dasha_name'],
    ['start', 'start_date', 'startDate'],
    ['end', 'end_date', 'endDate'],
    ['duration'],
  ];
  return _bioColumnsByGroups(discovered, preferred);
}

double _dashaColumnWidth(String column) {
  final key = _calcKey(column);
  if (key == 'planet' ||
      key == 'name' ||
      key == 'dasha' ||
      key == 'dasha_name') {
    return 82;
  }
  if (key.contains('start') || key.contains('end') || key.contains('date')) {
    return 106;
  }
  if (key.contains('duration')) return 82;
  if (key.contains('lord') || key.contains('sign')) return 86;
  return 104;
}

List<Map<String, dynamic>> _yoginiMajorRows(dynamic value) {
  return _calcRecordList(_calcCleanValue(value))
      .map((record) => {
            'dasha': _yoginiDashaName(record),
            'start': _yoginiDate(record['start_date'] ?? record['start']),
            'end': _yoginiDate(record['end_date'] ?? record['end']),
            if (!_calcIsMeaningfullyEmpty(record['duration']))
              'duration': _yoginiDuration(record['duration']),
          })
      .where((row) => row.values.any((item) => _calcValue(item) != '-'))
      .toList();
}

List<Map<String, dynamic>> _yoginiCurrentRows(dynamic value) {
  final map = _calcAsMap(_calcCleanValue(value));
  final rows = <Map<String, dynamic>>[];
  for (final entry in const [
    MapEntry('Mahadasha', 'major_dasha'),
    MapEntry('Antardasha', 'sub_dasha'),
    MapEntry('Pratyantardasha', 'sub_sub_dasha'),
  ]) {
    final record = _calcAsMap(map[entry.value]);
    if (record.isEmpty) continue;
    rows.add({
      'level': entry.key,
      'dasha': _yoginiDashaName(record),
      'start': _yoginiDate(record['start_date'] ?? record['start']),
      'end': _yoginiDate(record['end_date'] ?? record['end']),
      if (!_calcIsMeaningfullyEmpty(record['duration']))
        'duration': _yoginiDuration(record['duration']),
    });
  }
  return rows;
}

_YoginiSubGroup _yoginiSubGroup(Map<String, dynamic> record) {
  final major = _calcAsMap(record['major_dasha']);
  final rows = _calcRecordList(record['sub_dasha'])
      .map((sub) => {
            'dasha': _yoginiDashaName(sub),
            'start': _yoginiDate(sub['start_date'] ?? sub['start']),
            'end': _yoginiDate(sub['end_date'] ?? sub['end']),
          })
      .where((row) => row.values.any((item) => _calcValue(item) != '-'))
      .toList();
  return _YoginiSubGroup(
    name: major.isEmpty ? 'Yogini Dasha' : _yoginiDashaName(major),
    rows: rows,
  );
}

String _yoginiDashaName(Map<String, dynamic> record) {
  final name = _calcCleanText(
    _calcValue(record['dasha_name'] ?? record['name'] ?? record['dasha']),
  );
  if (name == '-') return name;
  final suffix = _yoginiPlanetSuffix(record['dasha_id'], name);
  if (suffix.isEmpty || name.contains('(')) return name;
  return '$name ($suffix)';
}

String _yoginiPlanetSuffix(dynamic id, String name) {
  final dashaId = id is num ? id.toInt() : int.tryParse('$id');
  const byId = {
    0: 'Mo',
    1: 'Su',
    2: 'Ju',
    3: 'Ma',
    4: 'Me',
    5: 'Sa',
    6: 'Ve',
    7: 'Ra-Ke',
  };
  if (dashaId != null && byId.containsKey(dashaId)) return byId[dashaId]!;
  const byName = {
    'mangla': 'Mo',
    'mangala': 'Mo',
    'pingla': 'Su',
    'pingala': 'Su',
    'dhanya': 'Ju',
    'bhramari': 'Ma',
    'bhadrika': 'Me',
    'ulka': 'Sa',
    'siddha': 'Ve',
    'sankata': 'Ra-Ke',
  };
  return byName[_calcKey(name)] ?? '';
}

String _yoginiDate(dynamic value) {
  final text = _calcCleanText(_calcValue(value));
  if (text == '-') return text;
  return text.replaceFirst(RegExp(r'\s+'), ' • ');
}

String _yoginiDuration(dynamic value) {
  if (_calcIsMeaningfullyEmpty(value)) return '-';
  if (value is num) return '${_varshaNumber(value)} yr';
  final text = _calcCleanText(_calcValue(value));
  return text.toLowerCase().contains('year') ? text : '$text yr';
}

class _NestedRecordResultBody extends StatelessWidget {
  final dynamic data;

  const _NestedRecordResultBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final clean = _calcCleanValue(data);
    final records = _calcRecordList(clean);
    if (records.isEmpty) {
      final map = _calcAsMap(clean);
      if (map.isEmpty) return _CleanResultBody(data: clean);

      final simple = <Map<String, dynamic>>[];
      final nested = <Widget>[];

      for (final entry in map.entries) {
        if (_calcShouldHideKey(entry.key) ||
            _calcIsMeaningfullyEmpty(entry.value)) {
          continue;
        }
        final value = _calcCleanValue(entry.value);
        final nestedRows = _calcRecordList(value);
        if (nestedRows.isNotEmpty) {
          nested.add(_RecordTable(
            title: _calcFriendlyTitle(entry.key),
            records: _compactDashaRows(nestedRows),
          ));
          continue;
        }

        final nestedMap = _calcAsMap(value);
        if (nestedMap.isNotEmpty) {
          final compact = _compactDashaRows([nestedMap]);
          if (compact.isNotEmpty) {
            nested.add(_SubSectionCard(
              title: _calcFriendlyTitle(entry.key),
              child: _InfoGrid(rows: compact.first.entries.toList()),
            ));
          }
          continue;
        }

        simple.add({entry.key: value});
      }

      if (simple.isEmpty && nested.isEmpty) {
        return _CleanResultBody(data: clean);
      }
      return Column(
        children: [
          if (simple.isNotEmpty)
            _RecordTable(title: 'Summary', records: _compactDashaRows(simple)),
          ...nested,
        ],
      );
    }

    final simpleRows = <Map<String, dynamic>>[];
    final cards = <Widget>[];

    for (var index = 0; index < records.length; index++) {
      final record = records[index];
      final simple = <String, dynamic>{};
      final nested = <MapEntry<String, dynamic>>[];

      for (final entry in record.entries) {
        if (_calcShouldHideKey(entry.key) ||
            _calcIsMeaningfullyEmpty(entry.value)) {
          continue;
        }
        final value = _calcCleanValue(entry.value);
        final nestedRecords = _calcRecordList(value);
        if (value is Map || nestedRecords.isNotEmpty) {
          nested.add(MapEntry(entry.key, value));
        } else if (value is List && !_calcListIsPrimitive(value)) {
          nested.add(MapEntry(entry.key, value));
        } else {
          simple[entry.key] = value;
        }
      }

      if (nested.isEmpty) {
        if (simple.isNotEmpty) simpleRows.add(simple);
        continue;
      }

      final title = _nestedRecordTitle(index, simple);
      cards.add(_SubSectionCard(
        title: title,
        child: Column(
          children: [
            if (simple.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _InfoGrid(rows: simple.entries.toList()),
              ),
            ...nested.map((entry) {
              final nestedRows = _calcRecordList(entry.value);
              if (nestedRows.isNotEmpty) {
                return _RecordTable(
                  title: _calcFriendlyTitle(entry.key),
                  records: _compactDashaRows(nestedRows),
                );
              }
              final nestedMap = _calcAsMap(entry.value);
              if (nestedMap.isNotEmpty) {
                final compact = _compactDashaRows([nestedMap]);
                if (compact.isEmpty) return const SizedBox.shrink();
                return _RecordTable(
                  title: _calcFriendlyTitle(entry.key),
                  records: [compact.first],
                );
              }
              return _TextCard(
                text:
                    '${_calcFriendlyTitle(entry.key)}: ${_calcValue(entry.value)}',
              );
            }),
          ],
        ),
      ));
    }

    if (cards.isEmpty) {
      return _RecordTable(title: '', records: _compactDashaRows(simpleRows));
    }
    return Column(
      children: [
        if (simpleRows.isNotEmpty)
          _RecordTable(
              title: 'Summary', records: _compactDashaRows(simpleRows)),
        ...cards,
      ],
    );
  }
}

String _nestedRecordTitle(int index, Map<String, dynamic> simple) {
  final label = simple['month_id'] ??
      simple['monthId'] ??
      simple['dasha'] ??
      simple['name'] ??
      simple['planet'] ??
      simple['sign_name'] ??
      simple['sign'];
  if (label == null) return 'Entry ${index + 1}';
  return _calcValue(label);
}

class _RudrakshaSuggestionBody extends StatelessWidget {
  final Map<String, dynamic> data;

  const _RudrakshaSuggestionBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final cleaned = Map<String, dynamic>.from(data)
      ..removeWhere((key, value) =>
          _calcIsImageKey(key) ||
          _rudrakshaHiddenKey(key) ||
          _calcIsMeaningfullyEmpty(value));
    final rows = _rudrakshaDisplayRows(cleaned);
    if (rows.isEmpty) {
      return const _UnavailableCard(
          message: 'Rudraksha suggestion is not available right now.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SuggestionCapsuleGrid(rows: rows),
      ],
    );
  }
}

bool _rudrakshaHiddenKey(String key) {
  final normalized = _calcKey(key);
  return normalized == 'rudrakshakey' ||
      normalized == 'key' ||
      normalized == 'imgurl' ||
      normalized == 'imageurl' ||
      normalized == 'image' ||
      normalized == 'rudrakshaimage';
}

List<MapEntry<String, dynamic>> _rudrakshaDisplayRows(
  Map<String, dynamic> data,
) {
  final rows = <MapEntry<String, dynamic>>[];
  final name = _bioLookup(data, const [
    'name',
    'rudraksha_name',
    'rudrakshaName',
    'rudraksha',
  ]);
  final recommend = _bioLookup(data, const [
    'recommend',
    'recommended',
    'recommendation',
    'is_recommended',
    'isRecommended',
  ]);
  final detail = _bioLookup(data, const [
    'detail',
    'details',
    'description',
    'report',
    'summary',
  ]);
  if (!_calcIsMeaningfullyEmpty(name)) rows.add(MapEntry('Name', name));
  if (!_calcIsMeaningfullyEmpty(recommend)) {
    rows.add(MapEntry('Recommend', recommend));
  }
  if (!_calcIsMeaningfullyEmpty(detail)) rows.add(MapEntry('Detail', detail));

  if (rows.isNotEmpty) return rows;
  for (final entry in data.entries) {
    if (_rudrakshaHiddenKey(entry.key) ||
        _calcIsMeaningfullyEmpty(entry.value)) {
      continue;
    }
    final key = _calcKey(entry.key);
    if (key.contains('name') ||
        key.contains('recommend') ||
        key.contains('detail') ||
        key.contains('description') ||
        key.contains('report') ||
        key.contains('summary')) {
      rows.add(entry);
    }
  }
  return rows;
}

class _SuggestionBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SuggestionBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5D7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFD7AF4B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1E3557),
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionTextBlock extends StatelessWidget {
  final String text;

  const _SuggestionTextBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    final cleaned = _calcCleanText(text);
    if (cleaned.isEmpty || cleaned == '-') return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Text(
        cleaned,
        style: const TextStyle(
          color: Color(0xFF102A52),
          fontSize: 12.5,
          height: 1.28,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _SuggestionCapsuleGrid extends StatelessWidget {
  final List<MapEntry<String, dynamic>> rows;

  const _SuggestionCapsuleGrid({required this.rows});

  @override
  Widget build(BuildContext context) {
    final visible = rows
        .where((entry) =>
            !_calcShouldHideKey(entry.key) &&
            !_calcIsImageKey(entry.key) &&
            !_calcIsMeaningfullyEmpty(entry.value))
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      final itemWidth = constraints.maxWidth < 350
          ? constraints.maxWidth
          : (constraints.maxWidth - 8) / 2;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: visible.map((entry) {
          final label = _calcFriendlyTitle(entry.key);
          final value = _calcCleanText(_calcValue(entry.value));
          final wide = value.length > 54 || constraints.maxWidth < 350;
          return SizedBox(
            width: wide ? constraints.maxWidth : itemWidth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6D7BA)),
              ),
              child: RichText(
                maxLines: wide ? 5 : 3,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: const TextStyle(
                    color: Color(0xFF102A52),
                    fontSize: 11.7,
                    height: 1.2,
                  ),
                  children: [
                    TextSpan(
                      text: '$label: ',
                      style: const TextStyle(
                        color: Color(0xFF1E3557),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: value,
                      style: const TextStyle(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

class _SuggestionRecordTable extends StatelessWidget {
  final List<Map<String, dynamic>> records;
  final Set<String> hiddenKeys;
  final List<List<String>> preferredColumns;

  const _SuggestionRecordTable({
    required this.records,
    this.hiddenKeys = const {},
    this.preferredColumns = const [],
  });

  @override
  Widget build(BuildContext context) {
    final cleaned = records
        .map((record) => Map<String, dynamic>.from(record)
          ..removeWhere((key, value) =>
              _suggestionHiddenKey(key, hiddenKeys) ||
              _calcIsMeaningfullyEmpty(value)))
        .where((record) => record.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return const SizedBox.shrink();

    final columns = <String>[];
    for (final record in cleaned) {
      for (final key in record.keys) {
        if (!_suggestionHiddenKey(key, hiddenKeys) && !columns.contains(key)) {
          columns.add(key);
        }
      }
    }
    final displayColumns = preferredColumns.isEmpty
        ? columns
        : _bioColumnsByGroups(columns, preferredColumns);
    if (displayColumns.isEmpty) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE6D7BA)),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(const Color(0xFFD7AF4B)),
            headingRowHeight: 34,
            dataRowMinHeight: 36,
            dataRowMaxHeight: 72,
            columnSpacing: 8,
            horizontalMargin: 8,
            dividerThickness: 0.7,
            headingTextStyle: const TextStyle(
              color: Color(0xFF1E3557),
              fontSize: 10.5,
              height: 1.1,
              fontWeight: FontWeight.w900,
            ),
            dataTextStyle: const TextStyle(
              color: Color(0xFF102A52),
              fontSize: 11.4,
              height: 1.16,
              fontWeight: FontWeight.w400,
            ),
            columns: displayColumns.map((column) {
              return DataColumn(
                label: SizedBox(
                  width: _suggestionColumnWidth(column),
                  child: Text(
                    _calcFriendlyTitle(column),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList(),
            rows: cleaned.map((record) {
              return DataRow(
                cells: displayColumns.map((column) {
                  final value = _calcCleanText(_calcValue(record[column]));
                  return DataCell(
                    SizedBox(
                      width: _suggestionColumnWidth(column, value: value),
                      child: Text(
                        value,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

dynamic _pujaSummary(dynamic data) {
  final map = _calcAsMap(data);
  if (map.isEmpty) return null;
  final direct = _bioLookup(map, const [
    'summary',
    'description',
    'report',
    'details',
  ]);
  if (!_calcIsMeaningfullyEmpty(direct) &&
      (_calcIsPrimitive(direct) || _calcListIsPrimitive(direct))) {
    return direct;
  }
  return null;
}

List<Map<String, dynamic>> _pujaSuggestionRows(dynamic data) {
  final direct = _calcRecordList(data);
  if (direct.isNotEmpty) return _normalizePujaRows(direct);

  final nested = _findSuggestionRecords(data, const ['suggestion', 'puja']);
  if (nested.isNotEmpty) return _normalizePujaRows(nested);

  final map = _calcAsMap(data);
  if (map.isEmpty) return const [];
  final candidate = _bioLookup(map, const [
    'suggestions',
    'suggestion',
    'puja',
    'pujas',
    'puja_suggestion',
    'pujaSuggestion',
  ]);
  return _normalizePujaRows(_calcRecordList(candidate));
}

List<Map<String, dynamic>> _normalizePujaRows(
  List<Map<String, dynamic>> records,
) {
  return records
      .map((record) {
        final normalized = <String, dynamic>{};
        final status = _bioLookup(record, const ['status']);
        final title = _bioLookup(record, const ['title', 'name']);
        final summary = _bioLookup(record, const [
          'summary',
          'description',
          'details',
        ]);
        final oneLine = _bioLookup(record, const [
          'one_line',
          'oneLine',
          'report',
        ]);
        if (!_calcIsMeaningfullyEmpty(status)) normalized['status'] = status;
        if (!_calcIsMeaningfullyEmpty(title)) normalized['title'] = title;
        if (!_calcIsMeaningfullyEmpty(summary)) normalized['summary'] = summary;
        if (!_calcIsMeaningfullyEmpty(oneLine)) {
          normalized['one_line'] = oneLine;
        }

        if (normalized.isNotEmpty) return normalized;
        final fallback = Map<String, dynamic>.from(record)
          ..removeWhere((key, value) =>
              _suggestionHiddenKey(key, const {
                'id',
                'puja_id',
                'pujaid',
                'priority',
              }) ||
              _calcIsMeaningfullyEmpty(value));
        return fallback;
      })
      .where((record) => record.isNotEmpty)
      .toList();
}

List<Map<String, dynamic>> _findSuggestionRecords(
  dynamic source,
  List<String> matchers,
) {
  final clean = _calcCleanValue(source);
  final records = _calcRecordList(clean);
  if (records.isNotEmpty) return records;

  final map = _calcAsMap(clean);
  if (map.isNotEmpty) {
    for (final entry in map.entries) {
      final key = _calcKey(entry.key);
      if (matchers.any((matcher) => key.contains(_calcKey(matcher)))) {
        final nestedRecords = _calcRecordList(entry.value);
        if (nestedRecords.isNotEmpty) return nestedRecords;
      }
    }
    for (final entry in map.entries) {
      final nestedRecords = _findSuggestionRecords(entry.value, matchers);
      if (nestedRecords.isNotEmpty) return nestedRecords;
    }
  }

  final list = _calcAsList(clean);
  for (final item in list) {
    final nestedRecords = _findSuggestionRecords(item, matchers);
    if (nestedRecords.isNotEmpty) return nestedRecords;
  }
  return const [];
}

bool _suggestionHiddenKey(String key, Set<String> extraHidden) {
  final normalized = key.toLowerCase().trim();
  final compact = _calcKey(key);
  return _calcShouldHideKey(key) ||
      _calcIsImageKey(key) ||
      extraHidden.contains(normalized) ||
      extraHidden.contains(compact);
}

double _suggestionColumnWidth(String column, {String value = ''}) {
  final key = _calcKey(column);
  if (key == 'status') return 76;
  if (key == 'title' || key == 'name') return 128;
  if (key.contains('summary') ||
      key.contains('description') ||
      key.contains('details')) {
    return value.length > 90 ? 210 : 170;
  }
  if (key.contains('oneline') || key.contains('report')) return 180;
  return value.length > 45 ? 140 : 96;
}

class _InfoGrid extends StatelessWidget {
  final List<MapEntry<String, dynamic>> rows;

  const _InfoGrid({required this.rows});

  @override
  Widget build(BuildContext context) {
    final visible = rows
        .where((entry) =>
            !_calcShouldHideKey(entry.key) &&
            !_calcIsImageKey(entry.key) &&
            !_calcIsMeaningfullyEmpty(entry.value))
        .toList();
    if (visible.isEmpty) {
      return const _UnavailableCard(message: 'No details returned.');
    }
    return LayoutBuilder(builder: (context, constraints) {
      final tileWidth = constraints.maxWidth < 340
          ? constraints.maxWidth
          : (constraints.maxWidth - 10) / 2;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: visible.map((entry) {
          final value = _calcCleanText(_calcValue(entry.value));
          final wide = value.length > 90 || constraints.maxWidth < 340;
          return SizedBox(
            width: wide ? constraints.maxWidth : tileWidth,
            child: _InfoTile(
              label: _calcFriendlyTitle(entry.key),
              value: value,
            ),
          );
        }).toList(),
      );
    });
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1E3557),
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubSectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SubSectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1E3557),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _FlatDataSection extends StatelessWidget {
  final String title;
  final dynamic value;

  const _FlatDataSection({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final clean = _calcCleanValue(value);
    if (_calcIsMeaningfullyEmpty(clean)) return const SizedBox.shrink();

    final recordRows = _calcRecordList(clean);
    if (recordRows.isNotEmpty) {
      return _RecordTable(title: title, records: recordRows);
    }

    final map = _calcAsMap(clean);
    if (map.isNotEmpty) {
      final simpleRows = <MapEntry<String, dynamic>>[];
      final childWidgets = <Widget>[];

      for (final entry in map.entries) {
        if (_calcShouldHideKey(entry.key) ||
            _calcIsMeaningfullyEmpty(entry.value)) {
          continue;
        }
        final entryValue = _calcCleanValue(entry.value);
        final nestedRecords = _calcRecordList(entryValue);

        if (_calcIsPrimitive(entryValue) || _calcListIsPrimitive(entryValue)) {
          simpleRows.add(entry);
          continue;
        }
        if (nestedRecords.isNotEmpty) {
          childWidgets.add(_RecordTable(
            title: _calcFriendlyTitle(entry.key),
            records: nestedRecords,
          ));
          continue;
        }

        final nestedMap = _calcAsMap(entryValue);
        if (nestedMap.isNotEmpty) {
          final visible = nestedMap.entries
              .where((nestedEntry) =>
                  !_calcShouldHideKey(nestedEntry.key) &&
                  !_calcIsMeaningfullyEmpty(nestedEntry.value))
              .toList();
          if (visible.isNotEmpty &&
              visible.every((nestedEntry) =>
                  _calcIsPrimitive(nestedEntry.value) ||
                  _calcListIsPrimitive(nestedEntry.value))) {
            childWidgets.add(_InfoGrid(rows: visible));
          } else {
            childWidgets.add(_PlainDataCard(
              title: _calcFriendlyTitle(entry.key),
              text: _calcValue(entryValue),
            ));
          }
          continue;
        }

        childWidgets.add(_PlainDataCard(
          title: _calcFriendlyTitle(entry.key),
          text: _calcValue(entryValue),
        ));
      }

      return _CollapsibleSectionCard(
        title: title,
        initiallyExpanded: simpleRows.length <= 6 && childWidgets.length <= 1,
        child: Column(
          children: [
            if (simpleRows.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(bottom: childWidgets.isEmpty ? 0 : 10),
                child: _InfoGrid(rows: simpleRows),
              ),
            ...childWidgets,
          ],
        ),
      );
    }

    return _PlainDataCard(title: title, text: _calcValue(clean));
  }
}

class _CollapsibleSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  const _CollapsibleSectionCard({
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: const Color(0xFF1E3557),
          collapsedIconColor: const Color(0xFF1E3557),
          title: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1E3557),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          children: [child],
        ),
      ),
    );
  }
}

class _PlainDataCard extends StatelessWidget {
  final String title;
  final String text;

  const _PlainDataCard({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 7),
          ],
          Text(
            _calcCleanText(text),
            style: const TextStyle(
              color: Color(0xFF1E3557),
              fontSize: 15,
              height: 1.35,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextCard extends StatelessWidget {
  final String text;

  const _TextCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Text(
        _calcCleanText(text),
        style: const TextStyle(
          color: Color(0xFF1E3557),
          fontSize: 15.5,
          height: 1.4,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _RecordTable extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> records;

  const _RecordTable({required this.title, required this.records});

  @override
  Widget build(BuildContext context) {
    final columns = <String>[];
    for (final record in records) {
      for (final key in record.keys) {
        if (!_calcShouldHideKey(key) &&
            !_calcIsImageKey(key) &&
            !columns.contains(key)) {
          columns.add(key);
        }
      }
    }
    if (columns.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1E3557),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE6D7BA)),
              ),
              child: const Text(
                'Scroll table left or right',
                style: TextStyle(
                  color: Color(0xFF8A6100),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFD7AF4B)),
                dataRowMinHeight: 40,
                dataRowMaxHeight: 96,
                columnSpacing: 10,
                horizontalMargin: 10,
                headingTextStyle: const TextStyle(
                  color: Color(0xFF1E3557),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
                dataTextStyle: const TextStyle(
                  color: Color(0xFF1E3557),
                  fontWeight: FontWeight.w400,
                  height: 1.25,
                  fontSize: 12.5,
                ),
                columns: columns.map((column) {
                  final width = _calcColumnWidth(column, '');
                  return DataColumn(
                    label: SizedBox(
                      width: width,
                      child: Text(
                        _calcFriendlyTitle(column),
                        softWrap: true,
                        maxLines: 2,
                      ),
                    ),
                  );
                }).toList(),
                rows: records.map((record) {
                  return DataRow(
                    cells: columns.map((column) {
                      final value = _calcCleanText(_calcValue(record[column]));
                      final width = _calcColumnWidth(column, value);
                      return DataCell(
                        SizedBox(
                          width: width,
                          child: Text(value, softWrap: true),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<Map<String, dynamic>> _compactDashaRows(List<Map<String, dynamic>> rows) {
  return rows
      .map((row) {
        final next = <String, dynamic>{};
        for (final entry in row.entries) {
          if (_dashaShouldHideKey(entry.key)) continue;
          if (_calcIsMeaningfullyEmpty(entry.value)) continue;
          final key = _calcKey(entry.key);
          if (key == 'duration' && _calcIsMeaningfullyEmpty(entry.value)) {
            continue;
          }
          final value = _calcCleanValue(entry.value);
          if (value is Map) {
            final nested = _calcAsMap(value);
            for (final nestedEntry in nested.entries) {
              final nestedKey = '${entry.key}_${nestedEntry.key}';
              if (_dashaShouldHideKey(nestedEntry.key) ||
                  _dashaShouldHideKey(nestedKey)) {
                continue;
              }
              if (_calcIsMeaningfullyEmpty(nestedEntry.value)) continue;
              next[nestedKey] = nestedEntry.value;
            }
          } else {
            next[entry.key] = value;
          }
        }
        return next;
      })
      .where((row) => row.isNotEmpty)
      .toList();
}

double _calcColumnWidth(String column, String value) {
  final key = _calcKey(column);
  if (key == 'id' || key.endsWith('_id')) return 54;
  if (key == 'planet' || key == 'dasha' || key == 'name') return 92;
  if (key.contains('date') || key == 'start' || key == 'end') return 104;
  if (key.contains('duration')) return 76;
  if (key == 'sign' || key.contains('sign_name')) return 90;
  if (key.contains('prediction') || key.contains('description')) return 190;
  if (value.length <= 8) return 64;
  if (value.length <= 18) return 96;
  if (value.length <= 42) return 132;
  return 180;
}

class _UnavailableCard extends StatelessWidget {
  final String message;

  const _UnavailableCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFD7AF4B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF1E3557),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

dynamic _calcUnwrap(dynamic value) {
  var current = value;
  for (var i = 0; i < 5; i++) {
    final map = _calcAsMap(current);
    if (map.isEmpty) break;
    if (map['status'] == 'error') return map;
    if (map.containsKey('data')) {
      current = map['data'];
      continue;
    }
    if (map.containsKey('provider_payload')) {
      current = map['provider_payload'];
      continue;
    }
    return _calcCleanMap(map);
  }
  return _calcCleanValue(current);
}

dynamic _calcCleanValue(dynamic value) {
  if (value is Map) return _calcCleanMap(_calcAsMap(value));
  if (value is List) {
    return value
        .map(_calcCleanValue)
        .where((item) => !_calcIsMeaningfullyEmpty(item))
        .toList();
  }
  return value;
}

Map<String, dynamic> _calcCleanMap(Map<String, dynamic> map) {
  final cleaned = <String, dynamic>{};
  for (final entry in map.entries) {
    if (_calcShouldHideKey(entry.key)) continue;
    if (_calcIsMeaningfullyEmpty(entry.value)) continue;
    cleaned[entry.key] = _calcCleanValue(entry.value);
  }
  return cleaned;
}

Map<String, dynamic> _calcAsMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

List<dynamic> _calcAsList(dynamic value) => value is List ? value : const [];

List<Map<String, dynamic>> _calcRecordList(dynamic value) {
  if (value is List) {
    final rows = value
        .whereType<Map>()
        .map((item) => _calcCleanMap(Map<String, dynamic>.from(item)))
        .where((item) => item.isNotEmpty)
        .toList();
    return rows;
  }
  final map = _calcAsMap(value);
  if (map.isNotEmpty &&
      map.length > 1 &&
      map.values.every((item) => item is Map)) {
    return map.entries
        .map((entry) => {
              'name': _calcFriendlyTitle(entry.key),
              ..._calcCleanMap(_calcAsMap(entry.value)),
            })
        .where((item) => item.length > 1)
        .toList();
  }
  return const [];
}

bool _calcIsPrimitive(dynamic value) =>
    value == null || value is String || value is num || value is bool;

bool _calcListIsPrimitive(dynamic value) =>
    value is List && value.every(_calcIsPrimitive);

bool _calcIsMeaningfullyEmpty(dynamic value) {
  if (value == null) return true;
  if (value is String) {
    final text = value.trim();
    return text.isEmpty || text == '-' || text == '--' || text == '[]';
  }
  if (value is Iterable) return value.every(_calcIsMeaningfullyEmpty);
  if (value is Map) {
    final map = _calcAsMap(value);
    if (map['status'] == 'error') return false;
    final filtered =
        map.entries.where((entry) => !_calcShouldHideKey(entry.key));
    return filtered.isEmpty ||
        filtered.every((entry) => _calcIsMeaningfullyEmpty(entry.value));
  }
  return false;
}

bool _calcShouldHideKey(String key) {
  final normalized = key.toLowerCase().trim();
  final compact = _calcKey(key);
  const hidden = {
    'status',
    'success',
    'endpoint',
    'api',
    'url',
    'provider_payload',
    'raw',
    'raw_response',
    'debug',
    'request',
    'message',
    'msg',
    'svg',
    'start_ms',
    'end_ms',
    'start_time_ms',
    'end_time_ms',
    'planet_small',
    'millisecond',
    'milliseconds',
    'milli_second',
    'milli_seconds',
    'startms',
    'endms',
    'startmilliseconds',
    'endmilliseconds',
    'planetsmall',
  };
  return hidden.contains(normalized) || hidden.contains(compact);
}

bool _dashaShouldHideKey(String key) {
  final compact = _calcKey(key);
  return _calcShouldHideKey(key) ||
      compact == 'planet_id' ||
      compact == 'planetid' ||
      compact.contains('_planet_id') ||
      compact.contains('_planetid');
}

bool _isCompactResultTool(String key) {
  const tools = {
    'daily_nakshatra_predictions',
    'daily_nakshatra_prediction',
    'mangal_dosha',
    'kaal_sarp_dosha',
    'kal_sarp_dosha',
    'kaalsarp_dosha',
    'sade_sati',
    'sadhesati',
    'pitra_dosha',
  };
  return tools.contains(_calcKey(key));
}

bool _calcHasError(dynamic value) {
  final map = _calcAsMap(value);
  if (map['status'] == 'error') return true;
  final data = _calcAsMap(map['data']);
  return data['status'] == false || data['status'] == 'error';
}

String _calcErrorMessage(dynamic value) {
  final map = _calcAsMap(value);
  final data = _calcAsMap(map['data']);
  return _calcValue(map['message'] ??
      data['msg'] ??
      data['message'] ??
      'This section is not available in the current plan.');
}

String _calcValue(dynamic value) {
  if (value == null || value == '') return '-';
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is num) return value.toString();
  if (value is List) {
    final parts = value
        .map(_calcValue)
        .where((item) => item != '-' && item.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? '-' : parts.join(', ');
  }
  if (value is Map) {
    final map = _calcCleanMap(_calcAsMap(value));
    return map.entries
        .map((entry) =>
            '${_calcFriendlyTitle(entry.key)}: ${_calcValue(entry.value)}')
        .join(' | ');
  }
  return _calcCleanText(value.toString());
}

String _calcCleanText(String value) {
  final cleaned = value
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.contains('://')) return cleaned;
  return cleaned.replaceAll('_', ' ');
}

String _calcKey(dynamic value) {
  return value
      .toString()
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

String _calcFriendlyTitle(dynamic raw) {
  final key = _calcKey(raw);
  const overrides = {
    'mangal_dosha': 'Mangal Dosha',
    'manglik': 'Mangal Dosha',
    'mangal_dosha_report': 'Mangal Dosha',
    'kaal_sarp_dosha': 'Kaal Sarp Dosha',
    'kalsarpa_details': 'Kaal Sarp Dosha',
    'pitra_dosha_report': 'Pitra Dosha',
    'sadhesati_current_status': 'Current Sade Sati',
    'sadhesati_life_details': 'Sade Sati Life Details',
    'sadhesati_remedies': 'Sade Sati Remedies',
    'basic_gem_suggestion': 'Gemstone Suggestions',
    'rudraksha_suggestion': 'Rudraksha Suggestion',
    'puja_suggestion': 'Pooja Suggestion',
    'current_vdasha': 'Current Dasha',
    'current_vdasha_all': 'Current Dasha',
    'major_vdasha': 'Mahadasha',
    'current_vdasha_date': 'Current Dasha by Date',
    'sub_vdasha': 'Antardasha / Bhukti',
    'sub_sub_vdasha': 'Pratyantar Dasha',
    'sub_sub_sub_vdasha': 'Sookshma Dasha',
    'sub_sub_sub_sub_vdasha': 'Prana Dasha',
    'major': 'Mahadasha',
    'major_dasha': 'Mahadasha',
    'maha_dasha': 'Mahadasha',
    'mahadasha': 'Mahadasha',
    'minor': 'Antardasha / Bhukti',
    'minor_dasha': 'Antardasha / Bhukti',
    'antar_dasha': 'Antardasha / Bhukti',
    'antardasha': 'Antardasha / Bhukti',
    'bhukti': 'Antardasha / Bhukti',
    'sub_minor': 'Pratyantar Dasha',
    'sub_minor_dasha': 'Pratyantar Dasha',
    'pratyantar': 'Pratyantar Dasha',
    'pratyantar_dasha': 'Pratyantar Dasha',
    'sub_sub_minor': 'Sookshma Dasha',
    'sub_sub_minor_dasha': 'Sookshma Dasha',
    'sub_sub_sub': 'Sookshma Dasha',
    'sookshma': 'Sookshma Dasha',
    'sookshma_dasha': 'Sookshma Dasha',
    'sub_sub_sub_minor': 'Prana Dasha',
    'sub_sub_sub_minor_dasha': 'Prana Dasha',
    'sub_sub_sub_sub': 'Prana Dasha',
    'pran': 'Prana Dasha',
    'pran_dasha': 'Prana Dasha',
    'prana': 'Prana Dasha',
    'prana_dasha': 'Prana Dasha',
    'major_chardasha': 'Major Char Dasha',
    'current_chardasha': 'Current Char Dasha',
    'sub_chardasha': 'Sub Char Dasha',
    'sub_sub_chardasha': 'Sub Sub Char Dasha',
    'major_yogini_dasha': 'Major Yogini Dasha',
    'current_yogini_dasha': 'Current Yogini Dasha',
    'yogini_dasha_details': 'Yogini Dasha Details',
    'sub_yogini_dasha': 'Sub Yogini Dasha',
    'varshaphal_year_chart': 'Varshaphal Year Chart',
    'varshaphal_month_chart': 'Varshaphal Month Chart',
    'varshaphal_details': 'Varshaphal Details',
    'varshaphal_planets': 'Varshaphal Planets',
    'varshaphal_muntha': 'Muntha',
    'varshaphal_mudda_dasha': 'Mudda Dasha',
    'varshaphal_panchavargeeya_bala': 'Panchavargeeya Bala',
    'varshaphal_harsha_bala': 'Harsha Bala',
    'varshaphal_saham_points': 'Saham Points',
    'varshaphal_yoga': 'Varshaphal Yoga',
    'kp_planets': 'KP Planets',
    'kp_house_cusps': 'KP House Cusps',
    'kp_birth_chart': 'KP Birth Chart',
    'kp_house_significator': 'KP House Significator',
    'kp_planet_significator': 'KP Planet Significator',
    'planet_ashtak': 'Planet Ashtakavarga',
    'sarvashtak': 'Sarvashtakavarga',
    'biorhythm': 'Biorhythm',
    'moon_biorhythm': 'Moon Biorhythm',
  };
  if (overrides.containsKey(key)) return overrides[key]!;
  if (key.startsWith('planet_ashtak')) return 'Ashtakavarga';
  final spaced = raw.toString().replaceAll('_', ' ').replaceAll('-', ' ');
  return spaced
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part.length <= 2
          ? part.toUpperCase()
          : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _profileString(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

LocationSelection? _locationFromProfile(Map<String, dynamic> profile) {
  final place = _profileString(
    profile['place_of_birth'] ?? profile['birth_place'] ?? profile['pob'],
  );
  final coordinates = profile['coordinates'];
  double? lat;
  double? lng;
  if (coordinates is String && coordinates.contains(',')) {
    final parts = coordinates.split(',');
    lat = double.tryParse(parts.first.trim());
    lng = double.tryParse(parts.last.trim());
  } else if (coordinates is Map) {
    lat = _toProfileDouble(coordinates['latitude'] ?? coordinates['lat']);
    lng = _toProfileDouble(
      coordinates['longitude'] ?? coordinates['lng'] ?? coordinates['lon'],
    );
  }
  lat ??= _toProfileDouble(
    profile['latitude'] ??
        profile['lat'] ??
        profile['birth_latitude'] ??
        profile['place_latitude'],
  );
  lng ??= _toProfileDouble(
    profile['longitude'] ??
        profile['lng'] ??
        profile['lon'] ??
        profile['birth_longitude'] ??
        profile['place_longitude'],
  );
  if (place.isEmpty || lat == null || lng == null) return null;
  return LocationSelection(name: place, latitude: lat, longitude: lng);
}

double? _toProfileDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

String _calcSubtitleFor(String tabId, String toolKey) {
  const subtitles = {
    'basic_gem_suggestion': 'Life, benefic and lucky gemstone recommendations.',
    'rudraksha_suggestion': 'Recommended Rudraksha details.',
    'manglik': 'Manglik status and supporting observations.',
    'kalsarpa_details': 'Kaal Sarp Dosha observations.',
    'pitra_dosha_report': 'Pitra Dosha findings and guidance.',
    'varshaphal_yoga': 'Annual yoga combinations and their details.',
    'kp_birth_chart': 'KP chart values arranged for mobile reading.',
  };
  return subtitles[tabId] ?? '';
}

bool _calcIsImageKey(String key) {
  final normalized = key.toLowerCase();
  return normalized == 'image' ||
      normalized == 'image_url' ||
      normalized == 'imageurl' ||
      normalized == 'img' ||
      normalized.endsWith('_image');
}

String _calcFormatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

String _calcFormatTime(TimeOfDay time) {
  final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final m = time.minute.toString().padLeft(2, '0');
  final p = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$h:$m $p';
}

class _StandaloneBiorhythmBody extends StatelessWidget {
  final dynamic data;
  final DateTime birthDate;

  const _StandaloneBiorhythmBody({
    required this.data,
    required this.birthDate,
  });

  @override
  Widget build(BuildContext context) {
    final root = _calcAsMap(_calcCleanValue(data));
    final metrics = [
      _StandaloneBioMetric(
        label: 'Physical',
        data: _bioLookup(root, const ['physical']),
        cycleDays: 23,
        color: const Color(0xFF14B8A6),
        icon: Icons.fitness_center_rounded,
      ),
      _StandaloneBioMetric(
        label: 'Emotional',
        data: _bioLookup(root, const ['emotional']),
        cycleDays: 28,
        color: const Color(0xFFEC4899),
        icon: Icons.favorite_rounded,
      ),
      _StandaloneBioMetric(
        label: 'Intellectual',
        data: _bioLookup(root, const ['intellectual']),
        cycleDays: 33,
        color: const Color(0xFF8B5CF6),
        icon: Icons.psychology_rounded,
      ),
      _StandaloneBioMetric(
        label: 'Average',
        data: _bioLookup(root, const ['average']),
        cycleDays: 0,
        color: const Color(0xFFD7AF4B),
        icon: Icons.auto_graph_rounded,
      ),
    ];
    final visible = metrics.where((metric) => metric.hasPercent).toList();

    if (visible.isEmpty && root.isEmpty) {
      return const _UnavailableCard(
        message: 'Biorhythm scores are not available for this profile.',
      );
    }

    final summaryRows = <MapEntry<String, dynamic>>[];
    for (final key in const [
      'date',
      'considered_date',
      'birth_date',
      'days_alive',
      'day_number',
    ]) {
      final value = _bioLookup(root, [key]);
      if (!_calcIsMeaningfullyEmpty(value)) {
        summaryRows.add(MapEntry(key, value));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (visible.isNotEmpty) ...[
          _BioHeroCard(metrics: visible, birthDate: birthDate),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            const gap = 8.0;
            final tileWidth = constraints.maxWidth < 350
                ? constraints.maxWidth
                : (constraints.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: visible
                  .map(
                    (metric) => SizedBox(
                      width: tileWidth,
                      child: _StandaloneBioScoreCard(metric: metric),
                    ),
                  )
                  .toList(),
            );
          }),
        ],
        if (summaryRows.isNotEmpty) ...[
          const SizedBox(height: 10),
          _BioCompactInfoGrid(rows: summaryRows),
        ],
        if (visible.isEmpty && root.isNotEmpty)
          _CleanResultBody(data: root, compact: true, tabId: 'biorhythm'),
      ],
    );
  }
}

class _BioHeroCard extends StatelessWidget {
  final List<_StandaloneBioMetric> metrics;
  final DateTime birthDate;

  const _BioHeroCard({required this.metrics, required this.birthDate});

  @override
  Widget build(BuildContext context) {
    double? average;
    for (final metric in metrics) {
      if (metric.label == 'Average' && metric.percent != null) {
        average = metric.percent;
        break;
      }
    }
    final values = metrics.map((metric) => metric.percent).whereType<double>();
    final score = average ??
        values.fold<double>(0, (sum, value) => sum + value) / values.length;
    final color = _bioValueColor(score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _bioPercentText(score),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Physical, emotional and intellectual rhythms.',
                      style: TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 138,
            child: CustomPaint(
              painter: _BioCyclePainter(metrics: metrics, birthDate: birthDate),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: metrics
                .where((metric) => metric.cycleDays > 0)
                .map(
                  (metric) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: metric.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        metric.label,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _StandaloneBioScoreCard extends StatelessWidget {
  final _StandaloneBioMetric metric;

  const _StandaloneBioScoreCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final value = metric.percent ?? 0;
    final color = _bioValueColor(value, fallback: metric.color);
    final fill = (value.abs().clamp(0, 100) / 100).toDouble();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 54,
                  height: 54,
                  child: CircularProgressIndicator(
                    value: fill,
                    strokeWidth: 7,
                    strokeCap: StrokeCap.round,
                    color: color,
                    backgroundColor: const Color(0xFFE8E0C9),
                  ),
                ),
                Text(
                  _bioPercentText(value),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(metric.icon, size: 14, color: metric.color),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        metric.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF1E3557),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Trend ${metric.trendText}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StandaloneMoonBiorhythmBody extends StatelessWidget {
  final dynamic data;

  const _StandaloneMoonBiorhythmBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final root = _calcAsMap(_calcCleanValue(data));
    if (root.isEmpty) {
      return const _UnavailableCard(
        message: 'Moon biorhythm details are not available for this profile.',
      );
    }

    final summary = _bioRows(root, const {
      'birth_pakshi': 'Birth Pakshi',
      'bird_id': 'Bird ID',
      'considered_date': 'Considered Date',
    });
    final details = _calcAsMap(_bioLookup(root, const [
      'birth_pakshi_details',
      'birthPakshiDetails',
      'pakshi_details',
      'pakshiDetails',
    ]));
    final activity = _bioLookup(root, const [
      'activity_cycle',
      'activityCycle',
      'activity',
    ]);

    final sections = [
      _MoonStandaloneSection(
        'Name Letter',
        _bioLookup(root, const ['name_letter', 'name_letters', 'nameLetter']),
      ),
      _MoonStandaloneSection(
        'Death Day',
        _bioLookup(root, const ['death_day', 'death_days', 'deathDay']),
      ),
      _MoonStandaloneSection(
        'Day Ruling Days',
        _bioLookup(root, const ['day_ruling_days', 'dayRulingDays']),
      ),
      _MoonStandaloneSection(
        'Night Ruling Days',
        _bioLookup(root, const ['night_ruling_days', 'nightRulingDays']),
      ),
      _MoonStandaloneSection('Enemy', _bioLookup(root, const ['enemy'])),
      _MoonStandaloneSection('Friend', _bioLookup(root, const ['friend'])),
    ].where((section) => !_calcIsMeaningfullyEmpty(section.data)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary.isNotEmpty) ...[
          _BioSectionCard(
            title: '',
            child: _BioCompactInfoGrid(rows: summary),
          ),
          const SizedBox(height: 8),
        ],
        if (details.isNotEmpty) ...[
          _BioSectionCard(
            title: '',
            highlighted: true,
            child: _BioCompactInfoGrid(rows: details.entries.toList()),
          ),
          const SizedBox(height: 8),
        ],
        for (final section in sections) ...[
          _BioCompactRecordTable(
            title: section.title,
            records: _bioSimpleRecords(section.data, section.title),
          ),
          const SizedBox(height: 8),
        ],
        ..._bioActivityTables(activity),
      ],
    );
  }
}

class _BioSectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool highlighted;

  const _BioSectionCard({
    required this.title,
    required this.child,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFFFF8E5) : Colors.transparent,
        borderRadius: BorderRadius.circular(highlighted ? 12 : 0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1E3557),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
          ],
          child,
        ],
      ),
    );
  }
}

class _BioCompactInfoGrid extends StatelessWidget {
  final List<MapEntry<String, dynamic>> rows;

  const _BioCompactInfoGrid({required this.rows});

  @override
  Widget build(BuildContext context) {
    final visible = rows
        .where((entry) =>
            !_calcShouldHideKey(entry.key) &&
            !_calcIsImageKey(entry.key) &&
            !_calcIsMeaningfullyEmpty(entry.value))
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      final itemWidth = constraints.maxWidth < 350
          ? constraints.maxWidth
          : (constraints.maxWidth - 8) / 2;
      return Wrap(
        spacing: 8,
        runSpacing: 7,
        children: visible.map((entry) {
          final label = _calcFriendlyTitle(entry.key);
          final value = _calcCleanText(_calcValue(entry.value));
          final wide = value.length > 44 || constraints.maxWidth < 350;
          return SizedBox(
            width: wide ? constraints.maxWidth : itemWidth,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF4),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE6D7BA)),
              ),
              child: RichText(
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: const TextStyle(
                    color: Color(0xFF1E3557),
                    fontSize: 11.5,
                    height: 1.2,
                  ),
                  children: [
                    TextSpan(
                      text: '$label: ',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    TextSpan(
                      text: value,
                      style: const TextStyle(fontWeight: FontWeight.w400),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

class _BioCompactRecordTable extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> records;
  final List<List<String>>? columnGroups;

  const _BioCompactRecordTable({
    required this.title,
    required this.records,
    this.columnGroups,
  });

  @override
  Widget build(BuildContext context) {
    final columns = <String>[];
    for (final record in records) {
      for (final key in record.keys) {
        if (!_calcShouldHideKey(key) &&
            !_calcIsImageKey(key) &&
            !columns.contains(key)) {
          columns.add(key);
        }
      }
    }
    if (columns.isEmpty) return const SizedBox.shrink();
    final displayColumns = columnGroups == null
        ? columns
        : _bioColumnsByGroups(columns, columnGroups!);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 0, 2, 5),
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF1E3557),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE6D7BA)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor:
                      WidgetStateProperty.all(const Color(0xFFD7AF4B)),
                  dataRowMinHeight: 34,
                  dataRowMaxHeight: 52,
                  headingRowHeight: 34,
                  columnSpacing: 8,
                  horizontalMargin: 8,
                  dividerThickness: 0.7,
                  headingTextStyle: const TextStyle(
                    color: Color(0xFF1E3557),
                    fontWeight: FontWeight.w900,
                    fontSize: 10.5,
                    height: 1.1,
                  ),
                  dataTextStyle: const TextStyle(
                    color: Color(0xFF1E3557),
                    fontWeight: FontWeight.w400,
                    fontSize: 11.5,
                    height: 1.12,
                  ),
                  columns: displayColumns.map((column) {
                    final width = _bioCompactColumnWidth(column);
                    return DataColumn(
                      label: SizedBox(
                        width: width,
                        child: Text(
                          _calcFriendlyTitle(column),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }).toList(),
                  rows: records.map((record) {
                    return DataRow(
                      cells: displayColumns.map((column) {
                        final value =
                            _calcCleanText(_calcValue(record[column]));
                        return DataCell(
                          SizedBox(
                            width: _bioCompactColumnWidth(column, value: value),
                            child: Text(
                              value,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BioCyclePainter extends CustomPainter {
  final List<_StandaloneBioMetric> metrics;
  final DateTime birthDate;

  const _BioCyclePainter({required this.metrics, required this.birthDate});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE8E0C9)
      ..strokeWidth = 1;
    final centerY = size.height / 2;
    canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), gridPaint);
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      gridPaint,
    );

    final usableHeight = size.height - 24;
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day)
        .difference(DateTime(birthDate.year, birthDate.month, birthDate.day))
        .inDays;
    const daysBefore = 15;
    const daysAfter = 15;
    const totalDays = daysBefore + daysAfter;

    for (final metric in metrics.where((metric) => metric.cycleDays > 0)) {
      final path = Path();
      for (var offset = -daysBefore; offset <= daysAfter; offset++) {
        final x = ((offset + daysBefore) / totalDays) * size.width;
        final value =
            math.sin(2 * math.pi * (base + offset) / metric.cycleDays);
        final y = centerY - value * usableHeight / 2;
        if (offset == -daysBefore) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      final paint = Paint()
        ..color = metric.color
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BioCyclePainter oldDelegate) {
    return oldDelegate.metrics != metrics || oldDelegate.birthDate != birthDate;
  }
}

class _StandaloneBioMetric {
  final String label;
  final dynamic data;
  final int cycleDays;
  final Color color;
  final IconData icon;

  const _StandaloneBioMetric({
    required this.label,
    required this.data,
    required this.cycleDays,
    required this.color,
    required this.icon,
  });

  double? get percent {
    final map = _calcAsMap(_calcCleanValue(data));
    return _bioNumber(map['percent'] ?? map['percentage'] ?? data);
  }

  bool get hasPercent => percent != null;

  String get trendText {
    final map = _calcAsMap(_calcCleanValue(data));
    final trend = _calcValue(map['trend']);
    if (trend == '1') return 'Up';
    if (trend == '0') return 'Neutral';
    if (trend == '-1') return 'Down';
    return trend == '-' ? 'Neutral' : trend;
  }
}

class _MoonStandaloneSection {
  final String title;
  final dynamic data;

  const _MoonStandaloneSection(this.title, this.data);
}

dynamic _bioLookup(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (map.containsKey(key)) return map[key];
  }
  final wanted = keys.map(_calcKey).toSet();
  for (final entry in map.entries) {
    if (wanted.contains(_calcKey(entry.key))) return entry.value;
  }
  return null;
}

List<MapEntry<String, dynamic>> _bioRows(
  Map<String, dynamic> map,
  Map<String, String> labels,
) {
  final rows = <MapEntry<String, dynamic>>[];
  for (final entry in labels.entries) {
    final value = _bioLookup(map, [entry.key]);
    if (!_calcIsMeaningfullyEmpty(value)) {
      rows.add(MapEntry(entry.value, value));
    }
  }
  return rows;
}

List<Map<String, dynamic>> _bioSimpleRecords(dynamic source, String title) {
  final cleaned = _calcCleanValue(source);
  final records = _calcRecordList(cleaned);
  if (records.isNotEmpty) {
    return List.generate(records.length, (index) {
      final record = Map<String, dynamic>.from(records[index]);
      record.putIfAbsent('sn', () => index + 1);
      return record;
    });
  }

  final list = _calcAsList(cleaned);
  if (list.isNotEmpty) {
    return List.generate(
      list.length,
      (index) => {'sn': index + 1, title: _calcValue(list[index])},
    );
  }

  final map = _calcAsMap(cleaned);
  if (map.isNotEmpty) {
    return map.entries
        .where((entry) => !_calcIsMeaningfullyEmpty(entry.value))
        .map((entry) => {
              'name': _calcFriendlyTitle(entry.key),
              title: _calcValue(entry.value),
            })
        .toList();
  }

  if (_calcIsMeaningfullyEmpty(cleaned)) return const [];
  return [
    {'sn': 1, title: _calcValue(cleaned)}
  ];
}

List<Widget> _bioActivityTables(dynamic source) {
  final cleaned = _calcCleanValue(source);
  if (_calcIsMeaningfullyEmpty(cleaned)) return const [];

  final map = _calcAsMap(cleaned);
  if (map.isNotEmpty) {
    final widgets = <Widget>[];
    for (final entry in map.entries) {
      final records = _bioSimpleRecords(entry.value, 'Activity');
      if (records.isEmpty) continue;
      widgets.add(_BioCompactRecordTable(
        title: '${_calcFriendlyTitle(entry.key)} Activity',
        records: records,
        columnGroups: _bioActivityColumnGroups,
      ));
    }
    if (widgets.isNotEmpty) return widgets;
  }

  final records = _bioSimpleRecords(cleaned, 'Activity');
  return records.isEmpty
      ? const []
      : [
          _BioCompactRecordTable(
            title: 'Activity Cycle',
            records: records,
            columnGroups: _bioActivityColumnGroups,
          )
        ];
}

const _bioActivityColumnGroups = [
  ['sn'],
  ['start_time', 'startTime'],
  ['end_time', 'endTime'],
  ['start_hours', 'startHours'],
  ['end_hours', 'endHours'],
  ['activity_id', 'activityId'],
  ['activity'],
  ['activity_meaning', 'activityMeaning', 'meaning'],
];

List<String> _bioColumnsByGroups(
  List<String> columns,
  List<List<String>> groups,
) {
  final ordered = <String>[];
  final normalizedColumns = {
    for (final column in columns) _calcKey(column): column,
  };
  for (final group in groups) {
    for (final key in group) {
      final column = normalizedColumns[_calcKey(key)];
      if (column != null && !ordered.contains(column)) {
        ordered.add(column);
        break;
      }
    }
  }
  for (final column in columns) {
    if (!ordered.contains(column)) ordered.add(column);
  }
  return ordered;
}

double _bioCompactColumnWidth(String column, {String value = ''}) {
  final key = _calcKey(column);
  if (key == 'sn' || key == 'id' || key.contains('number')) return 34;
  if (key.contains('time') || key.contains('date') || key.contains('day')) {
    return 78;
  }
  if (key.contains('description') ||
      key.contains('activity') ||
      key.contains('details')) {
    return value.length > 80 ? 168 : 124;
  }
  if (value.length > 45) return 132;
  return 92;
}

double? _bioNumber(dynamic value) {
  if (value is num) return value.toDouble();
  final text = _calcValue(value);
  final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(text);
  if (match == null) return null;
  return double.tryParse(match.group(0)!);
}

Color _bioValueColor(double value, {Color? fallback}) {
  if (value >= 75) return const Color(0xFF16A34A);
  if (value >= 40) return fallback ?? const Color(0xFFD7AF4B);
  return const Color(0xFFDC2626);
}

String _bioPercentText(double value) {
  final rounded = value.roundToDouble() == value
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$rounded%';
}

// Retained as a fallback renderer for targeted Biorhythm debugging.
// ignore: unused_element
class _BiorhythmResult extends StatelessWidget {
  final Map<String, dynamic> response;

  const _BiorhythmResult({required this.response});

  static const _navy = Color(0xFF1E3557);
  static const _border = Color(0xFFE6D29D);

  @override
  Widget build(BuildContext context) {
    final data = _asMap(response['data']);
    final sections = _asList(data['provider_sections']);
    final items = <String, dynamic>{};
    if (sections.isNotEmpty) {
      for (final section in sections) {
        items.addAll(_asMap(_asMap(section)['items']));
      }
    } else {
      items.addAll(_asMap(data['provider_payload'] ?? data));
    }

    final biorhythm = _unwrap(items['biorhythm'] ?? items['Biorhythm']);
    final moon = _unwrap(items['moon_biorhythm'] ?? items['Moon Biorhythm']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _panel(
          title: 'Biorhythm',
          subtitle: 'Physical, emotional and intellectual cycles.',
          child: _cycleCards(biorhythm),
        ),
        if (moon.isNotEmpty)
          _panel(
            title: 'Moon Biorhythm',
            subtitle: 'Moon-based rhythm and activity guidance.',
            child: _dynamicCards(moon),
          ),
      ],
    );
  }

  Widget _cycleCards(Map<String, dynamic> map) {
    final cycles = <MapEntry<String, dynamic>>[];
    for (final key in ['physical', 'emotional', 'intellectual']) {
      if (map.containsKey(key)) cycles.add(MapEntry(key, map[key]));
    }
    if (cycles.isEmpty) {
      cycles.addAll(map.entries.where((entry) => entry.value is Map));
    }

    if (cycles.isEmpty) return _dynamicCards(map);
    return Column(
      children: cycles.map((entry) {
        final value = _asMap(entry.value);
        final percent = _value(value['percent'] ?? value['percentage']);
        final trend = _value(value['trend']);
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                height: 54,
                width: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFD7AF4B),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    percent == '-' ? '--' : '$percent%',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _titleize(entry.key),
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      trend == '-' ? 'Cycle value available.' : 'Trend: $trend',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _dynamicCards(Map<String, dynamic> map) {
    if (map.isEmpty) {
      return const Text(
        'No data returned.',
        style: TextStyle(color: Color(0xFF64748B)),
      );
    }

    return Column(
      children: map.entries.map((entry) {
        final normalizedKey = entry.key.toLowerCase().replaceAll(' ', '_');
        final rawValue = entry.value;
        if (normalizedKey.contains('activity')) {
          final records = _recordList(rawValue);
          if (records.isNotEmpty) {
            return _recordTable(_titleize(entry.key), records);
          }
        }

        final value = _unwrap(rawValue);
        if (value.isEmpty && _isPrimitive(rawValue)) {
          return _infoCard(_titleize(entry.key), _value(entry.value));
        }
        if (value.isEmpty) return const SizedBox.shrink();

        if (normalizedKey.contains('pakshi')) {
          return _infoCard(_titleize(entry.key), null, rows: value);
        }

        final nestedRecords = _recordList(value);
        if (nestedRecords.isNotEmpty) {
          return _recordTable(_titleize(entry.key), nestedRecords);
        }

        return _infoCard(_titleize(entry.key), null, rows: value);
      }).toList(),
    );
  }

  Widget _recordTable(String title, List<Map<String, dynamic>> records) {
    final columns = <String>[];
    for (final record in records) {
      for (final key in record.keys) {
        if (!columns.contains(key)) columns.add(key);
      }
    }
    if (columns.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Text(
              title,
              style: const TextStyle(
                color: _navy,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: _border),
              ),
              child: const Text(
                'Scroll table left or right',
                style: TextStyle(
                  color: Color(0xFF8A6100),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFD7AF4B)),
                dataRowMinHeight: 46,
                dataRowMaxHeight: 82,
                headingTextStyle: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
                dataTextStyle: const TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w400,
                  height: 1.25,
                ),
                columns: columns
                    .map((column) => DataColumn(label: Text(_titleize(column))))
                    .toList(),
                rows: records.map((record) {
                  return DataRow(
                    cells: columns.map((column) {
                      return DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            _value(record[column]),
                            softWrap: true,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String? value, {Map<String, dynamic>? rows}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _navy,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          if (value != null)
            Text(value, style: const TextStyle(height: 1.35))
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: rows!.entries.map((entry) {
                return SizedBox(
                  width: 138,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE8E0CF)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _titleize(entry.key),
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _value(entry.value),
                          style: const TextStyle(fontWeight: FontWeight.w400),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _panel({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFD7AF4B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: _navy)),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }

  static Map<String, dynamic> _unwrap(dynamic value) {
    var current = value;
    for (var i = 0; i < 4; i++) {
      final map = _asMap(current);
      if (map.isEmpty) return {};
      if (map.containsKey('data')) {
        current = map['data'];
        continue;
      }
      if (map.containsKey('provider_payload')) {
        current = map['provider_payload'];
        continue;
      }
      return map;
    }
    return _asMap(current);
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  static List<dynamic> _asList(dynamic value) =>
      value is List ? value : const [];

  static List<Map<String, dynamic>> _recordList(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is Map) {
      final map = _asMap(value);
      if (map.values.every((item) => item is Map)) {
        return map.entries
            .map((entry) => {
                  'name': _titleize(entry.key),
                  ..._asMap(entry.value),
                })
            .toList();
      }
    }
    return const [];
  }

  static bool _isPrimitive(dynamic value) =>
      value == null || value is String || value is num || value is bool;

  static String _value(dynamic value) {
    if (value == null || value == '') return '-';
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is List) {
      final parts = value.map(_value).where((item) => item != '-').toList();
      return parts.isEmpty ? '-' : parts.join(', ');
    }
    if (value is Map) {
      final map = _asMap(value);
      return map.entries
          .map((entry) => '${_titleize(entry.key)}: ${_value(entry.value)}')
          .join(' | ');
    }
    return _calcCleanText(value.toString());
  }

  static String _titleize(String value) {
    final spaced = value.replaceAll('_', ' ').replaceAll('-', ' ');
    return spaced
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}
