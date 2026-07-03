// lib/screens/astrologer/screens/astrologer_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/contants/app_colors.dart';
import '../../../core/models/astrologer/astrologer_model.dart';
import '../../mainwidgets/header.dart';
import '../../mainwidgets/bottom_navbar.dart';
import '../../main_navigation.dart';
import '../widgets/profile_card.dart';
import '../widgets/about_section.dart';
import '../widgets/consultation_plans.dart';
import '../widgets/user_experience.dart';
import '../widgets/astrologer_horizontal_card.dart';

class AstrologerDetailScreen extends StatefulWidget {
  final AstrologerModel astrologer;
  final List<AstrologerModel> allAstrologers;

  const AstrologerDetailScreen({
    super.key,
    required this.astrologer,
    this.allAstrologers = const [],
  });

  @override
  State<AstrologerDetailScreen> createState() =>
      _AstrologerDetailScreenState();
}

class _AstrologerDetailScreenState extends State<AstrologerDetailScreen> {
  final int _currentIndex = 1;

  void _onTabTapped(int index) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => MainNavigation(initialIndex: index)),
      (route) => false,
    );
  }

  // ── Share functionality ────────────────────────────────────────────────────
  void _shareAstrologer() {
    final a = widget.astrologer;
    final text = '''
✨ Check out this amazing astrologer on AstroZura!

👤 ${a.name}
🔮 Specialities: ${a.specialities}
⭐ Rating: ${a.rating} (${a.totalReviews} reviews)
🗓 Experience: ${a.experienceYears} years
💬 Chat: ₹${a.chatPrice.toStringAsFixed(0)}/min

Book a consultation now on AstroZura app!
''';
    Share.share(text, subject: 'Meet ${a.name} on AstroZura');
  }

  // ── Similar astrologers ────────────────────────────────────────────────────
  List<AstrologerModel> get _similar {
    final current = widget.astrologer;
    final currentSpecs =
        current.specialityList.map((e) => e.toLowerCase()).toSet();

    final matched = widget.allAstrologers
        .where((a) => a.id != current.id)
        .where((a) => a.specialityList
            .map((e) => e.toLowerCase())
            .any(currentSpecs.contains))
        .take(10)
        .toList();

    return matched.isNotEmpty
        ? matched
        : widget.allAstrologers
            .where((a) => a.id != current.id)
            .take(10)
            .toList();
  }

  @override
  Widget build(BuildContext context) {
    final astrologer = widget.astrologer;

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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // ← left-align all
              children: [
                // ── HEADER ────────────────────────────────────────
                const HeaderWidget(),
                const SizedBox(height: 5),

                // ── TITLE ROW (share left, title left, back right) ─
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios, size: 18),
                      ),

                      const SizedBox(width: 90),

                      // Title — left aligned
                      Text(
                        'Expert Profile',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFFB38A2E),
                        ),
                      ),

                      const SizedBox(width: 80),
                      // Share icon — left of title
                      GestureDetector(
                        onTap: _shareAstrologer,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3CD),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFFD4AF37).withOpacity(0.4),
                            ),
                          ),
                          child: const Icon(
                            Icons.share_outlined,
                            size: 18,
                            color: Color(0xFFB38A2E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ── PROFILE CARD ──────────────────────────────────
                AstrologerProfileCard(astrologer: astrologer),
                const SizedBox(height: 20),

                // ── ABOUT ─────────────────────────────────────────
                AboutSection(astrologer: astrologer),
                const SizedBox(height: 20),

                // ── CONSULTATION PLANS ────────────────────────────
                ConsultationPlans(astrologer: astrologer),
                const SizedBox(height: 20),

                // ── REVIEWS ───────────────────────────────────────
                UserExperienceSection(reviews: astrologer.reviewsList),
                const SizedBox(height: 20),

                // ── SIMILAR EXPERTS ───────────────────────────────
                if (_similar.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Similar Experts',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E2E5D),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _similar.length,
                      itemBuilder: (context, index) {
                        final item = _similar[index];
                        return GestureDetector(
                          onTap: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AstrologerDetailScreen(
                                astrologer: item,
                                allAstrologers: widget.allAstrologers,
                              ),
                            ),
                          ),
                          child: AstrologerHorizontalCard(
                            astrologer: item,
                            allAstrologers: widget.allAstrologers,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavbar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}