import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/astrology_service.dart';
import '../../core/services/recent_profile_service.dart';
import '../main_navigation.dart';
import '../mainwidgets/header.dart';
import '../shared/widgets/location_search_field.dart';

class DetailedDoshaReportScreen extends StatefulWidget {
  const DetailedDoshaReportScreen({super.key});

  @override
  State<DetailedDoshaReportScreen> createState() =>
      _DetailedDoshaReportScreenState();
}

class _DetailedDoshaReportScreenState extends State<DetailedDoshaReportScreen> {
  static const _navy = Color(0xFF1E3557);
  static const _gold = Color(0xFFD7AF4B);
  static const _border = Color(0xFFE8D6A4);
  static const _muted = Color(0xFF64748B);

  final _service = AstrologyService();
  final _recentProfiles = RecentProfileService();
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;
  LocationSelection? _location;
  String _profileName = 'Dosha Profile';
  String _ayanamsa = 'Lahiri';
  String _language = 'English';
  bool _loading = false;
  String? _error;

  static const _languageCodes = {
    'English': 'en',
    'Hindi': 'hi',
  };

  static const _ayanamsaCodes = {
    'Lahiri': 1,
    'Raman': 3,
    'Krishnamurti': 5,
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
    final name = prefs.getString('user_name');
    if (!mounted) return;
    setState(() {
      if (name != null && name.trim().isNotEmpty) _profileName = name.trim();
      if (dob.isNotEmpty) {
        _date = DateTime.tryParse(dob);
        _dateCtrl.text = _formatDate(_date);
      }
      if (tob.isNotEmpty) {
        _time = _parseTime(tob);
        _timeCtrl.text = _formatTime(_time);
      }
      if (pob.isNotEmpty) {
        _placeCtrl.text = pob;
        if (lat != null && lng != null) {
          _location = LocationSelection(
            name: pob,
            latitude: lat,
            longitude: lng,
          );
        }
      }
    });
  }

