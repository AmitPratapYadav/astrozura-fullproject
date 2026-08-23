import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/services/astrology_service.dart';
import '../../core/services/recent_profile_service.dart';
import '../main_navigation.dart';
import '../mainwidgets/header.dart';
import '../shared/widgets/location_search_field.dart';

class LiveMatchmakingReportScreen extends StatefulWidget {
  const LiveMatchmakingReportScreen({super.key});

  @override
  State<LiveMatchmakingReportScreen> createState() =>
      _LiveMatchmakingReportScreenState();
}

class _LiveMatchmakingReportScreenState
    extends State<LiveMatchmakingReportScreen> {
  static const _navy = Color(0xFF1E3557);

  final AstrologyService _service = AstrologyService();
  final RecentProfileService _recentProfiles = RecentProfileService();
  final _male = _PersonBirthForm(role: 'male');
  final _female = _PersonBirthForm(role: 'female');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _male.dispose();
    _female.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    final maleLocation = await _resolvedLocation(_male);
    final femaleLocation = await _resolvedLocation(_female);
    if (!_male.hasDateTime ||
        !_female.hasDateTime ||
        maleLocation == null ||
        femaleLocation == null) {
      setState(() {
        _error =
            'Complete both male and female birth dates, birth times, and birthplaces.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    _male.location = maleLocation;
    _female.location = femaleLocation;

    try {
      final response = await _service.matchMaking({
        'boy_dob': _iso(_male.date!, _male.time!),
        'boy_coordinates': maleLocation.coordinates,
        'girl_dob': _iso(_female.date!, _female.time!),
        'girl_coordinates': femaleLocation.coordinates,
        'boy_timezone': '+05:30',
        'girl_timezone': '+05:30',
        'la': 'en',
      });
      if (!mounted) return;
      setState(() => _loading = false);
      if (response['status'] == 'success') {
        await Future.wait([
          _saveRecentProfile(_male, maleLocation),
          _saveRecentProfile(_female, femaleLocation),
        ]);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _MatchmakingResultScreen(
              male: _MatchPerson.fromForm(_male, maleLocation),
              female: _MatchPerson.fromForm(_female, femaleLocation),
              response: response,
            ),
          ),
        );
      } else {
        setState(() {
          _error =
              response['message']?.toString() ?? 'Unable to generate report.';
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<LocationSelection?> _resolvedLocation(_PersonBirthForm form) async {
    if (form.location != null) return form.location;
    final text = form.place.text.trim();
    if (text.isEmpty) return null;
    final matches = await _service.searchLocations(text);
    if (matches.isEmpty) return null;
    return LocationSelection.fromApi(matches.first);
  }

  Future<void> _saveRecentProfile(
    _PersonBirthForm form,
    LocationSelection location,
  ) async {
    try {
      await _recentProfiles.store({
        'profile_label':
            form.name.text.trim().isEmpty ? form.defaultName : form.name.text,
        'person_name':
            form.name.text.trim().isEmpty ? form.defaultName : form.name.text,
        'gender': form.role,
        'date_of_birth': _apiDate(form.date!),
        'time_of_birth': _apiTime(form.time!),
        'place_of_birth': location.name,
        'coordinates': location.coordinates,
        'source_module': 'detailed-matchmaking',
        'relation_role': form.role,
      });
    } catch (_) {
      // Recent profile save is an authenticated convenience only.
    }
  }

  Future<void> _showRecentProfiles(_PersonBirthForm form) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RecentProfilesSheet(
        service: _recentProfiles,
        title: 'Choose ${form.defaultName}',
        onSelected: (profile) {
          setState(() => form.applyProfile(profile));
        },
      ),
    );
  }

  static String _iso(DateTime date, TimeOfDay time) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}T'
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:00+05:30';
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
                          'Detailed Matchmaking Report',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: _navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _PersonCard(
                    title: 'Male Birth Details',
                    icon: Icons.male_rounded,
                    form: _male,
                    onChanged: () => setState(() {}),
                    onChooseRecent: () => _showRecentProfiles(_male),
                  ),
                  const SizedBox(height: 14),
                  _PersonCard(
                    title: 'Female Birth Details',
                    icon: Icons.female_rounded,
                    form: _female,
                    onChanged: () => setState(() {}),
                    onChooseRecent: () => _showRecentProfiles(_female),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _run,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Generate Match Report',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                    ),
                  ),
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchmakingResultScreen extends StatefulWidget {
  final _MatchPerson male;
  final _MatchPerson female;
  final Map<String, dynamic> response;

  const _MatchmakingResultScreen({
    required this.male,
    required this.female,
    required this.response,
  });

  @override
  State<_MatchmakingResultScreen> createState() =>
      _MatchmakingResultScreenState();
}

class _MatchmakingResultScreenState extends State<_MatchmakingResultScreen> {
  static const _navy = Color(0xFF1E3557);
  static const _border = Color(0xFFE8D7A7);

  final _pageController = PageController();
  final _tabController = ScrollController();
  final _service = AstrologyService();
  int _index = 0;
  String _chartType = _chartOptions.first.value;
  bool _chartLoading = false;
  String? _chartError;
  final Map<String, _ChartPair> _chartCache = {};

  List<_MatchTab> get _tabs => [
        ..._sectionTabs(widget.response),
        _MatchTab(
          id: 'match-summary-conclusion',
          title: 'Match Conclusion',
          summary: '',
          data: widget.response,
        ),
        _MatchTab(
          id: 'match-divisional-charts',
          title: 'Match Divisional Charts',
          summary: 'Compare Male and Female Kundali charts side by side.',
          data: const {},
          isCharts: true,
        ),
      ];

  @override
  void initState() {
    super.initState();
    Future.microtask(_ensureChartsLoaded);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _ensureChartsLoaded() async {
    if (_index != _tabs.length - 1 || _chartCache.containsKey(_chartType)) {
      return;
    }
    setState(() {
      _chartLoading = true;
      _chartError = null;
    });
    try {
      final results = await Future.wait([
        _service.divisionalCharts(widget.male.chartPayload(_chartType)),
        _service.divisionalCharts(widget.female.chartPayload(_chartType)),
      ]);
      if (!mounted) return;
      setState(() {
        _chartCache[_chartType] = _ChartPair(results[0], results[1]);
        _chartLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _chartLoading = false;
        _chartError = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _setTab(int index) {
    setState(() => _index = index);
    _scrollTab(index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
    if (index == _tabs.length - 1) Future.microtask(_ensureChartsLoaded);
  }

  void _scrollTab(int index) {
    if (!_tabController.hasClients) return;
    final target = (index * 112.0).clamp(
      0.0,
      _tabController.position.maxScrollExtent,
    );
    _tabController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E5),
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                    child: _ResultHeader(
                      male: widget.male,
                      female: widget.female,
                    ),
                  ),
                  SizedBox(
                    height: 52,
                    child: ListView.separated(
                      controller: _tabController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: tabs.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final selected = _index == index;
                        return ChoiceChip(
                          selected: selected,
                          showCheckmark: false,
                          label: Text(tabs[index].label),
                          selectedColor: _navy,
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : _navy,
                            fontWeight: FontWeight.w900,
                          ),
                          side: BorderSide(color: selected ? _navy : _border),
                          onSelected: (_) => _setTab(index),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: tabs.length,
                      onPageChanged: (next) {
                        setState(() => _index = next);
                        _scrollTab(next);
                        if (next == tabs.length - 1) {
                          Future.microtask(_ensureChartsLoaded);
                        }
                      },
                      itemBuilder: (context, index) {
                        final tab = tabs[index];
                        return ListView(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                          children: [_tabContent(tab)],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabContent(_MatchTab tab) {
    if (tab.isCharts) return _chartsTab();
    final key = '${tab.id} ${tab.title}'.toLowerCase();
    if (tab.id == 'match-summary-conclusion') {
      return _MatchConclusionTab(response: widget.response);
    }
    if (_containsAny(key, ['birth'])) {
      return _comparisonTab(
        rows: _birthRows(tab.data, widget.male, widget.female),
      );
    }
    if (_containsAny(key, ['astro'])) {
      return _comparisonTab(
        rows: _pairedRows(tab.data, const [
          'varna',
          'vashya',
          'yoni',
          'gan',
          'nadi',
          'sign_lord',
          'nakshatra',
          'nak_lord',
          'nakshatra_lord',
          'charan',
          'yog',
          'karan',
          'tithi',
          'yunja',
          'tatva',
          'name_alphabet',
          'paya',
          'sign',
        ]),
      );
    }
    if (_containsAny(key, ['ashtakoot', 'ashtakoota'])) {
      return _scoreTab('Ashtakoota', tab.data);
    }
    if (_containsAny(key, ['dashakoot', 'dashakoota'])) {
      return _scoreTab('Dashakoota', tab.data);
    }
    if (_containsAny(key, ['manglik', 'mangal'])) {
      return _manglikTab(tab.data);
    }
    if (_containsAny(key, ['obstruction'])) {
      return _conclusionTab(tab.data);
    }
    if (_containsAny(key, ['planet'])) {
      return _planetTab(tab.data);
    }
    return _cleanDetailsTab(tab.title, tab.data);
  }

  Widget _chartsTab() {
    final pair = _chartCache[_chartType];
    return _SectionPanel(
      title: 'Match Divisional Charts',
      subtitle: '',
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
                  _ensureChartsLoaded();
                },
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_chartLoading)
            const _InlineNotice('Loading charts...')
          else if (_chartError != null)
            _InlineNotice(_chartError!)
          else if (pair == null)
            const _InlineNotice('Select a chart to load match charts.')
          else ...[
            _ChartPanel(title: 'Male Chart', response: pair.male),
            const SizedBox(height: 12),
            _ChartPanel(title: 'Female Chart', response: pair.female),
          ],
        ],
      ),
    );
  }
}

class _PersonBirthForm {
  final String role;
  final name = TextEditingController();
  final place = TextEditingController();
  DateTime? date;
  TimeOfDay? time;
  LocationSelection? location;

  _PersonBirthForm({required this.role});

  String get defaultName => role == 'male' ? 'Male Profile' : 'Female Profile';
  bool get hasDateTime => date != null && time != null;

  void applyProfile(Map<String, dynamic> profile) {
    name.text = _string(
      profile['person_name'] ?? profile['profile_label'] ?? defaultName,
    );
    date = _parseDate(_string(profile['date_of_birth']));
    time = _parseTime(_string(profile['time_of_birth']));
    final selected = _locationFromProfile(profile);
    if (selected != null) {
      location = selected;
      place.text = selected.name;
    }
  }

  void dispose() {
    name.dispose();
    place.dispose();
  }
}

class _PersonCard extends StatelessWidget {
  static const _navy = Color(0xFF1E3557);
  static const _gold = Color(0xFFD7AF4B);
  static const _border = Color(0xFFE8D7A7);

  final String title;
  final IconData icon;
  final _PersonBirthForm form;
  final VoidCallback onChanged;
  final VoidCallback onChooseRecent;

  const _PersonCard({
    required this.title,
    required this.icon,
    required this.form,
    required this.onChanged,
    required this.onChooseRecent,
  });

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: form.date ?? DateTime(1995),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      form.date = date;
      onChanged();
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: form.time ?? const TimeOfDay(hour: 12, minute: 0),
    );
    if (time != null) {
      form.time = time;
      onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                foregroundColor: _navy,
                child: Icon(icon),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: onChooseRecent,
              icon: const Icon(Icons.history),
              label: const Text(
                'Choose a recent profile',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF8A6500),
                backgroundColor: const Color(0xFFFFF3D0),
                side: const BorderSide(color: _gold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: form.name,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              labelText: 'Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(context),
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    form.date == null ? 'Birth date' : _formatDate(form.date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickTime(context),
                  icon: const Icon(Icons.schedule),
                  label: Text(
                    form.time == null ? 'Birth time' : _formatTime(form.time),
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LocationSearchField(
            controller: form.place,
            onSelected: (selection) {
              form.location = selection;
              onChanged();
            },
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 11,
              ),
              labelText: 'Birthplace',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultHeader extends StatelessWidget {
  final _MatchPerson male;
  final _MatchPerson female;

  const _ResultHeader({required this.male, required this.female});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 34,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 34, height: 42),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_circle_left_rounded, size: 22),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ProfileCard(person: male, icon: Icons.male),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _ProfileCard(person: female, icon: Icons.female),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final _MatchPerson person;
  final IconData icon;

  const _ProfileCard({required this.person, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D7A7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFFFFF3D0),
                foregroundColor: const Color(0xFF1E3557),
                child: Icon(icon, size: 16),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  person.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1E3557),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatDate(person.date)} - ${_formatTime(person.time)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5),
          ),
          const SizedBox(height: 2),
          Text(
            person.place,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionPanel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8D7A7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFD7AF4B),
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
                if (subtitle.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontWeight: FontWeight.w600,
                    ),
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

class _ValueCard extends StatelessWidget {
  final String label;
  final String value;

  const _ValueCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9DFCB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1E3557),
              fontWeight: FontWeight.w400,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollHint extends StatelessWidget {
  const _ScrollHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3D0),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8D7A7)),
      ),
      child: const Text(
        'Scroll table left or right',
        style: TextStyle(color: Color(0xFF8A6500), fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  final String title;
  final Map<String, dynamic> response;

  const _ChartPanel({required this.title, required this.response});

  @override
  Widget build(BuildContext context) {
    final chart = _firstChart(_extractData(response));
    final svg = _chartSvg(chart);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8D7A7)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF1E3557),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (svg != null)
            SizedBox(
              width: double.infinity,
              height: 300,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: SvgPicture.string(svg, fit: BoxFit.contain),
                ),
              ),
            )
          else
            const _InlineNotice('Chart image is not available right now.'),
        ],
      ),
    );
  }
}

