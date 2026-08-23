import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/astrology_service.dart';
import '../../core/services/recent_profile_service.dart';
import '../main_navigation.dart';
import '../mainwidgets/header.dart';
import '../shared/widgets/location_search_field.dart';

class _AC {
  static const Color goldLight = Color(0xFFFFF3D0);
  static const Color gold = Color(0xFFD4A017);
  static const Color maroon = Color(0xFF973B43);
  static const Color remedyText = Color(0xFFB8860B);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
}

class _BackBar extends StatelessWidget {
  final VoidCallback onBack;

  const _BackBar({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_circle_left_rounded),
          color: _AC.textPrimary,
        ),
        const Expanded(
          child: Text(
            'Lal Kitab Report',
            style: TextStyle(
              color: _AC.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class LalKitabReportScreen extends StatefulWidget {
  const LalKitabReportScreen({super.key});

  @override
  State<LalKitabReportScreen> createState() => _LalKitabReportScreenState();
}

class _LalKitabReportScreenState extends State<LalKitabReportScreen> {
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _tobController = TextEditingController();
  final TextEditingController _placeController = TextEditingController();
  final AstrologyService _astrology = AstrologyService();
  final RecentProfileService _recentProfiles = RecentProfileService();
  LocationSelection? _location;
  bool _loading = false;
  String? _error;
  String _profileName = 'Lal Kitab Profile';

  /// True only when ALL three fields are non-empty
  bool get _hasDetails =>
      _dobController.text.trim().isNotEmpty &&
      _tobController.text.trim().isNotEmpty &&
      _placeController.text.trim().isNotEmpty &&
      _location != null;

  @override
  void initState() {
    super.initState();
    _loadSavedBirthDetails();
    // Rebuild when any field changes so the button / empty-state reacts live
    _dobController.addListener(_onFieldChanged);
    _tobController.addListener(_onFieldChanged);
    _placeController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  Future<void> _onGenerate() async {
    final date = _parseDate(_dobController.text);
    final time = _parseTime(_tobController.text);
    var location = _location;
    if (date == null || time == null || _placeController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter date, time, and birth place.');
      return;
    }

    if (location == null) {
      final matches = await _astrology.searchLocations(_placeController.text);
      if (matches.isNotEmpty) {
        location = LocationSelection.fromApi(matches.first);
      }
    }

    if (location == null) {
      setState(() {
        _error = 'Please select the birth place from the location list.';
      });
      return;
    }
    final selectedLocation = location;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _astrology.lalKitab({
        'datetime': _kolkataDateTime(date, time),
        'coordinates': location.coordinates,
        'ayanamsa': 1,
        'la': 'en',
      });
      if (!mounted) return;
      setState(() => _loading = false);
      if (response['status'] == 'success') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _LalKitabResultScreen(
              input: _LalKitabInput(
                name: _profileName,
                date: date,
                time: time,
                place: selectedLocation.name,
              ),
              response: response,
            ),
          ),
        );
      } else {
        setState(() {
          _error = response['message']?.toString() ??
              'Unable to generate Lal Kitab report.';
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
      if (name != null && name.trim().isNotEmpty) {
        _profileName = name.trim();
      }
      if (dob.isNotEmpty) {
        final date = DateTime.tryParse(dob);
        _dobController.text = date == null
            ? dob
            : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
      if (tob.isNotEmpty) {
        final parsed = _parseTime(tob);
        if (parsed != null) {
          final hour = parsed.hourOfPeriod == 0 ? 12 : parsed.hourOfPeriod;
          final minute = parsed.minute.toString().padLeft(2, '0');
          final period = parsed.period == DayPeriod.am ? 'AM' : 'PM';
          _tobController.text = '$hour:$minute $period';
        } else {
          _tobController.text = tob;
        }
      }
      if (pob.isNotEmpty) {
        _placeController.text = pob;
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
      builder: (context) => _LalRecentProfilesSheet(
        service: _recentProfiles,
        onSelected: _applyRecentProfile,
      ),
    );
  }

  void _applyRecentProfile(Map<String, dynamic> profile) {
    final dob = (profile['date_of_birth'] ?? '').toString();
    final tob = (profile['time_of_birth'] ?? '').toString();
    final pob =
        (profile['place_of_birth'] ?? profile['birth_place'] ?? '').toString();
    final location = _locationFromProfile(profile);
    setState(() {
      if (dob.isNotEmpty) {
        final date = DateTime.tryParse(dob);
        _dobController.text = date == null
            ? dob
            : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
      }
      if (tob.isNotEmpty) {
        final parsed = _parseTime(tob);
        if (parsed != null) {
          final hour = parsed.hourOfPeriod == 0 ? 12 : parsed.hourOfPeriod;
          final minute = parsed.minute.toString().padLeft(2, '0');
          final period = parsed.period == DayPeriod.am ? 'AM' : 'PM';
          _tobController.text = '$hour:$minute $period';
        } else {
          _tobController.text = tob;
        }
      }
      if (pob.isNotEmpty) _placeController.text = pob;
      _location = location;
      _error = null;
    });
  }

  void _onLocationSelected(LocationSelection? selection) {
    setState(() {
      _location = selection;
      _error = null;
    });
  }

  void _goBack() {
    MainNavigationState.returnHome(context);
  }

  Future<void> _pickDate() async {
    // Dismiss keyboard first
    FocusScope.of(context).unfocus();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _parseDate(_dobController.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => _goldTheme(context, child),
    );
    if (picked != null) {
      _dobController.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  Future<void> _pickTime() async {
    FocusScope.of(context).unfocus();
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _parseTime(_tobController.text) ?? TimeOfDay.now(),
      builder: (context, child) => _goldTheme(context, child),
    );
    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      _tobController.text = '$hour:$minute $period';
    }
  }

  /// Parse dd/MM/yyyy string back to DateTime for initialDate
  DateTime? _parseDate(String text) {
    try {
      final parts = text.split('/');
      if (parts.length == 3) {
        return DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
        );
      }
    } catch (_) {}
    return null;
  }

  /// Parse "h:mm AM/PM" string back to TimeOfDay for initialTime
  TimeOfDay? _parseTime(String text) {
    try {
      final trimmed = text.trim();
      final parts = trimmed.split(RegExp(r'\s+'));
      if (parts.length == 2) {
        final hm = parts[0].split(':');
        int hour = int.parse(hm[0]);
        final minute = int.parse(hm[1]);
        final isPm = parts[1].toUpperCase() == 'PM';
        if (isPm && hour != 12) hour += 12;
        if (!isPm && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
      final hm = trimmed.split(':');
      if (hm.length >= 2) {
        final hour = int.parse(hm[0]);
        final minute = int.parse(hm[1]);
        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          return TimeOfDay(hour: hour, minute: minute);
        }
      }
    } catch (_) {}
    return null;
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
    final place = (profile['place_of_birth'] ?? profile['birth_place'] ?? '')
        .toString()
        .trim();
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
        coordinates['longitude'] ?? coordinates['lng'] ?? coordinates['lon'],
      );
    }
    lat ??= _toDouble(
      profile['latitude'] ?? profile['lat'] ?? profile['birth_latitude'],
    );
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

  /// Applies gold accent to date/time picker dialogs
  Widget _goldTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: _AC.gold,
          onPrimary: Colors.white,
          onSurface: _AC.textPrimary,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _AC.gold),
        ),
      ),
      child: child!,
    );
  }

