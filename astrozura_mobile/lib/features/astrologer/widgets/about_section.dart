import 'package:flutter/material.dart';
import '../../../core/models/astrologer/astrologer_model.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutSection extends StatefulWidget {
  final AstrologerModel astrologer;

  const AboutSection({
    super.key,
    required this.astrologer,
  });

  @override
  State<AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<AboutSection> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final astrologer = widget.astrologer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// TITLE
          Text(
            "About Astrologer ${astrologer.name}",
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),

          const SizedBox(height: 10),

          /// CARD
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// DESCRIPTION
                Text(
                   astrologer.fullDescription,
                  style: const TextStyle(
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 8),

              ],
            ),
          ),
        ],
      ),
    );
  }
}