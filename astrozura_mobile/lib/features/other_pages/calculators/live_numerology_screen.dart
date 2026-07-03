import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/astrology_service.dart';
import '../../mainwidgets/header.dart';
import '../../shared/widgets/astrology_result_renderer.dart';

class LiveNumerologyScreen extends StatefulWidget {
  const LiveNumerologyScreen({super.key});

  @override
  State<LiveNumerologyScreen> createState() => _LiveNumerologyScreenState();
}

class _LiveNumerologyScreenState extends State<LiveNumerologyScreen> {
  final _name = TextEditingController();
  final AstrologyService _service = AstrologyService();
  DateTime? _date;
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

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

  Future<void> _run() async {
    if (_date == null) {
      setState(() => _error = 'Date of birth is required.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final response = await _service.numerology({
        'name': _name.text.trim(),
        'date_of_birth':
            '${_date!.year.toString().padLeft(4, '0')}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}',
      });
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (response['status'] == 'success') {
          _result = response;
        } else {
          _error = response['message']?.toString() ?? 'Request failed.';
        }
      });
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
        TextField(
          controller: _name,
          decoration: const InputDecoration(
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
          height: 48,
          child: ElevatedButton(
            onPressed: _loading ? null : _run,
            child: const Text('Generate Numerology Report'),
          ),
        ),
        _ToolResult(loading: _loading, error: _error, result: _result),
      ],
    );
  }
}

class _SimpleToolScaffold extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SimpleToolScaffold({required this.title, required this.children});

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
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
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
  final Map<String, dynamic>? result;

  const _ToolResult({required this.loading, this.error, this.result});

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
    if (result != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 18),
        child: AstrologyResultRenderer(response: result!),
      );
    }
    return const SizedBox.shrink();
  }
}
