import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/astrology_service.dart';

class LocationSelection {
  final String name;
  final double latitude;
  final double longitude;

  const LocationSelection({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  String get coordinates => '$latitude,$longitude';

  static LocationSelection? fromApi(Map<String, dynamic> item) {
    final name = (item['name'] ??
            item['display_name'] ??
            item['formatted_address'] ??
            item['label'])
        ?.toString()
        .trim();
    final coordinates = item['coordinates'];
    final lat = _toDouble(
      item['latitude'] ??
          item['lat'] ??
          (coordinates is Map
              ? coordinates['latitude'] ?? coordinates['lat']
              : null),
    );
    final lng = _toDouble(
      item['longitude'] ??
          item['lng'] ??
          item['lon'] ??
          (coordinates is Map
              ? coordinates['longitude'] ??
                  coordinates['lng'] ??
                  coordinates['lon']
              : null),
    );

    if (name == null || name.isEmpty || lat == null || lng == null) {
      return null;
    }

    return LocationSelection(name: name, latitude: lat, longitude: lng);
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class LocationSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final LocationSelection? initialSelection;
  final ValueChanged<LocationSelection?> onSelected;
  final InputDecoration? decoration;
  final TextStyle? style;
  final TextCapitalization textCapitalization;

  const LocationSearchField({
    super.key,
    required this.controller,
    required this.onSelected,
    this.hintText = 'Search city and select from list',
    this.initialSelection,
    this.decoration,
    this.style,
    this.textCapitalization = TextCapitalization.words,
  });

  @override
  State<LocationSearchField> createState() => _LocationSearchFieldState();
}

class _LocationSearchFieldState extends State<LocationSearchField> {
  final AstrologyService _service = AstrologyService();
  Timer? _debounce;
  List<LocationSelection> _results = [];
  bool _loading = false;
  LocationSelection? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialSelection;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _search(String query) async {
    _debounce?.cancel();
    widget.onSelected(null);
    _selected = null;

    if (query.trim().length < 2) {
      setState(() => _results = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;
      setState(() => _loading = true);
      try {
        final raw = await _service.searchLocations(query);
        final parsed = raw
            .map(LocationSelection.fromApi)
            .whereType<LocationSelection>()
            .take(6)
            .toList();
        if (mounted) {
          setState(() {
            _results = parsed;
            _loading = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _results = [];
            _loading = false;
          });
        }
      }
    });
  }

  void _select(LocationSelection selection) {
    setState(() {
      _selected = selection;
      _results = [];
      _loading = false;
    });
    widget.controller.text = selection.name;
    widget.onSelected(selection);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final decoration = widget.decoration ??
        InputDecoration(
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.location_on_outlined),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          style: widget.style,
          textCapitalization: widget.textCapitalization,
          decoration: decoration.copyWith(
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(13),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (_selected == null
                    ? decoration.suffixIcon
                    : const Icon(Icons.check_circle, color: Colors.green)),
          ),
          onChanged: _search,
        ),
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 220),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _results[index];
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.place_outlined, size: 20),
                  title: Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${item.latitude.toStringAsFixed(4)}, ${item.longitude.toStringAsFixed(4)}',
                  ),
                  onTap: () => _select(item),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
