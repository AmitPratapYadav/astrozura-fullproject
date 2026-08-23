import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AstrologyResultRenderer extends StatelessWidget {
  final Map<String, dynamic> response;

  const AstrologyResultRenderer({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    try {
      final data = _asMap(response['data']);
      final sections =
          _asList(data['provider_sections'] ?? response['provider_sections']);
      final payload =
          data['provider_payload'] ?? response['provider_payload'] ?? data;

      if (sections.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sections
              .map((section) => _ProviderSection(section: _asMap(section)))
              .toList(),
        );
      }

      return _DataBlock(title: 'Result', value: payload);
    } catch (error) {
      return _RenderError(message: error.toString());
    }
  }
}

class _ProviderSection extends StatelessWidget {
  final Map<String, dynamic> section;

  const _ProviderSection({required this.section});

  @override
  Widget build(BuildContext context) {
    final items = _asMap(section['items']);
    return _ReportPanel(
      title: _text(section['title'], fallback: 'Astrology Result'),
      subtitle: _text(section['summary']),
      child: Column(
        children: items.entries.map((entry) {
          final item = _asMap(entry.value);
          final status = _text(item['status']);
          final hasError = status == 'error';
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _friendlySectionTitle(entry.key),
                    style: const TextStyle(
                      color: Color(0xFF1E3557),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (hasError)
                    _ProviderError(
                      message: _text(
                        item['message'],
                        fallback: 'This result is unavailable right now.',
                      ),
                    )
                  else
                    _DataBlock(
                      title: 'Details',
                      value: item['data'] ?? entry.value,
                      depth: 0,
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ReportPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _ReportPanel({required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style: const TextStyle(color: Color(0xFF6B7280), height: 1.35)),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DataBlock extends StatelessWidget {
  final String title;
  final dynamic value;
  final int depth;

  const _DataBlock({required this.title, required this.value, this.depth = 0});

  @override
  Widget build(BuildContext context) {
    try {
      final normalized = _normalizePayload(value);
      if (normalized == null || normalized == '') {
        return const Text('No data returned.',
            style: TextStyle(color: Color(0xFF6B7280)));
      }

      if (normalized is String &&
          normalized.toString().trimLeft().startsWith('<svg')) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            color: Colors.white,
            child: SvgPicture.string(normalized, fit: BoxFit.contain),
          ),
        );
      }

      if (normalized is String && _looksLikeImageUrl(normalized)) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            normalized,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _KeyValueTable(rows: [
              [title, normalized]
            ]),
          ),
        );
      }

      if (normalized is Map && normalized['svg'] is String) {
        final rest = Map<String, dynamic>.from(normalized)..remove('svg');
        return Column(
          children: [
            SvgPicture.string(normalized['svg'].toString(),
                fit: BoxFit.contain),
            if (rest.isNotEmpty) ...[
              const SizedBox(height: 12),
              _DataBlock(title: title, value: rest, depth: depth + 1),
            ],
          ],
        );
      }

      if (_isPrimitive(normalized)) {
        return _InfoCards(rows: [
          [title, _display(normalized)],
        ]);
      }

      if (normalized is List) {
        if (normalized.isEmpty) {
          return const Text('No records returned.',
              style: TextStyle(color: Color(0xFF6B7280)));
        }
        if (_isRecordList(normalized)) {
          return _RecordTable(records: _recordMaps(normalized));
        }
        if (normalized.every(_isPrimitive)) {
          return _InfoCards(
            rows: normalized
                .asMap()
                .entries
                .map((entry) =>
                    ['$title ${entry.key + 1}', _display(entry.value)])
                .toList(),
          );
        }
        return _RecordCards(title: title, values: normalized, depth: depth);
      }

      final map = _cleanDisplayMap(_asMap(normalized));
      if (map.isEmpty) {
        return const Text('No displayable data returned.',
            style: TextStyle(color: Color(0xFF6B7280)));
      }
      if (map.length == 1 && !_isPrimitive(map.values.first)) {
        final entry = map.entries.first;
        final child = _normalizePayload(entry.value);
        if (child is List || child is Map) {
          return _DataBlock(
            title: _friendlySectionTitle(entry.key),
            value: child,
            depth: depth + 1,
          );
        }
      }
      if (_isGridMap(map)) {
        return _GridMapTable(map: map);
      }
      final simpleRows = <List<String>>[];
      final nested = <MapEntry<String, dynamic>>[];
      for (final entry in map.entries) {
        final cleanValue = _normalizePayload(entry.value);
        if (_isPrimitive(cleanValue) || _isNameValueMap(cleanValue)) {
          simpleRows.add([_titleize(entry.key), _display(entry.value)]);
        } else if (cleanValue is List && _isRecordList(cleanValue)) {
          nested.add(MapEntry(entry.key, cleanValue));
        } else {
          nested.add(MapEntry(entry.key, cleanValue));
        }
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (simpleRows.isNotEmpty) _InfoCards(rows: simpleRows),
          ...nested.map(
            (entry) => Padding(
              padding: EdgeInsets.only(top: simpleRows.isEmpty ? 0 : 10),
              child: _InlineSection(
                title: _friendlySectionTitle(entry.key),
                child: _NestedData(
                  title: _friendlySectionTitle(entry.key),
                  value: entry.value,
                  depth: depth + 1,
                ),
              ),
            ),
          ),
        ],
      );
    } catch (error) {
      return _RenderError(message: error.toString());
    }
  }
}

class _NestedData extends StatelessWidget {
  final String title;
  final dynamic value;
  final int depth;

  const _NestedData({
    required this.title,
    required this.value,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = _normalizePayload(value);
    if (normalized == null || normalized == '') {
      return const Text(
        'No data returned.',
        style: TextStyle(color: Color(0xFF6B7280)),
      );
    }
    if (_isPrimitive(normalized)) {
      return Text(
        _display(normalized),
        style: const TextStyle(
          color: Color(0xFF374151),
          height: 1.42,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    if (normalized is List) {
      if (normalized.isEmpty) {
        return const Text(
          'No records returned.',
          style: TextStyle(color: Color(0xFF6B7280)),
        );
      }
      if (_isRecordList(normalized)) {
        return _RecordTable(records: _recordMaps(normalized));
      }
      if (normalized.every(_isPrimitive)) {
        return _InfoCards(
          rows: normalized
              .asMap()
              .entries
              .map(
                  (entry) => ['$title ${entry.key + 1}', _display(entry.value)])
              .toList(),
        );
      }
      return _RecordCards(title: title, values: normalized, depth: depth);
    }
    final map = _cleanDisplayMap(_asMap(normalized));
    if (map.isEmpty) {
      return const Text(
        'No displayable data returned.',
        style: TextStyle(color: Color(0xFF6B7280)),
      );
    }
    if (_isGridMap(map)) {
      return _GridMapTable(map: map);
    }

    final simpleRows = <List<String>>[];
    final complexWidgets = <Widget>[];
    for (final entry in map.entries) {
      final cleanValue = _normalizePayload(entry.value);
      if (_isPrimitive(cleanValue) || _isNameValueMap(cleanValue)) {
        simpleRows.add([_titleize(entry.key), _display(entry.value)]);
      } else if (cleanValue is List && _isRecordList(cleanValue)) {
        complexWidgets.add(_InlineSection(
          title: _friendlySectionTitle(entry.key),
          child: _RecordTable(records: _recordMaps(cleanValue)),
        ));
      } else if (cleanValue is Map && _isGridMap(_asMap(cleanValue))) {
        complexWidgets.add(_InlineSection(
          title: _friendlySectionTitle(entry.key),
          child: _RecordCards(
            title: _friendlySectionTitle(entry.key),
            values: _asMap(cleanValue).entries.map((item) {
              return {
                'name': _titleize(item.key),
                ..._asMap(item.value),
              };
            }).toList(),
            depth: depth + 1,
          ),
        ));
      } else {
        complexWidgets.add(_InlineSection(
          title: _friendlySectionTitle(entry.key),
          child: _flatDisplay(cleanValue, _friendlySectionTitle(entry.key)),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (simpleRows.isNotEmpty) _InfoCards(rows: simpleRows),
        ...complexWidgets.map(
          (widget) => Padding(
            padding: EdgeInsets.only(top: simpleRows.isEmpty ? 0 : 10),
            child: widget,
          ),
        ),
      ],
    );
  }
}

Widget _flatDisplay(dynamic value, String title) {
  final normalized = _normalizePayload(value);
  if (normalized == null || normalized == '') {
    return const Text(
      'No data returned.',
      style: TextStyle(color: Color(0xFF6B7280)),
    );
  }
  if (_isPrimitive(normalized)) {
    return Text(
      _display(normalized),
      style: const TextStyle(
        color: Color(0xFF374151),
        height: 1.42,
        fontWeight: FontWeight.w600,
      ),
    );
  }
  if (normalized is List) {
    if (normalized.isEmpty) {
      return const Text(
        'No records returned.',
        style: TextStyle(color: Color(0xFF6B7280)),
      );
    }
    if (_isRecordList(normalized)) {
      return _RecordTable(records: _recordMaps(normalized));
    }
    return _RecordCards(title: title, values: normalized, depth: 0);
  }
  final map = _cleanDisplayMap(_asMap(normalized));
  if (map.isEmpty) {
    return const Text(
      'No displayable data returned.',
      style: TextStyle(color: Color(0xFF6B7280)),
    );
  }
  if (_isGridMap(map)) {
    return _GridMapTable(map: map);
  }
  return _InfoCards(
    rows: map.entries
        .map((entry) => [_titleize(entry.key), _display(entry.value)])
        .toList(),
  );
}

class _InlineSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _InlineSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1E3557),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _RecordCards extends StatelessWidget {
  final String title;
  final List<dynamic> values;
  final int depth;

  const _RecordCards({
    required this.title,
    required this.values,
    required this.depth,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: values.asMap().entries.map((entry) {
        final map = entry.value is Map
            ? _cleanDisplayMap(_asMap(entry.value))
            : <String, dynamic>{};
        final headingSource =
            map.remove('name') ?? map.remove('title') ?? map.remove('label');
        final heading = _display(headingSource ?? '$title ${entry.key + 1}');
        final rows = map.entries
            .map((item) => [_titleize(item.key), _display(item.value)])
            .toList();
        if (entry.value is Map && rows.length <= 1) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _InfoCard(
              label: heading,
              value: rows.isEmpty ? '-' : rows.first[1],
            ),
          );
        }
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFCF4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE8E0CF)),
          ),
          child: entry.value is Map
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD7AF4B),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(12)),
                      ),
                      child: Text(
                        heading,
                        style: const TextStyle(
                          color: Color(0xFF1E3557),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: rows.isEmpty
                          ? const Text(
                              '-',
                              style: TextStyle(color: Color(0xFF6B7280)),
                            )
                          : _PlainRows(rows: rows),
                    ),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(12),
                  child: _DataBlock(
                    title: '$title ${entry.key + 1}',
                    value: entry.value,
                    depth: depth + 1,
                  ),
                ),
        );
      }).toList(),
    );
  }
}

