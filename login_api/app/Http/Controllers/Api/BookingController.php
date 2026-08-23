<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AstrologerReview;
use App\Models\Booking;
use App\Models\AdminNotification;
use App\Models\User;
use App\Services\UserNotificationService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class BookingController extends Controller
{
    private array $allowedDurations = [10, 15, 20, 30];
    private array $blockingStatuses = ['confirmed', 'in_progress'];

    public function getAvailability(Request $request)
    {
        $validated = $request->validate([
            'astrologer_id' => [
                'required',
                'integer',
                Rule::exists('users', 'id')->where(fn ($query) => $query->where('role', 'astrologer')),
            ],
            'consultation_type' => 'required|in:chat,call',
            'service_context' => 'nullable|string|max:80',
            'duration' => ['required', 'integer', Rule::in($this->allowedDurations)],
            'booking_date' => 'required|date',
        ]);

        $timezone = 'Asia/Kolkata';
        $astrologer = User::with('astrologerDetail')->findOrFail($validated['astrologer_id']);
        $this->ensureAstrologerCanAccept($astrologer, $validated['consultation_type'], $validated['service_context'] ?? null);
        $day = Carbon::parse($validated['booking_date'], $timezone)->startOfDay();
        $slots = $this->generateAvailabilitySlots(
            $astrologer->id,
            $day,
            (int) $validated['duration'],
            $timezone
        );

        $amount = $this->consultationAmount($astrologer, $validated['consultation_type'], (int) $validated['duration']);
        $rate = $amount / (int) $validated['duration'];

        return response()->json([
            'success' => true,
            'slots' => $slots,
            'amount' => $amount,
            'rate_per_minute' => $rate,
            'timezone' => $timezone,
        ]);
    }

    public function store(Request $request, UserNotificationService $notifications)
    {
        $validated = $request->validate([
            'astrologer_id'     => [
                'required',
                'integer',
                Rule::exists('users', 'id')->where(fn ($query) => $query->where('role', 'astrologer')),
            ],
            'consultation_type' => 'required|in:chat,call',
            'service_context' => 'nullable|string|max:80',
            'duration'          => ['required', 'integer', Rule::in($this->allowedDurations)],
            'booking_date'      => 'required|date',
            'booking_time'      => 'required|string',
            'notes'             => 'nullable|string|max:1000',
            'birth_details' => 'nullable|array',
            'birth_details.date_of_birth' => 'nullable|date',
            'birth_details.time_of_birth' => 'nullable|string|max:50',
            'birth_details.place_of_birth' => 'nullable|string|max:255',
            'birth_details.latitude' => 'nullable|numeric|between:-90,90',
            'birth_details.longitude' => 'nullable|numeric|between:-180,180',
            'birth_details.coordinates' => 'nullable|string|max:80',
            'birth_details.gender' => 'nullable|in:male,female,other',
        ]);

        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'You must be logged in to book a consultation.',
            ], 401);
        }

        $astrologer = User::with('astrologerDetail')->findOrFail($validated['astrologer_id']);
        $this->ensureAstrologerCanAccept($astrologer, $validated['consultation_type'], $validated['service_context'] ?? null);
        $timezone = 'Asia/Kolkata';
        $scheduledAt = $this->parseScheduledAt($validated['booking_date'], $validated['booking_time'], $timezone);
        $endsAt = $scheduledAt->copy()->addMinutes((int) $validated['duration']);

        if ($scheduledAt->lessThan(Carbon::now($timezone))) {
            return response()->json([
                'success' => false,
                'message' => 'Please select an upcoming consultation slot.',
            ], 422);
        }

        if ($this->hasOverlappingBooking($astrologer->id, $scheduledAt, $endsAt)) {
            return response()->json([
                'success' => false,
                'message' => 'This slot is no longer available. Please choose another time.',
            ], 422);
        }

        $amount = $this->consultationAmount($astrologer, $validated['consultation_type'], (int) $validated['duration']);
        $commissionPercentage = (float) (
            $validated['consultation_type'] === 'chat'
                ? $astrologer->astrologerDetail?->chat_commission_percentage
                : $astrologer->astrologerDetail?->call_commission_percentage
        );
        $platformCommission = round($amount * $commissionPercentage / 100, 2);
        $localPaymentBypass = app()->environment('local');

        $booking = Booking::create([
            'user_id' => $user->id,
            'astrologer_id' => $astrologer->id,
            'user_name' => $user->name,
            'user_email' => $user->email,
            'astrologer_name' => $astrologer->name,
            'consultation_type' => $validated['consultation_type'],
            'service_context' => $validated['service_context'] ?? null,
            'duration' => (int) $validated['duration'],
            'booking_date' => $scheduledAt->toDateString(),
            'booking_time' => $scheduledAt->format('g:i A'),
            'scheduled_at' => $scheduledAt,
            'ends_at' => $endsAt,
            'timezone' => $timezone,
            'amount' => $amount,
            'commission_percentage' => $commissionPercentage,
            'platform_commission_amount' => $platformCommission,
            'astrologer_earning_amount' => round($amount - $platformCommission, 2),
            'status' => $localPaymentBypass ? 'confirmed' : 'payment_pending',
            'payment_status' => $localPaymentBypass ? 'paid' : 'pending',
            'payment_method' => $localPaymentBypass ? 'local_bypass' : 'razorpay',
            'payment_id' => $localPaymentBypass ? 'local_' . now()->timestamp : null,
            'notes' => $validated['notes'] ?? null,
            'birth_details' => $this->extractBirthDetails($validated['birth_details'] ?? null),
        ]);

        $booking->update([
            'booking_reference' => 'BK-' . str_pad((string) $booking->id, 6, '0', STR_PAD_LEFT),
        ]);

        $notifications->send(
            $user,
            'main',
            'booking_created',
            'Consultation reserved',
            $localPaymentBypass
                ? "{$booking->booking_reference} is confirmed for local testing."
                : "{$booking->booking_reference} is awaiting payment confirmation.",
            '/my-bookings',
            ['booking_id' => $booking->id]
        );

        return response()->json([
            'success' => true,
            'message' => $localPaymentBypass
                ? 'Booking confirmed with local payment bypass.'
                : 'Booking created. Complete payment to confirm the session.',
            'booking' => $booking->fresh()->load(['astrologer.astrologerDetail', 'user']),
        ], 201);
    }

    public function myBookings(Request $request)
    {
        $timezone = 'Asia/Kolkata';
        $now = Carbon::now($timezone);

        $bookings = Booking::with(['astrologer.astrologerDetail', 'review'])
            ->where('user_id', $request->user()->id)
            ->orderByDesc('scheduled_at')
            ->get();

        return response()->json([
            'success' => true,
            'bookings' => $bookings,
            'upcoming' => $bookings->filter(fn ($booking) => $this->isUpcomingBooking($booking, $now))->values(),
            'history' => $bookings->reject(fn ($booking) => $this->isUpcomingBooking($booking, $now))->values(),
        ]);
    }

    public function astrologerBookings(Request $request)
    {
        $user = $request->user();
        if (!$user || $user->role !== 'astrologer') {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized access.',
            ], 403);
        }

        $timezone = 'Asia/Kolkata';
        $now = Carbon::now($timezone);
        $bookings = Booking::with('user')
            ->where('astrologer_id', $user->id)
            ->orderByDesc('scheduled_at')
            ->get();

        $upcoming = $bookings
            ->filter(fn ($booking) => $this->isUpcomingBooking($booking, $now))
            ->sortBy('scheduled_at')
            ->values();
        $history = $bookings
            ->reject(fn ($booking) => $this->isUpcomingBooking($booking, $now))
            ->values();

        return response()->json([
            'success' => true,
            'bookings' => $bookings,
            'upcoming' => $upcoming,
            'history' => $history,
            'stats' => [
                'today_bookings' => $bookings->filter(function ($booking) use ($now) {
                    return optional($booking->scheduled_at)
                        ?->copy()
                        ->timezone($booking->timezone ?: 'Asia/Kolkata')
                        ?->isSameDay($now);
                })->count(),
                'active_sessions' => $bookings->filter(function ($booking) use ($now) {
                    return in_array($booking->status, $this->blockingStatuses, true)
                        && $booking->scheduled_at
                        && $booking->ends_at
                        && $now->betweenIncluded($booking->scheduled_at, $booking->ends_at);
                })->count(),
                'completed_sessions' => $bookings->where('status', 'completed')->count(),
                'monthly_revenue' => (float) $bookings
                    ->filter(function ($booking) use ($now) {
                        return $booking->payment_status === 'paid'
                            && $booking->scheduled_at
                            && $booking->scheduled_at
                                ->copy()
                                ->timezone($booking->timezone ?: 'Asia/Kolkata')
                                ->isSameMonth($now);
                    })
                    ->sum('amount'),
            ],
        ]);
    }

    public function astrologerPerformance(Request $request)
    {
        $user = $request->user();
        if (!$user || $user->role !== 'astrologer') {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized access.',
            ], 403);
        }

        [$start, $end, $range] = $this->resolvePerformanceRange($request);
        $startUtc = $start->copy()->utc();
        $endUtc = $end->copy()->utc();

        $bookings = Booking::where('astrologer_id', $user->id)
            ->whereBetween('scheduled_at', [$startUtc, $endUtc])
            ->get();

        $paidBookings = $bookings->where('payment_status', 'paid');
        $reviews = AstrologerReview::with(['user:id,name,profile_image', 'booking:id,booking_reference,scheduled_at'])
            ->where('astrologer_id', $user->id)
            ->whereBetween('created_at', [$startUtc, $endUtc])
            ->orderByDesc('is_pinned')
            ->orderByDesc('pinned_at')
            ->latest()
            ->get();

        $series = collect();
        $cursor = $start->copy()->startOfDay();
        while ($cursor->lessThanOrEqualTo($end)) {
            $dayStart = $cursor->copy()->startOfDay();
            $dayEnd = $cursor->copy()->endOfDay();
            $dayStartUtc = $dayStart->copy()->utc();
            $dayEndUtc = $dayEnd->copy()->utc();

            $dayBookings = $bookings->filter(fn ($booking) => $booking->scheduled_at && $booking->scheduled_at->betweenIncluded($dayStartUtc, $dayEndUtc));
            $dayPaid = $dayBookings->where('payment_status', 'paid');
            $dayReviews = $reviews->filter(fn ($review) => $review->created_at && $review->created_at->betweenIncluded($dayStartUtc, $dayEndUtc));

            $series->push([
                'label' => $dayStart->format($range === 'year' ? 'M d' : 'd M'),
                'bookings' => $dayBookings->count(),
                'income' => round((float) $dayPaid->sum('astrologer_earning_amount'), 2),
                'reviews' => $dayReviews->count(),
            ]);

            $cursor->addDay();
        }

        return response()->json([
            'success' => true,
            'range' => [
                'key' => $range,
                'from' => $start->toDateString(),
                'to' => $end->toDateString(),
                'timezone' => 'Asia/Kolkata',
            ],
            'stats' => [
                'bookings_received' => $bookings->count(),
                'completed_bookings' => $bookings->where('status', 'completed')->count(),
                'paid_bookings' => $paidBookings->count(),
                'gross_income' => round((float) $paidBookings->sum('amount'), 2),
                'astrologer_earnings' => round((float) $paidBookings->sum('astrologer_earning_amount'), 2),
                'platform_commission' => round((float) $paidBookings->sum('platform_commission_amount'), 2),
                'reviews_count' => $reviews->count(),
                'average_rating' => $reviews->count() ? round((float) $reviews->avg('rating'), 1) : null,
            ],
            'series' => $series,
            'reviews' => $reviews->take(10)->values(),
        ]);
    }

    public function markCompleted(Request $request, $id)
    {
        $user = $request->user();
        if (!$user || $user->role !== 'astrologer') {
            return response()->json([
                'success' => false,
                'message' => 'Unauthorized access.',
            ], 403);
        }

        $booking = Booking::where('astrologer_id', $user->id)->findOrFail($id);

        if (in_array($booking->status, ['completed', 'cancelled', 'declined'], true)) {
            return response()->json([
                'success' => false,
                'message' => 'This booking is already closed.',
            ], 422);
        }

        $booking->update([
            'status' => 'completed',
            'completed_at' => Carbon::now('Asia/Kolkata'),
            'session_ended_at' => Carbon::now('Asia/Kolkata'),
            'session_end_reason' => 'manual_complete',
            'session_ended_by' => "astrologer:{$user->id}",
            'session_last_activity_at' => Carbon::now('Asia/Kolkata'),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Booking marked as completed.',
            'booking' => $booking->fresh()->load('user'),
        ]);
    }

    private function parseScheduledAt(string $bookingDate, string $bookingTime, string $timezone): Carbon
    {
        $formats = ['Y-m-d g:i A', 'Y-m-d H:i', 'Y-m-d h:i A'];

        foreach ($formats as $format) {
            try {
                return Carbon::createFromFormat($format, "{$bookingDate} {$bookingTime}", $timezone);
            } catch (\Throwable $exception) {
                continue;
            }
        }

        return Carbon::parse("{$bookingDate} {$bookingTime}", $timezone);
    }

    private function resolvePerformanceRange(Request $request): array
    {
        $timezone = 'Asia/Kolkata';
        $range = (string) $request->query('range', 'month');
        $now = Carbon::now($timezone);

        if ($range === 'custom') {
            $start = Carbon::parse((string) $request->query('from', $now->toDateString()), $timezone)->startOfDay();
            $end = Carbon::parse((string) $request->query('to', $now->toDateString()), $timezone)->endOfDay();
            return [$start, $end, $range];
        }

        return match ($range) {
            'today', 'daily' => [$now->copy()->startOfDay(), $now->copy()->endOfDay(), 'today'],
            'week', 'weekly' => [$now->copy()->startOfWeek(), $now->copy()->endOfWeek(), 'week'],
            'year', 'yearly' => [$now->copy()->startOfYear(), $now->copy()->endOfYear(), 'year'],
            default => [$now->copy()->startOfMonth(), $now->copy()->endOfMonth(), 'month'],
        };
    }

    private function hasOverlappingBooking(int $astrologerId, Carbon $start, Carbon $end): bool
    {
        $startUtc = $start->copy()->utc();
        $endUtc = $end->copy()->utc();

        return Booking::where('astrologer_id', $astrologerId)
            ->where(function ($query) {
                $query->whereIn('status', $this->blockingStatuses)
                    ->orWhere(function ($pending) {
                        $pending->where('status', 'payment_pending')
                            ->where('created_at', '>=', Carbon::now()->subMinutes(15));
                    });
            })
            ->where(function ($query) use ($startUtc, $endUtc) {
                $query->where('scheduled_at', '<', $endUtc)
                    ->where('ends_at', '>', $startUtc);
            })
            ->exists();
    }

    private function generateAvailabilitySlots(int $astrologerId, Carbon $day, int $duration, string $timezone): array
    {
        $slotStart = $day->copy()->startOfDay();
        $slotEnd = $day->copy()->endOfDay();
        $now = Carbon::now($timezone);
        $slots = [];

        while ($slotStart->copy()->addMinutes($duration)->lessThanOrEqualTo($slotEnd)) {
            $candidateEnd = $slotStart->copy()->addMinutes($duration);
            $isPast = $slotStart->lessThan($now);
            $isAvailable = !$isPast && !$this->hasOverlappingBooking($astrologerId, $slotStart, $candidateEnd);

            $slots[] = [
                'label' => $slotStart->format('g:i A'),
                'start' => $slotStart->toIso8601String(),
                'end' => $candidateEnd->toIso8601String(),
                'is_available' => $isAvailable,
            ];

            $slotStart->addMinutes(30);
        }

        return $slots;
    }

    private function isUpcomingBooking(Booking $booking, Carbon $now): bool
    {
        if (in_array($booking->status, ['completed', 'cancelled', 'declined'], true)) {
            return false;
        }

        if ($booking->ends_at) {
            return $booking->ends_at->greaterThanOrEqualTo($now);
        }

        return $booking->scheduled_at ? $booking->scheduled_at->greaterThanOrEqualTo($now) : false;
    }

    private function extractBirthDetails(?array $birthDetails): ?array
    {
        if (!$birthDetails) {
            return null;
        }

        $normalized = array_filter([
            'date_of_birth' => $birthDetails['date_of_birth'] ?? null,
            'time_of_birth' => $birthDetails['time_of_birth'] ?? null,
            'place_of_birth' => $birthDetails['place_of_birth'] ?? null,
            'latitude' => $birthDetails['latitude'] ?? null,
            'longitude' => $birthDetails['longitude'] ?? null,
            'coordinates' => $birthDetails['coordinates'] ?? null,
            'gender' => $birthDetails['gender'] ?? null,
        ], fn ($value) => $value !== null && $value !== '');

        return $normalized === [] ? null : $normalized;
    }

    private function ensureAstrologerCanAccept(User $astrologer, string $type, ?string $serviceContext = null): void
    {
        $detail = $astrologer->astrologerDetail;
        abort_if(!$detail?->is_online, 422, 'This astrologer is currently unavailable.');
        abort_if($type === 'chat' && !$detail->supports_chat, 422, 'This astrologer is not available for chat consultations.');
        abort_if($type === 'call' && !$detail->supports_call, 422, 'This astrologer is not available for call consultations.');
        abort_if($serviceContext === 'palm-reading' && !$detail->supports_palm_reading, 422, 'This astrologer is not available for palm reading consultations.');
    }

    private function consultationAmount(User $astrologer, string $type, int $duration): float
    {
        $detail = $astrologer->astrologerDetail;
        $durationPrices = $type === 'chat'
            ? ($detail?->chat_duration_prices ?? [])
            : ($detail?->call_duration_prices ?? []);
        $override = $durationPrices[(string) $duration] ?? $durationPrices[$duration] ?? null;

        if ($override !== null && $override !== '') {
            return round((float) $override, 2);
        }

        $rate = $type === 'chat'
            ? (float) ($detail?->chat_price ?? 0)
            : (float) ($detail?->call_price ?? 0);

        return round($rate * $duration, 2);
    }
}
