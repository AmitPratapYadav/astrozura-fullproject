import 'package:flutter/material.dart';
import '../../../core/models/astrologer/astrologer_model.dart';
import './review_card.dart';

class UserExperienceSection extends StatelessWidget {
  final List<AstrologerReview> reviews;

  const UserExperienceSection({
    super.key,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "User Experiences",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 14),

          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final AstrologerReview review = reviews[index]; // ✅ FIX

                return ReviewCard(
                  review: review,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}