class _PlainRows extends StatelessWidget {
  final List<List<String>> rows;

  const _PlainRows({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows.map((row) {
        final label = row.isNotEmpty ? row[0] : '';
        final value = row.length > 1 ? row[1] : '-';
        final labelLooksGeneric = label.toLowerCase() == 'value' ||
            label.toLowerCase() == 'description' ||
            label.toLowerCase() == 'prediction' ||
            label.toLowerCase() == 'detail';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: labelLooksGeneric
              ? Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    height: 1.38,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Color(0xFF374151),
                        height: 1.38,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        );
      }).toList(),
    );
  }
}

class _InfoCards extends StatelessWidget {
  final List<List<String>> rows;

  const _InfoCards({required this.rows});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final twoColumns = constraints.maxWidth >= 330 && rows.length > 1;
      final gap = twoColumns ? 10.0 : 0.0;
      final itemWidth =
          twoColumns ? (constraints.maxWidth - gap) / 2 : constraints.maxWidth;
      return Wrap(
        spacing: gap,
        runSpacing: 10,
        children: rows.map((row) {
          return SizedBox(
            width: itemWidth,
            child: _InfoCard(
              label: row.isNotEmpty ? row[0] : 'Value',
              value: row.length > 1 ? row[1] : '-',
            ),
          );
        }).toList(),
      );
    });
  }
}

