import 'package:flutter/material.dart';

import '../../../core/services/astrology_service.dart';
import '../../mainwidgets/header.dart';
import '../../shared/widgets/astrology_result_renderer.dart';

class LiveTarotScreen extends StatefulWidget {
  const LiveTarotScreen({super.key});

  @override
  State<LiveTarotScreen> createState() => _LiveTarotScreenState();
}

class _LiveTarotScreenState extends State<LiveTarotScreen> {
  final _question = TextEditingController();
  final AstrologyService _service = AstrologyService();
  String _type = 'general';
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final response = await _service.tarot({
        'type': _type,
        'question': _question.text.trim(),
        'la': 'en',
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
                      const Expanded(
                        child: Text(
                          'Tarot Reading',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E3557),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'general',
                        label: Text('General'),
                      ),
                      ButtonSegment(
                        value: 'yes-no',
                        label: Text('Yes / No'),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (value) {
                      setState(() => _type = value.first);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _question,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Your question (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _run,
                      child: const Text('Draw Live Reading'),
                    ),
                  ),
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(30),
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
          ],
        ),
      ),
    );
  }
}
