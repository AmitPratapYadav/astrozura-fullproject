import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/app_content_catalog.dart';
import '../../other_pages/horoscope/live_horoscope_screen.dart';

class HoroscopeCard extends StatefulWidget {
  const HoroscopeCard({super.key});

  @override
  State<HoroscopeCard> createState() => _HoroscopeCardState();
}

class _HoroscopeCardState extends State<HoroscopeCard> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_controller.hasClients) return;
      _controller.animateToPage(
        (_index + 1) % zodiacSigns.length,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _openHoroscope(ZodiacSignInfo rashi) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveHoroscopeScreen(initialSign: rashi.key),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Your Daily Horoscope',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E3557),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 158,
          child: PageView.builder(
            controller: _controller,
            itemCount: zodiacSigns.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) {
              final rashi = zodiacSigns[index];
              return Padding(
                padding: const EdgeInsets.only(right: 10, bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => _openHoroscope(rashi),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDFDEFF), Color(0xFF8B88E6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${rashi.name} (${rashi.vedicName})',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF1E2360),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 38,
                                child: ElevatedButton(
                                  onPressed: () => _openHoroscope(rashi),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD4A73C),
                                    foregroundColor: const Color(0xFF1E3557),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                  ),
                                  child: const Text(
                                    'Full Horoscope',
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 82,
                          height: 82,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            rashi.assetPath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