  @override
  void dispose() {
    _dobController.dispose();
    _tobController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, _AC.goldLight],
            begin: Alignment.topCenter,
            end: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              HeaderWidget(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _BackBar(onBack: _goBack),
                      const SizedBox(height: 10),

                      // ── Birth Inputs ──
                      _BirthInputsCard(
                        dobController: _dobController,
                        tobController: _tobController,
                        placeController: _placeController,
                        initialLocation: _location,
                        hasDetails: _hasDetails,
                        onGenerate: _onGenerate,
                        onChooseRecent: _showRecentProfiles,
                        onLocationSelected: _onLocationSelected,
                        onPickDate: _pickDate,
                        onPickTime: _pickTime,
                      ),

                      const SizedBox(height: 20),

                      // ── Analysis Section ──
                      if (_loading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_error != null)
                        _ErrorCard(message: _error!)
                      else
                        const SizedBox.shrink(),

                      const SizedBox(height: 24),
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
}

// ─────────────────────────────────────────────
// Ready To Generate Empty-State Card
// ─────────────────────────────────────────────
class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          height: 1.35,
        ),
      ),
    );
  }
}

class _LalKitabInput {
  final String name;
  final DateTime date;
  final TimeOfDay time;
  final String place;

  const _LalKitabInput({
    required this.name,
    required this.date,
    required this.time,
    required this.place,
  });
}

