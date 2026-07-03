import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'onboarding_second.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,

        /// 🔥 GOLD GRADIENT (MATCHED)
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 250, 249, 248), Color(0xfffe7d6b3)],
          ),
        ),

       child: SafeArea(
  child: SingleChildScrollView(
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height,
      ),
      child: Column(
        children: [
              /// 🔝 TOP SPACE
              SizedBox(
  height: MediaQuery.of(context).size.height * 0.12,
),

              /// 🌙 IMAGE
              Image.asset(
  'assets/images/logo.png',
  width: MediaQuery.of(context).size.width * 0.65,
  height: MediaQuery.of(context).size.width * 0.65,
  fit: BoxFit.contain,
),

              const SizedBox(height: 10),

              /// 🔤 ASTRO ZURA
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "ASTRO ",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: const Color(0xFF2E2A72),
                    ),
                  ),
                  Text(
                    "ZURA",
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: const Color.fromARGB(255, 212, 162, 12),
                    ),
                  ),
                ],
              ),

              /// ✨ TAGLINE
              Text(
                "Your cosmic compass to destiny",
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF4A3FA2),
                ),
              ),

              const SizedBox(height: 40),

              /// 🧭 HEADING
              Text(
                "Discover Your Cosmic Path",
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2E2A72),
                ),
              ),

              const SizedBox(height: 12),

              /// 📄 DESCRIPTION
              Padding(
                padding: EdgeInsets.symmetric(
  horizontal: MediaQuery.of(context).size.width * 0.12,
),
                child: Text(
                  "Connect with professional astrologers and unlock the secrets of your natal chart with ease.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF3D2F85),
                  ),
                ),
              ),

              const SizedBox(height: 100),


              const SizedBox(height: 25),

              /// 🔘 BUTTON
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OnboardingSecond(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        "Get Started",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    ),
      )
    );
  }

  /// 🔹 Simple dot (no separate widget file)
  Widget dot(bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 10 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white54,
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}