class _MatchCompareRow {
  final String label;
  final String male;
  final String female;

  const _MatchCompareRow(this.label, this.male, this.female);
}

class _ScoreRow {
  final String label;
  final String total;
  final String matched;
  final bool? passed;
  final bool isTotal;

  const _ScoreRow({
    required this.label,
    required this.total,
    required this.matched,
    this.passed,
    this.isTotal = false,
  });
}

class _OverallRow {
  final String label;
  final String value;
  final bool? passed;

  const _OverallRow(this.label, this.value, this.passed);
}

class _ScoreSummary {
  final double score;
  final double maxScore;

  const _ScoreSummary(this.score, this.maxScore);
}

class _MatchConclusionSummary {
  final double score;
  final double maxScore;
  final bool recommended;
  final bool manglikBlocks;
  final String verdict;
  final String scoreLine;
  final String manglikLine;
  final String conclusion;

  const _MatchConclusionSummary({
    required this.score,
    required this.maxScore,
    required this.recommended,
    required this.manglikBlocks,
    required this.verdict,
    required this.scoreLine,
    required this.manglikLine,
    required this.conclusion,
  });
}

Widget _comparisonTab({required List<_MatchCompareRow> rows}) {
  return rows.isEmpty
      ? const _InlineNotice('No match details are available for this section.')
      : _ComparisonTable(rows: rows);
}

