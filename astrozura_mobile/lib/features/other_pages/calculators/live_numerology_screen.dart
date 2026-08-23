import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/astrology_service.dart';
import '../../../core/services/recent_profile_service.dart';
import '../../main_navigation.dart';
import '../../mainwidgets/header.dart';

class LiveNumerologyScreen extends StatefulWidget {
  const LiveNumerologyScreen({super.key});

  @override
  State<LiveNumerologyScreen> createState() => _LiveNumerologyScreenState();
}

class _LiveNumerologyScreenState extends State<LiveNumerologyScreen> {
  final _name = TextEditingController();
  final AstrologyService _service = AstrologyService();
  final RecentProfileService _recentProfiles = RecentProfileService();
  DateTime? _date;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  Future<void> _prefill() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _name.text = prefs.getString('user_name') ?? '';
      _date = DateTime.tryParse(prefs.getString('user_dob') ?? '');
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(1995),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _date = date);
  }

  void _showRecentProfiles() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NumerologyRecentProfilesSheet(
        service: _recentProfiles,
        onSelected: _applyRecentProfile,
      ),
    );
  }

  void _applyRecentProfile(Map<String, dynamic> profile) {
    final name = _profileString(
      profile['profile_label'] ?? profile['person_name'] ?? profile['name'],
    );
    final dob = _profileString(profile['date_of_birth'] ?? profile['dob']);
    setState(() {
      if (name.isNotEmpty) _name.text = name;
      if (dob.isNotEmpty) _date = _parseProfileDate(dob);
      _error = null;
    });
  }

  Future<void> _run() async {
    if (_date == null) {
      setState(() => _error = 'Date of birth is required.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await _service.numerology({
        'name': _name.text.trim(),
        'date_of_birth':
            '${_date!.year.toString().padLeft(4, '0')}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
      });
      if (!mounted) return;
      setState(() => _loading = false);
      if (response['status'] == 'success') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => NumerologyResultScreen(
              name: _name.text.trim().isEmpty
                  ? 'Numerology Report'
                  : _name.text.trim(),
              dateOfBirth:
                  '${_date!.day.toString().padLeft(2, '0')}/${_date!.month.toString().padLeft(2, '0')}/${_date!.year}',
              response: response,
            ),
          ),
        );
      } else {
        setState(() {
          _error = response['message']?.toString() ?? 'Request failed.';
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

  @override
  Widget build(BuildContext context) {
    return _SimpleToolScaffold(
      title: 'Detailed Numerology',
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
            onPressed: _showRecentProfiles,
            icon: const Icon(Icons.history_rounded, size: 16),
            label: const Text('Choose Previous Profile'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 34),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _name,
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            labelText: 'Full name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(
            _date == null
                ? 'Select date of birth'
                : '${_date!.day}/${_date!.month}/${_date!.year}',
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 46,
          child: ElevatedButton(
            onPressed: _loading ? null : _run,
            child: const Text('Generate Numerology Report'),
          ),
        ),
        _ToolResult(loading: _loading, error: _error),
      ],
    );
  }

  DateTime? _parseProfileDate(String text) {
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
}

class _NumerologyRecentProfilesSheet extends StatefulWidget {
  final RecentProfileService service;
  final ValueChanged<Map<String, dynamic>> onSelected;

  const _NumerologyRecentProfilesSheet({
    required this.service,
    required this.onSelected,
  });

  @override
  State<_NumerologyRecentProfilesSheet> createState() =>
      _NumerologyRecentProfilesSheetState();
}

class _NumerologyRecentProfilesSheetState
    extends State<_NumerologyRecentProfilesSheet> {
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
                                        profile['birth_place'],
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

String _profileString(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

class NumerologyResultScreen extends StatefulWidget {
  final String name;
  final String dateOfBirth;
  final Map<String, dynamic> response;

  const NumerologyResultScreen({
    super.key,
    required this.name,
    required this.dateOfBirth,
    required this.response,
  });

  @override
  State<NumerologyResultScreen> createState() => _NumerologyResultScreenState();
}

class _NumerologyResultScreenState extends State<NumerologyResultScreen>
    with SingleTickerProviderStateMixin {
  late final List<_NumerologyTab> _tabs;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabs = _buildNumerologyTabs(widget.response);
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E8),
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE6D7BA)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_circle_left_rounded),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E8),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: const Color(0xFFE6D7BA)),
                      ),
                      child: Image.asset(
                        'assets/images/calculators/detailed_numerology.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF1E3557),
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.dateOfBirth,
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 38,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF1E3557),
                labelStyle: const TextStyle(
                  fontSize: 11.2,
                  fontWeight: FontWeight.w900,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 11.2,
                  fontWeight: FontWeight.w800,
                ),
                indicator: BoxDecoration(
                  color: const Color(0xFF1E3557),
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                labelPadding: const EdgeInsets.symmetric(horizontal: 5),
                tabs: _tabs
                    .map(
                      (tab) => Tab(
                        height: 34,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(tab.title),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _tabs.map((tab) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 30),
                    children: [
                      _NumerologyTabBody(value: tab.value),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleToolScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SimpleToolScaffold({required this.title, required this.children});

  void _goBack(BuildContext context) {
    MainNavigationState.returnHome(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        onPressed: () => _goBack(context),
                        icon: const Icon(Icons.arrow_circle_left_rounded),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E3557),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolResult extends StatelessWidget {
  final bool loading;
  final String? error;

  const _ToolResult({required this.loading, this.error});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(30),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Text(error!, style: const TextStyle(color: Colors.redAccent)),
      );
    }
    return const SizedBox.shrink();
  }
}

class _NumerologyTabBody extends StatelessWidget {
  final dynamic value;

  const _NumerologyTabBody({required this.value});

  @override
  Widget build(BuildContext context) {
    final clean = _numerologyCleanValue(value);
    if (_numerologyIsEmpty(clean)) {
      return const _NumerologyEmptyState();
    }

    final records = _numerologyRecordList(clean);
    if (records.isNotEmpty) {
      return _NumerologyRecordTable(records: records);
    }

    final map = _asMap(clean);
    if (map.isEmpty) {
      return _NumerologyNarrativeBlock(
        title: '',
        text: _numerologyValue(clean),
      );
    }

    final numberItems = <_NumerologyNumberItem>[];
    final tableRows = <MapEntry<String, dynamic>>[];
    final narrativeBlocks = <_NumerologyNarrativeBlock>[];
    final nestedWidgets = <Widget>[];

    for (final entry in map.entries) {
      if (_numerologyShouldHideKey(entry.key) ||
          _numerologyIsEmpty(entry.value)) {
        continue;
      }
      final itemValue = _numerologyCleanValue(entry.value);
      final nestedRecords = _numerologyRecordList(itemValue);
      if (nestedRecords.isNotEmpty) {
        nestedWidgets.add(_NumerologyRecordTable(records: nestedRecords));
        continue;
      }

      final nestedMap = _asMap(itemValue);
      if (nestedMap.isNotEmpty && !_numerologyPrimitiveMap(nestedMap)) {
        nestedWidgets.add(_NumerologyTabBody(value: nestedMap));
        continue;
      }

      final text = _numerologyValue(itemValue);
      if (text == '-') continue;
      if (_isNumerologyNumberKey(entry.key) && _isCompactNumberText(text)) {
        numberItems.add(_NumerologyNumberItem(
          label: _friendlyTitle(entry.key),
          value: text,
        ));
      }
      if (_isNumerologyNarrativeKey(entry.key) || text.length > 110) {
        narrativeBlocks.add(_NumerologyNarrativeBlock(
          title: _numerologyNarrativeTitle(entry.key),
          text: text,
        ));
      } else {
        tableRows.add(MapEntry(_friendlyTitle(entry.key), itemValue));
      }
    }

    final children = <Widget>[
      if (numberItems.isNotEmpty) _NumerologyNumberGrid(items: numberItems),
      if (tableRows.isNotEmpty) _NumerologyKeyValueTable(rows: tableRows),
      ...nestedWidgets,
      ...narrativeBlocks,
    ];
    if (children.isEmpty) return const _NumerologyEmptyState();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _NumerologyNumberItem {
  final String label;
  final String value;

  const _NumerologyNumberItem({required this.label, required this.value});
}

class _NumerologyNumberGrid extends StatelessWidget {
  final List<_NumerologyNumberItem> items;

  const _NumerologyNumberGrid({required this.items});

  static const _colors = [
    Color(0xFFE0529F),
    Color(0xFF8A22D8),
    Color(0xFF6D28D9),
    Color(0xFF149144),
    Color(0xFF0EA5A4),
    Color(0xFF2563EB),
    Color(0xFFDC6B19),
    Color(0xFFBE123C),
    Color(0xFF475569),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 360 ? 4 : 3;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.9,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          final color = _colors[index % _colors.length];
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE6D7BA)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      item.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        height: 1,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF1E3557),
                    fontSize: 10.5,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

class _NumerologyKeyValueTable extends StatelessWidget {
  final List<MapEntry<String, dynamic>> rows;

  const _NumerologyKeyValueTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    final visible = rows
        .where((entry) =>
            !_numerologyShouldHideKey(entry.key) &&
            !_numerologyIsEmpty(entry.value))
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
            0: FlexColumnWidth(0.88),
            1: FlexColumnWidth(1.12),
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
                    entry.key.isEven ? Colors.white : const Color(0xFFF8FAFC),
              ),
              children: [
                _NumerologyTableCell(row.key, attribute: true),
                _NumerologyTableCell(_numerologyValue(row.value)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NumerologyRecordTable extends StatelessWidget {
  final List<Map<String, dynamic>> records;

  const _NumerologyRecordTable({required this.records});

  @override
  Widget build(BuildContext context) {
    final cleaned = records
        .map((record) => Map<String, dynamic>.from(record)
          ..removeWhere((key, value) =>
              _numerologyShouldHideKey(key) || _numerologyIsEmpty(value)))
        .where((record) => record.isNotEmpty)
        .toList();
    if (cleaned.isEmpty) return const SizedBox.shrink();
    if (cleaned.length == 1) {
      return _NumerologyKeyValueTable(rows: cleaned.first.entries.toList());
    }

    final columns = _numerologyColumns(cleaned);
    if (columns.isEmpty) return const SizedBox.shrink();
    final tableWidth = columns.fold<double>(
      0,
      (sum, column) => sum + _numerologyColumnWidth(column),
    );
    return LayoutBuilder(builder: (context, constraints) {
      final effectiveWidth =
          tableWidth < constraints.maxWidth ? constraints.maxWidth : tableWidth;
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
                for (var index = 0; index < columns.length; index++)
                  index: FixedColumnWidth(
                    effectiveWidth *
                        (_numerologyColumnWidth(columns[index]) / tableWidth),
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
                      .map((column) => _NumerologyTableCell(
                          _friendlyTitle(column),
                          header: true))
                      .toList(),
                ),
                ...cleaned.asMap().entries.map((entry) {
                  final record = entry.value;
                  return TableRow(
                    decoration: BoxDecoration(
                      color: entry.key.isEven
                          ? Colors.white
                          : const Color(0xFFF8FAFC),
                    ),
                    children: columns
                        .map((column) => _NumerologyTableCell(
                            _numerologyValue(record[column])))
                        .toList(),
                  );
                }),
              ],
            ),
          ),
        ),
      );
      if (tableWidth <= constraints.maxWidth) return table;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _NumerologyScrollHint(),
          const SizedBox(height: 5),
          table,
        ],
      );
    });
  }
}

