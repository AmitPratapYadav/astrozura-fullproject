import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AstrologyResultRenderer extends StatelessWidget {
  final Map<String, dynamic> response;

  const AstrologyResultRenderer({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
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

    return _ReportPanel(
      title: 'Result',
      child: _DataBlock(title: 'Result', value: payload),
    );
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
            child: Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: true,
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                title: Text(
                  _titleize(entry.key),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                subtitle: hasError
                    ? Text(
                        _text(item['message'],
                            fallback: 'Provider returned an error.'),
                        style: const TextStyle(color: Colors.red),
                      )
                    : null,
                children: [
                  if (hasError)
                    _KeyValueTable(rows: [
                      const ['Status', 'Unavailable'],
                      [
                        'Endpoint',
                        _text(item['endpoint'], fallback: entry.key)
                      ],
                      [
                        'Message',
                        _text(item['message'],
                            fallback: 'Provider returned an error.')
                      ],
                    ])
                  else
                    _DataBlock(
                        title: _titleize(entry.key),
                        value: item['data'] ?? entry.value),
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
    if (value == null || value == '') {
      return const Text('No data returned.',
          style: TextStyle(color: Color(0xFF6B7280)));
    }

    if (value is String && value.toString().trimLeft().startsWith('<svg')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          color: Colors.white,
          child: SvgPicture.string(value, fit: BoxFit.contain),
        ),
      );
    }

    if (value is Map && value['svg'] is String) {
      final rest = Map<String, dynamic>.from(value)..remove('svg');
      return Column(
        children: [
          SvgPicture.string(value['svg'].toString(), fit: BoxFit.contain),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DataBlock(title: title, value: rest, depth: depth + 1),
          ],
        ],
      );
    }

    if (_isPrimitive(value)) {
      return _KeyValueTable(rows: [
        [title, _display(value)],
      ]);
    }

    if (value is List) {
      if (value.isEmpty) {
        return const Text('No records returned.',
            style: TextStyle(color: Color(0xFF6B7280)));
      }
      return Column(
        children: value.asMap().entries.map((entry) {
          final child = entry.value;
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _DataBlock(
                title: '${title} ${entry.key + 1}',
                value: child,
                depth: depth + 1),
          );
        }).toList(),
      );
    }

    final map = _asMap(value);
    final simpleRows = <List<String>>[];
    final nested = <MapEntry<String, dynamic>>[];
    for (final entry in map.entries) {
      if (_isPrimitive(entry.value) ||
          (entry.value is Map &&
              (_asMap(entry.value)['name'] != null ||
                  _asMap(entry.value)['value'] != null))) {
        simpleRows.add([_titleize(entry.key), _display(entry.value)]);
      } else {
        nested.add(entry);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (simpleRows.isNotEmpty) _KeyValueTable(rows: simpleRows),
        ...nested.map((entry) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_titleize(entry.key),
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  _DataBlock(
                      title: _titleize(entry.key),
                      value: entry.value,
                      depth: depth + 1),
                ],
              ),
            )),
      ],
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
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: rows.map((row) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 118,
                  child: Text(row[0],
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(row.length > 1 ? row[1] : '-',
                      style: const TextStyle(
                          color: Color(0xFF4B5563), height: 1.35)),
                ),
              ],
            ),
          );
        }).toList(),
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
  return value.toString();
}

String _titleize(String value) {
  final spaced = value.replaceAll('_', ' ').replaceAll('-', ' ');
  return spaced
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}
