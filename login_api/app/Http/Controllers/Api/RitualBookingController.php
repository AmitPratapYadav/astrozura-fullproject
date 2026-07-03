<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RitualBooking;
use App\Models\RitualService;
use App\Models\AdminNotification;
use App\Services\UserNotificationService;
use Carbon\Carbon;
use Illuminate\Http\Request;

class RitualBookingController extends Controller
{
    public function store(Request $request, RitualService $ritual)
    {
        $user = $request->user();

        if (!$user) {
            return response()->json([
                'success' => false,
                'message' => 'You must be logged in to book a ritual.',
            ], 401);
        }

        $validated = $request->validate([
            'devotee_name' => 'required|string|max:255',
            'devotee_email' => 'nullable|email|max:255',
            'devotee_phone' => 'required|string|max:20',
            'preferred_date' => 'required|date',
            'preferred_time' => 'required|string|max:50',
            'venue_type' => 'required|in:online,temple,client_place',
            'location_address' => 'nullable|string|max:1000',
            'location_city' => 'required|string|max:120',
            'location_state' => 'required|string|max:120',
            'location_pincode' => 'nullable|string|max:20',
            'expense_acknowledged' => 'nullable|boolean',
            'notes' => 'nullable|string|max:2000',
            'birth_details' => 'nullable|array',
            'birth_details.date_of_birth' => 'nullable|string|max:30',
            'birth_details.time_of_birth' => 'nullable|string|max:30',
            'birth_details.place_of_birth' => 'nullable|string|max:255',
        ]);

        if (
            $validated['venue_type'] === 'client_place'
            && empty($validated['expense_acknowledged'])
        ) {
            return response()->json([
                'success' => false,
                'message' => 'Please confirm that priest travel and accommodation expenses will be borne by the client for offline rituals at your location.',
            ], 422);
        }

        $booking = RitualBooking::create([
            'booking_reference' => 'RB-' . str_pad((string) (RitualBooking::max('id') + 1), 6, '0', STR_PAD_LEFT),
            'user_id' => $user->id,
            'ritual_service_id' => $ritual->id,
            'astrologer_id' => $ritual->assigned_astrologer_id,
            'devotee_name' => $validated['devotee_name'],
            'devotee_email' => $validated['devotee_email'] ?? $user->email,
            'devotee_phone' => $validated['devotee_phone'],
            'preferred_date' => $validated['preferred_date'],
            'preferred_time' => $validated['preferred_time'],
            'timezone' => 'Asia/Kolkata',
            'venue_type' => $validated['venue_type'],
            'location_address' => $validated['location_address'] ?? null,
            'location_city' => $validated['location_city'],
            'location_state' => $validated['location_state'],
            'location_pincode' => $validated['location_pincode'] ?? null,
            'expense_acknowledged' => (bool) ($validated['expense_acknowledged'] ?? false),
            'notes' => $validated['notes'] ?? null,
            'birth_details' => $validated['birth_details'] ?? null,
            'amount' => $ritual->price ?? 0,
            'status' => 'payment_pending',
            'payment_status' => 'pending',
            'payment_method' => 'razorpay',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Ritual request created. Complete payment to submit it.',
            'booking' => $booking->load(['ritual', 'astrologer']),
        ], 201);
    }

    public function index(Request $request)
    {
        abort_unless($request->user()?->role === 'admin', 403);

        return response()->json([
            'success' => true,
            'bookings' => RitualBooking::with(['ritual', 'user', 'astrologer'])
                ->latest()
                ->get(),
        ]);
    }

    public function myBookings(Request $request)
    {
        $timezone = 'Asia/Kolkata';
        $now = Carbon::now($timezone);

        $bookings = RitualBooking::with(['ritual', 'astrologer'])
            ->where('user_id', $request->user()->id)
            ->latest()
            ->get();

        return response()->json([
            'success' => true,
            'bookings' => $bookings,
            'upcoming' => $bookings->filter(fn (RitualBooking $booking) => $this->isUpcomingBooking($booking, $now))->values(),
            'history' => $bookings->reject(fn (RitualBooking $booking) => $this->isUpcomingBooking($booking, $now))->values(),
        ]);
    }

    public function updateStatus(
        Request $request,
        RitualBooking $ritualBooking,
        UserNotificationService $notifications
    )
    {
        abort_unless($request->user()?->role === 'admin', 403);

        $validated = $request->validate([
            'status' => 'required|string|max:50',
            'admin_response' => 'nullable|string|max:4000',
            'confirmed_date' => 'nullable|date',
            'confirmed_time' => 'nullable|string|max:50',
        ]);

        $ritualBooking->update([
            'status' => $validated['status'],
            'admin_response' => $validated['admin_response'] ?? null,
            'confirmed_date' => $validated['confirmed_date'] ?? null,
            'confirmed_time' => $validated['confirmed_time'] ?? null,
            'admin_response_at' => isset($validated['admin_response']) && $validated['admin_response'] !== ''
                ? Carbon::now('Asia/Kolkata')
                : $ritualBooking->admin_response_at,
        ]);

        if ($ritualBooking->user_id) {
            $notifications->send(
                $ritualBooking->user_id,
                'main',
                'ritual_status',
                'Pooja Anusthan update',
                $validated['admin_response'] ?: "Your ritual booking is now {$validated['status']}.",
                '/my-bookings',
                ['ritual_booking_id' => $ritualBooking->id, 'status' => $validated['status']]
            );
        }

        return response()->json([
            'success' => true,
            'message' => 'Ritual booking updated successfully.',
            'booking' => $ritualBooking->fresh(['ritual', 'user', 'astrologer']),
        ]);
    }

    private function isUpcomingBooking(RitualBooking $booking, Carbon $now): bool
    {
        if (in_array($booking->status, ['completed', 'cancelled'], true)) {
            return false;
        }

        $bookingDate = $booking->confirmed_date ?? $booking->preferred_date;
        if (!$bookingDate) {
            return false;
        }

        $dateString = $bookingDate instanceof Carbon
            ? $bookingDate->toDateString()
            : (string) $bookingDate;

        $timeString = $booking->confirmed_time ?: $booking->preferred_time ?: '00:00';

        try {
            $scheduledAt = Carbon::parse("{$dateString} {$timeString}", $booking->timezone ?: 'Asia/Kolkata');
        } catch (\Throwable $exception) {
            $scheduledAt = Carbon::parse($dateString, $booking->timezone ?: 'Asia/Kolkata')->startOfDay();
        }

        return $scheduledAt->greaterThanOrEqualTo($now);
    }
}