class _NumerologyTableCell extends StatelessWidget {
  final String text;
  final bool attribute;
  final bool header;

  const _NumerologyTableCell(
    this.text, {
    this.attribute = false,
    this.header = false,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = text.trim().isEmpty ? '-' : text;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: header ? 7 : 6,
      ),
      child: Text(
        resolved,
        maxLines: header ? 2 : 5,
        overflow: TextOverflow.ellipsis,
        textAlign: header ? TextAlign.center : TextAlign.left,
        style: TextStyle(
          color: const Color(0xFF1E3557),
          fontSize: header ? 10.7 : 11.2,
          height: 1.12,
          fontWeight: header || attribute ? FontWeight.w900 : FontWeight.w400,
        ),
      ),
    );
  }
}

class _NumerologyNarrativeBlock extends StatelessWidget {
  final String title;
  final String text;

  const _NumerologyNarrativeBlock({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty || text == '-') return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.trim().isNotEmpty) ...[
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1E3557),
                fontSize: 13.5,
                height: 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 11.6,
              height: 1.45,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumerologyScrollHint extends StatelessWidget {
  const _NumerologyScrollHint();

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

class _NumerologyEmptyState extends StatelessWidget {
  const _NumerologyEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6D7BA)),
      ),
      child: const Text(
        'Numerology details are not available right now.',
        style: TextStyle(
          color: Color(0xFF1E3557),
          fontSize: 11.6,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NumerologyTab {
  final String title;
  final dynamic value;

  const _NumerologyTab({required this.title, required this.value});
}

List<_NumerologyTab> _buildNumerologyTabs(Map<String, dynamic> response) {
  final data = _asMap(response['data']);
  final sections =
      _asList(data['provider_sections'] ?? response['provider_sections']);
  final tabs = <_NumerologyTab>[];

  for (final section in sections) {
    final map = _asMap(section);
    final items = _asMap(map['items']);
    if (items.isEmpty) {
      final payload = map['data'] ?? map['provider_payload'];
      if (payload != null) {
        tabs.add(_NumerologyTab(
          title: _friendlyTitle(map['title'] ?? 'Numerology'),
          value: payload,
        ));
      }
      continue;
    }
    for (final entry in items.entries) {
      final item = _asMap(entry.value);
      if ((item['status'] ?? '').toString().toLowerCase() == 'error') {
        continue;
      }
      tabs.add(_NumerologyTab(
        title: _friendlyTitle(entry.key),
        value: _numerologyItemPayload(entry.value),
      ));
    }
  }

  if (tabs.isNotEmpty) return tabs;

  final payload =
      data['provider_payload'] ?? response['provider_payload'] ?? data;
  final payloadMap = _asMap(payload);
  if (payloadMap.isNotEmpty) {
    for (final entry in payloadMap.entries) {
      final key = entry.key.toString().toLowerCase();
      if (const {
        'status',
        'success',
        'message',
        'provider_payload',
        'provider_sections'
      }.contains(key)) {
        continue;
      }
      tabs.add(_NumerologyTab(
        title: _friendlyTitle(entry.key),
        value: _numerologyItemPayload(entry.value),
      ));
    }
  }

  return tabs.isEmpty
      ? [const _NumerologyTab(title: 'Numerology', value: {})]
      : tabs;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

List<dynamic> _asList(dynamic value) => value is List ? value : const [];

String _friendlyTitle(dynamic value) {
  final text = (value ?? 'Numerology').toString();
  return text
      .replaceAll(RegExp(r'^/'), '')
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

dynamic _numerologyCleanValue(dynamic value) {
  var current = value;
  for (var index = 0; index < 4; index++) {
    final map = _asMap(current);
    if (map.isEmpty) return current;
    if (map.containsKey('data') &&
        (map.length <= 3 || !_numerologyIsEmpty(map['data']))) {
      current = map['data'];
      continue;
    }
    if (map.containsKey('provider_payload') &&
        (map.length <= 4 || !_numerologyIsEmpty(map['provider_payload']))) {
      current = map['provider_payload'];
      continue;
    }
    return current;
  }
  return current;
}

bool _numerologyPrimitiveMap(Map<String, dynamic> map) {
  return map.values.every((value) {
    final clean = _numerologyCleanValue(value);
    return clean == null ||
        clean is String ||
        clean is num ||
        clean is bool ||
        _primitiveList(clean);
  });
}

bool _primitiveList(dynamic value) {
  return value is List &&
      value.every((item) =>
          item == null || item is String || item is num || item is bool);
}

bool _numerologyIsEmpty(dynamic value) {
  if (value == null) return true;
  if (value is String) {
    final text = value.trim();
    return text.isEmpty ||
        text == '-' ||
        text == '--' ||
        text == '[]' ||
        text.toLowerCase() == 'null';
  }
  if (value is Iterable) return value.every(_numerologyIsEmpty);
  if (value is Map) {
    final map = _asMap(value);
    final visible = map.entries.where(
      (entry) => !_numerologyShouldHideKey(entry.key),
    );
    return visible.isEmpty ||
        visible.every((entry) => _numerologyIsEmpty(entry.value));
  }
  return false;
}

bool _numerologyShouldHideKey(String key) {
  final compact = _numerologyKey(key);
  const hidden = {
    'status',
    'success',
    'message',
    'msg',
    'title',
    'heading',
    'subtitle',
    'sub_title',
    'provider_payload',
    'provider_sections',
    'data',
    'api',
    'endpoint',
    'url',
    'raw',
    'raw_response',
    'debug',
    'request',
    'millisecond',
    'milliseconds',
    'milli_second',
    'milli_seconds',
    'start_ms',
    'end_ms',
    'start_time_ms',
    'end_time_ms',
  };
  return hidden.contains(compact);
}

String _numerologyKey(dynamic value) {
  return value
      .toString()
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

String _numerologyValue(dynamic value) {
  final clean = _numerologyCleanValue(value);
  if (clean == null || clean == '') return '-';
  if (clean is bool) return clean ? 'Yes' : 'No';
  if (clean is num) return clean.toString();
  if (clean is List) {
    final parts = clean
        .map(_numerologyValue)
        .where((item) => item != '-' && item.trim().isNotEmpty)
        .toList();
    return parts.isEmpty ? '-' : parts.join(', ');
  }
  if (clean is Map) {
    final map = _asMap(clean);
    final parts = map.entries
        .where((entry) =>
            !_numerologyShouldHideKey(entry.key) &&
            !_numerologyIsEmpty(entry.value))
        .map((entry) =>
            '${_friendlyTitle(entry.key)}: ${_numerologyValue(entry.value)}')
        .toList();
    return parts.isEmpty ? '-' : parts.join(' | ');
  }
  return _cleanNumerologyText(clean.toString());
}

String _cleanNumerologyText(String value) {
  return value.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
}

bool _isNumerologyNumberKey(String key) {
  final compact = _numerologyKey(key);
  if (compact == 'name') return false;
  return compact == 'number' ||
      compact.endsWith('_number') ||
      compact.contains('number_') ||
      compact.contains('_number_');
}

bool _isCompactNumberText(String value) {
  final text = value.trim();
  return RegExp(r'^\d+(?:\.\d+)?(?:\s*,\s*\d+(?:\.\d+)?){0,2}$').hasMatch(text);
}

bool _isNumerologyNarrativeKey(String key) {
  final compact = _numerologyKey(key);
  return compact.contains('prediction') ||
      compact.contains('description') ||
      compact.contains('detail') ||
      compact.contains('report') ||
      compact.contains('analysis') ||
      compact.contains('says') ||
      compact.contains('about') ||
      compact.contains('summary') ||
      compact.contains('text') ||
      compact.contains('meaning') ||
      compact.contains('bot_response') ||
      compact.contains('personality') ||
      compact.contains('career') ||
      compact.contains('health') ||
      compact.contains('love') ||
      compact.contains('finance') ||
      compact.contains('remedy');
}

String _numerologyNarrativeTitle(String key) {
  final compact = _numerologyKey(key);
  if (const {
    'description',
    'short_description',
    'report',
    'prediction',
    'summary',
    'details',
    'detail',
    'text',
    'bot_response',
  }.contains(compact)) {
    return '';
  }
  return _friendlyTitle(key);
}

dynamic _numerologyItemPayload(dynamic value) {
  final item = _asMap(value);
  if (item.isEmpty) return value;
  final data = item['data'];
  if (!_numerologyIsEmpty(data)) return data;
  final payload = item['provider_payload'];
  if (!_numerologyIsEmpty(payload)) return payload;
  final cleaned = Map<String, dynamic>.from(item)
    ..removeWhere((key, value) =>
        _numerologyShouldHideKey(key) || _numerologyIsEmpty(value));
  return cleaned.isEmpty ? value : cleaned;
}

List<Map<String, dynamic>> _numerologyRecordList(dynamic value) {
  final clean = _numerologyCleanValue(value);
  if (clean is List) {
    final records = clean
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => item.isNotEmpty)
        .toList();
    return records;
  }
  final map = _asMap(clean);
  if (map.isNotEmpty && map.values.every((item) => item is Map)) {
    return map.entries
        .where((entry) => !_numerologyShouldHideKey(entry.key))
        .map((entry) => {
              'name': _friendlyTitle(entry.key),
              ..._asMap(entry.value),
            })
        .toList();
  }
  return const [];
}

List<String> _numerologyColumns(List<Map<String, dynamic>> records) {
  final columns = <String>[];
  for (final record in records) {
    for (final key in record.keys) {
      if (!_numerologyShouldHideKey(key) && !columns.contains(key)) {
        columns.add(key);
      }
    }
  }
  const preferred = [
    ['name', 'title', 'attribute'],
    ['number', 'value', 'result'],
    ['date', 'day'],
    ['planet', 'ruler', 'lord'],
    ['prediction', 'report', 'analysis', 'details'],
  ];
  return _orderColumnsByGroups(columns, preferred);
}

List<String> _orderColumnsByGroups(
  List<String> columns,
  List<List<String>> groups,
) {
  final ordered = <String>[];
  final normalized = {
    for (final column in columns) _numerologyKey(column): column,
  };
  for (final group in groups) {
    for (final key in group) {
      final column = normalized[_numerologyKey(key)];
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

double _numerologyColumnWidth(String column) {
  final key = _numerologyKey(column);
  if (key == 'sn' || key == 'id') return 42;
  if (key.contains('number') || key == 'value' || key == 'result') return 76;
  if (key.contains('date') || key.contains('day')) return 94;
  if (key.contains('prediction') ||
      key.contains('report') ||
      key.contains('analysis') ||
      key.contains('details')) {
    return 176;
  }
  if (key.contains('name') || key.contains('title')) return 96;
  return 112;
}