Widget _scoreTab(String title, dynamic data) {
  final rows = _scoreRows(data);
  return rows.isEmpty
      ? const _InlineNotice('No compatibility points are available.')
      : _ScoreTable(rows: rows);
}

Widget _manglikTab(dynamic data) {
  final pairs = _extractMaleFemaleMaps(data);
  final male = pairs.$1;
  final female = pairs.$2;
  final maleName = _display(_firstValue(male, const ['name', 'male_name']));
  final femaleName = _display(
    _firstValue(female, const ['name', 'female_name']),
  );
  final children = <Widget>[
    _ManglikCard(
      title: maleName == '-' ? 'Male Manglik Analysis' : '$maleName Analysis',
      data: male.isEmpty ? data : male,
      accent: const Color(0xFF3BA7D9),
    ),
    const SizedBox(height: 12),
    _ManglikCard(
      title: femaleName == '-'
          ? 'Female Manglik Analysis'
          : '$femaleName Analysis',
      data: female.isEmpty ? data : female,
      accent: const Color(0xFFD9468C),
    ),
  ];
  final conclusion = _cleanConclusionText(
    _bestText(data, const ['conclusion', 'summary', 'match_report', 'report']),
  );
  if (conclusion.isNotEmpty) {
    children.addAll([
      const SizedBox(height: 12),
      _ConclusionCard(title: 'Conclusion', text: conclusion),
    ]);
  }
  return _SectionPanel(
    title: 'Match Manglik',
    subtitle: '',
    child: Column(children: children),
  );
}

Widget _conclusionTab(dynamic data) {
  final rows = _overallRows(data);
  return rows.isNotEmpty
      ? _OverallTable(rows: rows, showStatus: false)
      : _CleanDataList(data: data);
}

Widget _planetTab(dynamic data) {
  return _PlanetDetailsTab(data: data);
}

class _PlanetDetailsTab extends StatefulWidget {
  final dynamic data;

  const _PlanetDetailsTab({required this.data});

  @override
  State<_PlanetDetailsTab> createState() => _PlanetDetailsTabState();
}

class _PlanetDetailsTabState extends State<_PlanetDetailsTab> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final pairs = _extractMaleFemaleMaps(widget.data);
    final maleRecords = _planetRecords(
      pairs.$1,
      _findValueByName(widget.data, 'male') ?? const [],
    );
    final femaleRecords = _planetRecords(
      pairs.$2,
      _findValueByName(widget.data, 'female') ?? const [],
    );
    final records = _selected == 0 ? maleRecords : femaleRecords;

    return Column(
      children: [
        _MatchSegmentSwitch(
          labels: const ['Male', 'Female'],
          selected: _selected,
          onChanged: (index) => setState(() => _selected = index),
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: records.isEmpty
              ? _CleanDataList(
                  key: ValueKey('planet-empty-$_selected'),
                  data: _selected == 0 ? pairs.$1 : pairs.$2,
                )
              : _CompactRecordsTable(
                  key: ValueKey('planet-records-$_selected'),
                  records: records,
                  hiddenColumns: const {'id', 'planet_id'},
                  maxColumns: 8,
                ),
        ),
      ],
    );
  }
}

class _MatchConclusionTab extends StatelessWidget {
  final Map<String, dynamic> response;

  const _MatchConclusionTab({required this.response});

  @override
  Widget build(BuildContext context) {
    final ashtakoot = _findMatchPayload(response, const [
      'match_ashtakoot_points',
      'match-ashtakoot-points',
      'ashtakoot',
      'ashtakoota',
    ]);
    final manglik = _findMatchPayload(response, const [
      'match_manglik_report',
      'match-manglik-report',
      'manglik',
      'mangal',
    ]);
    final summary = _matchConclusionSummary(ashtakoot, manglik);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF2),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8D7A7)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ScoreRing(
                score: summary.score,
                maxScore: summary.maxScore,
                color: summary.recommended
                    ? const Color(0xFF27A36A)
                    : const Color(0xFFE25555),
                size: 86,
                strokeWidth: 7,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Guna Milan Score',
                      style: TextStyle(
                        color: Color(0xFF1E3557),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Ashtakoota traditional points matched',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Verdict: ${summary.verdict}',
                      style: TextStyle(
                        color: summary.recommended
                            ? const Color(0xFF168856)
                            : const Color(0xFFC83F4A),
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      summary.scoreLine,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8D7A7)),
          ),
          child: Column(
            children: [
              const Text(
                'MUTUAL MANGLIK CANCELLATION',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                summary.manglikLine,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: summary.manglikBlocks
                      ? const Color(0xFFC83F4A)
                      : const Color(0xFF168856),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _ConclusionCard(title: 'Conclusion', text: summary.conclusion),
      ],
    );
  }
}

