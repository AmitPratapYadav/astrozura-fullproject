// lib/widgets/home/spotlight_card.dart
//
// Drop-in replacement — visually matches the "Spotlight Expert" design:
//   • Light lavender → mid-purple gradient card
//   • PRO badge (white pill, red bold text) — top-right
//   • Circular avatar with amber FEATURED badge below it
//   • Name in dark navy, description in white, stat divider, gold CTA
//   • Animated wishlist heart (stateful sub-widget)
//
// All original callbacks and parameters are preserved.

import 'package:flutter/material.dart';
import '../../shared/widgets/remote_avatar.dart';
import '../../../core/models/astrologer/astrologer_model.dart';
import '../../../core/contants/app_colors.dart';
import '../../astrologer/screens/astrologer_detail_screen.dart';
import 'responsive_star_rating.dart';

class SpotlightCard extends StatelessWidget {
  final AstrologerModel astrologer;
  final bool isWishlisted;

  /// Called when the heart is tapped. Parent decides whether to show
  /// a login prompt or call the provider.
  final VoidCallback onWishlistTap;

  const SpotlightCard({
    super.key,
    required this.astrologer,
    required this.isWishlisted,
    required this.onWishlistTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = astrologer.name;
    final imageUrl = astrologer.fullImageUrl;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── MAIN CARD (tappable anywhere → detail screen) ─────────────
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AstrologerDetailScreen(astrologer: astrologer),
            ),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDFDEFF), Color(0xFF8B88E6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.09),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── TOP ROW ───────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar + FEATURED badge
                    _AvatarWithBadge(
                      imageUrl: imageUrl,
                      isFeatured: astrologer.isFeatured,
                    ),

                    const SizedBox(width: 14),

                    // Name / description / stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Extra top padding to clear the PRO badge
                          const SizedBox(height: 4),

                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E2360),
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            astrologer.fullDescription,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              height: 1.45,
                            ),
                          ),

                          const SizedBox(height: 10),

                          _StatusPill(status: astrologer.availabilityLabel),

                          const SizedBox(height: 12),

                          // Stats row with vertical divider
                          Row(
                            children: [
                              _StatColumn(
                                label: 'EXPERIENCE',
                                value: '${astrologer.experienceYears} Years',
                              ),
                              const SizedBox(width: 14),
                              Container(
                                width: 1,
                                height: 30,
                                color: Colors.white38,
                              ),
                              const SizedBox(width: 14),
                              _RatingColumn(rating: astrologer.rating),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // ── BOOK BUTTON ───────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AstrologerDetailScreen(astrologer: astrologer),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text(
                      'Book Priority Session',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ), // end GestureDetector

        // ── PRO BADGE (top-right) ──────────────────────────────────────
        Positioned(
          top: 10,
          right: 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.red,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        // ── WISHLIST HEART (below PRO badge) ─────────────────────────
        Positioned(
          top: 42,
          right: 24,
          child: _WishlistButton(
            isWishlisted: isWishlisted,
            onTap: onWishlistTap,
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

/// Circular avatar with optional amber "FEATURED" pill at the bottom.
class _AvatarWithBadge extends StatelessWidget {
  final String imageUrl;
  final bool isFeatured;

  const _AvatarWithBadge({
    required this.imageUrl,
    required this.isFeatured,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            RemoteAvatar(
              radius: 36,
              backgroundColor: const Color(0xFFEEEEEE),
              imageUrl: imageUrl,
              name: 'Astrologer',
            ),
            if (isFeatured)
              Positioned(
                bottom: -8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'FEATURED',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Space below so FEATURED badge doesn't overlap content
        if (isFeatured) const SizedBox(height: 10),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Busy' => const Color(0xFFFFC857),
      'Offline' => const Color(0xFFFF6B6B),
      _ => const Color(0xFF38D58A),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.85)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingColumn extends StatelessWidget {
  final double rating;

  const _RatingColumn({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RATING',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Text(
              rating.toStringAsFixed(1),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 79,
              child: ResponsiveStarRating(
                rating: rating,
                maxSize: 15,
                spacing: 0.8,
                activeColor: Colors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Animated heart button with a scale-bounce on toggle.
class _WishlistButton extends StatefulWidget {
  final bool isWishlisted;
  final VoidCallback onTap;

  const _WishlistButton({required this.isWishlisted, required this.onTap});

  @override
  State<_WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<_WishlistButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scale = Tween<double>(begin: 1.0, end: 1.35)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque, // absorbs tap — doesn't bubble to card
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            widget.isWishlisted ? Icons.favorite : Icons.favorite_border,
            size: 17,
            color: widget.isWishlisted ? Colors.red : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
