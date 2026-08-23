import 'package:flutter/material.dart';
import '../../shared/widgets/remote_avatar.dart';
import '../../../core/models/astrologer/astrologer_model.dart';
import '../screens/schedule_session_screen.dart';

class AstrologerProfileCard extends StatelessWidget {
  final AstrologerModel astrologer;

  const AstrologerProfileCard({super.key, required this.astrologer});

  @override
  Widget build(BuildContext context) {
    final name = astrologer.name;
    final imageUrl = astrologer.fullImageUrl;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE6E1F8), Color(0xFF5B63D3)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          /// PROFILE IMAGE
          Stack(
            alignment: Alignment.center,
            children: [
              RemoteAvatar(
                radius: 50,
                backgroundColor: Colors.white,
                imageUrl: imageUrl,
                name: astrologer.name,
              ),

              /// FEATURED BADGE (instead of isOnline)
              if (astrologer.isFeatured)
                Positioned(
                  bottom: 4,
                  right: 6,
                  child: Container(
                    height: 18,
                    width: 18,
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          _statusBadge(astrologer),

          const SizedBox(height: 12),

          /// RATING
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Top Rated",
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              ...List.generate(
                5,
                (index) => Icon(
                  index < astrologer.rating.floor()
                      ? Icons.star
                      : Icons.star_border,
                  color: Colors.amber,
                  size: 16,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "(${astrologer.totalReviews} reviews)",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 10),

          /// NAME
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 6),

          /// EXPERIENCE
          Text(
            "${astrologer.experienceYears} Years Experience",
            style: const TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 4),

          /// LANGUAGES (STRING FIX)
          Text(
            astrologer.languages.isNotEmpty
                ? astrologer.languages
                : "Languages not available",
            style: const TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 14),

          /// SPECIALITIES (FIXED)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                astrologer.specialityList.take(4).map((e) => _tag(e)).toList(),
          ),

          const SizedBox(height: 18),

          /// BUTTONS
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScheduleSessionScreen(
                          astrologer: astrologer,
                          preselectedType: 'chat',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Book Chat"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD4A73A),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScheduleSessionScreen(
                          astrologer: astrologer,
                          preselectedType: 'call',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.call),
                  label: const Text("Book Audio"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    );
  }

  Widget _statusBadge(AstrologerModel astrologer) {
    final color = _statusColor(astrologer.availabilityLabel);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.9)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            astrologer.availabilityLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Busy':
        return const Color(0xFFFFC857);
      case 'Offline':
        return const Color(0xFFFF6B6B);
      default:
        return const Color(0xFF38D58A);
    }
  }
}
