import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/models/app_content_catalog.dart';
import '../../main_navigation.dart';

class HomeBannerCarousel extends StatefulWidget {
  const HomeBannerCarousel({super.key});

  @override
  State<HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<HomeBannerCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.94);
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_controller.hasClients) return;
      _controller.animateToPage(
        (_index + 1) % homeBanners.length,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _open(HomeBannerDestination destination) {
    final index = switch (destination) {
      HomeBannerDestination.shop => 3,
      HomeBannerDestination.pooja => 7,
      HomeBannerDestination.horoscope => 11,
    };
    if (MainNavigationState.activateIndex(index)) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MainNavigation(initialIndex: index)),
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
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 2.85,
          child: PageView.builder(
            controller: _controller,
            itemCount: homeBanners.length,
            onPageChanged: (value) {
              setState(() => _index = value);
              _startTimer();
            },
            itemBuilder: (context, index) {
              final banner = homeBanners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: InkWell(
                  onTap: () => _open(banner.destination),
                  borderRadius: BorderRadius.circular(8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      banner.assetPath,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(homeBanners.length, (index) {
            final selected = index == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: selected ? 18 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFD4A73C)
                    : const Color(0xFFD4A73C).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6),
              ),
            );
          }),
        ),
      ],
    );
  }
}
