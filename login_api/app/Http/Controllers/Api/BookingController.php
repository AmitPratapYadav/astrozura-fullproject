<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\User;
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
            'duration' => ['required', 'integer', Rule::in($this->allowedDurations)],
            'booking_date' => 'required|date',
        ]);

        $timezone = 'Asia/Kolkata';
        $astrologer = User::with('astrologerDetail')->findOrFail($validated['astrologer_id']);
        $day = Carbon::parse($validated['booking_date'], $timezone)->startOfDay();
        $slots = $this->generateAvailabilitySlots(
            $astrologer->id,
            $day,
            (int) $validated['duration'],
            $timezone
        );

        $rate = $validated['consultation_type'] === 'chat'
            ? (float) ($astrologer->astrologerDetail?->chat_price ?? 0)
            : (float) ($astrologer->astrologerDetail?->call_price ?? 0);

        return response()->json([
            'success' => true,
            'slots' => $slots,
            'amount' => $rate * (int) $validated['duration'],
            'rate_per_minute' => $rate,
            'timezone' => $timezone,
        ]);
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'astrologer_id'     => [
                'required',
                'integer',
                Rule::exists('users', 'id')->where(fn ($query) => $query->where('role', 'astrologer')),
            ],
            'consultation_type' => 'required|in:chat,call',
            'duration'          => ['required', 'integer', Rule::in($this->allowedDurations)],
            'booking_date'      => 'required|date',
            'booking_time'      => 'required|string',
            'notes'             => 'nullable|string|max:1000',
            'birth_details' => 'nullable|array',
            'birth_details.date_of_birth' => 'nullable|date',
            'birth_details.time_of_birth' => 'nullable|string|max:50',
            'birth_details.place_of_birth' => 'nullable|string|max:255',
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

        $rate = $validated['consultation_type'] === 'chat'
            ? (float) ($astrologer->astrologerDetail?->chat_price ?? 0)
            : (float) ($astrologer->astrologerDetail?->call_price ?? 0);

        $booking = Booking::create([
            'user_id' => $user->id,
            'astrologer_id' => $astrologer->id,
            'user_name' => $user->name,
            'user_email' => $user->email,
            'astrologer_name' => $astrologer->name,
            'consultation_type' => $validated['consultation_type'],
            'duration' => (int) $validated['duration'],
            'booking_date' => $scheduledAt->toDateString(),
            'booking_time' => $scheduledAt->format('g:i A'),
            'scheduled_at' => $scheduledAt,
            'ends_at' => $endsAt,
            'timezone' => $timezone,
            'amount' => $rate * (int) $validated['duration'],
            'status' => 'confirmed',
            'payment_status' => 'paid',
            'payment_method' => 'mock_gateway',
            'notes' => $validated['notes'] ?? null,
            'birth_details' => $this->extractBirthDetails($validated['birth_details'] ?? null),
        ]);

        $booking->update([
            'booking_reference' => 'BK-' . str_pad((string) $booking->id, 6, '0', STR_PAD_LEFT),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Booking created successfully',
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
            ->orderBy('scheduled_at')
            ->get();

        $upcoming = $bookings->filter(fn ($booking) => $this->isUpcomingBooking($booking, $now))->values();
        $history = $bookings->reject(fn ($booking) => $this->isUpcomingBooking($booking, $now))->values();

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

    private function hasOverlappingBooking(int $astrologerId, Carbon $start, Carbon $end): bool
    {
        $startUtc = $start->copy()->utc();
        $endUtc = $end->copy()->utc();

        return Booking::where('astrologer_id', $astrologerId)
            ->whereIn('status', $this->blockingStatuses)
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
            'gender' => $birthDetails['gender'] ?? null,
        ], fn ($value) => $value !== null && $value !== '');

        return $normalized === [] ? null : $normalized;
    }
}