class _InfoCard extends StatefulWidget {
  final String label;
  final String value;

  const _InfoCard({required this.label, required this.value});

  @override
  State<_InfoCard> createState() => _InfoCardState();
}

class _InfoCardState extends State<_InfoCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFFFFF6DE) : const Color(0xFFFFFCF4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8E0CF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.value.isEmpty ? '-' : widget.value,
              style: const TextStyle(
                color: Color(0xFF1E3557),
                fontSize: 15,
                height: 1.3,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordTable extends StatelessWidget {
  final List<Map<String, dynamic>> records;

  const _RecordTable({required this.records});

  @override
  Widget build(BuildContext context) {
    final columns = _recordColumns(records);
    if (columns.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E6),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE6D29D)),
          ),
          child: const Text(
            'Scroll table left or right',
            style: TextStyle(
              color: Color(0xFF8A6100),
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE6D29D)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFD7AF4B)),
                dataRowMinHeight: 46,
                dataRowMaxHeight: 74,
                headingTextStyle: const TextStyle(
                  color: Color(0xFF1E3557),
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
                          constraints: const BoxConstraints(maxWidth: 180),
                          child: Text(
                            _display(record[column]),
                            softWrap: true,
                            overflow: TextOverflow.visible,
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
    );
  }
}

class _GridMapTable extends StatelessWidget {
  final Map<String, dynamic> map;

