import 'dart:async';

import 'package:flutter/material.dart';

import '../../main_navigation.dart';

class TarotSpotlightBanner extends StatefulWidget {
  const TarotSpotlightBanner({super.key});

  @override
  State<TarotSpotlightBanner> createState() => _TarotSpotlightBannerState();
}

class _TarotSpotlightBannerState extends State<TarotSpotlightBanner> {
  static const _banners = [
    'assets/images/banners/tarot.png',
    'assets/images/banners/tarot-2.png',
  ];

  final PageController _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_controller.hasClients) return;
      _controller.animateToPage(
        (_index + 1) % _banners.length,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _openTarot(BuildContext context) {
    const index = 28;
    if (MainNavigationState.activateIndex(index)) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigation(initialIndex: index)),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => _openTarot(context),
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3557).withValues(alpha: 0.14),
                      blurRadius: 16,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 3,
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _banners.length,
                      onPageChanged: (value) {
                        setState(() => _index = value);
                        _startTimer();
                      },
                      itemBuilder: (context, index) => Image.asset(
                        _banners[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banners.length, (index) {
              final selected = index == _index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: selected ? 18 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFD4A73C)
                      : const Color(0xFFD4A73C).withValues(alpha: 0.32),
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