class _MatchSegmentSwitch extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const _MatchSegmentSwitch({
    required this.labels,
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
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            _MatchSegmentButton(
              label: labels[i],
              selected: selected == i,
              onTap: () => onChanged(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _MatchSegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MatchSegmentButton({
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
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  final double score;
  final double maxScore;
  final Color color;
  final double size;
  final double strokeWidth;

  const _ScoreRing({
    required this.score,
    required this.maxScore,
    required this.color,
    required this.size,
    required this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    final progress = maxScore <= 0 ? 0.0 : (score / maxScore).clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: strokeWidth,
              color: color,
              backgroundColor: const Color(0xFFE5E7EB),
              strokeCap: StrokeCap.round,
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: _displayScore(score),
                  style: const TextStyle(
                    color: Color(0xFF1E3557),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: '/${_displayScore(maxScore)}',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
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

class _PercentRing extends StatelessWidget {
  final double value;
  final Color color;

  const _PercentRing({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = value.clamp(0, 100).toDouble();
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: CircularProgressIndicator(
              value: pct / 100,
              strokeWidth: 10,
              color: color,
              backgroundColor: const Color(0xFFE5E7EB),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${pct.round()}%',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

Widget _cleanDetailsTab(String title, dynamic data) {
  return _SectionPanel(
    title: title,
    subtitle: '',
    child: _CleanDataList(data: data),
  );
}

class _ComparisonTable extends StatelessWidget {
  final List<_MatchCompareRow> rows;

  const _ComparisonTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.15),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(1.15),
        },
        border: TableBorder.all(color: Color(0xFFE8D7A7)),
        children: [
          _compareTableRow(
            'Male',
            'Details',
            'Female',
            header: true,
            color: const Color(0xFFD7AF4B),
          ),
          for (var i = 0; i < rows.length; i++)
            _compareTableRow(
              rows[i].male,
              rows[i].label,
              rows[i].female,
              color: i.isEven ? Colors.white : const Color(0xFFFFFCF2),
            ),
        ],
      ),
    );
  }
}

TableRow _compareTableRow(
  String left,
  String middle,
  String right, {
  required Color color,
  bool header = false,
}) {
  return TableRow(
    decoration: BoxDecoration(color: color),
    children: [
      _tableCell(left, align: TextAlign.center, header: header),
      _tableCell(middle, align: TextAlign.center, header: true),
      _tableCell(right, align: TextAlign.center, header: header),
    ],
  );
}

class _ScoreTable extends StatelessWidget {
  final List<_ScoreRow> rows;

  const _ScoreTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.8),
          1: FlexColumnWidth(.78),
          2: FlexColumnWidth(.9),
          3: FlexColumnWidth(.48),
        },
        border: TableBorder.all(color: Color(0xFFE8D7A7)),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFD7AF4B)),
            children: [
              _tableCell('Attribute', header: true),
              _tableCell('Total', header: true, align: TextAlign.center),
              _tableCell('Matched', header: true, align: TextAlign.center),
              _tableCell('', header: true, align: TextAlign.center),
            ],
          ),
          for (final row in rows)
            TableRow(
              decoration: BoxDecoration(
                color: row.isTotal ? const Color(0xFFFFD34D) : Colors.white,
              ),
              children: [
                _tableCell(row.label, header: row.isTotal),
                _tableCell(row.total, align: TextAlign.center),
                _tableCell(row.matched, align: TextAlign.center),
                _scoreStatusCell(row),
              ],
            ),
        ],
      ),
    );
  }
}

class _OverallTable extends StatelessWidget {
  final List<_OverallRow> rows;
  final bool showStatus;

  const _OverallTable({required this.rows, this.showStatus = true});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(1.55),
          1: FlexColumnWidth(1),
          2: FlexColumnWidth(.45),
        },
        border: TableBorder.all(color: Color(0xFFE8D7A7)),
        children: [
          TableRow(
            decoration: const BoxDecoration(color: Color(0xFFD7AF4B)),
            children: [
              _tableCell('Overall Analysis', header: true),
              _tableCell('Result', header: true),
              if (showStatus) _tableCell('', header: true),
            ],
          ),
          for (final row in rows)
            TableRow(
              children: [
                _tableCell(row.label),
                _tableCell(row.value),
                if (showStatus) _overallStatusCell(row),
              ],
            ),
        ],
      ),
    );
  }
}

class _ManglikCard extends StatelessWidget {
  final String title;
  final dynamic data;
  final Color accent;

