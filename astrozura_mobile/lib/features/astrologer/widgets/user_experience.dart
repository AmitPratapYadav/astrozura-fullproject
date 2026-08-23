import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/models/astrologer/astrologer_model.dart';

class UserExperienceSection extends StatelessWidget {
  final List<AstrologerReview> reviews;

  const UserExperienceSection({
    super.key,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    final visibleReviews = reviews
        .where(
          (review) => review.rating > 0 || review.comment.trim().isNotEmpty,
        )
        .take(8)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4A73A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'User Reviews',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E3557),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (visibleReviews.isEmpty)
            const _EmptyReviewCard()
          else
            SizedBox(
              height: 174,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.9),
                itemCount: visibleReviews.length,
                padEnds: false,
                itemBuilder: (context, index) {
                  return _CarouselReviewCard(review: visibleReviews[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _CarouselReviewCard extends StatelessWidget {
  final AstrologerReview review;

  const _CarouselReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    final trimmedName = review.userName.trim();
    final initial = trimmedName.isNotEmpty
        ? trimmedName.substring(0, 1).toUpperCase()
        : 'U';
    final comment = review.comment.trim().isNotEmpty
        ? review.comment.trim()
        : 'Rated this consultation ${review.rating.toStringAsFixed(1)} stars.';

    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAD9AE)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFFFF3CD),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Color(0xFF1E3557),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  review.userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1E3557),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _RatingPill(rating: review.rating),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Text(
              comment,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF44546A),
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  final double rating;

  const _RatingPill({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3557),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Color(0xFFD4A73A), size: 13),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyReviewCard extends StatelessWidget {
  const _EmptyReviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAD9AE)),
      ),
      child: const Text(
        'No reviews yet for this expert.',
        style: TextStyle(color: Color(0xFF607089), fontSize: 13),
      ),
    );
  }
}
