import 'package:flutter/material.dart';

import '../../core/services/astrology_service.dart';
import '../mainwidgets/header.dart';
import '../shared/widgets/astrology_result_renderer.dart';
import '../shared/widgets/location_search_field.dart';

class LiveMatchmakingReportScreen extends StatefulWidget {
  const LiveMatchmakingReportScreen({super.key});

  @override
  State<LiveMatchmakingReportScreen> createState() =>
      _LiveMatchmakingReportScreenState();
}

class _LiveMatchmakingReportScreenState
    extends State<LiveMatchmakingReportScreen> {
  final AstrologyService _service = AstrologyService();
  final _groom = _PersonBirthForm();
  final _bride = _PersonBirthForm();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _groom.dispose();
    _bride.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (!_groom.complete || !_bride.complete) {
      setState(() {
        _error =
            'Complete both birth dates, times, and select both birthplaces.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final response = await _service.matchMaking({
        'boy_dob': _iso(_groom.date!, _groom.time!),
        'boy_coordinates': _groom.location!.coordinates,
        'girl_dob': _iso(_bride.date!, _bride.time!),
        'girl_coordinates': _bride.location!.coordinates,
        'boy_timezone': '+05:30',
        'girl_timezone': '+05:30',
        'la': 'en',
        'detailed_report': true,
      });
      if (!mounted) return;
      setState(() {
        if (response['status'] == 'success') {
          _result = response;
        } else {
          _error =
              response['message']?.toString() ?? 'Unable to generate report.';
        }
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

  static String _iso(DateTime date, TimeOfDay time) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}T'
        '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:00+05:30';
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        ),
                        const Expanded(
                          child: Text(
                            'Detailed Matchmaking Report',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1E3557),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _PersonCard(
                      title: 'Groom Birth Details',
                      form: _groom,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    _PersonCard(
                      title: 'Bride Birth Details',
                      form: _bride,
                      onChanged: () => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _run,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D437B),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Generate Match Report',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      )
                    else if (_result != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: AstrologyResultRenderer(response: _result!),
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
}

class _PersonBirthForm {
  final name = TextEditingController();
  final place = TextEditingController();
  DateTime? date;
  TimeOfDay? time;
  LocationSelection? location;

  bool get complete => date != null && time != null && location != null;

  void dispose() {
    name.dispose();
    place.dispose();
  }
}

class _PersonCard extends StatelessWidget {
  final String title;
  final _PersonBirthForm form;
  final VoidCallback onChanged;

  const _PersonCard({
    required this.title,
    required this.form,
    required this.onChanged,
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
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE8D7A7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          TextField(
            controller: form.name,
            decoration: const InputDecoration(
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
                    form.date == null
                        ? 'Birth date'
                        : '${form.date!.day}/${form.date!.month}/${form.date!.year}',
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
                    form.time?.format(context) ?? 'Birth time',
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
              labelText: 'Birthplace',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
