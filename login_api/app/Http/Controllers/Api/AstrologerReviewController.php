<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AstrologerDetail;
use App\Models\AstrologerReview;
use App\Models\Booking;
use Carbon\Carbon;
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

    public function astrologerIndex(Request $request)
    {
        $user = $request->user();
        abort_unless($user?->role === 'astrologer', 403);

        $reviews = AstrologerReview::with(['user:id,name,profile_image', 'booking:id,booking_reference,scheduled_at'])
            ->where('astrologer_id', $user->id)
            ->orderByDesc('is_pinned')
            ->orderByDesc('pinned_at')
            ->latest()
            ->paginate((int) $request->query('per_page', 20));

        return response()->json([
            'success' => true,
            'reviews' => $reviews,
        ]);
    }

    public function pin(Request $request, AstrologerReview $review)
    {
        $user = $request->user();
        abort_unless($user?->role === 'astrologer' && (int) $review->astrologer_id === (int) $user->id, 403);

        $validated = $request->validate([
            'is_pinned' => 'nullable|boolean',
        ]);

        $pin = array_key_exists('is_pinned', $validated)
            ? (bool) $validated['is_pinned']
            : !$review->is_pinned;

        $review->update([
            'is_pinned' => $pin,
            'pinned_at' => $pin ? Carbon::now('UTC') : null,
        ]);

        return response()->json([
            'success' => true,
            'review' => $review->fresh(['user:id,name,profile_image', 'booking:id,booking_reference,scheduled_at']),
        ]);
    }

    public function flag(Request $request, AstrologerReview $review)
    {
        $user = $request->user();
        abort_unless($user?->role === 'astrologer' && (int) $review->astrologer_id === (int) $user->id, 403);

        $validated = $request->validate([
            'flag_reason' => 'nullable|string|max:1000',
        ]);

        $review->update([
            'is_flagged' => true,
            'flag_reason' => trim((string) ($validated['flag_reason'] ?? '')) ?: 'Flagged by astrologer for admin review.',
            'flagged_at' => Carbon::now('UTC'),
            'flagged_by' => $user->id,
        ]);

        return response()->json([
            'success' => true,
            'review' => $review->fresh(['user:id,name,profile_image', 'booking:id,booking_reference,scheduled_at']),
        ]);
    }

    public function adminIndex(Request $request)
    {
        abort_unless($request->user()?->role === 'admin', 403);

        $query = AstrologerReview::with([
                'user:id,name,email,profile_image',
                'astrologer:id,name,email',
                'booking:id,booking_reference,scheduled_at,status',
            ])
            ->latest();

        if ($request->boolean('flagged')) {
            $query->where('is_flagged', true);
        }

        return response()->json([
            'success' => true,
            'reviews' => $query->paginate((int) $request->query('per_page', 30)),
        ]);
    }

    public function adminDestroy(Request $request, AstrologerReview $review)
    {
        abort_unless($request->user()?->role === 'admin', 403);

        $astrologerId = (int) $review->astrologer_id;
        $review->delete();
        $summary = $this->refreshAstrologerReviewSummary($astrologerId);

        return response()->json([
            'success' => true,
            'message' => 'Review deleted.',
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
