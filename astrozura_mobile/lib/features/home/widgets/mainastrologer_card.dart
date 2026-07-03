import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/astrologer/astrologer_model.dart';
import '../../astrologer/screens/astrologer_detail_screen.dart';
import '../../shared/widgets/remote_avatar.dart';

class HomeAstrologerCarousel extends StatefulWidget {
  final List<AstrologerModel> astrologers;

  const HomeAstrologerCarousel({super.key, required this.astrologers});

  @override
  State<HomeAstrologerCarousel> createState() => _HomeAstrologerCarouselState();
}

class _HomeAstrologerCarouselState extends State<HomeAstrologerCarousel> {
  late final PageController _controller;
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.92);
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant HomeAstrologerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.astrologers.length != widget.astrologers.length) {
      _index = 0;
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (widget.astrologers.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients || widget.astrologers.isEmpty) return;
      final next = (_index + 1) % widget.astrologers.length;
      _controller.animateToPage(
        next,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Guidance, One Conversation Away',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E3557),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 196,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.astrologers.length,
            onPageChanged: (value) => setState(() => _index = value),
            itemBuilder: (context, index) {
              return _HomeAstrologerCard(
                astrologer: widget.astrologers[index],
              );
            },
          ),
        ),
        if (widget.astrologers.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.astrologers.length, (index) {
              final active = index == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: active ? 16 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: active
                      ? const Color(0xFFD4A73C)
                      : const Color(0xFFD4A73C).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _HomeAstrologerCard extends StatelessWidget {
  final AstrologerModel astrologer;

  const _HomeAstrologerCard({required this.astrologer});

  void _open(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AstrologerDetailScreen(astrologer: astrologer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        margin: const EdgeInsets.only(right: 10, bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFDFDEFF), Color(0xFF8B88E6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.09),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          RemoteAvatar(
                            radius: 38,
                            backgroundColor: Colors.white70,
                            imageUrl: astrologer.fullImageUrl,
                            name: astrologer.name,
                          ),
                          if (astrologer.isFeatured)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'FEATURED',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              astrologer.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E2360),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _Stat(
                                  label: 'EXPERIENCE',
                                  value: '${astrologer.experienceYears} Years',
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 14),
                                  color: Colors.white38,
                                ),
                                _Stat(
                                  label: 'RATING',
                                  value:
                                      '${astrologer.rating.toStringAsFixed(1)}  ★',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 36,
                child: ElevatedButton(
                  onPressed: () => _open(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4A73C),
                    foregroundColor: const Color(0xFF1E3557),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Book Session',
                    maxLines: 1,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
