// lib/screens/mainwidgets/greeting_widget.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/contants/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class GreetingWidget extends StatefulWidget {
  const GreetingWidget({super.key});

  @override
  State<GreetingWidget> createState() => _GreetingWidgetState();
}

class _GreetingWidgetState extends State<GreetingWidget> {
  String _firstName = 'User';

  @override
  void initState() {
    super.initState();
    _loadFirstName();
  }

  Future<void> _loadFirstName() async {
    final prefs = await SharedPreferences.getInstance();

    // 'user_name' is saved by AuthService.saveToken()
    // It stores the full name e.g. "Sahil Khan"
    // We extract only the first word as the first name
    final fullName = prefs.getString('user_name') ?? '';

    if (fullName.isNotEmpty) {
      final firstName = fullName.trim().split(' ').first;
      setState(() => _firstName = firstName);
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$_greeting, ',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryBlue,
                ),
              ),
              TextSpan(
                text: _firstName,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accentGold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          "Here's what the universe has for you today !",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      ],
    );
  }
}