  const _ManglikCard({
    required this.title,
    required this.data,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = _numberValue(data, const [
      'percentage_manglik_present',
      'manglik_percentage',
      'percentage',
      'score',
    ]);
    final present = _boolish(
      _firstValue(data, const [
        'manglik_present',
        'is_manglik_present',
        'is_present',
        'manglik',
      ]),
    );
    final report = _cleanConclusionText(
      _bestText(data, const [
        'manglik_report',
        'report',
        'summary',
        'description',
      ]),
    );
    final pct = percentage == null ? 0.0 : percentage.clamp(0, 100).toDouble();
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D7A7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: accent,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Are you Manglik?',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        present == null ? '-' : (present ? 'Yes' : 'No'),
                        style: const TextStyle(
                          color: Color(0xFF1E3557),
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (report.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          report,
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 96,
                  height: 96,
                  child: _PercentRing(value: pct, color: accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ConclusionCard extends StatelessWidget {
  final String title;
  final String text;

  const _ConclusionCard({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D7A7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFF4CB49B),
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontSize: 13,
                height: 1.38,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactRecordsTable extends StatelessWidget {
  final String? title;
  final List<Map<String, dynamic>> records;
  final Set<String> hiddenColumns;
  final int maxColumns;

  const _CompactRecordsTable({
    this.title,
    required this.records,
    this.hiddenColumns = const {},
    this.maxColumns = 7,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hidden = hiddenColumns.map(_normalizeKey).toSet();
    final columns = _columnsFor(records)
        .where((column) => !hidden.contains(_normalizeKey(column)))
        .take(maxColumns)
        .toList();
    if (columns.isEmpty) return _CleanDataList(data: records);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((title ?? '').trim().isNotEmpty) ...[
          Text(
            title!,
            style: const TextStyle(
              color: Color(0xFF1E3557),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
        ],
        const _ScrollHint(),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: DataTable(
              columnSpacing: 18,
              horizontalMargin: 12,
              headingRowHeight: 42,
              dataRowMinHeight: 38,
              dataRowMaxHeight: 54,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFD7AF4B)),
              border: TableBorder.all(color: const Color(0xFFE8D7A7)),
              columns: columns
                  .map(
                    (column) => DataColumn(
                      label: Text(
                        _cleanLabel(column),
                        style: const TextStyle(
                          color: Color(0xFF1E3557),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              rows: records
                  .map(
                    (record) => DataRow(
                      cells: columns
                          .map(
                            (column) => DataCell(
                              Text(
                                _display(record[column]),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _CleanDataList extends StatelessWidget {
  final dynamic data;

  const _CleanDataList({required this.data, super.key});

  @override
  Widget build(BuildContext context) {
    final records = _recordsFromAny(data);
    if (records.length >= 2) {
      return _CompactRecordsTable(title: 'Details', records: records);
    }
    final rows = _rowsFromAny(data);
    if (rows.isEmpty) {
      return const _InlineNotice('No details are available for this section.');
    }
    return Column(
      children: [
        for (final row in rows) ...[
          _ValueCard(label: row.label, value: row.value),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

Widget _tableCell(
  String text, {
  bool header = false,
  TextAlign align = TextAlign.left,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: Text(
      text,
      textAlign: align,
      style: TextStyle(
        color: const Color(0xFF1E3557),
        fontSize: 12,
        fontWeight: header ? FontWeight.w900 : FontWeight.w400,
        height: 1.25,
      ),
    ),
  );
}

Widget _scoreStatusCell(_ScoreRow row) {
  if (row.isTotal || row.passed == null) {
    return const SizedBox(height: 36);
  }
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Icon(
      row.passed == false ? Icons.close_rounded : Icons.check_rounded,
      color: row.passed == false
          ? const Color(0xFFE94141)
          : const Color(0xFF43B02A),
      size: 22,
    ),
  );
}

Widget _overallStatusCell(_OverallRow row) {
  if (row.passed == null) {
    return const SizedBox(height: 36);
  }
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Icon(
      row.passed == false ? Icons.close_rounded : Icons.check_rounded,
      color: row.passed == false
          ? const Color(0xFFE94141)
          : const Color(0xFF43B02A),
      size: 22,
    ),
  );
}

class _InlineNotice extends StatelessWidget {
  final String message;

  const _InlineNotice(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D7A7)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF1E3557),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RecentProfilesSheet extends StatefulWidget {
  final RecentProfileService service;
  final String title;
  final ValueChanged<Map<String, dynamic>> onSelected;

  const _RecentProfilesSheet({
    required this.service,
    required this.title,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Color(0xFF1E3557)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
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
                          'No recent profiles found for this side yet.',
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: controller,
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                      itemCount: profiles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final profile = profiles[index];
                        final name = _string(
                          profile['profile_label'] ??
                              profile['person_name'] ??
                              'Saved Profile',
                        );
                        final details = [
                          _string(profile['date_of_birth']),
                          _string(profile['time_of_birth']),
                          _string(profile['place_of_birth']),
                        ].where((item) => item.isNotEmpty).join(' • ');
                        return ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFE8D7A7)),
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          subtitle: details.isEmpty ? null : Text(details),
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

class _MatchPerson {
  final String role;
  final String name;
  final DateTime date;
  final TimeOfDay time;
  final String place;
  final String coordinates;

  const _MatchPerson({
    required this.role,
    required this.name,
    required this.date,
    required this.time,
    required this.place,
    required this.coordinates,
  });

  factory _MatchPerson.fromForm(
    _PersonBirthForm form,
    LocationSelection location,
  ) {
    return _MatchPerson(
      role: form.role,
      name: form.name.text.trim().isEmpty ? form.defaultName : form.name.text,
      date: form.date!,
      time: form.time!,
      place: location.name,
      coordinates: location.coordinates,
    );
  }

  Map<String, dynamic> chartPayload(String chartType) => {
        'datetime': _isoDateTime(date, time),
        'coordinates': coordinates,
        'ayanamsa': 1,
        'la': 'en',
        'chart_type': chartType,
      };
}

class _MatchTab {
  final String id;
  final String title;
  final String summary;
  final dynamic data;
  final bool isCharts;

  const _MatchTab({
    required this.id,
    required this.title,
    required this.summary,
    required this.data,
    this.isCharts = false,
  });

  String get label {
    if (title == 'Match Conclusion') return title;
    final cleanTitle = title.replaceFirst(RegExp(r'^Match\s+'), '');
    if (cleanTitle == 'Match Divisional Charts') return 'Charts';
    return cleanTitle;
  }
}

class _InfoRow {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);
}

class _ChartPair {
  final Map<String, dynamic> male;
  final Map<String, dynamic> female;

  const _ChartPair(this.male, this.female);
}

class _ChartOption {
  final String value;
  final String label;

  const _ChartOption(this.value, this.label);
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

bool _containsAny(String value, List<String> needles) {
  return needles.any(value.contains);
}

List<_MatchCompareRow> _birthRows(
  dynamic data,
  _MatchPerson male,
  _MatchPerson female,
) {
  final pairs = _extractMaleFemaleMaps(data);
  String maleValue(List<String> keys, String fallback) =>
      _display(_firstValue(pairs.$1, keys, fallback: fallback));
  String femaleValue(List<String> keys, String fallback) =>
      _display(_firstValue(pairs.$2, keys, fallback: fallback));
  return [
    _MatchCompareRow(
      'Name',
      maleValue(const ['name'], male.name),
      femaleValue(const ['name'], female.name),
    ),
    _MatchCompareRow(
      'Birth Date',
      maleValue(const [
        'birth_date',
        'date_of_birth',
        'dob',
        'date',
      ], _formatDate(male.date)),
      femaleValue(const [
        'birth_date',
        'date_of_birth',
        'dob',
        'date',
      ], _formatDate(female.date)),
    ),
    _MatchCompareRow(
      'Birth Time',
      maleValue(const [
        'birth_time',
        'time_of_birth',
        'tob',
        'time',
      ], _formatTime(male.time)),
      femaleValue(const [
        'birth_time',
        'time_of_birth',
        'tob',
        'time',
      ], _formatTime(female.time)),
    ),
    _MatchCompareRow(
      'Birth Place',
      maleValue(const ['birth_place', 'place', 'location'], male.place),
      femaleValue(const ['birth_place', 'place', 'location'], female.place),
    ),
    _MatchCompareRow(
      'Latitude',
      maleValue(const ['latitude', 'lat'], male.coordinates.split(',').first),
      femaleValue(const [
        'latitude',
        'lat',
      ], female.coordinates.split(',').first),
    ),
    _MatchCompareRow(
      'Longitude',
      maleValue(
        const ['longitude', 'lon', 'lng'],
        male.coordinates.split(',').length > 1
            ? male.coordinates.split(',').last
            : '-',
      ),
      femaleValue(
        const ['longitude', 'lon', 'lng'],
        female.coordinates.split(',').length > 1
            ? female.coordinates.split(',').last
            : '-',
      ),
    ),
    _MatchCompareRow(
      'Timezone',
      maleValue(const ['timezone', 'tz'], '+05:30'),
      femaleValue(const ['timezone', 'tz'], '+05:30'),
    ),
  ];
}

List<_MatchCompareRow> _pairedRows(dynamic data, List<String> preferredKeys) {
  final pairs = _extractMaleFemaleMaps(data);
  final male = pairs.$1;
  final female = pairs.$2;
  final keys = <String>[];
  for (final key in preferredKeys) {
    if (_hasKeyLike(male, key) || _hasKeyLike(female, key)) keys.add(key);
  }
  if (keys.isEmpty) {
    for (final key in {...male.keys, ...female.keys}) {
      if (!_skipKey(key) && !_containsAny(key.toLowerCase(), ['id'])) {
        keys.add(key);
      }
    }
  }
  return keys
      .map(
        (key) => _MatchCompareRow(
          _cleanLabel(key),
          _display(_firstValue(male, [key])),
          _display(_firstValue(female, [key])),
        ),
      )
      .where((row) => row.male != '-' || row.female != '-')
      .toList();
}

(Map<String, dynamic>, Map<String, dynamic>) _extractMaleFemaleMaps(
  dynamic data,
) {
  final map = _asMap(data);
  if (map == null) return (const {}, const {});
  final male = _findPersonMap(map, const [
    'male',
    'boy',
    'groom',
    'man',
    'male_details',
    'male_astro_details',
    'male_birth_details',
    'male_planet_details',
    'boy_details',
    'boy_astro_details',
    'boy_birth_details',
    'boy_planet_details',
    'groom_details',
  ]);
  final female = _findPersonMap(map, const [
    'female',
    'girl',
    'bride',
    'woman',
    'female_details',
    'female_astro_details',
    'female_birth_details',
    'female_planet_details',
    'girl_details',
    'girl_astro_details',
    'girl_birth_details',
    'girl_planet_details',
    'bride_details',
  ]);
  return (male ?? const {}, female ?? const {});
}

Map<String, dynamic>? _findPersonMap(dynamic value, List<String> keys) {
  final map = _asMap(value);
  if (map != null) {
    for (final entry in map.entries) {
      final normalized = entry.key.toLowerCase().replaceAll(
            RegExp(r'[^a-z]'),
            '',
          );
      if (keys.any((key) => normalized == key.replaceAll('_', ''))) {
        final found = _asMap(_extractData(entry.value));
        if (found != null) return _cleanMap(found);
      }
    }
    for (final entry in map.entries) {
      final found = _findPersonMap(entry.value, keys);
      if (found != null) return found;
    }
  }
  if (value is List) {
    for (final item in value) {
      final found = _findPersonMap(item, keys);
      if (found != null) return found;
    }
  }
  return null;
}

dynamic _findValueByName(dynamic value, String name) {
  final target = name.toLowerCase();
  final map = _asMap(value);
  if (map != null) {
    for (final entry in map.entries) {
      if (entry.key.toLowerCase().contains(target)) return entry.value;
    }
    for (final entry in map.entries) {
      final found = _findValueByName(entry.value, name);
      if (found != null) return found;
    }
  }
  if (value is List) {
    for (final item in value) {
      final found = _findValueByName(item, name);
      if (found != null) return found;
    }
  }
  return null;
}

bool _hasKeyLike(Map<String, dynamic> map, String key) {
  return _firstValue(map, [key]) != null;
}

dynamic _firstValue(dynamic data, List<String> keys, {String? fallback}) {
  final map = _asMap(data);
  if (map == null) return fallback;
  final normalizedKeys = keys.map(_normalizeKey).toSet();
  for (final entry in map.entries) {
    if (normalizedKeys.contains(_normalizeKey(entry.key))) {
      final cleaned = _cleanValue(entry.value);
      if (_hasUsefulData(cleaned)) return cleaned;
    }
  }
  for (final entry in map.entries) {
    final value = entry.value;
    if (value is Map || value is List) {
      final found = _firstValue(value, keys);
      if (_hasUsefulData(found)) return found;
    }
  }
  return fallback;
}

dynamic _firstDirectValue(dynamic data, List<String> keys) {
  final map = _asMap(data);
  if (map == null) return null;
  final normalizedKeys = keys.map(_normalizeKey).toSet();
  for (final entry in map.entries) {
    if (normalizedKeys.contains(_normalizeKey(entry.key))) {
      final cleaned = _cleanValue(entry.value);
      if (_hasUsefulData(cleaned)) return cleaned;
    }
  }
  return null;
}

String _normalizeKey(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
}

List<_ScoreRow> _scoreRows(dynamic data) {
  final rows = <_ScoreRow>[];
  final records = _scoreRecords(data);
  for (final record in records) {
    final label = _display(
      _firstValue(record, const [
        'attribute',
        'name',
        'koot',
        'guna',
        'title',
        'category',
      ]),
    );
    if (label == '-' ||
        _skipKey(label) ||
        _normalizeKey(label) == 'total' ||
        _containsAny(_normalizeKey(label), ['conclusion', 'description'])) {
      continue;
    }
    final total = _display(
      _firstValue(record, const [
        'total',
        'total_points',
        'full_score',
        'maximum',
        'max',
        'out_of',
        'points',
      ]),
    );
    final matched = _display(
      _firstValue(record, const [
        'matched',
        'match',
        'received_points',
        'obtained',
        'score',
        'points_obtained',
        'actual',
      ]),
    );
    final passed = _scorePassed(record, matched, total);
    rows.add(
      _ScoreRow(label: label, total: total, matched: matched, passed: passed),
    );
  }

  final totals = _scoreSummary(data, rows);
  if (totals.score > 0 || totals.maxScore > 0) {
    rows.add(
      _ScoreRow(
        label: 'Total',
        total: _displayScore(totals.maxScore <= 0 ? 36 : totals.maxScore),
        matched: _displayScore(totals.score),
        isTotal: true,
      ),
    );
  }
  return rows;
}

_ScoreSummary _scoreSummary(dynamic data, List<_ScoreRow> rows) {
  final map = _asMap(data);
  final totalMap = _asMap(map?['total']) ??
      _asMap(map?['summary']) ??
      _asMap(map?['total_points']);
  final directScore = _firstDirectValue(map, const [
    'total_received_points',
    'received_points',
    'total_score',
    'score',
    'matched_points',
  ]);
  final directMax = _firstDirectValue(map, const [
    'maximum_points',
    'max_points',
    'out_of',
    'full_score',
  ]);
  final totalScore = _firstDirectValue(totalMap, const [
    'received_points',
    'matched',
    'score',
    'obtained',
    'points_obtained',
  ]);
  final totalMax = _firstDirectValue(totalMap, const [
    'total_points',
    'maximum_points',
    'max_points',
    'out_of',
    'total',
  ]);

  var score = _numberFromAny(directScore ?? totalScore);
  var maxScore = _numberFromAny(directMax ?? totalMax);

  if (score == null && rows.isNotEmpty) {
    score = rows.fold<double>(0, (sum, row) => sum + _parseNumber(row.matched));
  }
  if (maxScore == null && rows.isNotEmpty) {
    maxScore = rows.fold<double>(
      0,
      (sum, row) => sum + _parseNumber(row.total),
    );
  }

  return _ScoreSummary(score ?? 0, maxScore ?? 36);
}

List<Map<String, dynamic>> _scoreRecords(dynamic data) {
  final records = <Map<String, dynamic>>[];
  final map = _asMap(data);
  if (map != null) {
    for (final entry in map.entries) {
      if (_skipKey(entry.key)) continue;
      if (_normalizeKey(entry.key) == 'total') continue;
      final item = _asMap(entry.value);
      if (item != null) {
        final clean = _cleanMap(item);
        if (clean.isNotEmpty) {
          clean.putIfAbsent('attribute', () => _cleanLabel(entry.key));
          if (_looksLikeScore(clean)) records.add(clean);
        }
      }
    }
  }
  records.addAll(_recordsFromAny(data).where(_looksLikeScore));
  final seen = <String>{};
  return records.where((record) {
    final label = _display(_firstValue(record, const ['attribute', 'name']));
    if (seen.contains(label)) return false;
    seen.add(label);
    return true;
  }).toList();
}

bool _looksLikeScore(Map<String, dynamic> record) {
  final text = record.keys.map(_normalizeKey).join(' ');
  return text.contains('total') ||
      text.contains('matched') ||
      text.contains('received') ||
      text.contains('score') ||
      text.contains('points');
}

bool? _scorePassed(Map<String, dynamic> record, String matched, String total) {
  final explicit = _firstValue(record, const [
    'matched_status',
    'is_matched',
    'passed',
    'is_compatible',
  ]);
  final boolValue = _boolish(explicit);
  if (boolValue != null) return boolValue;
  final matchedNum = _parseNumber(matched);
  final totalNum = _parseNumber(total);
  if (totalNum <= 0) return null;
  return matchedNum >= totalNum / 2;
}

List<Map<String, dynamic>> _planetRecords(dynamic primary, dynamic fallback) {
  final primaryRows = _recordsFromAny(primary);
  if (primaryRows.isNotEmpty) return primaryRows.map(_stripPlanetIds).toList();
  final fallbackRows = _recordsFromAny(fallback);
  return fallbackRows.map(_stripPlanetIds).toList();
}

Map<String, dynamic> _stripPlanetIds(Map<String, dynamic> record) {
  final result = <String, dynamic>{};
  record.forEach((key, value) {
    final normalized = _normalizeKey(key);
    if (normalized == 'id' || normalized == 'planetid') return;
    result[key] = value;
  });
  return result;
}

dynamic _findMatchPayload(Map<String, dynamic> response, List<String> names) {
  final normalized = names.map(_normalizeKey).toSet();
  final data = _asMap(response['data']) ?? response;
  final sections = data['provider_sections'];
  if (sections is List) {
    for (final item in sections) {
      final section = _asMap(item);
      if (section == null) continue;
      final id = _normalizeKey(_string(section['id']));
      final title = _normalizeKey(_string(section['title']));
      if (normalized.any((name) => id.contains(name) || title.contains(name))) {
        final items = _asMap(section['items']);
        if (items != null && items.isNotEmpty) {
          return _extractData(items.values.first);
        }
        return _extractData(section);
      }
    }
  }

  final payload = _asMap(_asMap(response['meta'])?['provider_payload']);
  if (payload != null) {
    for (final entry in payload.entries) {
      final key = _normalizeKey(entry.key);
      if (normalized.any(key.contains)) return _extractData(entry.value);
    }
  }
  return null;
}

_MatchConclusionSummary _matchConclusionSummary(
  dynamic ashtakoot,
  dynamic manglik,
) {
  final scoreRows = _scoreRows(ashtakoot);
  final score = _scoreSummary(
    ashtakoot,
    scoreRows.where((row) => !row.isTotal).toList(),
  );
  final scoreValue = score.score;
  final maxValue = score.maxScore <= 0 ? 36.0 : score.maxScore;

  final manglikPairs = _extractMaleFemaleMaps(manglik);
  final malePresent = _boolish(
        _firstValue(manglikPairs.$1, const [
          'is_present',
          'manglik_present',
          'is_manglik_present',
          'manglik',
        ]),
      ) ??
      false;
  final femalePresent = _boolish(
        _firstValue(manglikPairs.$2, const [
          'is_present',
          'manglik_present',
          'is_manglik_present',
          'manglik',
        ]),
      ) ??
      false;
  final malePercent = _numberValue(manglikPairs.$1, const [
        'percentage_manglik_present',
        'manglik_percentage',
        'percentage',
      ]) ??
      0;
  final femalePercent = _numberValue(manglikPairs.$2, const [
        'percentage_manglik_present',
        'manglik_percentage',
        'percentage',
      ]) ??
      0;
  final explicitCancelled = _boolish(
    _firstValue(manglik, const [
      'is_cancelled',
      'is_manglik_cancelled',
      'is_mars_manglik_cancelled',
      'manglik_cancelled',
      'mutual_manglik_cancellation',
    ]),
  );
  final explicitMatch = _boolish(
    _firstValue(manglik, const [
      'match',
      'manglik_match',
      'is_match',
      'is_compatible',
    ]),
  );
  final bothManglik = malePresent && femalePresent;
  final oneStrongManglik = malePresent != femalePresent &&
      (malePercent >= 50 || femalePercent >= 50);
  final cancelled = explicitCancelled == true || bothManglik;
  final manglikBlocks =
      explicitMatch == false || (!cancelled && oneStrongManglik);
  final enoughScore = scoreValue >= 18;
  final recommended = enoughScore && !manglikBlocks;

  final verdict = recommended ? 'Recommended' : 'Not Recommended';
  final scoreLine = enoughScore
      ? 'Ashtakoota matching is ${_displayScore(scoreValue)} out of ${_displayScore(maxValue)}, meeting the traditional 18 point benchmark.'
      : 'Ashtakoota matching is ${_displayScore(scoreValue)} out of ${_displayScore(maxValue)}, below the traditional 18 point benchmark.';
  final manglikLine = manglikBlocks
      ? 'Manglik influence needs astrologer review'
      : cancelled
          ? 'Mutual Manglik cancellation considered'
          : 'No major Manglik blocker returned';
  final conclusion = recommended
      ? cancelled
          ? 'The Ashtakoota score meets the usual recommendation threshold and the Manglik condition is considered cancelled or balanced. This match can be considered after reviewing the complete charts with an astrologer.'
          : 'The Ashtakoota score meets the usual recommendation threshold and the Manglik comparison does not show a strong blocking condition. This match can be considered after reviewing the complete charts with an astrologer.'
      : manglikBlocks
          ? enoughScore
              ? 'The Ashtakoota score meets the usual recommendation threshold, but Manglik influence creates a blocking caution. This match is not recommended without a detailed astrologer review.'
              : 'The Ashtakoota score is below the usual recommendation threshold and Manglik influence also creates a caution flag. This match is not recommended on the combined checks.'
          : 'The Ashtakoota score is below the usual recommendation threshold, so this match is not recommended on score alone.';

  return _MatchConclusionSummary(
    score: scoreValue,
    maxScore: maxValue,
    recommended: recommended,
    manglikBlocks: manglikBlocks,
    verdict: verdict,
    scoreLine: scoreLine,
    manglikLine: manglikLine,
    conclusion: conclusion,
  );
}

List<_OverallRow> _overallRows(dynamic data) {
  final labels = const [
    ['ashtakoota_match', 'ashtakoot_match', 'ashtakoota', 'ashtakoot'],
    ['manglik_match', 'mangal_match', 'manglik'],
    ['rajju_dosha', 'rajju'],
    ['vedha_dosha', 'vedha'],
    ['dashakoota_match', 'dashakoot_match', 'dashakoota', 'dashakoot'],
  ];
  final rows = <_OverallRow>[];
  for (final keys in labels) {
    final value = _firstValue(data, keys);
    if (!_hasUsefulData(value)) continue;
    rows.add(
      _OverallRow(
        _cleanLabel(keys.first),
        _display(value),
        _boolish(value) ?? !_display(value).toLowerCase().contains('no'),
      ),
    );
  }
  if (rows.isNotEmpty) return rows;
  final scalarRows = _rowsFromAny(data);
  return scalarRows
      .where(
        (row) => !_containsAny(row.label.toLowerCase(), [
          'conclusion',
          'summary',
          'report',
        ]),
      )
      .take(6)
      .map(
        (row) => _OverallRow(
          row.label,
          row.value,
          _boolish(row.value) ?? !row.value.toLowerCase().contains('no'),
        ),
      )
      .toList();
}

String _bestText(dynamic data, List<String> keys) {
  final value = _firstValue(data, keys);
  final text = _display(value);
  if (text != '-') return text;
  return '';
}

bool? _boolish(dynamic value) {
  if (value is bool) return value;
  final text = _display(value).toLowerCase();
  if (text == 'yes' || text == 'true' || text == '1') return true;
  if (text == 'no' || text == 'false' || text == '0') return false;
  if (text.contains('not') || text.contains('no ')) return false;
  if (text.contains('present') || text.contains('matched')) return true;
  return null;
}

double? _numberValue(dynamic data, List<String> keys) {
  final value = _firstValue(data, keys);
  return _numberFromAny(value);
}

double? _numberFromAny(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  final text = _display(value);
  if (text == '-') return null;
  return _parseNumber(text);
}

double _parseNumber(String value) {
  final match = RegExp(r'-?\d+(\.\d+)?').firstMatch(value);
  if (match == null) return 0;
  return double.tryParse(match.group(0) ?? '') ?? 0;
}

String _displayScore(double value) {
  if ((value - value.roundToDouble()).abs() < 0.001) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1).replaceFirst(RegExp(r'\.?0+$'), '');
}

String _cleanConclusionText(String text) {
  var cleaned = text.trim();
  if (cleaned.isEmpty) return '';
  cleaned = cleaned
      .replaceFirst(
        RegExp(r'^match\s*:\s*(yes|no)\s*', caseSensitive: false),
        '',
      )
      .replaceFirst(RegExp(r'^report\s*:\s*', caseSensitive: false), '')
      .trim();
  return cleaned;
}

List<_MatchTab> _sectionTabs(Map<String, dynamic> response) {
  final data = _asMap(response['data']) ?? response;
  final sections = data['provider_sections'];
  final tabs = <_MatchTab>[];
  if (sections is List) {
    for (final item in sections) {
      final section = _asMap(item);
      if (section == null) continue;
      final title = _string(section['title']);
      final id = _string(section['id']);
      final summary = _string(section['summary']);
      final items = _asMap(section['items']);
      dynamic payload = items;
      if (items != null && items.length == 1) {
        payload = _extractData(items.values.first);
      }
      tabs.add(
        _MatchTab(
          id: id.isEmpty ? title : id,
          title: title.isEmpty ? 'Match Section' : title,
          summary: summary,
          data: _cleanValue(payload),
        ),
      );
    }
  }
  if (tabs.isNotEmpty) return tabs;

  final payload = _asMap(_asMap(response['meta'])?['provider_payload']);
  if (payload != null) {
    payload.forEach((key, value) {
      tabs.add(
        _MatchTab(
          id: key.toString(),
          title: _cleanLabel(key),
          summary: '',
          data: _cleanValue(value),
        ),
      );
    });
  }
  return tabs;
}

dynamic _extractData(dynamic value) {
  final map = _asMap(value);
  if (map == null) return value;
  if (map.containsKey('data')) return _extractData(map['data']);
  return map;
}

List<Map<String, dynamic>> _recordsFromAny(dynamic value) {
  if (value is List) {
    return value
        .map(_asMap)
        .whereType<Map<String, dynamic>>()
        .map(_cleanMap)
        .where((item) => item.isNotEmpty)
        .toList();
  }
  final map = _asMap(value);
  if (map == null) return const [];
  for (final item in map.values) {
    if (item is List) {
      final rows = _recordsFromAny(item);
      if (rows.length >= 2) return rows;
    }
  }
  return const [];
}

Map<String, dynamic> _cleanMap(Map<String, dynamic> map) {
  final result = <String, dynamic>{};
  map.forEach((key, value) {
    if (_skipKey(key)) return;
    final cleaned = _cleanValue(value);
    if (_hasUsefulData(cleaned)) result[key] = cleaned;
  });
  return result;
}

List<_InfoRow> _rowsFromAny(dynamic value) {
  final map = _asMap(value);
  if (map == null) {
    final text = _display(value);
    return text == '-' ? const [] : [_InfoRow('Details', text)];
  }
  final rows = <_InfoRow>[];
  map.forEach((key, item) {
    if (_skipKey(key)) return;
    final cleaned = _cleanValue(item);
    if (cleaned is Map || cleaned is List || !_hasUsefulData(cleaned)) return;
    rows.add(_InfoRow(_cleanLabel(key), _display(cleaned)));
  });
  return rows;
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

bool _skipKey(String key) {
  final normalized = key.toLowerCase();
  return normalized == 'status' ||
      normalized == 'success' ||
      normalized == 'endpoint' ||
      normalized == 'provider_payload' ||
      normalized == 'provider_sections' ||
      normalized == 'raw' ||
      normalized == 'url' ||
      normalized == 'data' ||
      normalized == 'message' ||
      normalized == 'chart_svg';
}

String _display(dynamic value) {
  if (value == null) return '-';
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is num) {
    if (value is int) return value.toString();
    return value.toStringAsFixed(4).replaceFirst(RegExp(r'\.?0+$'), '');
  }
  if (value is List) {
    return value.map(_display).where((item) => item != '-').join(', ');
  }
  if (value is Map) {
    return value.entries
        .where((entry) => !_skipKey(entry.key.toString()))
        .map((entry) => '${_cleanLabel(entry.key)}: ${_display(entry.value)}')
        .join('\n');
  }
  return _stripHtml(value.toString().trim());
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

String _cleanLabel(dynamic value) {
  final text = value.toString().trim();
  if (text.isEmpty) return '';
  final normalized = _normalizeKey(text);
  const labels = {
    'ispresent': 'Is Present',
    'vedhaname': 'Vedha Name',
    'ashtakootamatch': 'Ashtakoota Match',
    'ashtakootmatch': 'Ashtakoota Match',
    'dashakootamatch': 'Dashakoota Match',
    'dashakootmatch': 'Dashakoota Match',
    'manglikmatch': 'Manglik Match',
    'mangalmatch': 'Manglik Match',
    'rajj dosha': 'Rajju Dosha',
    'rajjdosh': 'Rajju Dosha',
    'rajjudosha': 'Rajju Dosha',
  };
  final mapped = labels[normalized];
  if (mapped != null) return mapped;
  return text
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAllMapped(
        RegExp(r'([a-z])([A-Z])'),
        (match) => '${match.group(1)} ${match.group(2)}',
      )
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map(
        (part) => part.length <= 2
            ? part.toUpperCase()
            : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

String _string(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

String _apiDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String _apiTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}

String _isoDateTime(DateTime date, TimeOfDay time) {
  return '${_apiDate(date)}T${_apiTime(time)}:00+05:30';
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Birth date';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatTime(TimeOfDay? time) {
  if (time == null) return 'Birth time';
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

DateTime? _parseDate(String value) {
  if (value.trim().isEmpty) return null;
  final iso = DateTime.tryParse(value);
  if (iso != null) return iso;
  final parts = value.split(RegExp(r'[-/]'));
  if (parts.length != 3) return null;
  final a = int.tryParse(parts[0]);
  final b = int.tryParse(parts[1]);
  final c = int.tryParse(parts[2]);
  if (a == null || b == null || c == null) return null;
  if (parts[0].length == 4) return DateTime(a, b, c);
  return DateTime(c, b, a);
}

TimeOfDay? _parseTime(String value) {
  final match = RegExp(
    r'(\d{1,2}):(\d{2})\s*(AM|PM)?',
    caseSensitive: false,
  ).firstMatch(value);
  if (match == null) return null;
  var hour = int.tryParse(match.group(1) ?? '') ?? 0;
  final minute = int.tryParse(match.group(2) ?? '') ?? 0;
  final period = match.group(3)?.toUpperCase();
  if (period == 'PM' && hour != 12) hour += 12;
  if (period == 'AM' && hour == 12) hour = 0;
  return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
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

Map<String, dynamic>? _firstChart(dynamic chartData) {
  final map = _asMap(chartData);
  if (map == null) return null;
  final charts = map['charts'];
  if (charts is List && charts.isNotEmpty) return _asMap(charts.first);
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
