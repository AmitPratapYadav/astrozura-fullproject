// puja_card.dart
// A single Puja Anusthan card matching the reference design.
//
// Usage:

import 'package:flutter/material.dart';
import '../../../core/models/puja_anusthan/puja_anusthan_model.dart';
import '../puja_anusthan_detail_screen.dart';

class PujaCard extends StatelessWidget {
  final PujaItem item;
  final VoidCallback onBookNow;

  const PujaCard({
    super.key,
    required this.item,
    required this.onBookNow,
  });

  // Parse hex color string → Color
  static Color _hexColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PujaAnusthanDetailScreen(item: item)),
            ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Featured image with overlays
              _CardImage(item: item, hexColor: _hexColor),

              // ── Info section
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        height: 1.25,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    const Text(
                      'Consult first, pay later',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFD4A84F),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Book Now button
                    SizedBox(
                      width: double.infinity,
                      height: 34,
                      child: ElevatedButton(
                        onPressed: onBookNow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0d437b),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Book Now',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image section with tag badge + acharya name overlay
// ─────────────────────────────────────────────────────────────────────────────

class _CardImage extends StatelessWidget {
  final PujaItem item;
  final Color Function(String) hexColor;

  const _CardImage({required this.item, required this.hexColor});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      child: AspectRatio(
        aspectRatio: 1.28,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Main image
            _PujaImage(asset: item.imageAsset),

            // ── Gradient overlay (bottom fade for acharya name readability)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.72),
                    ],
                  ),
                ),
              ),
            ),

            // ── Tag badge (top-left)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: hexColor(item.tagColor),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  item.tag,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),

            // ── Acharya name + rating (bottom-left)
            Positioned(
              bottom: 7,
              left: 8,
              right: 8,
              child: Row(
                children: [
                  // Avatar circle
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                      color: const Color(0xFFD4A84F),
                    ),
                    child:
                        const Icon(Icons.person, size: 13, color: Colors.white),
                  ),
                  const SizedBox(width: 5),
                  if (item.aacharyaName.isNotEmpty)
                    Expanded(
                      child: Text(
                        item.aacharyaName,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (item.aacharyaName.isEmpty) const Spacer(),
                  if (item.rating > 0) ...[
                    const Icon(
                      Icons.star_rounded,
                      size: 11,
                      color: Color(0xFFFFD700),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      item.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Smart image widget — handles network URLs, asset paths, and placeholder
// ─────────────────────────────────────────────────────────────────────────────

class _PujaImage extends StatelessWidget {
  final String asset;

  const _PujaImage({required this.asset});

  bool get _isNetwork =>
      asset.startsWith('http://') || asset.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    if (_isNetwork) {
      final dpr = MediaQuery.of(context).devicePixelRatio;
      final width = (MediaQuery.of(context).size.width / 2 * dpr)
          .round()
          .clamp(240, 720)
          .toInt();
      return Image.network(
        asset,
        fit: BoxFit.cover,
        cacheWidth: width,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => _Placeholder(),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _LoadingShimmer(),
      );
    }

    // Asset path — wrap in try, show placeholder if not found
    return Image.asset(
      asset,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _Placeholder(),
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color.fromARGB(255, 255, 255, 255),
      child: const Center(
        child: Icon(Icons.local_fire_department_outlined,
            size: 40, color: Color(0xFFD4A84F)),
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(color: const Color(0xFFF0F0F0));
  }
}