class _LalKitabResultScreen extends StatefulWidget {
  final _LalKitabInput input;
  final Map<String, dynamic> response;

  const _LalKitabResultScreen({required this.input, required this.response});

  @override
  State<_LalKitabResultScreen> createState() => _LalKitabResultScreenState();
}

class _LalKitabResultScreenState extends State<_LalKitabResultScreen> {
  int _index = 0;
  late final PageController _pageController;
  late final ScrollController _tabScrollController;
  late final List<GlobalKey> _tabKeys;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabScrollController = ScrollController();
    _tabKeys = List.generate(_tabs.length, (_) => GlobalKey());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  List<_LalTab> get _tabs {
    final report = _unwrapReport(widget.response);
    return [
      _LalTab(
        label: 'Debts',
        child: _LalDebtsSection(rows: _asList(report['debts'])),
      ),
      _LalTab(
        label: 'Houses',
        child: _LalTableSection(
          rows: _asList(report['houses']),
          emptyLabel: 'No house details returned.',
          columns: const [
            _LalColumn('House', 'khana_number', width: 72),
            _LalColumn('Maalik', 'maalik', width: 92),
            _LalColumn('Pakka\nGhar', 'pakka_ghar', width: 96),
            _LalColumn('Kismat', 'kismat', width: 88),
            _LalColumn('Soya', 'soya', width: 72),
            _LalColumn('Exalted', 'exalt', width: 90),
            _LalColumn('Debili-\ntated', 'debilitated', width: 100),
          ],
          fallbackBuilder: (index) => 'House ${index + 1}',
        ),
      ),
      _LalTab(
        label: 'Planets',
        child: _LalTableSection(
          rows: _asList(report['planets']),
          emptyLabel: 'No planet details returned.',
          columns: const [
            _LalColumn('Planet', 'planet', width: 88),
            _LalColumn('Rashi', 'rashi', width: 92),
            _LalColumn('Soya\nGraha', 'soya', width: 82),
            _LalColumn('Position', 'position', width: 108),
            _LalColumn('Nature', 'nature', width: 92),
          ],
          fallbackBuilder: (index) => 'Planet ${index + 1}',
        ),
      ),
    ];
  }

