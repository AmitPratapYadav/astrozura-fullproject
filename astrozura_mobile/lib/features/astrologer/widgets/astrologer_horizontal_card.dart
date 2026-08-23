import 'package:flutter/material.dart';
import '../../shared/widgets/remote_avatar.dart';
import '../../../core/models/astrologer/astrologer_model.dart';
import '../screens/astrologer_detail_screen.dart';

class AstrologerHorizontalCard extends StatelessWidget {
  final AstrologerModel astrologer;
  final List<AstrologerModel> allAstrologers; // ✅ needed for navigation

  const AstrologerHorizontalCard({
    super.key,
    required this.astrologer,
    this.allAstrologers = const [],
  });

  @override
  Widget build(BuildContext context) {
    final name = astrologer.name;

    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// 🔝 TOP ROW
          Row(
            children: [
              /// IMAGE (SAFE)
              RemoteAvatar(
                radius: 26,
                backgroundColor: const Color(0xFFEEEEEE),
                imageUrl: astrologer.fullImageUrl,
                name: astrologer.name,
              ),

              const SizedBox(width: 10),

              /// TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 2),

                    /// EXPERIENCE (FIXED)
                    Text(
                      "${astrologer.experienceYears} yrs exp",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _statusBadge(astrologer),
                  ],
                ),
              ),

              /// ⭐ RATING
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B3FD3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    const SizedBox(width: 3),
                    Text(
                      astrologer.rating.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          /// 💰 PRICE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Chat: ₹${astrologer.chatPrice.toStringAsFixed(0)}/min",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              Text(
                "Call: ₹${astrologer.callPrice.toStringAsFixed(0)}/min",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

          const Spacer(),

          /// 🔘 BUTTON
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AstrologerDetailScreen(
                      astrologer: astrologer,
                      allAstrologers: allAstrologers, // ✅ FIXED
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4A43C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                "Book Now",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(AstrologerModel astrologer) {
    final color = _statusColor(astrologer.availabilityLabel);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          astrologer.availabilityLabel,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Busy':
        return const Color(0xFFB86A10);
      case 'Offline':
        return const Color(0xFFD43F3A);
      default:
        return const Color(0xFF0F9F6E);
    }
  }
}
