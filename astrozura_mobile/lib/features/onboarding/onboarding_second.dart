import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../auth/login_screen.dart';
import 'onboarding_third.dart';
import 'widgets/feature_card.dart';

class OnboardingSecond extends StatelessWidget {
  const OnboardingSecond({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: constraints.maxHeight * 0.38,
                      width: double.infinity,
                      child: Image.asset(
                        'assets/images/onboarding2.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Illuminate Your Path',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2E2A72),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Discover ancient wisdom tailored for your modern spiritual journey.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF685E5E),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const FeatureCard(
                            icon: Icons.auto_awesome,
                            title: 'Expert Consultation',
                            description:
                                'Book 1-on-1 sessions with world-class astrologers for deep natal chart insights.',
                          ),
                          const SizedBox(height: 12),
                          const FeatureCard(
                            icon: Icons.shopping_bag_outlined,
                            title: 'Sacred Marketplace',
                            description:
                                'Shop a curated selection of ritual tools, crystals, and wellness products.',
                          ),
                          const SizedBox(height: 32),
                          _SolidButton(
                            label: 'Next',
                            background: const Color(0xFF2E2A72),
                            foreground: Colors.white,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const OnboardingThird(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Skip for now',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SolidButton extends StatelessWidget {
  const _SolidButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 55,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.arrow_forward, color: foreground, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
