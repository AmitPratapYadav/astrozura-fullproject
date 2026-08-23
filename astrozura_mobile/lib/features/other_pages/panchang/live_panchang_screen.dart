import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/astrology_service.dart';
import '../../main_navigation.dart';
import '../../mainwidgets/header.dart';
import '../../shared/widgets/location_search_field.dart';

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
  int _dailyTabIndex = 0;
  int _elementTabIndex = 0;

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
      final payload = {
        'datetime': _kolkataDateTime(_selectedDate, 6, 0),
        'coordinates': location.coordinates,
        'ayanamsa': 1,
        'mode': _modeKey,
        'la': _languageCodes[_language] ?? 'en',
      };
      final response = await _service.panchang(payload);

      final data = _asMap(response['data']);
      if (widget.mode == PanchangMode.daily) {
        try {
          final extrasResponse = await _service.panchangExtras({
            ...payload,
            'extras': [
              'planetary_positions',
              'sunrise_planetary_positions',
              'panchang_chart',
              'panchang_festival',
              'panchang_lagna_table',
            ],
          });
          final extras = _asMap(extrasResponse['data']);
          final panchang = _asMap(data['panchang']);
          data['panchang'] = {
            ...panchang,
            'planetary_positions': extras['planetary_positions'] ??
                panchang['planetary_positions'],
            'sunrise_planetary_positions':
                extras['sunrise_planetary_positions'] ??
                    panchang['sunrise_planetary_positions'],
            'chart': extras['panchang_chart'] ?? panchang['chart'],
            'festival': extras['panchang_festival'] ?? panchang['festival'],
            'lagna_table':
                extras['panchang_lagna_table'] ?? panchang['lagna_table'],
          };
        } catch (_) {
          // Core Panchang is still useful if an optional extras API is unavailable.
        }
      }
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
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _topModeTabs(),
                          const SizedBox(height: 10),
                          _filters(),
                          const SizedBox(height: 12),
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
      ),
    );
  }

  Widget _topModeTabs() {
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: _goBack,
          icon: const Icon(Icons.arrow_circle_left_rounded, color: _textDark),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _modeChip(PanchangMode.daily, 'Daily Panchang'),
                _modeChip(PanchangMode.chaughadiya, 'Chaughadiya'),
                _modeChip(PanchangMode.hora, 'Hora'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _modeChip(PanchangMode mode, String label) {
    final selected = widget.mode == mode;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => _openMode(mode),
        selectedColor: const Color(0xFF1E3557),
        backgroundColor: Colors.white,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: const VisualDensity(horizontal: -3, vertical: -3),
        labelStyle: TextStyle(
          color: selected ? Colors.white : const Color(0xFF1E3557),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
        side: BorderSide(color: selected ? const Color(0xFF1E3557) : _gold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  int _modeNavigationIndex(PanchangMode mode) => switch (mode) {
        PanchangMode.daily => 8,
        PanchangMode.chaughadiya => 9,
        PanchangMode.hora => 10,
      };

  void _openMode(PanchangMode mode) {
    if (widget.mode == mode) return;
    if (MainNavigationState.activateIndex(_modeNavigationIndex(mode))) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LivePanchangScreen(mode: mode),
      ),
    );
  }

  void _goBack() {
    final navigationHandled = MainNavigationState.goHome();
    final navigator = Navigator.of(context, rootNavigator: true);
    if (!navigator.canPop()) {
      if (!navigationHandled) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => const MainNavigation(initialIndex: 0),
          ),
          (_) => false,
        );
      }
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const MainNavigation(initialIndex: 0),
      ),
      (_) => false,
    );
  }

  Widget _filters() {
    const compactInputTextStyle = TextStyle(
      color: _textDark,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.15,
    );

    final compactLocationDecoration = InputDecoration(
      hintText: 'Search city for Panchang',
      hintStyle: const TextStyle(
        color: Color(0xFF94A3B8),
        fontSize: 13.5,
        fontWeight: FontWeight.w500,
      ),
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      prefixIcon:
          const Icon(Icons.location_on_outlined, size: 18, color: _textGrey),
      prefixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 34),
      suffixIconConstraints: const BoxConstraints(minWidth: 38, minHeight: 34),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: _gold, width: 1.2),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('SELECT DATE', Icons.calendar_today_outlined),
        const SizedBox(height: 4),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(9),
          child: _fieldShell(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formattedDate, style: compactInputTextStyle),
                const Icon(Icons.calendar_month_outlined,
                    size: 17, color: _textGrey),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _label('LOCATION', Icons.location_on_outlined),
        const SizedBox(height: 4),
        LocationSearchField(
          controller: _locationCtrl,
          initialSelection: _location,
          hintText: 'Search city for Panchang',
          decoration: compactLocationDecoration,
          style: compactInputTextStyle,
          onSelected: (selection) async {
            setState(() => _location = selection);
            if (selection != null) await _fetch();
          },
        ),
        const SizedBox(height: 8),
        _label('LANGUAGE', Icons.translate_outlined),
        const SizedBox(height: 4),
        _fieldShell(
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _language,
              isExpanded: true,
              isDense: true,
              style: compactInputTextStyle,
              icon: const Icon(Icons.keyboard_arrow_down,
                  size: 20, color: _textGrey),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ],
    );
  }

  Widget _dailyContent() {
    final summary = _asMap(_data['summary']);
    final panchang = _asMap(_data['panchang']);
    final advanced = _asMap(panchang['advanced']);
    final basic = _asMap(panchang['basic']);
    final hinduMaah = _asMap(advanced['hindu_maah']);
    final tabs = [
      _PanchangContentTab(
        'Overview',
        Icons.today_outlined,
        () => _dailyOverview(summary, advanced, basic, hinduMaah, panchang),
      ),
      _PanchangContentTab(
        'Elements',
        Icons.blur_circular_outlined,
        () => _panchangElementsTab(summary, advanced),
      ),
      _PanchangContentTab(
        'Lagna',
        Icons.table_chart_outlined,
        () => _recordTableTab(panchang['lagna_table']),
      ),
      _PanchangContentTab(
        'Chart',
        Icons.pie_chart_outline,
        () => _recordTableTab(panchang['chart']),
      ),
      _PanchangContentTab(
        'Planets',
        Icons.public_outlined,
        () => _recordTableTab(panchang['planetary_positions']),
      ),
      _PanchangContentTab(
        'Sunrise Planets',
        Icons.wb_twilight,
        () => _recordTableTab(panchang['sunrise_planetary_positions']),
      ),
    ];
    final index = _dailyTabIndex.clamp(0, tabs.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _contentTabs(tabs, index),
        const SizedBox(height: 12),
        tabs[index].builder(),
      ],
    );
  }

  Widget _dailyOverview(
    Map<String, dynamic> summary,
    Map<String, dynamic> advanced,
    Map<String, dynamic> basic,
    Map<String, dynamic> hinduMaah,
    Map<String, dynamic> panchang,
  ) {
    return Column(
      children: [
        _compactSection('Sun & Moon', Icons.wb_sunny_outlined, [
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
        _compactSection('Hindu Month & Year', Icons.auto_awesome_outlined, [
          _row('Vikram Samvat',
              _value(advanced['vikram_samvat'] ?? basic['vikram_samvat'])),
          _row(
              'Vikram Samvat Name',
              _value(
                  advanced['vkram_samvat_name'] ?? basic['vkram_samvat_name'])),
          _row('Shaka Samvat',
              _value(advanced['shaka_samvat'] ?? basic['shaka_samvat'])),
          _row(
              'Shaka Samvat Name',
              _value(
                  advanced['shaka_samvat_name'] ?? basic['shaka_samvat_name'])),
          _row(
              'Paksha',
              _value(advanced['paksha'] ??
                  _asMap(advanced['tithi'])['paksha'] ??
                  basic['paksha'])),
          _row('Ritu', _value(advanced['ritu'] ?? basic['ritu'])),
          _row('Ayana',
              _value(advanced['ayan'] ?? advanced['ayana'] ?? basic['ayana'])),
          _row(
              'Purnimanta',
              _value(hinduMaah['purnimanta'] ??
                  advanced['purnimanta'] ??
                  basic['purnimanta'])),
          _row('Amanta', _value(hinduMaah['amanta'] ?? advanced['amanta'])),
          _row(
              'Adhik Maas',
              _value(hinduMaah['adhik_status'] == null
                  ? null
                  : (hinduMaah['adhik_status'] == true ? 'Yes' : 'No'))),
          _row('Sun Sign', _value(advanced['sun_sign'] ?? basic['sun_sign'])),
          _row(
              'Moon Sign', _value(advanced['moon_sign'] ?? basic['moon_sign'])),
        ]),
        _festivalSection(panchang['festival']),
        _compactSection('Auspicious Timings', Icons.check_circle_outline, [
          _row('Abhijit Muhurta', _range(_asMap(advanced['abhijit_muhurta']))),
          _row('Amrit Kalam', _range(_asMap(advanced['amrit_kalam']))),
          _row('Panchang Yog', _value(advanced['panchang_yog'])),
        ]),
        _compactSection('Inauspicious Timings', Icons.cancel_outlined, [
          _row('Rahu Kalam', _range(_asMap(advanced['rahukaal']))),
          _row('Gulika Kalam', _range(_asMap(advanced['guliKaal']))),
          _row('Yamghant Kalam', _range(_asMap(advanced['yamghant_kaal']))),
        ]),
        _compactSection('Shool & Nivas', Icons.self_improvement_outlined, [
          _row('Disha Shool', _value(advanced['disha_shool'])),
          _row(
              'Nakshatra Shool',
              _value(_asMap(advanced['nak_shool'])['direction'] ??
                  advanced['nakshatra_shool'])),
          _row('Moon Nivas',
              _value(advanced['moon_nivas'] ?? advanced['moon_nivash'])),
        ]),
      ],
    );
  }

  Widget _contentTabs(List<_PanchangContentTab> tabs, int selectedIndex) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          final tab = tabs[index];
          return ChoiceChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tab.icon,
                  size: 14,
                  color: selected ? Colors.white : const Color(0xFF1E3557),
                ),
                const SizedBox(width: 5),
                Text(tab.label),
              ],
            ),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => setState(() => _dailyTabIndex = index),
            selectedColor: const Color(0xFF1E3557),
            backgroundColor: Colors.white,
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: const VisualDensity(horizontal: -2, vertical: -3),
            labelStyle: TextStyle(
              color: selected ? Colors.white : const Color(0xFF1E3557),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
            side: BorderSide(color: selected ? const Color(0xFF1E3557) : _gold),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999)),
          );
        },
      ),
    );
  }

  Widget _panchangElementsTab(
    Map<String, dynamic> summary,
    Map<String, dynamic> advanced,
  ) {
    final tabs = [
      _ElementContentTab(
        'Tithi',
        _elementRows(
          summary['current_tithi'],
          _asMap(advanced['tithi']),
          {
            'Number': 'tithi_number',
            'Name': 'tithi_name',
            'Paksha': 'paksha',
            'Special': 'special',
            'Deity': 'deity',
            'Summary': 'summary',
          },
        ),
      ),
      _ElementContentTab(
        'Nakshatra',
        _elementRows(
          summary['current_nakshatra'],
          _asMap(advanced['nakshatra']),
          {
            'Number': 'nak_number',
            'Name': 'nak_name',
            'Ruler': 'ruler',
            'Deity': 'deity',
            'Special': 'special',
            'Summary': 'summary',
          },
        ),
      ),
      _ElementContentTab(
        'Yog',
        _elementRows(
          summary['current_yoga'],
          _asMap(advanced['yog']),
          {
            'Number': 'yog_number',
            'Name': 'yog_name',
            'Special': 'special',
            'Meaning': 'meaning',
          },
        ),
      ),
      _ElementContentTab(
        'Karan',
        _elementRows(
          summary['current_karana'],
          _asMap(advanced['karan']),
          {
            'Number': 'karan_number',
            'Name': 'karan_name',
            'Special': 'special',
            'Deity': 'deity',
          },
        ),
      ),
    ];
    final visibleTabs = tabs.where((tab) => tab.rows.isNotEmpty).toList();
    if (visibleTabs.isEmpty) {
      return _errorCard(message: 'Panchang element details are unavailable.');
    }
    final index = _elementTabIndex.clamp(0, visibleTabs.length - 1);
    final selected = visibleTabs[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: visibleTabs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, tabIndex) {
              final isSelected = tabIndex == index;
              return ChoiceChip(
                label: Text(visibleTabs[tabIndex].label),
                selected: isSelected,
                showCheckmark: false,
                onSelected: (_) => setState(() => _elementTabIndex = tabIndex),
                selectedColor: const Color(0xFFD7AF4B),
                backgroundColor: Colors.white,
                labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity:
                    const VisualDensity(horizontal: -2, vertical: -3),
                labelStyle: TextStyle(
                  color: isSelected
                      ? const Color(0xFF1E3557)
                      : const Color(0xFF334155),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                ),
                side: BorderSide(
                  color: isSelected ? const Color(0xFFD7AF4B) : _border,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _compactKeyValueTable(selected.rows),
      ],
    );
  }

  List<_DisplayRow> _elementRows(
    dynamic summaryValue,
    Map<String, dynamic> element,
    Map<String, String> fields,
  ) {
    final summary = _asMap(summaryValue);
    final details = _asMap(element['details']);
    final rows = <_DisplayRow>[
      if (_value(summary['name'] ?? summary['value']) != '--')
        _row('Current', _value(summary['name'] ?? summary['value'])),
      for (final entry in fields.entries)
        _row(entry.key, _value(details[entry.value])),
      _row('Ends At', _endTime(element)),
    ];
    return rows.where((row) => row.value != '--').toList();
  }

  Widget _compactSection(String title, IconData icon, List<_DisplayRow> rows) {
    final visible = rows.where((item) => item.value != '--').toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _compactSectionHeader(title, icon),
          const SizedBox(height: 7),
          _compactKeyValueTable(visible),
        ],
      ),
    );
  }

  Widget _compactSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: _gold, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1E3557),
            ),
          ),
        ),
      ],
    );
  }

  Widget _compactKeyValueTable(List<_DisplayRow> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8D6A4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(0.88),
            1: FlexColumnWidth(1.42),
          },
          border: TableBorder.symmetric(
            inside: const BorderSide(color: Color(0xFFE8E2D8)),
          ),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            const TableRow(
              decoration: BoxDecoration(color: Color(0xFFD7AF4B)),
              children: [
                _PanchangTableHeader('Attribute'),
                _PanchangTableHeader('Value'),
              ],
            ),
            ...rows.asMap().entries.map(
                  (entry) => TableRow(
                    decoration: BoxDecoration(
                      color: entry.key.isEven
                          ? Colors.white
                          : const Color(0xFFFFFCF4),
                    ),
                    children: [
                      _PanchangTableCell(entry.value.label, attribute: true),
                      _PanchangTableCell(entry.value.value),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _recordTableTab(dynamic payload, {bool singleColumn = false}) {
    final records = _normalizeRecords(payload);
    if (records.isEmpty) {
      return _errorCard(message: 'This Panchang table is unavailable.');
    }
    if (singleColumn || (records.length == 1 && records.first.length > 4)) {
      final rows = records
          .expand((record) => record.entries)
          .where((entry) => _value(entry.value) != '--')
          .map((entry) => _row(_titleize(entry.key), _value(entry.value)))
          .toList();
      return _compactKeyValueTable(rows);
    }
    return _DynamicPanchangTable(records: records);
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

  Widget _festivalSection(dynamic payload) {
    final rows = _normalizeRecords(payload);
    if (rows.isEmpty) {
      return _compactSection('Festival & Vrat', Icons.celebration_outlined, [
        _row('Festival', 'No festival returned'),
      ]);
    }
    final displayRows = <_DisplayRow>[];
    for (var i = 0; i < rows.length; i++) {
      for (final entry in rows[i].entries) {
        final value = _value(entry.value);
        if (value == '--') continue;
        final label = rows.length == 1
            ? _titleize(entry.key)
            : '${_titleize(entry.key)} ${i + 1}';
        displayRows.add(_row(label, value));
      }
    }
    return _compactSection(
      'Festival & Vrat',
      Icons.celebration_outlined,
      displayRows,
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
        Icon(icon, size: 12, color: _textGrey),
        const SizedBox(width: 3),
        Text(
          text,
          style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: _textGrey),
        ),
      ],
    );
  }

  Widget _fieldShell(Widget child,
      {EdgeInsetsGeometry padding =
          const EdgeInsets.symmetric(horizontal: 12, vertical: 9)}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9),
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

  static List<Map<String, dynamic>> _normalizeRecords(dynamic payload) {
    if (payload == null || payload == '') return [];
    if (payload is List) {
      return payload
          .map((item) {
            if (item is Map) return Map<String, dynamic>.from(item);
            return {'value': item};
          })
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      final nestedList = map['data'] ??
          map['items'] ??
          map['records'] ??
          map['planetary_positions'] ??
          map['planets'] ??
          map['chart'] ??
          map['festival'] ??
          map['festivals'] ??
          map['lagna_table'];
      if (nestedList is List) return _normalizeRecords(nestedList);
      if (map.values.every((value) => value is Map)) {
        return map.entries
            .map((entry) => {
                  'name': _titleize(entry.key),
                  ...Map<String, dynamic>.from(entry.value as Map),
                })
            .toList();
      }
      return [map];
    }
    return [
      {'value': payload}
    ];
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

  static String _endTime(Map<String, dynamic> element) {
    final direct = _value(element['end']);
    if (direct != '--') return _formatDateTime(direct);
    final endTime = _asMap(element['end_time']);
    final hour = endTime['hour'];
    final minute = endTime['minute'];
    final second = endTime['second'];
    if (hour == null || minute == null) return '--';
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${(second ?? 0).toString().padLeft(2, '0')}';
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

  static String _titleize(String value) {
    final spaced = value.replaceAll('_', ' ').replaceAll('-', ' ');
    return spaced
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
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

class _PanchangContentTab {
  final String label;
  final IconData icon;
  final Widget Function() builder;

  const _PanchangContentTab(this.label, this.icon, this.builder);
}

class _ElementContentTab {
  final String label;
  final List<_DisplayRow> rows;

  const _ElementContentTab(this.label, this.rows);
}

class _DynamicPanchangTable extends StatelessWidget {
  final List<Map<String, dynamic>> records;

  const _DynamicPanchangTable({required this.records});

  @override
  Widget build(BuildContext context) {
    final usefulRecords = records
        .map((record) => Map<String, dynamic>.fromEntries(
              record.entries.where(
                (entry) => _LivePanchangScreenState._value(entry.value) != '--',
              ),
            ))
        .where((record) => record.isNotEmpty)
        .toList();
    if (usefulRecords.isEmpty) return const SizedBox.shrink();
    final columns = _columns(usefulRecords);
    final tableWidth =
        columns.fold<double>(0, (total, column) => total + column.width);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = tableWidth < constraints.maxWidth
            ? constraints.maxWidth
            : tableWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE8D6A4)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SizedBox(
                width: width,
                child: Table(
                  columnWidths: {
                    for (var i = 0; i < columns.length; i++)
                      i: FixedColumnWidth(
                        width * (columns[i].width / tableWidth),
                      ),
                  },
                  border: TableBorder.symmetric(
                    inside: const BorderSide(color: Color(0xFFE8E2D8)),
                  ),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFD7AF4B)),
                      children: columns
                          .map((column) => _PanchangTableHeader(column.label))
                          .toList(),
                    ),
                    ...usefulRecords.asMap().entries.map(
                          (entry) => TableRow(
                            decoration: BoxDecoration(
                              color: entry.key.isEven
                                  ? Colors.white
                                  : const Color(0xFFFFFCF4),
                            ),
                            children: columns.asMap().entries.map((column) {
                              return _PanchangTableCell(
                                _LivePanchangScreenState._value(
                                  entry.value[column.value.key],
                                ),
                                attribute: column.key == 0,
                              );
                            }).toList(),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<_PanchangColumn> _columns(List<Map<String, dynamic>> rows) {
    const preferred = [
      'name',
      'lagna',
      'planet',
      'rashi',
      'sign',
      'house',
      'degree',
      'full_degree',
      'norm_degree',
      'nakshatra',
      'pada',
      'lord',
      'start',
      'start_time',
      'end',
      'end_time',
      'time',
      'duration',
    ];
    final keys = <String>[];
    for (final key in preferred) {
      if (rows.any((row) => row.containsKey(key))) keys.add(key);
    }
    for (final row in rows) {
      for (final key in row.keys) {
        if (!keys.contains(key)) keys.add(key);
      }
    }
    return keys.map((key) {
      final label = _LivePanchangScreenState._titleize(key);
      final width = label.length > 13 ? 126.0 : 104.0;
      return _PanchangColumn(key, label, width);
    }).toList();
  }
}

class _PanchangColumn {
  final String key;
  final String label;
  final double width;

  const _PanchangColumn(this.key, this.label, this.width);
}

class _PanchangTableHeader extends StatelessWidget {
  final String label;

  const _PanchangTableHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      child: Text(
        label.toUpperCase(),
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFF1E3557),
          fontSize: 10.5,
          height: 1.08,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PanchangTableCell extends StatelessWidget {
  final String value;
  final bool attribute;

  const _PanchangTableCell(this.value, {this.attribute = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
      child: Text(
        value,
        textAlign: TextAlign.center,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: const Color(0xFF102A52),
          fontSize: attribute ? 11.5 : 11,
          height: 1.12,
          fontWeight: attribute ? FontWeight.w900 : FontWeight.w400,
        ),
      ),
    );
  }
}