  const _GridMapTable({required this.map});

  @override
  Widget build(BuildContext context) {
    final rows = map.entries
        .map((entry) => <String, dynamic>{
              'name': _titleize(entry.key),
              ..._asMap(entry.value),
            })
        .toList();
    return _RecordTable(records: rows);
  }
}

class _ProviderError extends StatelessWidget {
  final String message;

  const _ProviderError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFF9A3412),
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

class _RenderError extends StatelessWidget {
  final String message;

  const _RenderError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Text(
        'This section could not be displayed cleanly.',
        style: const TextStyle(
          color: Color(0xFF9A3412),
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

class _KeyValueTable extends StatelessWidget {
  final List<List<String>> rows;

  const _KeyValueTable({required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE6D29D)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: rows.asMap().entries.map((entry) {
          final row = entry.value;
          final last = entry.key == rows.length - 1;
          return _MobileResultCell(
            label: row.isNotEmpty ? row[0] : 'Value',
            value: row.length > 1 ? row[1] : '-',
            isLast: last,
          );
        }).toList(),
      ),
    );
  }
}

class _MobileResultCell extends StatefulWidget {
  final String label;
  final String value;
  final bool isLast;

  const _MobileResultCell({
    required this.label,
    required this.value,
    required this.isLast,
  });

