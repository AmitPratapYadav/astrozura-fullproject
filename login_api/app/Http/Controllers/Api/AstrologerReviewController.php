<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AstrologerDetail;
use App\Models\AstrologerReview;
use App\Models\Booking;
use Illuminate\Http\Request;

class AstrologerReviewController extends Controller
{
    public function store(Request $request, Booking $booking)
    {
        $user = $request->user();

        if (!$user || $booking->user_id !== $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'You can only review your own completed booking.',
            ], 403);
        }

        if ($booking->status !== 'completed') {
            return response()->json([
                'success' => false,
                'message' => 'Reviews can only be submitted after the consultation is completed.',
            ], 422);
        }

        if (!$booking->astrologer_id) {
            return response()->json([
                'success' => false,
                'message' => 'This booking has no astrologer assigned for review.',
            ], 422);
        }

        $validated = $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'review' => 'nullable|string|max:1000',
        ]);

        $review = AstrologerReview::updateOrCreate(
            ['booking_id' => $booking->id],
            [
                'user_id' => $user->id,
                'astrologer_id' => $booking->astrologer_id,
                'rating' => $validated['rating'],
                'review' => trim((string) ($validated['review'] ?? '')) ?: null,
            ]
        );

        $summary = $this->refreshAstrologerReviewSummary($booking->astrologer_id);

        return response()->json([
            'success' => true,
            'message' => 'Rating submitted successfully.',
            'review' => $review->load('user'),
            'summary' => $summary,
        ]);
    }

    private function refreshAstrologerReviewSummary(int $astrologerId): array
    {
        $summary = AstrologerReview::where('astrologer_id', $astrologerId)
            ->selectRaw('AVG(rating) as average_rating, COUNT(*) as total_reviews')
            ->first();

        $averageRating = $summary && $summary->average_rating !== null
            ? round((float) $summary->average_rating, 1)
            : null;
        $totalReviews = (int) ($summary->total_reviews ?? 0);

        AstrologerDetail::updateOrCreate(
            ['user_id' => $astrologerId],
            [
                'rating' => $averageRating,
                'total_reviews' => $totalReviews,
            ]
        );

        return [
            'rating' => $averageRating,
            'total_reviews' => $totalReviews,
        ];
    }
}
