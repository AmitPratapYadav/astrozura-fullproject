import 'package:flutter/material.dart';
import '../../../core/models/astrologer/astrologer_model.dart';
import 'spotlight_card.dart';

class SpotlightSection extends StatelessWidget {
  final AstrologerModel astrologer;

  const SpotlightSection({
    super.key,
    required this.astrologer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── SECTION LABEL ─────────────────────────────────────────────
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'SPOTLIGHT EXPERT',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Color(0xFF5A5A7A),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ── CARD ──────────────────────────────────────────────────────
        SpotlightCard(
          astrologer: astrologer,
          isWishlisted: false,        // wire up via provider as needed
          onWishlistTap: () {},       // wire up via provider as needed
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}