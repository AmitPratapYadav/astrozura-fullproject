import 'package:flutter/material.dart';

import '../panchang/chaughadiya_pamchang.dart';
import '../panchang/daily_panchang.dart';
import '../panchang/hora_panchang.dart';

class AyanaCard extends StatelessWidget {
  final int currentIndex;

  const AyanaCard({super.key, required this.currentIndex});

  static const _pages = [
    ('Daily Panchang', DailyPanchangScreen()),
    ('Chaughadiya Panchang', ChaughadiyaPanchangScreen()),
    ('Hora Panchang', HoraPanchangPage()),
  ];

  void _navigate(BuildContext context, int index) {
    if (index < 0 || index >= _pages.length) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => _pages[index].$2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = currentIndex.clamp(0, _pages.length - 1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFB8860B).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: index > 0 ? () => _navigate(context, index - 1) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'PANCHANG',
                  style: TextStyle(
                    color: Color(0xFFB8860B),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _pages[index].$1,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF1E3557),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: index < _pages.length - 1
                ? () => _navigate(context, index + 1)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}