  Future<void> _showRecentProfiles() async {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RecentProfilesSheet(
        service: _recentProfiles,
        onSelected: _applyRecentProfile,
      ),
    );
  }

  void _applyRecentProfile(Map<String, dynamic> profile) {
    final dob = _string(profile['date_of_birth']);
    final tob = _string(profile['time_of_birth']);
    final pob = _string(profile['place_of_birth'] ?? profile['birth_place']);
    final name = _string(
      profile['profile_label'] ?? profile['person_name'] ?? profile['name'],
    );
    final location = _locationFromProfile(profile);
    setState(() {
      if (name.isNotEmpty) _profileName = name;
      if (dob.isNotEmpty) {
        _date = DateTime.tryParse(dob);
        _dateCtrl.text = _formatDate(_date);
      }
      if (tob.isNotEmpty) {
        _time = _parseTime(tob);
        _timeCtrl.text = _formatTime(_time);
      }
      if (pob.isNotEmpty) _placeCtrl.text = pob;
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
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _gold),
        ),
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
    var location = _location;
    if (date == null || time == null || _placeCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Date, time, and birth place are required.');
      return;
    }
    if (location == null) {
      final matches = await _service.searchLocations(_placeCtrl.text);
      if (matches.isNotEmpty) {
        location = LocationSelection.fromApi(matches.first);
      }
    }
    if (location == null) {
      setState(() => _error = 'Please select the birth place from the list.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final payload = <String, dynamic>{
      'datetime': _kolkataDateTime(date, time),
      'coordinates': location.coordinates,
      'ayanamsa': _ayanamsaCodes[_ayanamsa] ?? 1,
      'la': _languageCodes[_language] ?? 'en',
    };

    try {
      final results = await Future.wait([
        _service.vedicCalculator('mangal-dosha', payload),
        _service.vedicCalculator('kaal-sarp-dosha', payload),
        _service.vedicCalculator('sade-sati', payload),
        _service.vedicCalculator('pitra-dosha', payload),
      ]);
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _DetailedDoshaResultScreen(
            input: _DoshaInput(
              name: _profileName,
              date: date,
              time: time,
              place: location!.name,
            ),
            results: {
              'mangal': results[0],
              'kaal': results[1],
              'sade': results[2],
              'pitra': results[3],
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _goBack() {
    MainNavigationState.returnHome(context);
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _goBack,
                        icon: const Icon(Icons.arrow_circle_left_rounded),
                      ),
                      const Expanded(
                        child: Text(
                          'Detailed Dosha Analysis',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _form(),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_error != null)
                    _ErrorCard(message: _error!),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Birth Inputs',
            style: TextStyle(
              color: _navy,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: _showRecentProfiles,
              icon: const Icon(Icons.history_rounded),
              label: const Text('Choose a recent profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8A6400),
                side: const BorderSide(color: _gold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _label('Date of Birth'),
          _readonlyField(
              _dateCtrl, 'Select date', Icons.calendar_today, _pickDate),
          const SizedBox(height: 10),
          _label('Time of Birth'),
          _readonlyField(
              _timeCtrl, 'Select time', Icons.access_time, _pickTime),
          const SizedBox(height: 10),
          _label('Birth Place'),
          LocationSearchField(
            controller: _placeCtrl,
            initialSelection: _location,
            onSelected: (selection) => setState(() => _location = selection),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _dropdown(
                  'Ayanamsa',
                  _ayanamsa,
                  _ayanamsaCodes.keys.toList(),
                  (value) => setState(() => _ayanamsa = value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dropdown(
                  'Language',
                  _language,
                  _languageCodes.keys.toList(),
                  (value) => setState(() => _language = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: _loading ? null : _run,
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: _navy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _loading ? 'Generating...' : 'Generate Dosha Report',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _readonlyField(
    TextEditingController controller,
    String hint,
    IconData icon,
    VoidCallback onTap,
  ) {
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

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
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
            border: Border.all(color: const Color(0xFFE5E7EB)),
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

  Widget _label(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: _muted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DetailedDoshaResultScreen extends StatefulWidget {
  final _DoshaInput input;
  final Map<String, Map<String, dynamic>> results;

  const _DetailedDoshaResultScreen({
    required this.input,
    required this.results,
  });

  @override
  State<_DetailedDoshaResultScreen> createState() =>
      _DetailedDoshaResultScreenState();
}

class _DetailedDoshaResultScreenState
    extends State<_DetailedDoshaResultScreen> {
  static const _navy = Color(0xFF1E3557);
  static const _border = Color(0xFFE8D6A4);
  final _pageController = PageController();
  final _tabController = ScrollController();
  late final List<GlobalKey> _tabKeys;
  int _index = 0;

  List<_DoshaTab> get _tabs => [
        _DoshaTab(
          'mangal',
          'Mangal',
          'Mangal Dosha',
          _cleanDosha('mangal', _extractPayload(widget.results['mangal'])),
        ),
        _DoshaTab(
          'kaal',
          'Kaal Sarp',
          'Kaal Sarp Dosha',
          _cleanDosha('kaal', _extractPayload(widget.results['kaal'])),
        ),
        _DoshaTab(
          'sade',
          'Sade-Sati',
          'Sade-Sati',
          _cleanDosha('sade', _extractPayload(widget.results['sade'])),
        ),
        _DoshaTab(
          'pitra',
          'Pitra',
          'Pitra Dosha',
          _cleanDosha('pitra', _extractPayload(widget.results['pitra'])),
        ),
      ];

  @override
  void initState() {
    super.initState();
    _tabKeys = List.generate(_tabs.length, (_) => GlobalKey());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _setTab(int index) {
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
    _scrollTab(index);
  }

  void _scrollTab(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _tabKeys[index].currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 220),
        alignment: 0.5,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F0),
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(),
            _resultHeader(),
            SizedBox(
              height: 40,
              child: ListView.separated(
                controller: _tabController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final selected = index == _index;
                  return KeyedSubtree(
                    key: _tabKeys[index],
                    child: ChoiceChip(
                      label: Text(tabs[index].label),
                      selected: selected,
                      onSelected: (_) => _setTab(index),
                      showCheckmark: false,
                      selectedColor: _navy,
                      backgroundColor: Colors.white,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 9),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: const VisualDensity(
                        horizontal: -2,
                        vertical: -3,
                      ),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : _navy,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                      side: BorderSide(color: selected ? _navy : _border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: tabs.length,
                onPageChanged: (index) {
                  setState(() => _index = index);
                  _scrollTab(index);
                },
                itemBuilder: (context, index) {
                  final tab = tabs[index];
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 28),
                    children: [
                      _DoshaAssessmentCard(tab: tab),
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

  Widget _resultHeader() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      padding: const EdgeInsets.fromLTRB(8, 9, 12, 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            iconSize: 18,
            constraints: const BoxConstraints.tightFor(width: 34, height: 34),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.arrow_back, color: _navy),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.input.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDate(widget.input.date)} - ${_formatTime(widget.input.time)} - ${widget.input.place}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.5,
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

class _DoshaAssessmentCard extends StatelessWidget {
  final _DoshaTab tab;

  const _DoshaAssessmentCard({required this.tab});

  @override
  Widget build(BuildContext context) {
    final summary = _DoshaSummary.fromTab(tab);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFEFE3D1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: summary.iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(summary.icon, color: summary.iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      summary.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF1E3557),
                        fontSize: 16,
                        height: 1.25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      summary.subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusPill(text: summary.status, alert: summary.alert),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
              height: 1, color: const Color(0xFFE5E7EB).withValues(alpha: 0.7)),
          const SizedBox(height: 14),
          Text(
            summary.description,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (summary.sections.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final section in summary.sections) ...[
              _CompactDoshaSection(section: section),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final bool alert;

  const _StatusPill({required this.text, required this.alert});

  @override
  Widget build(BuildContext context) {
    final color = alert ? const Color(0xFFDC2626) : const Color(0xFF059669);
    final bg = alert ? const Color(0xFFFFECEB) : const Color(0xFFE8FFF4);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 112),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text.toUpperCase(),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 10,
            height: 1.05,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _CompactDoshaSection extends StatelessWidget {
  final _DoshaSection section;

  const _CompactDoshaSection({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            section.alert ? const Color(0xFFFFF7ED) : const Color(0xFFFBF7F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              section.alert ? const Color(0xFFF6D7A7) : const Color(0xFFF2ECE1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.title.toUpperCase(),
            style: TextStyle(
              color: section.alert
                  ? const Color(0xFFB05B35)
                  : const Color(0xFF1E3557),
              fontSize: 10,
              letterSpacing: 0.45,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          ...section.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: section.alert
                        ? const Color(0xFFD97706)
                        : const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFB91C1C),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RecentProfilesSheet extends StatefulWidget {
  final RecentProfileService service;
  final ValueChanged<Map<String, dynamic>> onSelected;

  const _RecentProfilesSheet({
    required this.service,
    required this.onSelected,
  });

  @override
  State<_RecentProfilesSheet> createState() => _RecentProfilesSheetState();
}

class _RecentProfilesSheetState extends State<_RecentProfilesSheet> {
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
      initialChildSize: 0.62,
      minChildSize: 0.36,
      maxChildSize: 0.9,
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
                width: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
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
                      fontSize: 19,
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
                                    'No recent profiles yet.',
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
                                  final title = _string(
                                    profile['profile_label'] ??
                                        profile['person_name'] ??
                                        profile['name'] ??
                                        'Saved Profile',
                                  );
                                  final subtitle = [
                                    profile['date_of_birth'],
                                    profile['time_of_birth'],
                                    profile['place_of_birth'],
                                  ]
                                      .where((item) =>
                                          item != null &&
                                          item.toString().trim().isNotEmpty)
                                      .join(' - ');
                                  return ListTile(
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
                                        : Text(subtitle),
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

class _DoshaInput {
  final String name;
  final DateTime date;
  final TimeOfDay time;
  final String place;

  const _DoshaInput({
    required this.name,
    required this.date,
    required this.time,
    required this.place,
  });
}

class _DoshaTab {
  final String type;
  final String label;
  final String title;
  final dynamic data;

  const _DoshaTab(this.type, this.label, this.title, this.data);
}

class _DoshaSummary {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String status;
  final bool alert;
  final String description;
  final List<_DoshaSection> sections;

  const _DoshaSummary({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.alert,
    required this.description,
    required this.sections,
  });

  factory _DoshaSummary.fromTab(_DoshaTab tab) {
    final root = _asMap(tab.data) ?? const <String, dynamic>{};
    final core = _coreDoshaMap(tab.type, root);
    return switch (tab.type) {
      'mangal' => _mangalSummary(core, root),
      'kaal' => _kaalSummary(core, root),
      'sade' => _sadeSummary(core, root),
      'pitra' => _pitraSummary(core, root),
      _ => _genericSummary(tab, core),
    };
  }
}

class _DoshaSection {
  final String title;
  final List<String> items;
  final bool alert;

  const _DoshaSection({
    required this.title,
    required this.items,
    this.alert = false,
  });
}

Map<String, dynamic> _extractPayload(Map<String, dynamic>? response) {
  if (response == null) return const {};
  final data = _asMap(response['data']) ?? response;
  final payload = _asMap(data['provider_payload']);
  if (payload != null) {
    for (final item in payload.values) {
      final unwrapped = _unwrapSuccess(item);
      if (_hasUsefulData(unwrapped)) {
        return _asMap(unwrapped) ?? {'details': unwrapped};
      }
    }
  }
  final sections = data['provider_sections'];
  if (sections is List) {
    final combined = <String, dynamic>{};
    for (final section in sections) {
      final map = _asMap(section);
      final items = _asMap(map?['items']);
      if (items != null) combined.addAll(items);
    }
    if (combined.isNotEmpty) return combined;
  }
  final unwrapped = _unwrapSuccess(data);
  return _asMap(unwrapped) ?? {'details': unwrapped};
}

dynamic _unwrapSuccess(dynamic value) {
  final map = _asMap(value);
  if (map == null) return value;
  if (map.containsKey('data') && map.length <= 4) {
    return _unwrapSuccess(map['data']);
  }
  return map;
}

dynamic _cleanDosha(String type, dynamic value) {
  final blocked = switch (type) {
    'mangal' => {
        'manglik_present_rule',
        'manglik present rule',
        'based_on_house',
        'based on house',
      },
    'kaal' => <String>{},
    'sade' => <String>{},
    'pitra' => {'rules_matched', 'rules matched'},
    _ => <String>{},
  };
  return _cleanValue(value, blocked);
}

dynamic _cleanValue(dynamic value, Set<String> blocked) {
  if (value is List) {
    return value
        .map((item) => _cleanValue(item, blocked))
        .where(_hasUsefulData)
        .toList();
  }
  final map = _asMap(value);
  if (map == null) return value;
  final result = <String, dynamic>{};
  map.forEach((key, item) {
    final normalized = _normalizeKey(key);
    if (_skipKey(normalized) || blocked.contains(normalized)) return;
    final cleaned = _cleanValue(item, blocked);
    if (_hasUsefulData(cleaned)) result[key.toString()] = cleaned;
  });
  if (result.length == 1 && result.containsKey('value')) return result['value'];
  return result;
}

bool _skipKey(String normalized) {
  return normalized == 'status' ||
      normalized == 'success' ||
      normalized == 'endpoint' ||
      normalized == 'provider_payload' ||
      normalized == 'provider_sections' ||
      normalized == 'raw' ||
      normalized == 'url' ||
      normalized == 'data' ||
      normalized == 'message';
}

_DoshaSummary _mangalSummary(
  Map<String, dynamic> core,
  Map<String, dynamic> root,
) {
  final hasDosha = _boolish(_firstValue(core, const [
        'has_dosha',
        'is_dosha_present',
        'manglik',
        'is_manglik',
        'mangal_dosha_present',
      ])) ??
      _boolish(_firstValue(root, const [
        'has_dosha',
        'is_dosha_present',
        'manglik',
        'is_manglik',
        'mangal_dosha_present',
      ]));
  final type = _firstText(core, const [
    'manglik_type',
    'manglik_status',
    'dosha_type',
    'type',
    'status',
  ]);
  final description = _firstText(core, const [
        'description',
        'report',
        'summary',
        'details',
        'result',
      ]) ??
      _firstText(root, const ['description', 'report', 'summary']) ??
      'No Mangal Dosha was detected from the returned chart details. Mars '
          'placement is not showing a major marriage-related obstruction in '
          'this assessment.';
  final sections = <_DoshaSection>[
    _sectionFromValue(
      'Cancellation Checks',
      _firstValue(core, const [
            'exceptions',
            'cancellation',
            'cancellation_exceptions',
            'manglik_cancellation',
          ]) ??
          _firstValue(root, const ['exceptions', 'cancellation']),
    ),
    _sectionFromValue(
      'Suggested Remedies',
      _firstValue(core, const ['remedies', 'remedy', 'suggested_remedies']) ??
          _firstValue(root, const ['remedies', 'remedy']),
      alert: true,
    ),
  ].where((section) => section.items.isNotEmpty).toList();

  final status = hasDosha == true
      ? (type == null ? 'Manglik' : _shortStatus(type, fallback: 'Manglik'))
      : 'No Dosha Detected';
  return _DoshaSummary(
    icon: Icons.local_fire_department_rounded,
    iconColor: const Color(0xFFFF7043),
    title: 'Mangal Dosha Assessment',
    subtitle: 'Mars Placement & Auspicious Cancellation Checks',
    status: status,
    alert: hasDosha == true,
    description: description,
    sections: sections,
  );
}

_DoshaSummary _kaalSummary(
    Map<String, dynamic> core, Map<String, dynamic> root) {
  final present = _boolish(_firstValue(core, const [
        'has_dosha',
        'is_present',
        'present',
        'kaal_sarp_present',
      ])) ??
      _boolish(_firstValue(root, const [
        'has_dosha',
        'is_present',
        'present',
        'kaal_sarp_present',
      ]));
  final description = _firstText(core, const [
        'description',
        'report',
        'summary',
        'details',
        'result',
      ]) ??
      _firstText(root, const ['description', 'report', 'summary']) ??
      'No Kaal Sarp Dosha detected in the natal chart. The planetary '
          'configuration does not fall entirely within the Rahu-Ketu '
          'containment axis.';
  final sections = <_DoshaSection>[
    _sectionFromValue(
      'Dosha Configuration',
      _firstValue(core, const ['type', 'dosha_type', 'name']),
      alert: present == true,
    ),
    _sectionFromValue(
      'Suggested Remedies',
      _firstValue(core, const ['remedies', 'remedy', 'suggested_remedies']) ??
          _firstValue(root, const ['remedies', 'remedy']),
      alert: true,
    ),
  ].where((section) => section.items.isNotEmpty).toList();

  return _DoshaSummary(
    icon: Icons.all_inclusive_rounded,
    iconColor: const Color(0xFF10B981),
    title: 'Kaal Sarp Dosha Assessment',
    subtitle: 'Rahu-Ketu Axis Containment Check',
    status: present == true ? 'Present' : 'Not Present',
    alert: present == true,
    description: description,
    sections: sections,
  );
}

_DoshaSummary _sadeSummary(
    Map<String, dynamic> core, Map<String, dynamic> root) {
  final active = _boolish(_firstValue(core, const [
        'is_active',
        'active',
        'in_sade_sati',
        'is_sade_sati',
        'sade_sati_present',
      ])) ??
      _boolish(_firstValue(root, const [
        'is_active',
        'active',
        'in_sade_sati',
        'is_sade_sati',
        'sade_sati_present',
      ]));
  final description = _firstText(core, const [
        'description',
        'report',
        'summary',
        'details',
        'result',
      ]) ??
      _firstText(root, const ['description', 'report', 'summary']) ??
      'Saturn is not currently transiting the 12th, 1st, or 2nd houses from '
          'your natal Moon sign. Sade Sati is not active at this time.';
  final sections = <_DoshaSection>[
    _sectionFromValue(
      'Transit Timeline',
      _firstValue(core, const [
            'timeline',
            'transits',
            'sade_sati_life_details',
            'life_details',
          ]) ??
          _firstValue(root, const ['timeline', 'sade_sati_life_details']),
      alert: active == true,
    ),
    _sectionFromValue(
      'Suggested Remedies',
      _firstValue(core, const [
            'remedies',
            'sade_sati_remedies',
            'remedy',
            'suggested_remedies',
          ]) ??
          _firstValue(root, const ['remedies', 'sade_sati_remedies']),
      alert: true,
    ),
  ].where((section) => section.items.isNotEmpty).toList();

  return _DoshaSummary(
    icon: Icons.public_rounded,
    iconColor: const Color(0xFFF59E0B),
    title: 'Shani Sade Sati Cycle',
    subtitle: "Saturn's 7.5 Year Transit Cycle",
    status: active == true ? 'Currently Active' : 'Inactive',
    alert: active == true,
    description: description,
    sections: sections,
  );
}

_DoshaSummary _pitraSummary(
  Map<String, dynamic> core,
  Map<String, dynamic> root,
) {
  final detected = _boolish(_firstValue(core, const [
        'has_dosha',
        'is_present',
        'present',
        'pitra_dosha_present',
      ])) ??
      _boolish(_firstValue(root, const [
        'has_dosha',
        'is_present',
        'present',
        'pitra_dosha_present',
      ]));
  final description = _firstText(core, const [
        'description',
        'report',
        'summary',
        'details',
        'result',
      ]) ??
      _firstText(root, const ['description', 'report', 'summary']) ??
      'No major lineage-related modifications found. Your 9th house '
          'placements are stable and free of severe malefic conjunctions.';
  final sections = <_DoshaSection>[
    _sectionFromValue(
      'Lineage Indicators',
      _firstValue(core, const ['indicators', 'rules_matched', 'factors']),
      alert: detected == true,
    ),
    _sectionFromValue(
      'Suggested Remedies',
      _firstValue(core, const ['remedies', 'remedy', 'suggested_remedies']) ??
          _firstValue(root, const ['remedies', 'remedy']),
      alert: true,
    ),
  ].where((section) => section.items.isNotEmpty).toList();

  return _DoshaSummary(
    icon: Icons.flare_rounded,
    iconColor: const Color(0xFFF97316),
    title: 'Pitra Dosha Assessment',
    subtitle: '9th House Lineage Indicators',
    status: detected == true ? 'Detected' : 'Clean Chart',
    alert: detected == true,
    description: description,
    sections: sections,
  );
}

_DoshaSummary _genericSummary(_DoshaTab tab, Map<String, dynamic> core) {
  return _DoshaSummary(
    icon: Icons.auto_awesome_rounded,
    iconColor: const Color(0xFF0EA5E9),
    title: tab.title,
    subtitle: 'Detailed Dosha Analysis',
    status: 'Available',
    alert: false,
    description: _firstText(core, const ['description', 'report', 'summary']) ??
        'Dosha details are available for this section.',
    sections: const [],
  );
}

Map<String, dynamic> _coreDoshaMap(String type, Map<String, dynamic> root) {
  final keys = switch (type) {
    'mangal' => {
        'mangal dosha',
        'mangal dosha report',
        'manglik',
        'manglik report',
      },
    'kaal' => {
        'kaal sarp dosha',
        'kaalsarp dosha',
        'kal sarp dosha',
        'kalsarpa dosha',
      },
    'sade' => {
        'sade sati',
        'sade sati report',
        'shani sade sati',
      },
    'pitra' => {
        'pitra dosha',
        'pitru dosha',
        'pitra dosha report',
      },
    _ => <String>{},
  };
  return _findMapByKeys(root, keys) ?? root;
}

Map<String, dynamic>? _findMapByKeys(
    dynamic value, Set<String> normalizedKeys) {
  final map = _asMap(value);
  if (map != null) {
    for (final entry in map.entries) {
      if (normalizedKeys.contains(_normalizeKey(entry.key))) {
        final found = _asMap(entry.value);
        if (found != null) return found;
      }
    }
    for (final entry in map.entries) {
      final found = _findMapByKeys(entry.value, normalizedKeys);
      if (found != null) return found;
    }
  }
  if (value is List) {
    for (final item in value) {
      final found = _findMapByKeys(item, normalizedKeys);
      if (found != null) return found;
    }
  }
  return null;
}

dynamic _firstValue(dynamic value, List<String> keys) {
  final wanted = keys.map(_normalizeKey).toSet();
  dynamic search(dynamic current) {
    final map = _asMap(current);
    if (map != null) {
      for (final entry in map.entries) {
        if (wanted.contains(_normalizeKey(entry.key)) &&
            _hasUsefulData(entry.value)) {
          return entry.value;
        }
      }
      for (final entry in map.entries) {
        final found = search(entry.value);
        if (_hasUsefulData(found)) return found;
      }
    }
    if (current is List) {
      for (final item in current) {
        final found = search(item);
        if (_hasUsefulData(found)) return found;
      }
    }
    return null;
  }

  return search(value);
}

String? _firstText(dynamic value, List<String> keys) {
  final found = _firstValue(value, keys);
  if (!_hasUsefulData(found)) return null;
  final text = _textFromValue(found);
  return text.isEmpty ? null : text;
}

String _textFromValue(dynamic value) {
  if (!_hasUsefulData(value)) return '';
  final map = _asMap(value);
  if (map != null) {
    const preferredKeys = [
      'description',
      'report',
      'summary',
      'prediction',
      'interpretation',
      'result',
      'details',
      'message',
    ];
    final wanted = preferredKeys.map(_normalizeKey).toSet();
    for (final entry in map.entries) {
      if (!wanted.contains(_normalizeKey(entry.key)) ||
          !_hasUsefulData(entry.value)) {
        continue;
      }
      final text = _textFromValue(entry.value);
      if (text.isNotEmpty) return text;
    }
    for (final entry in map.entries) {
      final key = _normalizeKey(entry.key);
      if (_skipKey(key) || key.endsWith('id') || key == 'house') continue;
      if (entry.value is Map || entry.value is List) continue;
      final text = _display(entry.value);
      if (text.isNotEmpty) return text;
    }
    return _stringListFromValue(map, limit: 3).join('\n');
  }
  if (value is List) {
    return value
        .map(_textFromValue)
        .where((text) => text.isNotEmpty)
        .take(3)
        .join('\n');
  }
  return _display(value);
}

bool? _boolish(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final text = _stripHtml(value.toString()).toLowerCase();
  if (text.isEmpty) return null;
  if (RegExp(r'\b(no|not|inactive|absent|false|clean|none|without)\b')
      .hasMatch(text)) {
    return false;
  }
  if (RegExp(r'\b(yes|present|active|true|detected|exists|exist)\b')
      .hasMatch(text)) {
    return true;
  }
  return null;
}

_DoshaSection _sectionFromValue(
  String title,
  dynamic value, {
  bool alert = false,
}) {
  return _DoshaSection(
    title: title,
    items: _stringListFromValue(value, limit: 4),
    alert: alert,
  );
}

List<String> _stringListFromValue(dynamic value, {int limit = 4}) {
  final items = <String>[];
  void add(dynamic current, [String? label]) {
    if (items.length >= limit || !_hasUsefulData(current)) return;
    final map = _asMap(current);
    if (map != null) {
      for (final entry in map.entries) {
        if (items.length >= limit) break;
        if (_skipKey(_normalizeKey(entry.key)) ||
            !_hasUsefulData(entry.value)) {
          continue;
        }
        final nested = _asMap(entry.value);
        if (nested != null || entry.value is List) {
          add(entry.value, _cleanLabel(entry.key));
        } else {
          items.add('${_cleanLabel(entry.key)}: ${_display(entry.value)}');
        }
      }
      return;
    }
    if (current is List) {
      for (final item in current) {
        if (items.length >= limit) break;
        add(item, label);
      }
      return;
    }
    final text = _display(current);
    if (text.isNotEmpty) items.add(label == null ? text : '$label: $text');
  }

  add(value);
  return items;
}

String _shortStatus(String value, {required String fallback}) {
  final cleaned = _stripHtml(value).replaceAll(RegExp(r'\s+'), ' ').trim();
  if (cleaned.isEmpty) return fallback;
  if (cleaned.length <= 20) return cleaned;
  return fallback;
}

bool _hasUsefulData(dynamic value) {
  if (value == null) return false;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isNotEmpty &&
        trimmed != '-' &&
        trimmed.toLowerCase() != 'null';
  }
  if (value is List) return value.any(_hasUsefulData);
  if (value is Map) return value.values.any(_hasUsefulData);
  return true;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _display(dynamic value) {
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is num) {
    if (value is int) return value.toString();
    return value.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');
  }
  final map = _asMap(value);
  if (map != null) return _stringListFromValue(map, limit: 4).join('\n');
  if (value is List) return _stringListFromValue(value, limit: 4).join('\n');
  return _stripHtml(_string(value));
}

String _stripHtml(String value) {
  return value
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _cleanLabel(Object key) {
  return key
      .toString()
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part.length <= 2
          ? part.toUpperCase()
          : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _normalizeKey(Object key) {
  return key.toString().toLowerCase().replaceAll(RegExp(r'[_-]+'), ' ').trim();
}

String _string(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

String _formatDate(DateTime? date) {
  if (date == null) return '';
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

String _formatTime(TimeOfDay? time) {
  if (time == null) return '';
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

TimeOfDay? _parseTime(String text) {
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

String _kolkataDateTime(DateTime date, TimeOfDay time) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  final h = time.hour.toString().padLeft(2, '0');
  final min = time.minute.toString().padLeft(2, '0');
  return '$y-$m-${d}T$h:$min:00+05:30';
}

LocationSelection? _locationFromProfile(Map<String, dynamic> profile) {
  final place = _string(profile['place_of_birth'] ?? profile['birth_place']);
  final coordinates = profile['coordinates'];
  double? lat;
  double? lng;
  if (coordinates is String && coordinates.contains(',')) {
    final parts = coordinates.split(',');
    lat = double.tryParse(parts.first.trim());
    lng = double.tryParse(parts.last.trim());
  } else if (coordinates is Map) {
    lat = _toDouble(coordinates['latitude'] ?? coordinates['lat']);
    lng = _toDouble(
        coordinates['longitude'] ?? coordinates['lng'] ?? coordinates['lon']);
  }
  lat ??= _toDouble(
      profile['latitude'] ?? profile['lat'] ?? profile['birth_latitude']);
  lng ??= _toDouble(
    profile['longitude'] ??
        profile['lng'] ??
        profile['lon'] ??
        profile['birth_longitude'],
  );
  if (place.isEmpty || lat == null || lng == null) return null;
  return LocationSelection(name: place, latitude: lat, longitude: lng);
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
