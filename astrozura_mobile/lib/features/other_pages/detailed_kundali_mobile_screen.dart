import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/contants/api_constants.dart';
import '../../core/services/api_client.dart';
import '../../core/services/astrology_service.dart';
import '../../core/services/recent_profile_service.dart';
import '../main_navigation.dart';
import '../mainwidgets/header.dart';
import '../shared/widgets/location_search_field.dart';

class DetailedKundaliMobileScreen extends StatefulWidget {
  const DetailedKundaliMobileScreen({super.key});

  @override
  State<DetailedKundaliMobileScreen> createState() =>
      _DetailedKundaliMobileScreenState();
}

class _DetailedKundaliMobileScreenState
    extends State<DetailedKundaliMobileScreen> {
  static const _navy = Color(0xFF1E3557);
  static const _gold = Color(0xFFD7AF4B);
  static const _cream = Color(0xFFFFF8E5);
  static const _border = Color(0xFFE6D7BA);
  static const _muted = Color(0xFF64748B);

  final _service = AstrologyService();
  final _recentProfiles = RecentProfileService();
  final _nameCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _placeCtrl = TextEditingController();

  DateTime? _date;
  TimeOfDay? _time;
  LocationSelection? _location;
  String _gender = 'Male';
  String _language = 'English';
  String _ayanamsa = 'Lahiri';
  String _chartStyle = 'North Indian';
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
    _nameCtrl.dispose();
    _dateCtrl.dispose();
    _timeCtrl.dispose();
    _placeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSavedBirthDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? prefs.getString('name') ?? '';
    final dob =
        prefs.getString('user_dob') ?? prefs.getString('date_of_birth') ?? '';
    final tob =
        prefs.getString('user_tob') ?? prefs.getString('time_of_birth') ?? '';
    final pob =
        prefs.getString('user_pob') ?? prefs.getString('place_of_birth') ?? '';
    final lat = prefs.getDouble('user_pob_lat');
    final lng = prefs.getDouble('user_pob_lng');

    if (!mounted) return;
    setState(() {
      if (name.trim().isNotEmpty) _nameCtrl.text = name.trim();
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
    final name = _string(profile['person_name'] ??
        profile['profile_label'] ??
        profile['name'] ??
        'Saved Profile');
    final dob = _string(profile['date_of_birth']);
    final tob = _string(profile['time_of_birth']);
    final pob = _string(profile['place_of_birth']);
    final gender = _string(profile['gender']);
    final location = _locationFromProfile(profile);

    setState(() {
      _nameCtrl.text = name;
      if (gender.isNotEmpty) _gender = _titleCase(gender);
      if (dob.isNotEmpty) {
        _date = DateTime.tryParse(dob);
        _dateCtrl.text = _formatDate(_date);
      }
      if (tob.isNotEmpty) {
        _time = _parseTime(tob);
        _timeCtrl.text = _formatTime(_time);
      }
      if (location != null) {
        _location = location;
        _placeCtrl.text = location.name;
      } else if (pob.isNotEmpty) {
        _placeCtrl.text = pob;
      }
    });
  }

  Future<void> _generate() async {
    final date = _date;
    final time = _time;
    final location = _location;
    if (date == null || time == null || location == null) {
      setState(() {
        _error = 'Date, time, and a selected birth place are required.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final requestPayload = <String, dynamic>{
      'datetime': _kolkataDateTime(date, time),
      'coordinates': location.coordinates,
      'ayanamsa': _ayanamsaCodes[_ayanamsa] ?? 1,
      'chart_style': _chartStyleCodes[_chartStyle] ?? 'north-indian',
      'la': _languageCodes[_language] ?? 'en',
    };

    try {
      final loads = await Future.wait<_LoadedSection>([
        _loadSection(
          'basic',
          () => _service.kundliDetailSection(
            'basic-astro-details',
            requestPayload,
          ),
        ),
        _loadSection(
          'vimshottari',
          () => _service.kundliDetailSection(
            'vimshottari-dasha',
            requestPayload,
          ),
        ),
        _loadSection(
          'biorhythm',
          () => _service.kundliDetailSection('biorhythm', requestPayload),
        ),
        _loadSection(
          'remedies',
          () => _service.kundliDetailSection(
            'suggestions-remedies',
            requestPayload,
          ),
        ),
        _loadSection(
          'dosha',
          () => _service.kundliDetailSection('dosha', requestPayload),
        ),
        _loadPredictions(requestPayload),
      ]);

      final bundle = _DetailedKundaliBundle.fromLoads(loads);
      await _saveRecentProfile(date, time, location);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => _DetailedKundaliResultScreen(
            input: _DetailedKundaliInput(
              name: _nameCtrl.text.trim().isEmpty
                  ? 'Detailed Kundali'
                  : _nameCtrl.text.trim(),
              date: date,
              time: time,
              place: location.name,
              coordinates: location.coordinates,
              language: _language,
              ayanamsa: _ayanamsa,
              chartStyle: _chartStyle,
            ),
            requestPayload: requestPayload,
            bundle: bundle,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _friendlyError(e);
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<_LoadedSection> _loadSection(
    String key,
    Future<Map<String, dynamic>> Function() loader,
  ) async {
    try {
      final response = await loader();
      return _LoadedSection(key, data: _responseData(response));
    } catch (e) {
      return _LoadedSection(key, error: _friendlyError(e));
    }
  }

  Future<_LoadedSection> _loadPredictions(Map<String, dynamic> payload) async {
    final predictions = <String, dynamic>{};
    final errors = <String, String>{};
    for (final area in _predictionTabs) {
      try {
        final response = await _service.predictions({
          ...payload,
          'type': area.id,
        });
        predictions[area.id] = _responseData(response);
      } catch (e) {
        errors[area.id] = _friendlyError(e);
      }
    }
    return _LoadedSection(
      'predictions',
      data: {'items': predictions, 'errors': errors},
    );
  }

  Future<void> _saveRecentProfile(
    DateTime date,
    TimeOfDay time,
    LocationSelection location,
  ) async {
    try {
      await _recentProfiles.store({
        'profile_label': _nameCtrl.text.trim().isEmpty
            ? 'Detailed Kundali Profile'
            : _nameCtrl.text.trim(),
        'person_name': _nameCtrl.text.trim().isEmpty
            ? 'Detailed Kundali Profile'
            : _nameCtrl.text.trim(),
        'gender': _gender.toLowerCase(),
        'date_of_birth': _apiDate(date),
        'time_of_birth': _apiTime(time),
        'place_of_birth': location.name,
        'coordinates': location.coordinates,
        'source_module': 'detailed-kundali',
        'relation_role': 'self',
        'metadata': {
          'language': _language,
          'ayanamsa': _ayanamsa,
          'chart_style': _chartStyle,
        },
      });
    } catch (_) {
      // Recent profiles are an authenticated convenience. Report generation
      // should remain available even when the user is not logged in.
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
                children: [
                  _backBar(),
                  const SizedBox(height: 10),
                  _formCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _backBar() {
    return Row(
      children: [
        IconButton(
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_circle_left_rounded, color: _navy),
        ),
        const Expanded(
          child: Text(
            'Detailed Kundali Analysis',
            style: TextStyle(
              color: _navy,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  void _goBack() {
    MainNavigationState.returnHome(context);
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'Birth Details',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showRecentProfiles,
                icon: const Icon(Icons.history, size: 17),
                label: const Text('Recent'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF8A5A00),
                  side: const BorderSide(color: _gold),
                  backgroundColor: _cream,
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _label('Profile Name'),
          _textField(
            _nameCtrl,
            hint: 'Example: Amit, Brother profile',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 8),
          _label('Gender'),
          _dropdown(
            _gender,
            const ['Male', 'Female', 'Other'],
            (next) => setState(() => _gender = next),
          ),
          const SizedBox(height: 8),
          _label('Date of Birth'),
          _readonlyField(
            controller: _dateCtrl,
            hint: 'Select date',
            icon: Icons.calendar_today_outlined,
            onTap: _pickDate,
          ),
          const SizedBox(height: 8),
          _label('Time of Birth'),
          _readonlyField(
            controller: _timeCtrl,
            hint: 'Select time',
            icon: Icons.access_time,
            onTap: _pickTime,
          ),
          const SizedBox(height: 8),
          _label('Birth Place'),
          LocationSearchField(
            controller: _placeCtrl,
            initialSelection: _location,
            onSelected: (selection) => setState(() => _location = selection),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Ayanamsa'),
                    _dropdown(
                      _ayanamsa,
                      _ayanamsaCodes.keys.toList(),
                      (next) => setState(() => _ayanamsa = next),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Language'),
                    _dropdown(
                      _language,
                      _languageCodes.keys.toList(),
                      (next) => setState(() => _language = next),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _label('Chart Style'),
          _dropdown(
            _chartStyle,
            _chartStyleCodes.keys.toList(),
            (next) => setState(() => _chartStyle = next),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            _InlineNotice(message: _error!, icon: Icons.error_outline),
          ],
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loading ? null : _generate,
            style: ElevatedButton.styleFrom(
              backgroundColor: _navy,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Generate Detailed Kundali',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF475569),
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller, {
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        prefixIcon: Icon(icon, size: 18),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 36, minHeight: 36),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _readonlyField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        prefixIcon: Icon(icon, size: 18),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 36, minHeight: 36),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _dropdown(
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD8E0EA)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      ),
    );
  }
}

class _DetailedKundaliResultScreen extends StatefulWidget {
  final _DetailedKundaliInput input;
  final Map<String, dynamic> requestPayload;
  final _DetailedKundaliBundle bundle;

  const _DetailedKundaliResultScreen({
    required this.input,
    required this.requestPayload,
    required this.bundle,
  });

  @override
  State<_DetailedKundaliResultScreen> createState() =>
      _DetailedKundaliResultScreenState();
}

class _DetailedKundaliResultScreenState
    extends State<_DetailedKundaliResultScreen> {
  static const _navy = Color(0xFF1E3557);
  static const _border = Color(0xFFE6D7BA);
  static const _muted = Color(0xFF64748B);

  final _service = AstrologyService();
  String _activeTab = 'birth';
  late final PageController _pageController;
  late final ScrollController _tabScrollController;
  String _chartType = _chartOptions.first.value;
  final Map<String, dynamic> _chartCache = {};
  late final List<GlobalKey> _tabKeys;
  bool _chartLoading = false;
  String? _chartError;

  static const _tabs = [
    _ResultTab('birth', 'Birth Details'),
    _ResultTab('astro', 'Astro Details'),
    _ResultTab('charts', 'Divisional Charts'),
    _ResultTab('predictions', 'Life Predictions'),
    _ResultTab('biorhythm', 'Biorhythm'),
    _ResultTab('dasha', 'Vimshottari Dasha'),
    _ResultTab('remedies', 'Gem & Rudraksha'),
    _ResultTab('mangal', 'Mangal Dosha'),
    _ResultTab('pitra', 'Pitra Dosha'),
    _ResultTab('kaal', 'Kaal Sarp Dosha'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabScrollController = ScrollController();
    _tabKeys = List.generate(_tabs.length, (_) => GlobalKey());
    Future.microtask(_ensureChartLoaded);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  Future<void> _ensureChartLoaded() async {
    if (_activeTab != 'charts' || _chartCache.containsKey(_chartType)) return;
    setState(() {
      _chartLoading = true;
      _chartError = null;
    });
    try {
      final response = await _service.divisionalCharts({
        ...widget.requestPayload,
        'chart_type': _chartType,
      });
      final data = _responseData(response);
      if (!mounted) return;
      setState(() {
        _chartCache[_chartType] = data;
        _chartLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chartError = _friendlyError(e);
        _chartLoading = false;
      });
    }
  }

  void _setActiveTab(String id) {
    final index = _tabs.indexWhere((tab) => tab.id == id);
    if (index >= 0 && _pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      _scrollActiveTabIntoView(index);
    }
    setState(() => _activeTab = id);
    if (id == 'charts') Future.microtask(_ensureChartLoaded);
  }

  void _onPageChanged(int index) {
    final tab = _tabs[index];
    setState(() => _activeTab = tab.id);
    _scrollActiveTabIntoView(index);
    if (tab.id == 'charts') Future.microtask(_ensureChartLoaded);
  }

  void _scrollActiveTabIntoView(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final tabContext = _tabKeys[index].currentContext;
      if (tabContext == null) return;
      Scrollable.ensureVisible(
        tabContext,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        alignment: 0.5,
      );
    });
  }

  void _safeBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F0),
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(),
            _resultHeader(),
            _tabBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _tabs.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) => ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
                  children: [_bodyForTab(_tabs[index].id)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resultHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 2, 14, 7),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _safeBack,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.arrow_circle_left_rounded, color: _navy),
          ),
          const SizedBox(width: 6),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${_formatDate(widget.input.date)} • ${_formatTime(widget.input.time)} • ${widget.input.place}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabBar() {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        controller: _tabScrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final tab = _tabs[index];
          final selected = tab.id == _activeTab;
          return KeyedSubtree(
            key: _tabKeys[index],
            child: ChoiceChip(
              visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelPadding: const EdgeInsets.symmetric(horizontal: 7),
              selected: selected,
              onSelected: (_) => _setActiveTab(tab.id),
              selectedColor: _navy,
              backgroundColor: Colors.white,
              side: BorderSide(color: selected ? _navy : _border),
              label: Text(
                tab.label,
                style: TextStyle(
                  color: selected ? Colors.white : _navy,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _bodyForTab(String tabId) {
    switch (tabId) {
      case 'birth':
        return _birthTab();
      case 'astro':
        return _astroTab();
      case 'charts':
        return _chartsTab();
      case 'predictions':
        return _predictionsTab();
      case 'biorhythm':
        return _biorhythmTab();
      case 'dasha':
        return _dashaTab();
      case 'remedies':
        return _remediesTab();
      case 'mangal':
        return _doshaTab(
          title: 'Mangal Dosha',
          itemKeys: const ['manglik', 'mangal_dosha', 'manglik_report'],
        );
      case 'pitra':
        return _doshaTab(
          title: 'Pitra Dosha',
          itemKeys: const ['pitra_dosha_report', 'pitra_dosha', 'pitra'],
        );
      case 'kaal':
        return _doshaTab(
          title: 'Kaal Sarp Dosha',
          itemKeys: const [
            'kalsarpa_details',
            'kaal_sarp_dosha',
            'kalsarpa_dosha',
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _birthTab() {
    final basic = widget.bundle.section('basic');
    final birth = _firstAvailableMap(basic, const [
      'birth_details',
      'birth_details_male',
      'basic_details',
    ]);
    final astro = _providerData(basic, 'astro_details');
    final rows = <_InfoRow>[
      _InfoRow('Name', widget.input.name),
      _InfoRow('Birth Place', widget.input.place),
      _InfoRow('Coordinates', widget.input.coordinates),
      ..._mapRows(
        birth,
        preferredKeys: const [
          'year',
          'month',
          'day',
          'hour',
          'minute',
          'latitude',
          'longitude',
          'timezone',
          'sunrise',
          'sunset',
          'ayanamsha',
        ],
      ),
      ..._mapRows(
        astro,
        preferredKeys: const [
          'ascendant',
          'ascendant_lord',
          'Varna',
          'Vashya',
          'Yoni',
          'Gan',
          'Nadi',
          'SignLord',
          'sign',
          'Naksahtra',
          'NaksahtraLord',
          'Charan',
          'Yog',
          'Karan',
          'Tithi',
          'yunja',
          'tatva',
          'name_alphabet',
          'paya',
        ],
      ),
    ];

    return _SectionPanel(
      title: 'Birth Details',
      child: _CompactInfoGrid(rows: _dedupeRows(rows)),
    );
  }

  Widget _astroTab() {
    final basic = widget.bundle.section('basic');
    final astro = _providerData(basic, 'astro_details');
    final planets = _planetRows(basic);
    final modules = [
      _ModuleSpec('bhav_madhya', 'Bhav Madhya'),
      _ModuleSpec('ayanamsha', 'Ayanamsha'),
      _ModuleSpec('ghat_chakra', 'Ghat Chakra'),
    ];

    return Column(
      children: [
        _SectionPanel(
          title: 'Astro Details',
          child: _CompactInfoGrid(rows: _mapRows(astro)),
        ),
        if (planets.isNotEmpty) ...[
          const SizedBox(height: 12),
          _SectionPanel(
            title: 'Planetary Positions',
            child: Column(
              children: planets
                  .map((planet) => _CompactPlanetCard(record: planet))
                  .toList(),
            ),
          ),
        ],
        for (final module in modules) ...[
          const SizedBox(height: 12),
          _astroModulePanel(
            keyName: module.key,
            title: module.label,
            data: _providerData(basic, module.key),
          ),
        ],
      ],
    );
  }

  Widget _chartsTab() {
    final selected = _chartOptions.firstWhere(
      (option) => option.value == _chartType,
      orElse: () => _chartOptions.first,
    );
    final chartData = _chartCache[_chartType];
    final chart = _firstChart(chartData);
    final svg = _chartSvg(chart);

    return _SectionPanel(
      title: 'Divisional Charts',
      subtitle: 'Choose a chart. Dense chart data stays full width on mobile.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _chartType,
                isExpanded: true,
                items: _chartOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option.value,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
                onChanged: (next) {
                  if (next == null) return;
                  setState(() {
                    _chartType = next;
                    _chartError = null;
                  });
                  _ensureChartLoaded();
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_chartLoading)
            const _LoadingCard(message: 'Loading chart...')
          else if (_chartError != null)
            _InlineNotice(message: _chartError!, icon: Icons.info_outline)
          else if (svg != null && svg.trim().isNotEmpty)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  Text(
                    selected.label,
                    style: const TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SvgPicture.string(svg),
                ],
              ),
            )
          else
            const _InlineNotice(
              message: 'This chart is not available for this profile.',
              icon: Icons.info_outline,
            ),
        ],
      ),
    );
  }

  Widget _predictionsTab() {
    final predictions =
        _asMap(widget.bundle.section('predictions')?['items']) ??
            <String, dynamic>{};
    final errors = _asMap(widget.bundle.section('predictions')?['errors']) ??
        <String, dynamic>{};
    return Column(
      children: [
        for (final area in _predictionTabs) ...[
          _PredictionCard(
            title: area.label,
            color: area.color,
            blocks: _predictionBlocks(predictions[area.id]),
            error: _string(errors[area.id]),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _biorhythmTab() {
    final data = widget.bundle.section('biorhythm');
    final biorhythm = _providerData(data, 'biorhythm');
    final moon = _providerData(data, 'moon_biorhythm');
    return Column(
      children: [
        _SectionPanel(
          title: 'Biorhythm',
          child: _BiorhythmScoreGrid(data: biorhythm),
        ),
        const SizedBox(height: 12),
        _SectionPanel(
          title: 'Moon Biorhythm',
          child: _MoonBiorhythmContent(data: moon),
        ),
      ],
    );
  }

  Widget _dashaTab() {
    final data = widget.bundle.section('vimshottari');
    final current = _providerData(data, 'current_vdasha_all') ??
        _providerData(data, 'current_vdasha');
    final major = _providerData(data, 'major_vdasha');

    return _VimshottariDashaPanel(current: current, major: major);
  }

  Widget _remediesTab() {
    final data = widget.bundle.section('remedies');
    final gems = _providerData(data, 'basic_gem_suggestion');
    final rudraksha = _providerData(data, 'rudraksha_suggestion');
    return Column(
      children: [
        _SectionPanel(
          title: 'Gemstone Suggestions',
          child: _GemstoneCards(data: gems),
        ),
        const SizedBox(height: 12),
        _SectionPanel(
          title: 'Rudraksha Suggestion',
          child: _RudrakshaCards(data: rudraksha),
        ),
      ],
    );
  }

  Widget _doshaTab({
    required String title,
    required List<String> itemKeys,
  }) {
    final data = widget.bundle.section('dosha');
    dynamic dosha;
    for (final key in itemKeys) {
      dosha = _providerData(data, key);
      if (_hasUsefulData(dosha)) break;
    }

    return _SectionPanel(
      title: title,
      child: _hasUsefulData(dosha)
          ? _renderDataCards(
              title,
              dosha,
              compactRows: true,
              forceWideRows: true,
            )
          : const _InlineNotice(
              message: 'This dosha report is not available.',
              icon: Icons.info_outline,
            ),
    );
  }

  Widget _modulePanel({required String title, required dynamic data}) {
    return _SectionPanel(
      title: title,
      child: _hasUsefulData(data)
          ? _renderData(title, data)
          : const _InlineNotice(
              message: 'This section is not available for this profile.',
              icon: Icons.info_outline,
            ),
    );
  }

  Widget _astroModulePanel({
    required String keyName,
    required String title,
    required dynamic data,
  }) {
    if (keyName == 'bhav_madhya') {
      return _BhavMadhyaPanel(data: data);
    }
    if (keyName == 'ayanamsha') {
      return _AyanamshaPanel(data: data);
    }
    if (keyName == 'ghat_chakra') {
      return _SectionPanel(
        title: title,
        child: _CompactInfoGrid(rows: _mapRows(data)),
      );
    }
    return _modulePanel(title: title, data: data);
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
  late Future<List<Map<String, dynamic>>> _profiles;

  @override
  void initState() {
    super.initState();
    _profiles = widget.service.list();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.38,
      maxChildSize: 0.9,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD8E0EA),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Row(
                  children: [
                    Icon(Icons.history, color: Color(0xFF1E3557)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Recent Profiles',
                        style: TextStyle(
                          color: Color(0xFF1E3557),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _profiles,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Login to reuse saved birth profiles.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    final profiles = snapshot.data ?? [];
                    if (profiles.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No recent profiles yet. Generate a report once and it will appear here.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 22),
                      itemCount: profiles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final profile = profiles[index];
                        final title = _string(profile['profile_label'] ??
                            profile['person_name'] ??
                            'Saved Profile');
                        final subtitle =
                            '${_string(profile['date_of_birth'])} • ${_string(profile['time_of_birth'])}\n${_string(profile['place_of_birth'])}';
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFE6D7BA)),
                          ),
                          tileColor: const Color(0xFFFFF8E5),
                          title: Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF1E3557),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          subtitle: Text(subtitle),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onSelected(profile);
                          },
                        );
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

class _DetailedKundaliInput {
  final String name;
  final DateTime date;
  final TimeOfDay time;
  final String place;
  final String coordinates;
  final String language;
  final String ayanamsa;
  final String chartStyle;

  const _DetailedKundaliInput({
    required this.name,
    required this.date,
    required this.time,
    required this.place,
    required this.coordinates,
    required this.language,
    required this.ayanamsa,
    required this.chartStyle,
  });
}

class _DetailedKundaliBundle {
  final Map<String, dynamic> sections;
  final Map<String, String> errors;

  const _DetailedKundaliBundle({
    required this.sections,
    required this.errors,
  });

  factory _DetailedKundaliBundle.fromLoads(List<_LoadedSection> loads) {
    return _DetailedKundaliBundle(
      sections: {
        for (final load in loads)
          if (load.data != null) load.key: load.data,
      },
      errors: {
        for (final load in loads)
          if (load.error != null) load.key: load.error!,
      },
    );
  }

  Map<String, dynamic>? section(String key) => _asMap(sections[key]);
}

class _LoadedSection {
  final String key;
  final dynamic data;
  final String? error;

  const _LoadedSection(this.key, {this.data, this.error});
}

class _ResultTab {
  final String id;
  final String label;

  const _ResultTab(this.id, this.label);
}

class _ModuleSpec {
  final String key;
  final String label;

  const _ModuleSpec(this.key, this.label);
}

class _ChartOption {
  final String value;
  final String label;

  const _ChartOption(this.value, this.label);
}

class _PredictionSpec {
  final String id;
  final String label;
  final Color color;

  const _PredictionSpec(this.id, this.label, this.color);
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);
}

class _CardRecord {
  final String label;
  final dynamic value;

  const _CardRecord(this.label, this.value);
}

const _chartOptions = [
  _ChartOption('chalit', 'Chalit Chart'),
  _ChartOption('gochar', 'Gochar / Transit Chart'),
  _ChartOption('sun', 'Sun Chart'),
  _ChartOption('moon', 'Moon Chart'),
  _ChartOption('rasi', 'D1 Birth Chart'),
  _ChartOption('hora', 'D2 Hora Chart'),
  _ChartOption('drekkana', 'D3 Drekkana Chart'),
  _ChartOption('chaturthamsa', 'D4 Chaturthamsha Chart'),
  _ChartOption('panchamsa', 'D5 Panchamsha Chart'),
  _ChartOption('saptamsa', 'D7 Saptamsha Chart'),
  _ChartOption('ashtamsa', 'D8 Ashtamsha Chart'),
  _ChartOption('navamsa', 'D9 Navamsha Chart'),
  _ChartOption('dasamsa', 'D10 Dashamsha Chart'),
  _ChartOption('dwadasamsa', 'D12 Dwadashamsha Chart'),
  _ChartOption('shodasamsa', 'D16 Shodashamsha Chart'),
  _ChartOption('vimsamsa', 'D20 Vishamansha Chart'),
  _ChartOption('chaturvimsamsa', 'D24 Chaturvimshamsha Chart'),
  _ChartOption('bhamsa', 'D27 Bhamsha Chart'),
  _ChartOption('trimsamsa', 'D30 Trishamansha Chart'),
  _ChartOption('khavedamsa', 'D40 Khavedamsha Chart'),
  _ChartOption('akshavedamsa', 'D45 Akshvedamsha Chart'),
  _ChartOption('shastiamsa', 'D60 Shashtyamsha Chart'),
];

const _predictionTabs = [
  _PredictionSpec('health', 'Health', Color(0xFFE8F7EE)),
  _PredictionSpec('emotions', 'Emotions', Color(0xFFFFEEF2)),
  _PredictionSpec('profession', 'Profession', Color(0xFFEAF2FF)),
  _PredictionSpec('luck', 'Luck', Color(0xFFFFF4D6)),
  _PredictionSpec('personal_life', 'Personal Life', Color(0xFFF3E8FF)),
  _PredictionSpec('travel', 'Travel', Color(0xFFE2FBF5)),
];

class _SectionPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionPanel({
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(13, 11, 13, 10),
            color: const Color(0xFFD7AF4B),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1E3557),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: Color(0xFF384B68),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _InfoList extends StatelessWidget {
  final List<_InfoRow> rows;

  const _InfoList({required this.rows});

  @override
  Widget build(BuildContext context) {
    final usefulRows = rows
        .where((row) => row.value.trim().isNotEmpty && row.value != '-')
        .toList();
    if (usefulRows.isEmpty) {
      return const _InlineNotice(
        message: 'This section is not available for this profile.',
        icon: Icons.info_outline,
      );
    }
    return Column(
      children: usefulRows
          .map(
            (row) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 9),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE6D7BA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.label.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xFF7A8AA3),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .8,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    row.value,
                    style: const TextStyle(
                      color: Color(0xFF102A52),
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoRow> rows;

  const _InfoGrid({required this.rows});

  @override
  Widget build(BuildContext context) {
    final usefulRows = rows
        .where((row) => row.value.trim().isNotEmpty && row.value != '-')
        .toList();
    if (usefulRows.isEmpty) {
      return const _InlineNotice(
        message: 'This section is not available for this profile.',
        icon: Icons.info_outline,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 8.0;
        final halfWidth = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: usefulRows.map((row) {
            final wide = row.label.toLowerCase().contains('coordinate') ||
                row.value.length > 42;
            return SizedBox(
              width: wide ? constraints.maxWidth : halfWidth,
              child: _InfoCell(row: row),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CompactInfoGrid extends StatelessWidget {
  final List<_InfoRow> rows;
  final bool forceWide;

  const _CompactInfoGrid({required this.rows, this.forceWide = false});

  @override
  Widget build(BuildContext context) {
    final usefulRows = rows
        .where((row) => row.value.trim().isNotEmpty && row.value != '-')
        .toList();
    if (usefulRows.isEmpty) {
      return const _InlineNotice(
        message: 'This section is not available for this profile.',
        icon: Icons.info_outline,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 7.0;
        final halfWidth = (constraints.maxWidth - gap) / 2;
        bool prefersWide(_InfoRow row) {
          final label = row.label.trim();
          final value = row.value.trim();
          final textSize = label.length + value.length;
          return forceWide ||
              label.toLowerCase().contains('coordinate') ||
              label.length > 10 ||
              value.length > 16 ||
              textSize > 24 ||
              value.contains('\n');
        }

        final children = <Widget>[];
        var index = 0;
        while (index < usefulRows.length) {
          final row = usefulRows[index];
          final rowWide = prefersWide(row);
          if (!rowWide &&
              index + 1 < usefulRows.length &&
              !prefersWide(usefulRows[index + 1])) {
            children.add(
              SizedBox(
                width: halfWidth,
                child: _CompactInfoCell(row: row, wide: false),
              ),
            );
            children.add(
              SizedBox(
                width: halfWidth,
                child: _CompactInfoCell(
                  row: usefulRows[index + 1],
                  wide: false,
                ),
              ),
            );
            index += 2;
            continue;
          }

          children.add(
            SizedBox(
              width: constraints.maxWidth,
              child: _CompactInfoCell(row: row, wide: true),
            ),
          );
          index += 1;
        }

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children,
        );
      },
    );
  }
}

class _CompactInfoCell extends StatelessWidget {
  final _InfoRow row;
  final bool wide;

  const _CompactInfoCell({required this.row, required this.wide});

  @override
  Widget build(BuildContext context) {
    final labelWidth = wide ? 150.0 : 82.0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Row(
        children: [
          SizedBox(width: labelWidth, child: _CompactLabel(row.label)),
          const SizedBox(width: 5),
          Expanded(
            child: _CompactValue(
              row.value,
              maxLines: 1,
              textAlign: TextAlign.right,
              shrinkToFit: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactLabel extends StatelessWidget {
  final String text;

  const _CompactLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF1E3557),
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: .25,
        height: 1.08,
      ),
    );
  }
}

class _CompactValue extends StatelessWidget {
  final String text;
  final int maxLines;
  final TextAlign textAlign;
  final bool shrinkToFit;

  const _CompactValue(
    this.text, {
    this.maxLines = 1,
    this.textAlign = TextAlign.left,
    this.shrinkToFit = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Text(
      text,
      textAlign: textAlign,
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
      style: const TextStyle(
        color: Color(0xFF102A52),
        fontSize: 13,
        height: 1.16,
        fontWeight: FontWeight.w400,
      ),
    );
    if (!shrinkToFit) return child;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: child,
    );
  }
}

class _InfoCell extends StatelessWidget {
  final _InfoRow row;

  const _InfoCell({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 76),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            row.label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF7A8AA3),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: .7,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            row.value,
            style: const TextStyle(
              color: Color(0xFF102A52),
              fontSize: 14,
              height: 1.3,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableRecordCard extends StatelessWidget {
  final Map<String, dynamic> record;

  const _ExpandableRecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final title =
        _string(record['name'] ?? record['planet'] ?? record['Planet']);
    final sign = _string(record['sign'] ?? record['Sign']);
    final degree = _string(
        record['normDegree'] ?? record['fullDegree'] ?? record['degree']);
    final rows = _mapRows(record);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        title: Text(
          title.isEmpty ? 'Planet' : title,
          style: const TextStyle(
            color: Color(0xFF1E3557),
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          [sign, degree.isEmpty ? null : 'Degree $degree']
              .whereType<String>()
              .join(' • '),
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
        ),
        children: [_InfoGrid(rows: rows)],
      ),
    );
  }
}

class _CompactPlanetCard extends StatelessWidget {
  final Map<String, dynamic> record;

  const _CompactPlanetCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final title =
        _string(record['name'] ?? record['planet'] ?? record['Planet']);
    final sign = _string(record['sign'] ?? record['Sign']);
    final degree = _string(
        record['normDegree'] ?? record['fullDegree'] ?? record['degree']);
    final summary = [sign, degree.isEmpty ? null : 'Degree $degree']
        .whereType<String>()
        .join(' • ');
    final rows = _mapRows(record)
        .where((row) => row.label.toLowerCase() != 'id')
        .toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        dense: true,
        visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
        title: Row(
          children: [
            Flexible(
              flex: 3,
              child: Text(
                title.isEmpty ? 'Planet' : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF1E3557),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (summary.isNotEmpty) ...[
              const SizedBox(width: 6),
              Expanded(
                flex: 7,
                child: Text(
                  summary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ],
        ),
        children: [
          _CompactInfoGrid(
            rows: rows
                .where((row) =>
                    row.label.toLowerCase() != 'name' &&
                    row.label.toLowerCase() != 'planet')
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _BhavMadhyaPanel extends StatelessWidget {
  final dynamic data;

  const _BhavMadhyaPanel({required this.data});

  @override
  Widget build(BuildContext context) {
    final cleaned = _cleanValue(data);
    if (!_hasUsefulData(cleaned)) {
      return const _SectionPanel(
        title: 'Bhav Madhya',
        child: _InlineNotice(
          message: 'This section is not available for this profile.',
          icon: Icons.info_outline,
        ),
      );
    }

    final summaryRows = _mapRows(cleaned).take(3).toList();
    final madhyaRows = _recordsFromKeys(cleaned, const [
      'bhav_madhya',
      'bhav_madhya_details',
      'madhya',
      'details',
    ]);
    final sandhiRows = _recordsFromKeys(cleaned, const [
      'bhav_sandhi',
      'bhav_sandhi_details',
      'sandhi',
    ]);

    return _SectionPanel(
      title: 'Bhav Madhya',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (summaryRows.isNotEmpty) ...[
            _CompactInfoGrid(rows: summaryRows, forceWide: true),
            const SizedBox(height: 8),
          ],
          if (madhyaRows.isNotEmpty)
            _CompactDataTable(
              title: 'Bhav Madhya',
              records: madhyaRows,
              columns: const [
                _CompactDataColumn('House', ['house', 'house_id'], width: 54),
                _CompactDataColumn('Sign', ['sign', 'sign_name'], width: 82),
                _CompactDataColumn('Degree', ['degree', 'full_degree'],
                    width: 86),
                _CompactDataColumn(
                  'Norm Degree',
                  ['norm_degree', 'normDegree'],
                  width: 90,
                ),
              ],
            ),
          if (sandhiRows.isNotEmpty) ...[
            const SizedBox(height: 8),
            _CompactDataTable(
              title: 'Bhav Sandhi',
              records: sandhiRows,
              columns: const [
                _CompactDataColumn('House', ['house', 'house_id'], width: 54),
                _CompactDataColumn('Sign', ['sign', 'sign_name'], width: 82),
                _CompactDataColumn('Degree', ['degree', 'full_degree'],
                    width: 86),
                _CompactDataColumn(
                  'Norm Degree',
                  ['norm_degree', 'normDegree'],
                  width: 90,
                ),
              ],
            ),
          ],
          if (summaryRows.isEmpty && madhyaRows.isEmpty && sandhiRows.isEmpty)
            _CompactInfoGrid(rows: _rowsFromAny(cleaned)),
        ],
      ),
    );
  }
}

class _AyanamshaPanel extends StatelessWidget {
  final dynamic data;

  const _AyanamshaPanel({required this.data});

  @override
  Widget build(BuildContext context) {
    final cleaned = _cleanValue(data);
    final records = _recordsFromAny(cleaned);
    final rows = records.isNotEmpty
        ? records
        : _mapRows(cleaned)
            .map((row) => {'type': row.label, 'degree': row.value})
            .toList();
    return _SectionPanel(
      title: 'Ayanamsha',
      child: rows.isEmpty
          ? const _InlineNotice(
              message: 'This section is not available for this profile.',
              icon: Icons.info_outline,
            )
          : _CompactDataTable(
              records: rows,
              columns: const [
                _CompactDataColumn('Type', ['type', 'name']),
                _CompactDataColumn('Degree', ['degree', 'value']),
                _CompactDataColumn(
                    'Formatted', ['formatted', 'formatted_degree']),
              ],
            ),
    );
  }
}

class _CompactDataColumn {
  final String label;
  final List<String> keys;
  final double width;

  const _CompactDataColumn(this.label, this.keys, {this.width = 104});
}

class _CompactDataTable extends StatelessWidget {
  final String? title;
  final List<Map<String, dynamic>> records;
  final List<_CompactDataColumn> columns;
  final bool showScrollHint;

  const _CompactDataTable({
    required this.records,
    required this.columns,
    this.title,
    this.showScrollHint = true,
  });

  @override
  Widget build(BuildContext context) {
    final usefulRecords = records.where(_hasUsefulData).toList();
    if (usefulRecords.isEmpty) {
      return const _InlineNotice(
        message: 'This section is not available for this profile.',
        icon: Icons.info_outline,
      );
    }
    final tableWidth =
        columns.fold<double>(0, (sum, column) => sum + column.width);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle(
              color: Color(0xFF1E3557),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
        ],
        if (showScrollHint) ...[
          const _CompactScrollHint(),
          const SizedBox(height: 5),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final effectiveWidth = tableWidth < constraints.maxWidth
                ? constraints.maxWidth
                : tableWidth;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: effectiveWidth,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE6D7BA)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Table(
                    columnWidths: {
                      for (var i = 0; i < columns.length; i++)
                        i: FixedColumnWidth(
                          effectiveWidth * (columns[i].width / tableWidth),
                        ),
                    },
                    border: TableBorder.symmetric(
                      inside: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    children: [
                      TableRow(
                        decoration:
                            const BoxDecoration(color: Color(0xFFD7AF4B)),
                        children: columns
                            .map((column) => _CompactTableHeader(column.label))
                            .toList(),
                      ),
                      ...usefulRecords.map(
                        (record) => TableRow(
                          decoration:
                              const BoxDecoration(color: Color(0xFFFFFCF2)),
                          children: columns
                              .map((column) => _CompactTableCell(
                                    _columnValue(record, column.keys),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _CompactTableHeader extends StatelessWidget {
  final String text;

  const _CompactTableHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF1E3557),
          fontSize: 10,
          height: 1.05,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CompactTableCell extends StatelessWidget {
  final String text;

  const _CompactTableCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      child: Text(
        text,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF102A52),
          fontSize: 10,
          height: 1.08,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}

class _CompactScrollHint extends StatelessWidget {
  const _CompactScrollHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E5),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swipe_left_alt_rounded,
              size: 14, color: Color(0xFF8A5A00)),
          SizedBox(width: 5),
          Text(
            'Scroll table left or right',
            style: TextStyle(
              color: Color(0xFF8A5A00),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlatDataCard extends StatelessWidget {
  final String title;
  final dynamic data;
  final bool compactRows;
  final bool forceWideRows;

  const _FlatDataCard({
    required this.title,
    required this.data,
    this.compactRows = false,
    this.forceWideRows = false,
  });

  @override
  Widget build(BuildContext context) {
    final rows = _mapRows(data);
    final records = _recordsFromAny(data);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1E3557),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (rows.isNotEmpty)
            compactRows
                ? _CompactRowsWithNarratives(
                    rows: rows,
                    forceWide: forceWideRows,
                  )
                : _InfoGrid(rows: rows)
          else if (records.isNotEmpty)
            Column(
              children: records
                  .map((record) => _FlatDataCard(
                        title: _string(record['name']).isEmpty
                            ? 'Details'
                            : _string(record['name']),
                        data: record,
                        compactRows: compactRows,
                        forceWideRows: forceWideRows,
                      ))
                  .toList(),
            )
          else
            _NarrativeText(text: _displayValue(data)),
        ],
      ),
    );
  }
}

class _CompactRowsWithNarratives extends StatelessWidget {
  final List<_InfoRow> rows;
  final bool forceWide;

  const _CompactRowsWithNarratives({
    required this.rows,
    this.forceWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final compactRows = <_InfoRow>[];
    final narrativeRows = <_InfoRow>[];
    for (final row in rows) {
      if (row.value.length > 90 || row.value.contains(RegExp(r'[.!?]\s'))) {
        narrativeRows.add(row);
      } else {
        compactRows.add(row);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compactRows.isNotEmpty)
          _CompactInfoGrid(rows: compactRows, forceWide: forceWide),
        ...narrativeRows.map(
          (row) => Padding(
            padding: EdgeInsets.only(top: compactRows.isEmpty ? 0 : 8),
            child: _NarrativeBlock(row: row),
          ),
        ),
      ],
    );
  }
}

class _NarrativeBlock extends StatelessWidget {
  final _InfoRow row;

  const _NarrativeBlock({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CompactLabel(row.label),
          const SizedBox(height: 4),
          _NarrativeText(text: row.value),
        ],
      ),
    );
  }
}

class _NarrativeText extends StatelessWidget {
  final String text;

  const _NarrativeText({required this.text});

  @override
  Widget build(BuildContext context) {
    final sections = _splitNarrativeSections(text);
    if (sections.length <= 1 &&
        (sections.isEmpty || sections.first.title == null)) {
      return Text(
        text,
        style: const TextStyle(color: Color(0xFF334155), height: 1.42),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (section.title != null) ...[
                Text(
                  section.title!,
                  style: const TextStyle(
                    color: Color(0xFF1E3557),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              if (section.body.isNotEmpty)
                Text(
                  section.body,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    height: 1.42,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _NarrativeSection {
  final String? title;
  final String body;

  const _NarrativeSection({this.title, required this.body});
}

class _RhythmCards extends StatelessWidget {
  final dynamic data;

  const _RhythmCards({required this.data});

  @override
  Widget build(BuildContext context) {
    final cleaned = _cleanValue(data);
    final cards = _cardRecords(cleaned);
    if (cards.isEmpty) {
      return const _InlineNotice(
        message: 'Biorhythm details are not available.',
        icon: Icons.info_outline,
      );
    }
    return Column(
      children: cards
          .map((card) => _FlatDataCard(
                title: card.label,
                data: card.value,
              ))
          .toList(),
    );
  }
}

class _BiorhythmScoreGrid extends StatelessWidget {
  final dynamic data;

  const _BiorhythmScoreGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    final root = _asMap(_cleanValue(data)) ?? <String, dynamic>{};
    final scores = [
      _BiorhythmMetric('Physical', _lookupValue(root, const ['physical'])),
      _BiorhythmMetric('Emotional', _lookupValue(root, const ['emotional'])),
      _BiorhythmMetric(
        'Intellectual',
        _lookupValue(root, const ['intellectual']),
      ),
      _BiorhythmMetric('Average', _lookupValue(root, const ['average'])),
    ].where((metric) => metric.hasPercent).toList();

    if (scores.isEmpty) {
      return const _InlineNotice(
        message: 'Biorhythm scores are not available for this profile.',
        icon: Icons.info_outline,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 8.0;
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: scores
              .map(
                (metric) => SizedBox(
                  width: width,
                  child: _BiorhythmScoreCard(metric: metric),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _BiorhythmScoreCard extends StatelessWidget {
  final _BiorhythmMetric metric;

  const _BiorhythmScoreCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    final value = metric.percent ?? 0;
    final color = _biorhythmColor(value);
    final fill = (value.abs().clamp(0, 100) / 100).toDouble();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            height: 54,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    value: fill,
                    strokeWidth: 7,
                    strokeCap: StrokeCap.round,
                    color: color,
                    backgroundColor: const Color(0xFFE8E0C9),
                  ),
                ),
                Text(
                  _displayValue(value),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
                Text(
                  metric.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1E3557),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Trend ${metric.trendText}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
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

class _MoonBiorhythmContent extends StatelessWidget {
  final dynamic data;

  const _MoonBiorhythmContent({required this.data});

  @override
  Widget build(BuildContext context) {
    final root = _asMap(_cleanValue(data)) ?? <String, dynamic>{};
    if (root.isEmpty) {
      return const _InlineNotice(
        message: 'Moon biorhythm details are not available for this profile.',
        icon: Icons.info_outline,
      );
    }

    final summary = _dedupeRows([
      _InfoRow(
          'Birth Pakshi',
          _displayValue(_lookupValue(root, const [
            'birth_pakshi',
            'birthPakshi',
            'pakshi',
          ]))),
      _InfoRow(
          'Bird ID',
          _displayValue(_lookupValue(root, const [
            'bird_id',
            'birdId',
          ]))),
      _InfoRow(
          'Considered Date',
          _displayValue(_lookupValue(root, const [
            'considered_date',
            'consideredDate',
            'date',
          ]))),
    ]).where((row) => row.value != '-').toList();

    final details = _asMap(_lookupValue(root, const [
          'birth_pakshi_details',
          'birthPakshiDetails',
          'pakshi_details',
          'pakshiDetails',
        ])) ??
        <String, dynamic>{};
    final listSections = [
      _MoonSimpleSection(
          'Name Letter',
          _lookupValue(root, const [
            'name_letter',
            'name_letters',
            'nameLetter',
          ])),
      _MoonSimpleSection(
          'Death Day',
          _lookupValue(root, const [
            'death_day',
            'death_days',
            'deathDay',
          ])),
      _MoonSimpleSection(
          'Day Ruling Days',
          _lookupValue(root, const [
            'day_ruling_days',
            'dayRulingDays',
          ])),
      _MoonSimpleSection(
          'Night Ruling Days',
          _lookupValue(root, const [
            'night_ruling_days',
            'nightRulingDays',
          ])),
      _MoonSimpleSection('Enemy', _lookupValue(root, const ['enemy'])),
      _MoonSimpleSection('Friend', _lookupValue(root, const ['friend'])),
    ].where((section) => _hasUsefulData(section.data)).toList();

    final activity = _lookupValue(root, const [
      'activity_cycle',
      'activityCycle',
      'activity',
    ]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary.isNotEmpty) ...[
          _CompactInfoGrid(rows: summary, forceWide: true),
          const SizedBox(height: 8),
        ],
        if (details.isNotEmpty) ...[
          _HighlightedMoonBlock(
            title: 'Birth Pakshi Details',
            child: _CompactInfoGrid(rows: _mapRows(details), forceWide: true),
          ),
          const SizedBox(height: 8),
        ],
        for (final section in listSections) ...[
          _SimpleMoonTable(section: section),
          const SizedBox(height: 8),
        ],
        ..._activityCycleTables(activity),
      ],
    );
  }
}

class _HighlightedMoonBlock extends StatelessWidget {
  final String title;
  final Widget child;

  const _HighlightedMoonBlock({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7AF4B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1E3557),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _SimpleMoonTable extends StatelessWidget {
  final _MoonSimpleSection section;

  const _SimpleMoonTable({required this.section});

  @override
  Widget build(BuildContext context) {
    final records = _simpleMoonRecords(section.data, section.title);
    return _CompactDataTable(
      title: section.title,
      records: records,
      columns: [
        const _CompactDataColumn('S.N.', ['sn'], width: 46),
        _CompactDataColumn(section.title, const ['value'], width: 176),
      ],
    );
  }
}

class _VimshottariDashaPanel extends StatefulWidget {
  final dynamic current;
  final dynamic major;

  const _VimshottariDashaPanel({
    required this.current,
    required this.major,
  });

  @override
  State<_VimshottariDashaPanel> createState() => _VimshottariDashaPanelState();
}

class _VimshottariDashaPanelState extends State<_VimshottariDashaPanel> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _DashaSwitch(
          selected: _selected,
          onChanged: (index) => setState(() => _selected = index),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: _selected == 0
              ? _CurrentDashaView(
                  key: const ValueKey('current-dasha'),
                  data: widget.current,
                  onJumpToMaha: () => setState(() => _selected = 1),
                )
              : _MahadashaView(
                  key: const ValueKey('maha-dasha'),
                  data: widget.major,
                ),
        ),
      ],
    );
  }
}

class _DashaSwitch extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;

  const _DashaSwitch({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Row(
        children: [
          _DashaSwitchButton(
            label: 'Current',
            selected: selected == 0,
            onTap: () => onChanged(0),
          ),
          const SizedBox(width: 5),
          _DashaSwitchButton(
            label: 'Mahadasha',
            selected: selected == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _DashaSwitchButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _DashaSwitchButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(11),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF1E3557) : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF1E3557),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrentDashaView extends StatelessWidget {
  final dynamic data;
  final VoidCallback onJumpToMaha;

  const _CurrentDashaView({
    super.key,
    required this.data,
    required this.onJumpToMaha,
  });

  @override
  Widget build(BuildContext context) {
    final entries = _currentDashaEntries(data);
    return _SectionPanel(
      title: 'Current Vimshottari Dasha',
      child: entries.isEmpty
          ? const _InlineNotice(
              message: 'Current dasha data is not available.',
              icon: Icons.info_outline,
            )
          : Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  _DashaLevelCard(entry: entries[i]),
                  if (i < entries.length - 1) const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: onJumpToMaha,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: const Text('Jump to Mahadasha'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1E3557),
                      textStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _DashaLevelCard extends StatelessWidget {
  final _DashaEntry entry;

  const _DashaLevelCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final rows = _dashaRows(entry.record);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFFFFF1BC),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Text(
              entry.label,
              style: const TextStyle(
                color: Color(0xFF1E3557),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: rows.isEmpty
                ? const _InlineNotice(
                    message: 'This dasha level is not available.',
                    icon: Icons.info_outline,
                  )
                : _CompactDataTable(
                    records: [entry.record],
                    showScrollHint: false,
                    columns: const [
                      _CompactDataColumn('Planet', ['planet', 'name', 'dasha'],
                          width: 76),
                      _CompactDataColumn(
                          'Start', ['start', 'start_date', 'startDate'],
                          width: 108),
                      _CompactDataColumn('End', ['end', 'end_date', 'endDate'],
                          width: 108),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _MahadashaView extends StatelessWidget {
  final dynamic data;

  const _MahadashaView({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final records = _mahadashaRecords(data);
    return _SectionPanel(
      title: 'Vimshottari Mahadasha',
      child: records.isEmpty
          ? const _InlineNotice(
              message: 'Major dasha periods are not available.',
              icon: Icons.info_outline,
            )
          : _CompactDataTable(
              records: records,
              showScrollHint: false,
              columns: const [
                _CompactDataColumn('Planet', ['planet', 'name', 'dasha_name'],
                    width: 98),
                _CompactDataColumn(
                    'Start', ['start', 'start_date', 'startDate'],
                    width: 116),
                _CompactDataColumn('End', ['end', 'end_date', 'endDate'],
                    width: 116),
              ],
            ),
    );
  }
}

class _DashaEntry {
  final String key;
  final String label;
  final Map<String, dynamic> record;

  const _DashaEntry({
    required this.key,
    required this.label,
    required this.record,
  });
}

class _GemstoneCards extends StatelessWidget {
  final dynamic data;

  const _GemstoneCards({required this.data});

  @override
  Widget build(BuildContext context) {
    final map = _asMap(_cleanValue(data));
    if (map == null || map.isEmpty) {
      return const _InlineNotice(
        message: 'Gemstone suggestions are not available.',
        icon: Icons.info_outline,
      );
    }
    final entries = map.entries
        .where((entry) => _asMap(entry.value) != null)
        .map((entry) => MapEntry(_cleanLabel(entry.key), _asMap(entry.value)!))
        .toList();
    if (entries.isEmpty) return _InfoGrid(rows: _mapRows(map));

    return SizedBox(
      height: 318,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.9),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF8E5), Color(0xFFFFFFFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE6D7BA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD7AF4B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.diamond_outlined,
                          color: Color(0xFF1E3557),
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${entry.key} Stone',
                          style: const TextStyle(
                            color: Color(0xFF1E3557),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Expanded(
                    child: _CompactInfoGrid(
                      rows: _mapRows(entry.value),
                      forceWide: true,
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

class _RudrakshaCards extends StatelessWidget {
  final dynamic data;

  const _RudrakshaCards({required this.data});

  @override
  Widget build(BuildContext context) {
    final cleaned = _cleanValue(_removeImageUrl(data));
    final originalCards = _cardRecords(data);
    final cards = _cardRecords(cleaned);
    if (cards.isEmpty) {
      return const _InlineNotice(
        message: 'Rudraksha suggestion is not available.',
        icon: Icons.info_outline,
      );
    }
    return Column(
      children: List.generate(cards.length, (index) {
        final card = cards[index];
        final source =
            index < originalCards.length ? originalCards[index].value : data;
        final image = _imageUrl(source) ?? _imageUrl(data);
        final heading = _rudrakshaHeading(card.value, card.label);
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6D7BA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (image != null) ...[
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: const Color(0xFFE6D7BA)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        image,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (heading.isNotEmpty)
                    Expanded(
                      child: Text(
                        heading,
                        style: const TextStyle(
                          color: Color(0xFF1E3557),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                ],
              ),
              const SizedBox(height: 9),
              _RudrakshaInfoGrid(rows: _rudrakshaRows(card.value)),
            ],
          ),
        );
      }),
    );
  }
}

class _RudrakshaInfoGrid extends StatelessWidget {
  final List<_InfoRow> rows;

  const _RudrakshaInfoGrid({required this.rows});

  @override
  Widget build(BuildContext context) {
    final stackedRows = <_InfoRow>[];
    final compactRows = <_InfoRow>[];
    for (final row in rows) {
      final key = _lookupKey(row.label);
      if (key == 'name' || key == 'recommend' || key == 'detail') {
        stackedRows.add(row);
      } else {
        compactRows.add(row);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (compactRows.isNotEmpty)
          _CompactInfoGrid(rows: compactRows, forceWide: true),
        ...List.generate(stackedRows.length, (index) {
          final hasContentAbove = compactRows.isNotEmpty || index > 0;
          return Padding(
            padding: EdgeInsets.only(top: hasContentAbove ? 8 : 0),
            child: _StackedInfoCell(row: stackedRows[index]),
          );
        }),
      ],
    );
  }
}

class _StackedInfoCell extends StatelessWidget {
  final _InfoRow row;

  const _StackedInfoCell({required this.row});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CompactLabel(row.label),
          const SizedBox(height: 4),
          Text(
            row.value,
            style: const TextStyle(
              color: Color(0xFF102A52),
              fontSize: 13,
              height: 1.28,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _HorizontalRecordTable extends StatelessWidget {
  final List<Map<String, dynamic>> records;

  const _HorizontalRecordTable({required this.records});

  @override
  Widget build(BuildContext context) {
    final columns = _columnsFor(records);
    if (records.isEmpty || columns.isEmpty) {
      return const _InlineNotice(
        message: 'This table is not available for this profile.',
        icon: Icons.info_outline,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E5),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE6D7BA)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.swipe_left_alt, size: 16, color: Color(0xFF8A5A00)),
              SizedBox(width: 6),
              Text(
                'Scroll table left or right',
                style: TextStyle(
                  color: Color(0xFF8A5A00),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 18,
            horizontalMargin: 12,
            headingRowColor: WidgetStateProperty.all(const Color(0xFFD7AF4B)),
            headingTextStyle: const TextStyle(
              color: Color(0xFF1E3557),
              fontWeight: FontWeight.w900,
            ),
            dataRowMinHeight: 48,
            dataRowMaxHeight: 78,
            columns: columns
                .map((key) => DataColumn(label: Text(_cleanLabel(key))))
                .toList(),
            rows: records
                .map(
                  (record) => DataRow(
                    cells: columns
                        .map(
                          (key) => DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 132),
                              child: Text(
                                _displayValue(record[key]),
                                softWrap: true,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _PredictionCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<_InfoRow> blocks;
  final String error;

  const _PredictionCard({
    required this.title,
    required this.color,
    required this.blocks,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1E3557),
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (blocks.isNotEmpty)
            ...blocks.map(
              (block) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (block.label.toLowerCase() != title.toLowerCase())
                      Text(
                        block.label,
                        style: const TextStyle(
                          color: Color(0xFF102A52),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    Text(
                      block.value,
                      style: const TextStyle(
                        color: Color(0xFF334155),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Text(
              error.isNotEmpty
                  ? error
                  : 'Prediction is not available for this area.',
              style: const TextStyle(color: Color(0xFF64748B), height: 1.4),
            ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final String message;

  const _LoadingCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Row(
        children: [
          const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final String message;
  final IconData icon;

  const _InlineNotice({
    required this.message,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD7AF4B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF475569), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _renderData(String title, dynamic value) {
  final cleaned = _cleanValue(value);
  if (!_hasUsefulData(cleaned)) {
    return const _InlineNotice(
      message: 'This section is not available for this profile.',
      icon: Icons.info_outline,
    );
  }

  if (cleaned is List) {
    final records = _recordsFromAny(cleaned);
    if (records.isNotEmpty) return _HorizontalRecordTable(records: records);
    return _InfoList(
      rows: cleaned
          .map((item) => _InfoRow(title, _displayValue(item)))
          .where((row) => row.value.isNotEmpty)
          .toList(),
    );
  }

  if (cleaned is Map<String, dynamic>) {
    final records = _recordsFromAny(cleaned);
    if (records.length > 1) return _HorizontalRecordTable(records: records);
    final rows = _mapRows(cleaned);
    final nested = <Widget>[];
    cleaned.forEach((key, nestedValue) {
      final next = _cleanValue(nestedValue);
      if (next is Map || next is List) {
        nested.add(
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _FlatDataCard(title: _cleanLabel(key), data: next),
          ),
        );
      }
    });
    return Column(
      children: [
        if (rows.isNotEmpty) _InfoGrid(rows: rows),
        ...nested,
      ],
    );
  }

  return _InfoGrid(rows: [_InfoRow(title, _displayValue(cleaned))]);
}

Widget _renderDataCards(
  String title,
  dynamic value, {
  bool compactRows = false,
  bool forceWideRows = false,
}) {
  final cleaned = _cleanValue(value);
  if (!_hasUsefulData(cleaned)) {
    return const _InlineNotice(
      message: 'This section is not available for this profile.',
      icon: Icons.info_outline,
    );
  }
  final cards = _cardRecords(cleaned);
  if (cards.isEmpty) {
    final rows = [_InfoRow(title, _displayValue(cleaned))];
    return compactRows
        ? _CompactRowsWithNarratives(
            rows: rows,
            forceWide: forceWideRows,
          )
        : _InfoGrid(rows: rows);
  }
  return Column(
    children: cards
        .map((card) => _FlatDataCard(
              title: card.label,
              data: card.value,
              compactRows: compactRows,
              forceWideRows: forceWideRows,
            ))
        .toList(),
  );
}

dynamic _responseData(Map<String, dynamic> response) {
  return response.containsKey('data') ? response['data'] : response;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<dynamic> _asList(dynamic value) {
  if (value is List) return value;
  return const [];
}

dynamic _providerData(dynamic source, String key) {
  final root = _asMap(source);
  if (root == null) return null;

  final payload = _asMap(root['provider_payload']);
  if (payload != null && payload.containsKey(key)) {
    return _entryData(payload[key]);
  }

  final items = _asMap(root['items']);
  if (items != null && items.containsKey(key)) {
    return _entryData(items[key]);
  }

  final sections = _asList(root['provider_sections']);
  for (final section in sections) {
    final sectionItems = _asMap(_asMap(section)?['items']);
    if (sectionItems != null && sectionItems.containsKey(key)) {
      return _entryData(sectionItems[key]);
    }
  }

  if (root.containsKey(key)) return _entryData(root[key]);
  return null;
}

dynamic _entryData(dynamic value) {
  final map = _asMap(value);
  if (map != null && map.containsKey('data')) return map['data'];
  return value;
}

dynamic _lookupValue(dynamic source, List<String> keys) {
  final map = _asMap(source);
  if (map == null) return null;

  for (final key in keys) {
    if (map.containsKey(key)) return map[key];
  }

  final wanted = keys.map(_lookupKey).toSet();
  for (final entry in map.entries) {
    if (wanted.contains(_lookupKey(entry.key))) return entry.value;
  }
  return null;
}

String _lookupKey(dynamic value) {
  return value.toString().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

class _BiorhythmMetric {
  final String label;
  final dynamic data;

  const _BiorhythmMetric(this.label, this.data);

  double? get percent {
    final map = _asMap(_cleanValue(data));
    return _numberValue(map?['percent'] ?? map?['percentage'] ?? data);
  }

  bool get hasPercent => percent != null;

  String get trendText {
    final map = _asMap(_cleanValue(data));
    final trend = _displayValue(map?['trend']);
    if (trend == '1') return 'Up';
    if (trend == '0') return 'Neutral';
    if (trend == '-1') return 'Down';
    return trend == '-' ? 'Neutral' : trend;
  }
}

double? _numberValue(dynamic value) {
  if (value is num) return value.toDouble();
  final text = _string(value);
  if (text.isEmpty) return null;
  final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(text);
  return match == null ? null : double.tryParse(match.group(0)!);
}

Color _biorhythmColor(double value) {
  if (value >= 75) return const Color(0xFF16A34A);
  if (value >= 40) return const Color(0xFFD7AF4B);
  return const Color(0xFFDC2626);
}

class _MoonSimpleSection {
  final String title;
  final dynamic data;

  const _MoonSimpleSection(this.title, this.data);
}

List<Map<String, dynamic>> _simpleMoonRecords(dynamic source, String title) {
  final cleaned = _cleanValue(source);
  final records = _recordsFromAny(cleaned);
  if (records.isNotEmpty) {
    return List.generate(records.length, (index) {
      final record = Map<String, dynamic>.from(records[index]);
      record.putIfAbsent('sn', () => index + 1);
      return record;
    });
  }

  final list = _asList(cleaned);
  if (list.isNotEmpty) {
    return List.generate(
      list.length,
      (index) => {'sn': index + 1, 'value': _displayValue(list[index])},
    );
  }

  final map = _asMap(cleaned);
  if (map != null && map.isNotEmpty) {
    var index = 0;
    return map.entries
        .where((entry) => _hasUsefulData(entry.value))
        .map((entry) => {
              'sn': ++index,
              'value': _displayValue(entry.value),
            })
        .toList();
  }

  if (_hasUsefulData(cleaned)) {
    return [
      {'sn': 1, 'value': _displayValue(cleaned)}
    ];
  }
  return const [];
}

List<Widget> _activityCycleTables(dynamic source) {
  final cleaned = _cleanValue(source);
  final map = _asMap(cleaned);
  final tables = <Widget>[];

  if (map != null) {
    final day = _activityRows(_lookupValue(map, const ['day']));
    final night = _activityRows(_lookupValue(map, const ['night']));
    if (day.isNotEmpty) {
      tables.add(_activityCycleTable('Activity Cycle - Day', day));
    }
    if (night.isNotEmpty) {
      if (tables.isNotEmpty) tables.add(const SizedBox(height: 8));
      tables.add(_activityCycleTable('Activity Cycle - Night', night));
    }
    if (tables.isNotEmpty) return tables;
  }

  final rows = _activityRows(cleaned);
  if (rows.isNotEmpty) {
    tables.add(_activityCycleTable('Activity Cycle', rows));
  }
  return tables;
}

List<Map<String, dynamic>> _activityRows(dynamic source) {
  final records = _recordsFromAny(source);
  if (records.isNotEmpty) {
    return List.generate(records.length, (index) {
      final record = Map<String, dynamic>.from(records[index]);
      record.putIfAbsent('sn', () => index + 1);
      return record;
    });
  }

  final list = _asList(_cleanValue(source));
  if (list.isEmpty) return const [];
  return List.generate(list.length, (index) {
    final map = _asMap(list[index]);
    if (map != null) {
      final record = Map<String, dynamic>.from(map);
      record.putIfAbsent('sn', () => index + 1);
      return record;
    }
    return {'sn': index + 1, 'activity': _displayValue(list[index])};
  });
}

Widget _activityCycleTable(String title, List<Map<String, dynamic>> rows) {
  return _CompactDataTable(
    title: title,
    records: rows,
    columns: const [
      _CompactDataColumn('S.N.', ['sn'], width: 44),
      _CompactDataColumn('Start Time', ['start_time', 'startTime'], width: 72),
      _CompactDataColumn('End Time', ['end_time', 'endTime'], width: 72),
      _CompactDataColumn('Start Hours', ['start_hours', 'startHours'],
          width: 72),
      _CompactDataColumn('End Hours', ['end_hours', 'endHours'], width: 68),
      _CompactDataColumn('Activity ID', ['activity_id', 'activityId'],
          width: 62),
      _CompactDataColumn('Activity', ['activity'], width: 70),
      _CompactDataColumn(
        'Activity Meaning',
        ['activity_meaning', 'activityMeaning', 'meaning'],
        width: 122,
      ),
    ],
  );
}

List<_DashaEntry> _currentDashaEntries(dynamic source) {
  final cleaned = _cleanValue(source);
  final specs = const [
    _DashaSpec(
      key: 'major',
      label: 'Mahadasha',
      aliases: ['major', 'mahadasha', 'maha_dasha', 'major_dasha'],
    ),
    _DashaSpec(
      key: 'minor',
      label: 'Antardasha / Bhukti',
      aliases: ['minor', 'antardasha', 'antar_dasha', 'bhukti', 'minor_dasha'],
    ),
    _DashaSpec(
      key: 'sub_minor',
      label: 'Pratyantar Dasha',
      aliases: [
        'sub_minor',
        'sub minor',
        'pratyantar',
        'pratyantar_dasha',
        'sub_minor_dasha'
      ],
    ),
    _DashaSpec(
      key: 'sub_sub_minor',
      label: 'Sookshma Dasha',
      aliases: [
        'sub_sub_minor',
        'sub sub minor',
        'sub_sub_sub',
        'sub sub sub',
        'sookshma',
        'sookshma_dasha',
        'sookshma dasha',
        'sookshmadasha',
        'sub_sub_minor_dasha'
      ],
    ),
    _DashaSpec(
      key: 'sub_sub_sub_minor',
      label: 'Prana Dasha',
      aliases: [
        'sub_sub_sub_minor',
        'sub sub sub minor',
        'sub_sub_sub_sub',
        'sub sub sub sub',
        'pran',
        'pran_dasha',
        'pran dasha',
        'prandasha',
        'prana',
        'prana_dasha',
        'prana dasha',
        'pranadasha',
        'sub_sub_sub_minor_dasha'
      ],
    ),
  ];

  final entries = <_DashaEntry>[];
  for (final spec in specs) {
    final data = _findDashaLevel(cleaned, spec.aliases);
    final record = _dashaRecord(data);
    if (record.isEmpty) continue;
    entries.add(_DashaEntry(key: spec.key, label: spec.label, record: record));
  }

  if (entries.isNotEmpty) return entries;

  final records = _recordsFromAny(cleaned);
  for (final spec in specs) {
    for (final record in records) {
      final name = _lookupKey(
        _columnValue(record, const ['level', 'name', 'dasha', 'type']),
      );
      if (spec.aliases.map(_lookupKey).contains(name)) {
        final cleanRecord = _stripDashaIds(record);
        if (cleanRecord.isNotEmpty) {
          entries.add(
            _DashaEntry(
              key: spec.key,
              label: spec.label,
              record: cleanRecord,
            ),
          );
        }
        break;
      }
    }
  }
  return entries;
}

dynamic _findDashaLevel(dynamic source, List<String> aliases) {
  final cleaned = _cleanValue(source);
  final map = _asMap(cleaned);
  if (map == null) return null;

  final direct = _lookupValue(map, aliases);
  if (_hasUsefulData(direct)) return direct;

  for (final key in const ['current', 'details', 'items', 'data']) {
    final nested = _lookupValue(map, [key]);
    final found = _findDashaLevel(nested, aliases);
    if (_hasUsefulData(found)) return found;
  }

  final wanted = aliases.map(_lookupKey).toSet();
  for (final entry in map.entries) {
    if (wanted.contains(_lookupKey(entry.key))) return entry.value;
  }
  return null;
}

Map<String, dynamic> _dashaRecord(dynamic source) {
  final cleaned = _cleanValue(source);
  final map = _asMap(cleaned);
  if (map != null) {
    final nested = _lookupValue(map, const [
      'dasha_period',
      'dashaPeriod',
      'period',
      'details',
    ]);
    final nestedMap = _asMap(_cleanValue(nested));
    if (nestedMap != null) return _stripDashaIds(nestedMap);
    return _stripDashaIds(map);
  }

  final records = _recordsFromAny(cleaned);
  if (records.isNotEmpty) return _stripDashaIds(records.first);

  if (cleaned is String) return _stripDashaIds(_parseDashaText(cleaned));
  return const {};
}

List<_InfoRow> _dashaRows(Map<String, dynamic> record) {
  return [
    _InfoRow('Planet', _columnValue(record, const ['planet', 'name', 'dasha'])),
    _InfoRow(
      'Start',
      _columnValue(record, const ['start', 'start_date', 'startDate']),
    ),
    _InfoRow('End', _columnValue(record, const ['end', 'end_date', 'endDate'])),
  ].where((row) => row.value != '-' && row.value.trim().isNotEmpty).toList();
}

List<Map<String, dynamic>> _mahadashaRecords(dynamic source) {
  final cleaned = _cleanValue(source);
  final direct = _recordsFromAny(cleaned);
  if (_looksLikeDashaRecords(direct)) {
    return direct.map(_stripDashaIds).where(_hasUsefulData).toList();
  }

  final map = _asMap(cleaned);
  if (map != null) {
    for (final key in const [
      'dasha_period',
      'dashaPeriod',
      'periods',
      'items',
      'data',
      'major',
    ]) {
      final records = _recordsFromAny(_lookupValue(map, [key]));
      if (records.isNotEmpty) {
        return records.map(_stripDashaIds).where(_hasUsefulData).toList();
      }
    }
  }

  if (cleaned is String) {
    return _parseDashaPeriodList(cleaned).map(_stripDashaIds).toList();
  }
  return const [];
}

bool _looksLikeDashaRecords(List<Map<String, dynamic>> records) {
  if (records.isEmpty) return false;
  return records.any((record) =>
      _columnValue(record, const ['planet', 'name', 'dasha_name']) != '-' ||
      _columnValue(record, const ['start', 'start_date', 'startDate']) != '-' ||
      _columnValue(record, const ['end', 'end_date', 'endDate']) != '-');
}

Map<String, dynamic> _stripDashaIds(Map<String, dynamic> record) {
  final cleaned = <String, dynamic>{};
  record.forEach((key, value) {
    final normalized = _lookupKey(key);
    if (normalized == 'planetid' ||
        normalized == 'planetsid' ||
        normalized == 'planetids') {
      return;
    }
    if (!_hasUsefulData(value)) return;
    cleaned[key] = value;
  });
  return cleaned;
}

Map<String, dynamic> _parseDashaText(String text) {
  final record = <String, dynamic>{};
  for (final part in text.split('|')) {
    final index = part.indexOf(':');
    if (index <= 0) continue;
    final key = part.substring(0, index).trim();
    final value = part.substring(index + 1).trim();
    if (key.isEmpty || value.isEmpty) continue;
    record[_dashaKey(key)] = value;
  }
  return record;
}

List<Map<String, dynamic>> _parseDashaPeriodList(String text) {
  final records = <Map<String, dynamic>>[];
  final chunks = text.split(RegExp(r',\s*(?=Planet\s*:)'));
  for (final chunk in chunks) {
    final record = _parseDashaText(chunk);
    if (record.isNotEmpty) records.add(record);
  }
  return records;
}

String _dashaKey(String key) {
  final normalized = _lookupKey(key);
  if (normalized == 'planetid') return 'planet_id';
  if (normalized == 'startdate') return 'start_date';
  if (normalized == 'enddate') return 'end_date';
  return key.toLowerCase().replaceAll(RegExp(r'\s+'), '_');
}

class _DashaSpec {
  final String key;
  final String label;
  final List<String> aliases;

  const _DashaSpec({
    required this.key,
    required this.label,
    required this.aliases,
  });
}

Map<String, dynamic> _firstAvailableMap(
  dynamic source,
  List<String> keys,
) {
  for (final key in keys) {
    final data = _providerData(source, key);
    final map = _asMap(data);
    if (map != null && map.isNotEmpty) return map;
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _planetRows(dynamic source) {
  final direct = _providerData(source, 'planets');
  final records = _recordsFromAny(direct);
  if (records.isNotEmpty) return records;

  final root = _asMap(source);
  final possible = [
    root?['planets'],
    root?['planet_details'],
    root?['planetary_positions'],
  ];
  for (final item in possible) {
    final next = _recordsFromAny(item);
    if (next.isNotEmpty) return next;
  }
  return const [];
}

List<_InfoRow> _mapRows(
  dynamic value, {
  List<String> preferredKeys = const [],
}) {
  final map = _asMap(value);
  if (map == null) return const [];
  final rows = <_InfoRow>[];
  final handled = <String>{};

  for (final key in preferredKeys) {
    if (!map.containsKey(key)) continue;
    final next = _cleanValue(map[key]);
    if (next is Map || next is List || !_hasUsefulData(next)) continue;
    rows.add(_InfoRow(_cleanLabel(key), _displayValue(next)));
    handled.add(key);
  }

  map.forEach((key, rawValue) {
    if (handled.contains(key) || _skipKey(key)) return;
    final next = _cleanValue(rawValue);
    if (next is Map || next is List || !_hasUsefulData(next)) return;
    rows.add(_InfoRow(_cleanLabel(key), _displayValue(next)));
  });

  return rows;
}

List<_InfoRow> _rowsFromAny(dynamic value) {
  final cleaned = _cleanValue(value);
  if (cleaned is Map<String, dynamic>) return _mapRows(cleaned);
  if (cleaned is List && cleaned.isNotEmpty) {
    final first = cleaned.first;
    if (first is Map) return _mapRows(first);
  }
  return const [];
}

List<Map<String, dynamic>> _recordsFromAny(dynamic value) {
  final cleaned = _cleanValue(value);
  if (cleaned is List) {
    return cleaned
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  if (cleaned is Map<String, dynamic>) {
    final records = <Map<String, dynamic>>[];
    cleaned.forEach((key, item) {
      final next = _cleanValue(item);
      if (next is Map<String, dynamic>) {
        final record = {'name': _cleanLabel(key), ...next};
        records.add(record);
      }
    });
    return records;
  }
  return const [];
}

List<Map<String, dynamic>> _recordsFromKeys(
  dynamic value,
  List<String> keys,
) {
  final cleaned = _cleanValue(value);
  final root = _asMap(cleaned);
  if (root == null) return _recordsFromAny(cleaned);

  for (final key in keys) {
    final direct = root[key];
    final records = _recordsFromAny(direct);
    if (records.isNotEmpty) return records;

    final directMap = _asMap(direct);
    if (directMap != null) {
      for (final nestedKey in const ['details', 'items', 'data']) {
        final nested = _recordsFromAny(directMap[nestedKey]);
        if (nested.isNotEmpty) return nested;
      }
    }
  }
  return const [];
}

List<_CardRecord> _cardRecords(dynamic value) {
  final cleaned = _cleanValue(value);
  if (cleaned is List) {
    final cards = <_CardRecord>[];
    for (var index = 0; index < cleaned.length; index++) {
      final item = cleaned[index];
      if (!_hasUsefulData(item)) continue;
      final map = _asMap(item);
      final label = _string(
        map?['name'] ??
            map?['title'] ??
            map?['planet'] ??
            map?['dasha'] ??
            'Item ${index + 1}',
      );
      cards.add(_CardRecord(label.isEmpty ? 'Item ${index + 1}' : label, item));
    }
    return cards;
  }
  if (cleaned is Map<String, dynamic>) {
    final scalarRows = _mapRows(cleaned);
    final cards = <_CardRecord>[];
    if (scalarRows.isNotEmpty) cards.add(_CardRecord('Summary', cleaned));
    cleaned.forEach((key, item) {
      final next = _cleanValue(item);
      if (next is Map || next is List) {
        cards.add(_CardRecord(_cleanLabel(key), next));
      }
    });
    if (cards.isEmpty && scalarRows.isNotEmpty) {
      cards.add(_CardRecord('Details', cleaned));
    }
    return cards;
  }
  if (_hasUsefulData(cleaned)) return [_CardRecord('Details', cleaned)];
  return const [];
}

List<_NarrativeSection> _splitNarrativeSections(String value) {
  var text = value.replaceAll(RegExp(r'\s+\|\s+'), '\n').trim();
  text = text.replaceAllMapped(
    RegExp(r'\s+(Based\s+ON\s+House\s*:)', caseSensitive: false),
    (match) => '\n${match.group(1)}',
  );
  text = text.replaceAllMapped(
    RegExp(r'\s+(Based\s+ON\s+Aspect\s*:)', caseSensitive: false),
    (match) => '\n${match.group(1)}',
  );
  if (text.isEmpty) return const [];

  final sections = <_NarrativeSection>[];
  for (final part in text.split(RegExp(r'\n+'))) {
    final clean = part.trim();
    if (clean.isEmpty) continue;
    final match = RegExp(
      r'^(Based\s+ON\s+(?:Aspect|House))\s*:\s*(.*)$',
      caseSensitive: false,
    ).firstMatch(clean);
    if (match != null) {
      sections.add(
        _NarrativeSection(
          title: _titleCase(match.group(1)!.replaceAll(RegExp(r'\s+'), ' ')),
          body: match.group(2)?.trim() ?? '',
        ),
      );
    } else {
      sections.add(_NarrativeSection(body: clean));
    }
  }
  return sections;
}

String _rudrakshaHeading(dynamic value, String fallback) {
  final map = _asMap(value);
  final preferred = _string(
    map?['name'] ??
        map?['rudraksha_name'] ??
        map?['rudraksha'] ??
        map?['rudraksha_key'] ??
        map?['rudrakshaKey'],
  );
  if (preferred.isNotEmpty) return _cleanLabel(preferred);
  final normalized = fallback.trim().toLowerCase();
  if (normalized == 'summary' || normalized == 'details') return '';
  return fallback;
}

List<_InfoRow> _rudrakshaRows(dynamic value) {
  return _mapRows(value).where((row) {
    final key = _lookupKey(row.label);
    return key != 'rudrakshakey' &&
        key != 'imgurl' &&
        key != 'imageurl' &&
        key != 'image' &&
        key != 'img';
  }).toList();
}

dynamic _cleanValue(dynamic value) {
  if (value is Map) {
    final result = <String, dynamic>{};
    value.forEach((key, item) {
      final keyText = key.toString();
      if (_skipKey(keyText)) return;
      final cleaned = _cleanValue(item);
      if (_hasUsefulData(cleaned)) result[keyText] = cleaned;
    });
    if (result.length == 1 && result.containsKey('value')) {
      return result['value'];
    }
    return result;
  }
  if (value is List) {
    return value.map(_cleanValue).where(_hasUsefulData).toList();
  }
  return value;
}

bool _skipKey(String key) {
  final normalized = key.toLowerCase();
  return normalized == 'status' ||
      normalized == 'success' ||
      normalized == 'endpoint' ||
      normalized == 'provider_payload' ||
      normalized == 'provider_sections' ||
      normalized == 'raw' ||
      normalized == 'url' ||
      normalized == 'image' ||
      normalized == 'img' ||
      normalized == 'img_url' ||
      normalized == 'imgurl' ||
      normalized == 'image_url' ||
      normalized == 'imageurl' ||
      normalized == 'img_url' ||
      normalized == 'rudraksha_image' ||
      normalized == 'rudrakshaimage' ||
      normalized == 'rudraksh_image' ||
      normalized == 'chart_svg';
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

String _displayValue(dynamic value) {
  if (value == null) return '-';
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is num) {
    if (value is int) return value.toString();
    return value.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');
  }
  if (value is List) {
    return value.map(_displayValue).where((item) => item != '-').join(', ');
  }
  if (value is Map) {
    return value.entries
        .where((entry) => !_skipKey(entry.key.toString()))
        .map((entry) =>
            '${_cleanLabel(entry.key)}: ${_displayValue(entry.value)}')
        .join('\n');
  }
  final text = value.toString().trim();
  if (text.startsWith('http://') || text.startsWith('https://')) return '-';
  if (text.startsWith('/') ||
      text.startsWith('uploads/') ||
      text.startsWith('storage/')) {
    return '-';
  }
  final stripped = _stripHtml(text);
  if (stripped.isEmpty) return '-';
  if (stripped.contains('_') ||
      RegExp(r'^[A-Z][A-Z_ ]{3,}$').hasMatch(stripped)) {
    return _humanizeApiValue(stripped);
  }
  return stripped;
}

String _stripHtml(String value) {
  return value
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .trim();
}

String _humanizeApiValue(String value) {
  return value
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) {
    if (part.length <= 2) return part.toUpperCase();
    final lower = part.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }).join(' ');
}

String _cleanLabel(dynamic value) {
  final text = value.toString().trim();
  if (text.isEmpty) return '';
  return text
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part.length <= 2
          ? part.toUpperCase()
          : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _string(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

String _titleCase(String value) {
  final clean = value.trim().toLowerCase();
  if (clean.isEmpty) return value;
  return '${clean[0].toUpperCase()}${clean.substring(1)}';
}

String _friendlyError(Object error) {
  if (error is ApiException) return error.message;
  return error.toString().replaceFirst('Exception: ', '');
}

List<String> _columnsFor(List<Map<String, dynamic>> records) {
  final columns = <String>[];
  for (final record in records) {
    for (final key in record.keys) {
      if (_skipKey(key) || columns.contains(key)) continue;
      final value = _cleanValue(record[key]);
      if (value is Map || value is List || !_hasUsefulData(value)) continue;
      columns.add(key);
    }
  }
  return columns.take(10).toList();
}

List<_InfoRow> _dedupeRows(List<_InfoRow> rows) {
  final seen = <String>{};
  final unique = <_InfoRow>[];
  for (final row in rows) {
    final key = row.label.toLowerCase();
    if (seen.contains(key)) continue;
    seen.add(key);
    unique.add(row);
  }
  return unique;
}

String _columnValue(Map<String, dynamic> record, List<String> keys) {
  for (final key in keys) {
    if (!record.containsKey(key)) continue;
    final value = _cleanValue(record[key]);
    if (_hasUsefulData(value)) return _displayValue(value);
  }
  for (final entry in record.entries) {
    final normalized = entry.key.toLowerCase().replaceAll('_', '');
    for (final key in keys) {
      final wanted = key.toLowerCase().replaceAll('_', '');
      if (normalized == wanted && _hasUsefulData(entry.value)) {
        return _displayValue(entry.value);
      }
    }
  }
  return '-';
}

List<_InfoRow> _predictionBlocks(dynamic payload) {
  final blocks = <_InfoRow>[];
  if (payload is List) {
    for (final item in payload) {
      final map = _asMap(item);
      if (map != null) {
        final title = _string(map['title'] ?? map['name'] ?? 'Prediction');
        final body = _string(map['description'] ?? map['body'] ?? map['value']);
        if (body.isNotEmpty) blocks.add(_InfoRow(title, body));
      } else if (_string(item).isNotEmpty) {
        blocks.add(_InfoRow('Prediction', _string(item)));
      }
    }
    return blocks;
  }
  final map = _asMap(payload);
  if (map != null) {
    final prediction = _asMap(map['prediction']);
    if (prediction != null) {
      prediction.forEach((key, value) {
        if (_hasUsefulData(value)) {
          blocks.add(_InfoRow(_cleanLabel(key), _displayValue(value)));
        }
      });
    }
    for (final row in _mapRows(map)) {
      if (row.label.toLowerCase() != 'prediction') blocks.add(row);
    }
  }
  return blocks;
}

Map<String, dynamic>? _firstChart(dynamic chartData) {
  final map = _asMap(chartData);
  if (map == null) return null;
  final charts = _asList(map['charts']);
  if (charts.isNotEmpty) return _asMap(charts.first);
  return map;
}

String? _chartSvg(Map<String, dynamic>? chart) {
  if (chart == null) return null;
  final candidates = [
    chart['chart_svg'],
    chart['svg'],
    _asMap(chart['chart'])?['svg'],
    _asMap(chart['data'])?['chart_svg'],
  ];
  for (final value in candidates) {
    final text = _string(value);
    if (text.contains('<svg')) return text;
  }
  return null;
}

String? _imageUrl(dynamic value) {
  if (value is String) {
    final text = value.trim();
    if (text.startsWith('data:image/')) return text;
    if (text.startsWith('//')) return ApiConstants.storageUrl(text);
    if (text.startsWith('http://') || text.startsWith('https://')) return text;
    if (text.startsWith('/')) return ApiConstants.storageUrl(text);
    if (text.startsWith('uploads/') || text.startsWith('storage/')) {
      return ApiConstants.storageUrl(text);
    }
    if (RegExp(r'\.(png|jpe?g|webp|gif)$', caseSensitive: false)
        .hasMatch(text)) {
      return ApiConstants.storageUrl(text);
    }
  }
  if (value is List) {
    for (final item in value) {
      final found = _imageUrl(item);
      if (found != null) return found;
    }
    return null;
  }
  final map = _asMap(value);
  if (map == null) return null;
  final candidates = [
    map['img_url'],
    map['imgUrl'],
    map['imgurl'],
    map['img'],
    map['image'],
    map['image_url'],
    map['imageUrl'],
    map['rudraksha_image'],
    map['rudrakshaImage'],
    map['rudraksh_image'],
    map['photo'],
    map['src'],
    map['img'],
  ];
  for (final candidate in candidates) {
    final text = _string(candidate);
    if (text.startsWith('data:image/')) return text;
    if (text.startsWith('//')) return ApiConstants.storageUrl(text);
    if (text.startsWith('http://') || text.startsWith('https://')) {
      return text;
    }
    if (text.startsWith('/')) return ApiConstants.storageUrl(text);
    if (text.startsWith('uploads/') || text.startsWith('storage/')) {
      return ApiConstants.storageUrl(text);
    }
    if (RegExp(r'\.(png|jpe?g|webp|gif)$', caseSensitive: false)
        .hasMatch(text)) {
      return ApiConstants.storageUrl(text);
    }
  }
  for (final item in map.values) {
    if (item is Map || item is List || item is String) {
      final found = _imageUrl(item);
      if (found != null) return found;
    }
  }
  return null;
}

dynamic _removeImageUrl(dynamic value) {
  if (value is List) return value.map(_removeImageUrl).toList();
  final map = _asMap(value);
  if (map == null) return value;
  final clone = <String, dynamic>{};
  map.forEach((key, item) {
    final normalized = key.toString().toLowerCase();
    if (normalized.contains('image') ||
        normalized == 'url' ||
        normalized == 'img' ||
        normalized == 'img_url' ||
        normalized == 'imgurl') {
      return;
    }
    clone[key.toString()] = item is Map ? _removeImageUrl(item) : item;
  });
  return clone;
}

LocationSelection? _locationFromProfile(Map<String, dynamic> profile) {
  final place = _string(profile['place_of_birth']);
  final coordinates = profile['coordinates'];
  double? lat;
  double? lng;
  if (coordinates is String && coordinates.contains(',')) {
    final parts = coordinates.split(',');
    lat = double.tryParse(parts.first.trim());
    lng = double.tryParse(parts.last.trim());
  } else if (coordinates is Map) {
    lat = _toDouble(coordinates['latitude'] ?? coordinates['lat']);
    lng = _toDouble(coordinates['longitude'] ?? coordinates['lng']);
  }
  lat ??= _toDouble(profile['latitude'] ?? profile['lat']);
  lng ??= _toDouble(profile['longitude'] ?? profile['lng']);
  if (place.isEmpty || lat == null || lng == null) return null;
  return LocationSelection(name: place, latitude: lat, longitude: lng);
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

String _formatDate(DateTime? date) {
  if (date == null) return '';
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

String _apiDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

String _formatTime(TimeOfDay? time) {
  if (time == null) return '';
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

String _apiTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
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
  return TimeOfDay(
    hour: hour.clamp(0, 23).toInt(),
    minute: minute.clamp(0, 59).toInt(),
  );
}

String _kolkataDateTime(DateTime date, TimeOfDay time) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  final h = time.hour.toString().padLeft(2, '0');
  final min = time.minute.toString().padLeft(2, '0');
  return '$y-$m-${d}T$h:$min:00+05:30';
}
