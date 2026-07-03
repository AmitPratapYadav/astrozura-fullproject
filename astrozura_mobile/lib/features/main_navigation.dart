// main_navigation.dart
// Tab index mapping:
// 0 → Home
// 1 → Experts
// 2 → Spark (center) — opens SparkCategorySheet as bottom sheet overlay
// 3 → Shop
// 4 → Profile
// 5 → MyOrders   (hidden, no navbar item)
// 6 → MyBookings (hidden, no navbar item)

import 'package:flutter/material.dart';
import './home/home_screen.dart';
import '../features/shop/shop_screen.dart';
import '../features/mainwidgets/bottom_navbar.dart';
import '../features/other_pages/category_page.dart'; // ← new
import 'astrologer/screens/astrologer_screen.dart';
import '../features/profile/profile_screen.dart';
import './profile/my_booking_page.dart';
import './profile/my_orders_page.dart';
import './auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/pujaanusthan/puja_anusthan_screen.dart'; // ← new
import 'other_pages/panchang/daily_panchang.dart'; // ← new
import 'other_pages/panchang/chaughadiya_pamchang.dart'; // ← new
import 'other_pages/panchang/hora_panchang.dart'; // ← new
import '../features/other_pages/horoscope/live_horoscope_screen.dart';
import '../features/other_pages/lal_kitab_report.dart';
import './other_pages/calculators/live_vedic_calculator_screen.dart';
import './other_pages/calculators/live_numerology_screen.dart';
import './other_pages/calculators/live_tarot_screen.dart';
import '../features/other_pages/live_matchmaking_report_screen.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;

  static final GlobalKey<MainNavigationState> navigatorKey =
      GlobalKey<MainNavigationState>();

  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => MainNavigationState();
}

class MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  DateTime? lastBackPressed;

  static MainNavigationState? _instance;
  static MainNavigationState? get instance => _instance;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _instance = this;
  }

  @override
  void dispose() {
    if (_instance == this) _instance = null;
    super.dispose();
  }

  void _onTabTapped(int index) {
    // Index 2 = Spark center button → open bottom sheet, don't change tab
    if (index == 2) {
      SparkCategorySheet.show(context);
      return;
    }
    setState(() => _currentIndex = index);
  }

  void switchTab(int index) => _onTabTapped(index);

  @override
  Widget build(BuildContext context) {
    final sharedNavbar = CustomBottomNavbar(
      currentIndex: _currentIndex,
      onTap: _onTabTapped,
    );

    final List<Widget> screens = [
      const HomeScreen(), // 0
      const AstrologerScreen(), // 1
      const SizedBox.shrink(), // 2 — placeholder; tap opens sheet instead
      const ShopScreen(), // 3
      const ProfileScreen(), // 4
      MyOrdersPage(
        // 5
        bottomNavigationBar: sharedNavbar,
      ),
      MyBookingsPage(
        // 6
        bottomNavigationBar: sharedNavbar,
      ),
      const PoojaAnusthanScreen(), // 7 — direct page, no navbar item
      const DailyPanchangScreen(), // 8 — direct page, no navbar item
      const ChaughadiyaPanchangScreen(), // 9 — direct page, no navbar item
      const HoraPanchangPage(), //rect page, no navbar itemq
      const LiveHoroscopeScreen(),
      const LalKitabReportScreen(),
      const LiveVedicCalculatorScreen(
        toolKey: 'daily-nakshatra-predictions',
        title: 'Daily Nakshatra Predictions',
        description:
            'Review previous, current, next and consolidated daily Nakshatra predictions.',
      ),
      const LiveVedicCalculatorScreen(
        toolKey: 'mangal-dosha',
        title: 'Mangal Dosha',
        description:
            'Check manglik dosha, exceptions, and remedial notes from birth details.',
        supportsAdvanced: true,
      ),
      const LiveVedicCalculatorScreen(
        toolKey: 'kaal-sarp-dosha',
        title: 'Kaalsarp Dosha',
        description:
            'Inspect Kaal Sarp Dosha indicators from live planetary placements.',
      ),
      const LiveVedicCalculatorScreen(
        toolKey: 'sade-sati',
        title: 'Sade-Sati',
        description:
            'Generate Shani Sade-Sati status, life details, and remedies.',
        supportsAdvanced: true,
      ),
      const LiveVedicCalculatorScreen(
        toolKey: 'pitra-dosha',
        title: 'Pitra Dosha',
        description:
            'Generate the Pitra Dosha report from date, time, and birthplace.',
      ),
      const LiveVedicCalculatorScreen(
        toolKey: 'puja-suggestion',
        title: 'Puja Suggestion',
        description: 'Review recommended puja remedies based on the horoscope.',
      ),
      const LiveVedicCalculatorScreen(
        toolKey: 'basic-gem-suggestion',
        title: 'Gemstone Suggestion',
        description: 'Find basic gemstone recommendations for the native.',
      ),
      const LiveVedicCalculatorScreen(
        toolKey: 'rudraksha-suggestion',
        title: 'Rudraksha Suggestion',
        description:
            'Find suitable rudraksha recommendations from birth details.',
      ),
      const LiveVedicCalculatorScreen(
        toolKey: 'vimshottari-dasha',
        title: 'Vimshottari Dasha',
        description: 'Review current and major Vimshottari dasha periods.',
      ),
      const LiveVedicCalculatorScreen(
        toolKey: 'char-dasha',
        title: 'Char Dasha',
        description: 'Review major and current Char Dasha periods.',
      ),
      const LiveVedicCalculatorScreen(
        toolKey: 'yogini-dasha',
        title: 'Yogini Dasha',
        description: 'Review current and major Yogini Dasha periods.',
      ),
      const LiveVedicCalculatorScreen(
        toolKey: 'varshaphal',
        title: 'Varshaphal',
        description:
            'Generate annual chart, planets, muntha, dasha, bala, saham, and yoga details.',
        requiresYear: true,
      ),
      const LiveVedicCalculatorScreen(
        toolKey: 'kp',
        title: 'Krishnamurti Paddhati',
        description:
            'Generate KP planets, house cusps, birth chart, and house significators.',
      ),
      const LiveVedicCalculatorScreen(
        toolKey: 'sarvashtakavarga',
        title: 'Ashtakavarga and Sarvashta Varga Chart',
        description: 'Generate planet Ashtakavarga and Sarvashtakavarga data.',
        requiresPlanet: true,
        requiresChartStyle: true,
      ),
      const LiveNumerologyScreen(),
      const LiveTarotScreen(),
      const AstrologerScreen(),
      const LiveMatchmakingReportScreen(),
      const LiveVedicCalculatorScreen(
        toolKey: '__kundli__',
        title: 'Kundali Report',
        description:
            'Generate a live Kundali report from birth details and birthplace.',
      ),
      const LiveVedicCalculatorScreen(
        toolKey: '__kundli__',
        title: 'Detailed Kundali Analysis',
        description:
            'Generate live chart, planetary, dasha, and interpretation data.',
      ),
      const LiveVedicCalculatorScreen(
        toolKey: 'mangal-dosha',
        additionalToolKeys: [
          'kaal-sarp-dosha',
          'sade-sati',
          'pitra-dosha',
        ],
        title: 'Detailed Dosha Analysis',
        description:
            'Review Mangal, Kaal Sarp, Sade-Sati, and Pitra Dosha results.',
        supportsAdvanced: true,
      ),
      const LiveMatchmakingReportScreen(),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex == 5 || _currentIndex == 6) {
          setState(() => _currentIndex = 4);
          return false;
        }
        if (_currentIndex == 7) {
          setState(() => _currentIndex = 0); // back to Home
          return false;
        }

        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false;
        }
        final now = DateTime.now();
        if (lastBackPressed == null ||
            now.difference(lastBackPressed!) > const Duration(seconds: 2)) {
          lastBackPressed = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tap back again to logout'),
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: screens,
        ),
        bottomNavigationBar:
            (_currentIndex != 5 && _currentIndex != 6) ? sharedNavbar : null,
      ),
    );
  }
}