  @override
  State<_MobileResultCell> createState() => _MobileResultCellState();
}

class _MobileResultCellState extends State<_MobileResultCell> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: double.infinity,
        decoration: BoxDecoration(
          color: _pressed ? const Color(0xFFFFF6DE) : Colors.white,
          border: widget.isLast
              ? null
              : const Border(bottom: BorderSide(color: Color(0xFFE8E0CF))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: const Color(0xFFD7AF4B),
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: Color(0xFF1E3557),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Text(
                widget.value.isEmpty ? '-' : widget.value,
                style: const TextStyle(
                  color: Color(0xFF374151),
                  height: 1.42,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return {};
}

List<dynamic> _asList(dynamic value) => value is List ? value : const [];

bool _isPrimitive(dynamic value) =>
    value == null || value is String || value is num || value is bool;

dynamic _normalizePayload(dynamic value) {
  var current = value;
  for (var i = 0; i < 4; i++) {
    if (current is! Map) return current;
    final map = _asMap(current);
    if (map.containsKey('provider_payload')) {
      current = map['provider_payload'];
      continue;
    }
    if (map.containsKey('data') && _isResponseWrapper(map)) {
      current = map['data'];
      continue;
    }
    if (map.length == 1 && map.containsKey('data')) {
      current = map['data'];
      continue;
    }
    return map;
  }
  return current;
}

bool _isResponseWrapper(Map<String, dynamic> map) {
  final keys = map.keys.map((key) => key.toString().toLowerCase()).toSet();
  if (!keys.contains('data')) return false;
  const wrapperKeys = {
    'status',
    'success',
    'message',
    'data',
    'provider_payload',
    'provider_sections',
  };
  final onlyWrapperKeys = keys.every(wrapperKeys.contains);
  final status = map['status']?.toString().toLowerCase();
  return onlyWrapperKeys ||
      map['success'] == true ||
      status == 'success' ||
      status == 'ok';
}

Map<String, dynamic> _cleanDisplayMap(Map<String, dynamic> map) {
  final cleaned = <String, dynamic>{};
  for (final entry in map.entries) {
    final key = entry.key.toString();
    if (_hideKey(key, entry.value)) continue;
    final normalized = _normalizePayload(entry.value);
    if (normalized == null || normalized == '') continue;
    cleaned[key] = normalized;
  }
  return cleaned;
}

bool _hideKey(String key, dynamic value) {
  final lower = key.toLowerCase();
  final compact = lower
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  if (lower == 'data') return true;
  if (compact == 'millisecond' ||
      compact == 'milliseconds' ||
      compact == 'milli_second' ||
      compact == 'milli_seconds') {
    return true;
  }
  if (lower == 'provider_payload' || lower == 'provider_sections') return true;
  if (lower == 'endpoint' ||
      lower == 'provider_endpoint' ||
      lower == 'api_endpoint' ||
      lower == 'request_url' ||
      lower == 'url') {
    return true;
  }
  if (lower == 'success') return true;
  if (lower == 'status') {
    final text = value?.toString().toLowerCase().trim();
    return text == 'success' || text == 'ok' || text == 'true';
  }
  if (lower == 'message') {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text.toLowerCase().contains('success');
  }
  return false;
}

bool _isNameValueMap(dynamic value) {
  if (value is! Map) return false;
  final map = _asMap(value);
  return map.length <= 3 &&
      (map.containsKey('name') ||
          map.containsKey('full_name') ||
          map.containsKey('title') ||
          map.containsKey('value')) &&
      map.values.every(_isPrimitive);
}

bool _isRecordList(List<dynamic> values) {
  final maps = _recordMaps(values);
  if (maps.length < 2) return false;
  return maps.every((map) => map.isNotEmpty && map.values.every(_isCellValue));
}

List<Map<String, dynamic>> _recordMaps(List<dynamic> values) {
  return values
      .whereType<Map>()
      .map((item) => _cleanDisplayMap(Map<String, dynamic>.from(item)))
      .where((item) => item.isNotEmpty)
      .toList();
}

bool _isCellValue(dynamic value) =>
    _isPrimitive(value) || _isNameValueMap(value) || value is List;

List<String> _recordColumns(List<Map<String, dynamic>> records) {
  final columns = <String>[];
  for (final record in records) {
    for (final key in record.keys) {
      if (!columns.contains(key)) columns.add(key);
    }
  }
  return columns;
}

bool _isGridMap(Map<String, dynamic> map) {
  if (map.length < 2) return false;
  if (!map.values.every((value) => value is Map)) return false;
  final nestedMaps = map.values.map((value) => _asMap(value)).toList();
  return nestedMaps.every(
    (nested) => nested.isNotEmpty && nested.values.every(_isCellValue),
  );
}

bool _looksLikeImageUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    return false;
  }
  final path = uri.path.toLowerCase();
  return path.endsWith('.png') ||
      path.endsWith('.jpg') ||
      path.endsWith('.jpeg') ||
      path.endsWith('.webp');
}

String _text(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  final text = value.toString().trim();
  return text.isEmpty ? fallback : text;
}

String _display(dynamic value) {
  if (value == null || value == '') return '-';
  if (value is bool) return value ? 'Yes' : 'No';
  if (value is Map) {
    return _display(value['name'] ??
        value['full_name'] ??
        value['title'] ??
        value['value'] ??
        value.entries
            .map((e) => '${_titleize(e.key)}: ${_display(e.value)}')
            .join(' | '));
  }
  if (value is List) {
    final parts = value.map(_display).where((item) => item != '-').toList();
    return parts.isEmpty ? '-' : parts.join(', ');
  }
  return _cleanDisplayText(value.toString());
}

String _titleize(String value) {
  final spaced = value.replaceAll('_', ' ').replaceAll('-', ' ');
  return spaced
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

String _cleanDisplayText(String value) {
  final cleaned = value
      .replaceAll(RegExp(r'<[^>]*>'), ' ')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (cleaned.contains('://')) return cleaned;
  return cleaned.replaceAll('_', ' ');
}

String _friendlySectionTitle(String value) {
  final normalized = value
      .replaceAll(RegExp(r'^/'), '')
      .replaceAll(RegExp(r'^v1/'), '')
      .replaceAll(RegExp(r'^api/'), '');
  return _titleize(normalized);
}
