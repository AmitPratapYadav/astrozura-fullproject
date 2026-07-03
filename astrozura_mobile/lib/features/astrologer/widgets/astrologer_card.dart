import 'package:flutter/material.dart';
import '../../shared/widgets/remote_avatar.dart';

import '../../../core/models/astrologer/astrologer_model.dart';
import '../../../core/contants/app_colors.dart';
import '../screens/astrologer_detail_screen.dart';
import '../screens/schedule_session_screen.dart';

class AstrologerCard extends StatelessWidget {
  final AstrologerModel astrologer;
  final List<AstrologerModel> allAstrologers;

  const AstrologerCard({
    super.key,
    required this.astrologer,
    this.allAstrologers = const [],
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AstrologerDetailScreen(
              astrologer: astrologer,
              allAstrologers: allAstrologers,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TOP SECTION
            Row(
              children: [
                /// IMAGE
                RemoteAvatar(
                  radius: 32,
                  backgroundColor: const Color(0xFFEEEEEE),
                  imageUrl: astrologer.fullImageUrl,
                  name: astrologer.name,
                ),

                const SizedBox(width: 14),

                /// TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        astrologer.name ?? "Astrologer",
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "${astrologer.experienceYears} Years Exp | ${astrologer.totalReviews} Reviews",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// SPECIALIZATION
                      Wrap(
                        spacing: 6,
                        children: astrologer.specialityList.map((skill) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F1F1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              skill,
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// PRICE SECTION
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _priceItem("CHAT", astrologer.chatPrice),
                  Container(width: 1, height: 30, color: Colors.grey),
                  _priceItem("CALL", astrologer.callPrice),
                ],
              ),
            ),

            const SizedBox(height: 16),

            /// ACTION BUTTONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AstrologerDetailScreen(
                            astrologer: astrologer,
                            allAstrologers: allAstrologers,
                          ),
                        ),
                      );
                    },
                    child: const Text("View Profile"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ScheduleSessionScreen(astrologer: astrologer),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGold,
                    ),
                    child: const Text("Book Now",
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceItem(String label, double price) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10)),
        Text(
          "₹${price.toStringAsFixed(0)}/min",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF5B3FD3),
          ),
        ),
      ],
    );
  }
}