  void _setTab(int index) {
    setState(() => _index = index);
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
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

  void _safeBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _tabs;
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F0),
      body: SafeArea(
        child: Column(
          children: [
            HeaderWidget(),
            _resultHeader(),
            SizedBox(
              height: 48,
              child: ListView.separated(
                controller: _tabScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemCount: tabs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final selected = index == _index;
                  return KeyedSubtree(
                    key: _tabKeys[index],
                    child: ChoiceChip(
                      label: Text(tabs[index].label),
                      selected: selected,
                      onSelected: (_) => _setTab(index),
                      selectedColor: const Color(0xFF1E3557),
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color:
                            selected ? Colors.white : const Color(0xFF1E3557),
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                      side: BorderSide(
                        color: selected
                            ? const Color(0xFF1E3557)
                            : const Color(0xFFE8D6A4),
                      ),
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
                itemBuilder: (context, index) => ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
                  children: [
                    _ResultShell(
                      title: index == 0
                          ? 'Lal Kitab Debts'
                          : index == 1
                              ? 'Lal Kitab Houses'
                              : 'Lal Kitab Planets',
                      child: tabs[index].child,
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

  Widget _resultHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _safeBack,
            icon: const Icon(
              Icons.arrow_circle_left_rounded,
              color: Color(0xFF1E3557),
            ),
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
                    color: Color(0xFF1E3557),
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_formatInputDate(widget.input.date)} - ${_formatInputTime(widget.input.time)} - ${widget.input.place}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _ResultShell({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8D6A4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _AC.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _LalDebtsSection extends StatelessWidget {
  final List<Map<String, dynamic>> rows;

  const _LalDebtsSection({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _EmptyLalResult('No Lal Kitab debts returned.');
    }
    return Column(
      children: rows.asMap().entries.map((entry) {
        final index = entry.key;
        final debt = entry.value;
        return Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: index == rows.length - 1 ? 0 : 14),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: index.isEven
                ? const Color(0xFFFFF8CF)
                : const Color(0xFFFFEAEA),
            borderRadius: BorderRadius.circular(18),
            border: Border(
              left: BorderSide(
                color: index.isEven ? _AC.gold : const Color(0xFFE05A63),
                width: 4,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _display(debt['debt_name'], fallback: 'Lal Kitab Debt'),
                style: const TextStyle(
                  color: _AC.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              _NarrativeBlock(
                title: 'Indications',
                value: _display(debt['indications']),
              ),
              const SizedBox(height: 10),
              _NarrativeBlock(
                title: 'Effects',
                value: _display(debt['events']),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _LalTableSection extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  final String emptyLabel;
  final List<_LalColumn> columns;
  final String Function(int index)? fallbackBuilder;

  const _LalTableSection({
    required this.rows,
    required this.emptyLabel,
    required this.columns,
    this.fallbackBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return _EmptyLalResult(emptyLabel);
    final tableWidth = columns.fold<double>(
      0,
      (total, column) => total + column.width,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _ScrollHint(),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE8D6A4)),
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: tableWidth,
                child: Table(
                  columnWidths: {
                    for (var i = 0; i < columns.length; i++)
                      i: FixedColumnWidth(columns[i].width),
                  },
                  border: TableBorder.symmetric(
                    inside: const BorderSide(color: Color(0xFFE8E2D8)),
                  ),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFD7AF4B)),
                      children: columns
                          .map((column) => _TableHeaderCell(column.label))
                          .toList(),
                    ),
                    ...rows.asMap().entries.map((entry) {
                      final row = entry.value;
                      return TableRow(
                        decoration: BoxDecoration(
                          color: entry.key.isEven
                              ? Colors.white
                              : const Color(0xFFF8FAFC),
                        ),
                        children: columns.map((column) {
                          return _TableBodyCell(
                            _valueForColumn(row, column, entry.key),
                          );
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _valueForColumn(
    Map<String, dynamic> row,
    _LalColumn column,
    int index,
  ) {
    final value = row[column.key];
    if (value == null &&
        fallbackBuilder != null &&
        columns.isNotEmpty &&
        columns.first.key == column.key) {
      return fallbackBuilder!(index);
    }
    if (column.key == 'khana_number') {
      return _display(value, fallback: fallbackBuilder?.call(index));
    }
    return _display(value);
  }
}

class _ScrollHint extends StatelessWidget {
  const _ScrollHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAE8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8D6A4)),
      ),
      child: const Text(
        'Scroll table left or right',
        style: TextStyle(
          color: Color(0xFF8A6400),
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String label;

  const _TableHeaderCell(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      child: Text(
        label.toUpperCase(),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF1E3557),
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          height: 1.08,
        ),
      ),
    );
  }
}

class _TableBodyCell extends StatelessWidget {
  final String value;

  const _TableBodyCell(this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        value,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _AC.textPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.2,
        ),
      ),
    );
  }
}

class _NarrativeBlock extends StatelessWidget {
  final String title;
  final String value;

  const _NarrativeBlock({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: _AC.remedyText,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              color: _AC.textPrimary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniValueCard extends StatelessWidget {
  final String label;
  final String value;

  const _MiniValueCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 70),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9DFCB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _AC.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: _AC.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w400,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLalResult extends StatelessWidget {
  final String message;

  const _EmptyLalResult(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8D6A4)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: _AC.textSecondary, height: 1.35),
      ),
    );
  }
}

class _LalTab {
  final String label;
  final Widget child;

  const _LalTab({required this.label, required this.child});
}

class _LalField {
  final String label;
  final String key;

  const _LalField(this.label, this.key);
}

class _LalColumn {
  final String label;
  final String key;
  final double width;

  const _LalColumn(this.label, this.key, {required this.width});
}

Map<String, dynamic> _unwrapReport(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is Map) return Map<String, dynamic>.from(data);
  return response;
}

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is List) {
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
  return const [];
}

String _display(dynamic value, {Object? fallback}) {
  if (value == null || value == '') return fallback?.toString() ?? '-';
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is List) {
    if (value.isEmpty) return fallback?.toString() ?? '-';
    return value.map((item) => _display(item)).join(', ');
  }
  if (value is Map) {
    if (value.isEmpty) return fallback?.toString() ?? '-';
    return value.entries
        .map((entry) =>
            '${_titleCase(entry.key.toString())}: ${_display(entry.value)}')
        .join(' | ');
  }
  final text = value.toString().trim();
  return text.isEmpty ? fallback?.toString() ?? '-' : text;
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _formatInputDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

String _formatInputTime(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

// ─────────────────────────────────────────────
// Birth Inputs Card
// ─────────────────────────────────────────────
class _BirthInputsCard extends StatelessWidget {
  final TextEditingController dobController;
  final TextEditingController tobController;
  final TextEditingController placeController;
  final LocationSelection? initialLocation;
  final bool hasDetails;
  final Future<void> Function() onGenerate;
  final VoidCallback onChooseRecent;
  final ValueChanged<LocationSelection?> onLocationSelected;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;

  const _BirthInputsCard({
    required this.dobController,
    required this.tobController,
    required this.placeController,
    required this.initialLocation,
    required this.hasDetails,
    required this.onGenerate,
    required this.onChooseRecent,
    required this.onLocationSelected,
    required this.onPickDate,
    required this.onPickTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Birth Inputs',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _AC.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onChooseRecent,
            icon: const Icon(Icons.history),
            label: const Text('Choose a recent profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _AC.remedyText,
              side: const BorderSide(color: _AC.gold),
              backgroundColor: _AC.goldLight,
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _InputField(
            label: 'Date of Birth',
            controller: dobController,
            suffixIcon: Icons.calendar_today_outlined,
            readOnly: true,
            onTap: onPickDate,
            hint: 'DD/MM/YYYY',
          ),
          const SizedBox(height: 10),
          _InputField(
            label: 'Time of Birth',
            controller: tobController,
            suffixIcon: Icons.access_time_outlined,
            readOnly: true,
            onTap: onPickTime,
            hint: 'HH:MM AM/PM',
          ),
          const SizedBox(height: 10),
          const Text(
            'Birth Place',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _AC.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          LocationSearchField(
            controller: placeController,
            initialSelection: initialLocation,
            onSelected: onLocationSelected,
            hintText: 'Search city and select from list',
            decoration: InputDecoration(
              hintText: 'City, State, Country',
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: const Icon(
                Icons.location_on_outlined,
                color: _AC.gold,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _AC.gold, width: 1.4),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasDetails ? () => onGenerate() : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _AC.gold,
                disabledBackgroundColor: _AC.gold.withValues(alpha: 0.45),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white70,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Generate Lal Kitab Report',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData suffixIcon;
  final String? hint;
  final bool readOnly;
  final VoidCallback? onTap;

  const _InputField({
    required this.label,
    required this.controller,
    required this.suffixIcon,
    this.hint,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _AC.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
          // Show cursor even in readOnly so it looks interactive
          showCursor: true,
          style: const TextStyle(fontSize: 14, color: _AC.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
            suffixIcon: GestureDetector(
              onTap: onTap,
              child: Icon(suffixIcon, size: 18, color: _AC.textSecondary),
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _AC.gold),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _LalRecentProfilesSheet extends StatefulWidget {
  final RecentProfileService service;
  final ValueChanged<Map<String, dynamic>> onSelected;

  const _LalRecentProfilesSheet({
    required this.service,
    required this.onSelected,
  });

  @override
  State<_LalRecentProfilesSheet> createState() =>
      _LalRecentProfilesSheetState();
}

class _LalRecentProfilesSheetState extends State<_LalRecentProfilesSheet> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
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
                      color: _AC.textPrimary,
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
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          )
                        : _items.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(18),
                                  child: Text(
                                    'No recent profiles yet. Generate any report once and it will appear here.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: _AC.textSecondary),
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
                                  final title = (profile['profile_label'] ??
                                          profile['person_name'] ??
                                          profile['name'] ??
                                          'Saved Profile')
                                      .toString();
                                  final subtitle = [
                                    profile['date_of_birth'],
                                    profile['time_of_birth'],
                                    profile['place_of_birth'],
                                  ]
                                      .where((item) =>
                                          item != null &&
                                          item.toString().trim().isNotEmpty)
                                      .join(' • ');
                                  return ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: const BorderSide(
                                          color: Color(0xFFE6D7BA)),
                                    ),
                                    leading: const CircleAvatar(
                                      backgroundColor: _AC.goldLight,
                                      child: Icon(Icons.person_outline,
                                          color: _AC.gold),
                                    ),
                                    title: Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w900),
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
