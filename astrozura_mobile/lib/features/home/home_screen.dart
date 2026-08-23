import 'package:flutter/material.dart';

import '../../core/contants/app_colors.dart';
import '../../core/models/astrologer/astrologer_model.dart';
import '../../core/models/other_pages/pages_data.dart';
import '../../core/services/astrologer_service.dart';
import '../mainwidgets/header.dart';
import 'widgets/blog_section.dart';
import 'widgets/greeting_search_widget.dart';
import 'widgets/home_banner_carousel.dart';
import 'widgets/home_footer.dart';
import 'widgets/horoscope_card.dart';
import 'widgets/live_session_section.dart';
import 'widgets/mainastrologer_card.dart';
import 'widgets/panchang_screen.dart';
import 'widgets/product_section.dart';
import 'widgets/puja_section.dart';
import 'widgets/service_tools_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AstrologerModel> _astrologers = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAstrologers();
  }

  Future<void> _loadAstrologers() async {
    try {
      final rawList = await AstrologerService.getAllAstrologers();
      final parsed = rawList
          .map((json) => AstrologerModel.fromJson(json))
          .toList()
        ..sort((a, b) => b.rating.compareTo(a.rating));
      if (!mounted) return;
      setState(() {
        _astrologers = parsed.take(6).toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, AppColors.goldLight],
            begin: Alignment.topCenter,
            end: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadAstrologers,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  const HeaderWidget(),
                  const GreetingSearchWidget(userName: ''),
                  const SizedBox(height: 8),
                  _buildAstrologerSection(),
                  const SizedBox(height: 14),
                  const PanchangSection(),
                  const SizedBox(height: 18),
                  const HoroscopeCard(),
                  const SizedBox(height: 20),
                  const HomePujaSection(),
                  const SizedBox(height: 18),
                  const ServiceToolsSection(
                    title: 'Explore Your Cosmic Reports',
                    services: reportServices,
                  ),
                  const SizedBox(height: 18),
                  const HomeBannerCarousel(),
                  const SizedBox(height: 18),
                  const ServiceToolsSection(
                    title: 'Tools for Deeper Insight',
                    services: calculatorServices,
                  ),
                  const SizedBox(height: 20),
                  const ProductsSection(),
                  const SizedBox(height: 28),
                  const HomeLiveSessionSection(),
                  const SizedBox(height: 28),
                  const HomeBlogSection(),
                  const HomeFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAstrologerSection() {
    if (_isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: OutlinedButton.icon(
          onPressed: _loadAstrologers,
          icon: const Icon(Icons.refresh),
          label: const Text('Retry astrologers'),
        ),
      );
    }
    if (_astrologers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No astrologers are available right now.'),
      );
    }
    return HomeAstrologerCarousel(astrologers: _astrologers);
  }
}
