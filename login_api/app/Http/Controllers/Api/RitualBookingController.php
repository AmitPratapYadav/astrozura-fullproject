<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\RitualBooking;
use App\Models\RitualBookingUpdate;
use App\Models\RitualService;
use App\Models\AdminNotification;
use App\Models\User;
use App\Services\SmartChatWhatsAppService;
use App\Services\UltronSmsService;
use App\Services\UserNotificationService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class RitualBookingController extends Controller
{
    private int $consultationDuration = 30;
    private array $blockingStatuses = ['confirmed', 'in_progress'];

    public function availability(Request $request, RitualService $ritual)
    {
        $validated = $request->validate([
            'booking_date' => 'required|date',
        ]);

        $expert = $this->resolveRitualExpert($ritual);
        if (!$expert) {
            return response()->json([
                'success' => false,
                'message' => 'No ritual booking expert is currently configured. Please contact support.',
                'slots' => [],
            ], 422);
        }

        $timezone = 'Asia/Kolkata';
        $day = Carbon::parse($validated['booking_date'], $timezone)->startOfDay();

        return response()->json([
            'success' => true,
            'astrologer' => $expert->only(['id', 'name']),
            'duration' => $this->consultationDuration,
            'timezone' => $timezone,
            'slots' => $this->generateAvailabilitySlots($expert->id, $day, $this->consultationDuration, $timezone),
        ]);
    }

    public function store(Request $request, RitualService $ritual, UserNotificationService $notifications)
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

        $expert = $this->resolveRitualExpert($ritual);
        if (!$expert) {
            return response()->json([
                'success' => false,
                'message' => 'No ritual booking expert is currently configured. Please contact support before booking this ritual.',
            ], 422);
        }

        $timezone = 'Asia/Kolkata';
        $scheduledAt = $this->parseScheduledAt($validated['preferred_date'], $validated['preferred_time'], $timezone);
        $endsAt = $scheduledAt->copy()->addMinutes($this->consultationDuration);

        if ($scheduledAt->lessThan(Carbon::now($timezone))) {
            return response()->json([
                'success' => false,
                'message' => 'Please select an upcoming ritual consultation slot.',
            ], 422);
        }

        if ($this->hasOverlappingBooking($expert->id, $scheduledAt, $endsAt)) {
            return response()->json([
                'success' => false,
                'message' => 'This ritual consultation slot is no longer available. Please choose another time.',
            ], 422);
        }

        [$booking, $consultation] = DB::transaction(function () use ($user, $ritual, $expert, $validated, $scheduledAt, $endsAt, $timezone) {
            $consultation = Booking::create([
                'user_id' => $user->id,
                'astrologer_id' => $expert->id,
                'user_name' => $user->name,
                'user_email' => $user->email,
                'astrologer_name' => $expert->name,
                'consultation_type' => 'chat',
                'service_context' => 'ritual-consultation',
                'duration' => $this->consultationDuration,
                'booking_date' => $scheduledAt->toDateString(),
                'booking_time' => $scheduledAt->format('g:i A'),
                'scheduled_at' => $scheduledAt,
                'ends_at' => $endsAt,
                'timezone' => $timezone,
                'amount' => 0,
                'commission_percentage' => 0,
                'platform_commission_amount' => 0,
                'astrologer_earning_amount' => 0,
                'status' => 'confirmed',
                'payment_status' => 'paid',
                'payment_method' => 'ritual_consultation_free',
                'payment_id' => 'ritual_consult_' . now()->timestamp,
                'notes' => 'Pooja Anusthan consultation for ' . $ritual->name,
                'birth_details' => $validated['birth_details'] ?? null,
            ]);

            $consultation->update([
                'booking_reference' => 'BK-' . str_pad((string) $consultation->id, 6, '0', STR_PAD_LEFT),
            ]);

            $booking = RitualBooking::create([
                'booking_reference' => 'RB-' . str_pad((string) (RitualBooking::max('id') + 1), 6, '0', STR_PAD_LEFT),
                'user_id' => $user->id,
                'ritual_service_id' => $ritual->id,
                'astrologer_id' => $expert->id,
                'consultation_booking_id' => $consultation->id,
                'consultation_status' => 'scheduled',
                'devotee_name' => $validated['devotee_name'],
                'devotee_email' => $validated['devotee_email'] ?? $user->email,
                'devotee_phone' => $validated['devotee_phone'],
                'preferred_date' => $scheduledAt->toDateString(),
                'preferred_time' => $scheduledAt->format('H:i'),
                'confirmed_date' => $scheduledAt->toDateString(),
                'confirmed_time' => $scheduledAt->format('H:i'),
                'timezone' => $timezone,
                'venue_type' => $validated['venue_type'],
                'location_address' => $validated['location_address'] ?? null,
                'location_city' => $validated['location_city'],
                'location_state' => $validated['location_state'],
                'location_pincode' => $validated['location_pincode'] ?? null,
                'expense_acknowledged' => (bool) ($validated['expense_acknowledged'] ?? false),
                'notes' => $validated['notes'] ?? null,
                'birth_details' => $validated['birth_details'] ?? null,
                'amount' => 0,
                'status' => 'consultation_scheduled',
                'payment_status' => 'not_requested',
                'payment_method' => null,
            ]);

            return [$booking, $consultation];
        });

        $notifications->send(
            $user,
            'main',
            'ritual_consultation_scheduled',
            'Ritual consultation scheduled',
            "{$booking->booking_reference} is scheduled with {$expert->name}.",
            "/session/{$consultation->id}",
            ['ritual_booking_id' => $booking->id, 'booking_id' => $consultation->id]
        );

        AdminNotification::create([
            'type' => 'ritual_consultation',
            'title' => 'New ritual consultation',
            'message' => "{$user->name} booked a ritual consultation for {$ritual->name}.",
            'route' => '/ritual-bookings',
            'data' => ['ritual_booking_id' => $booking->id, 'booking_id' => $consultation->id],
        ]);

        $freshConsultation = $consultation->fresh(['user', 'astrologer']);
        app(UltronSmsService::class)->sendBookingConfirmation($freshConsultation);
        app(SmartChatWhatsAppService::class)->sendBookingConfirmation($freshConsultation);

        return response()->json([
            'success' => true,
            'message' => 'Ritual consultation scheduled successfully.',
            'booking' => $booking->load(['ritual', 'astrologer.astrologerDetail', 'consultationBooking', 'updates.sender']),
        ], 201);
    }

    public function index(Request $request)
    {
        abort_unless($request->user()?->role === 'admin', 403);

        return response()->json([
            'success' => true,
            'bookings' => RitualBooking::with(['ritual', 'user', 'astrologer'])
                ->with(['consultationBooking', 'updates.sender'])
                ->latest()
                ->get()
                ->map(fn (RitualBooking $booking) => $this->syncConsultationLifecycle($booking)),
        ]);
    }

    public function myBookings(Request $request)
    {
        $timezone = 'Asia/Kolkata';
        $now = Carbon::now($timezone);

        $bookings = RitualBooking::with(['ritual', 'astrologer.astrologerDetail', 'consultationBooking', 'updates.sender'])
            ->where('user_id', $request->user()->id)
            ->latest()
            ->get()
            ->map(fn (RitualBooking $booking) => $this->syncConsultationLifecycle($booking));

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
            'confirmed_date' => 'nullable|string|max:80',
            'confirmed_time' => 'nullable|string|max:50',
        ]);

        $updates = [
            'status' => $validated['status'],
            'admin_response' => $validated['admin_response'] ?? null,
            'admin_response_at' => isset($validated['admin_response']) && $validated['admin_response'] !== ''
                ? Carbon::now('Asia/Kolkata')
                : $ritualBooking->admin_response_at,
        ];

        if ($request->filled('confirmed_date')) {
            $updates['confirmed_date'] = $this->normalizeDateForStorage($request->input('confirmed_date'));
        }

        if ($request->filled('confirmed_time')) {
            $updates['confirmed_time'] = $this->normalizeTimeForStorage($request->input('confirmed_time'));
        }

        $ritualBooking->update($updates);

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
            'booking' => $ritualBooking->fresh(['ritual', 'user', 'astrologer', 'consultationBooking', 'updates.sender']),
        ]);
    }

    private function normalizeDateForStorage(mixed $value): ?string
    {
        if ($value instanceof Carbon) {
            return $value->toDateString();
        }

        $text = trim((string) $value);
        if ($text === '') {
            return null;
        }

        if (preg_match('/^(\d{4})-(\d{2})-(\d{2})/', $text, $matches)) {
            return "{$matches[1]}-{$matches[2]}-{$matches[3]}";
        }

        foreach (['d-m-Y', 'd/m/Y', 'm/d/Y'] as $format) {
            try {
                return Carbon::createFromFormat($format, $text, 'Asia/Kolkata')->toDateString();
            } catch (\Throwable) {
                // Try the next known date format.
            }
        }

        try {
            return Carbon::parse($text, 'Asia/Kolkata')->toDateString();
        } catch (\Throwable) {
            throw ValidationException::withMessages([
                'confirmed_date' => 'Please provide the confirmed date in yyyy-mm-dd format.',
            ]);
        }
    }

    private function normalizeTimeForStorage(mixed $value): ?string
    {
        $text = trim((string) $value);
        if ($text === '') {
            return null;
        }

        if (preg_match('/(?:T|^)(\d{1,2}):(\d{2})/', $text, $matches)) {
            $hour = (int) $matches[1];
            $minute = (int) $matches[2];
            if ($hour >= 0 && $hour <= 23 && $minute >= 0 && $minute <= 59) {
                return sprintf('%02d:%02d', $hour, $minute);
            }
        }

        try {
            return Carbon::parse($text, 'Asia/Kolkata')->format('H:i');
        } catch (\Throwable) {
            throw ValidationException::withMessages([
                'confirmed_time' => 'Please provide the confirmed time in HH:mm format.',
            ]);
        }
    }

    public function contextForBooking(Request $request, Booking $booking)
    {
        $user = $request->user();
        abort_unless((int) $booking->user_id === (int) $user->id || (int) $booking->astrologer_id === (int) $user->id, 403);

        $ritualBooking = RitualBooking::with(['ritual', 'user', 'astrologer.astrologerDetail', 'consultationBooking', 'updates.sender'])
            ->where('consultation_booking_id', $booking->id)
            ->first();

        if ($ritualBooking) {
            $ritualBooking = $this->syncConsultationLifecycle($ritualBooking);
        }

        return response()->json([
            'success' => true,
            'ritual_booking' => $ritualBooking,
        ]);
    }

    public function astrologerResponse(
        Request $request,
        RitualBooking $ritualBooking,
        UserNotificationService $notifications
    ) {
        $user = $request->user();
        abort_unless($user?->role === 'astrologer' && (int) $ritualBooking->astrologer_id === (int) $user->id, 403);

        $validated = $request->validate([
            'message' => 'required|string|max:4000',
        ]);

        $consultation = $ritualBooking->consultationBooking;
        if (!$consultation || $consultation->status !== 'completed') {
            return response()->json([
                'success' => false,
                'message' => 'Complete the ritual consultation chat before sending a ritual response.',
            ], 422);
        }

        $update = $ritualBooking->updates()->create([
            'sender_id' => $user->id,
            'sender_role' => 'astrologer',
            'type' => 'reply',
            'message' => $validated['message'],
        ]);

        $notifications->send(
            $ritualBooking->user_id,
            'main',
            'ritual_response',
            'Ritual consultation response',
            $validated['message'],
            '/my-bookings',
            ['ritual_booking_id' => $ritualBooking->id, 'update_id' => $update->id]
        );

        return response()->json([
            'success' => true,
            'message' => 'Ritual response sent.',
            'ritual_booking' => $ritualBooking->fresh(['ritual', 'user', 'astrologer.astrologerDetail', 'consultationBooking', 'updates.sender']),
        ]);
    }

    public function paymentRequest(
        Request $request,
        RitualBooking $ritualBooking,
        UserNotificationService $notifications
    ) {
        $user = $request->user();
        abort_unless($user?->role === 'astrologer' && (int) $ritualBooking->astrologer_id === (int) $user->id, 403);

        $validated = $request->validate([
            'amount' => 'required|numeric|min:1|max:999999',
            'message' => 'nullable|string|max:4000',
        ]);

        $consultation = $ritualBooking->consultationBooking;
        if (!$consultation || $consultation->status !== 'completed') {
            return response()->json([
                'success' => false,
                'message' => 'Complete the ritual consultation chat before requesting payment.',
            ], 422);
        }

        $amount = round((float) $validated['amount'], 2);
        $note = $validated['message'] ?? "Please complete payment of Rs {$amount} to confirm your Pooja Anusthan booking.";

        DB::transaction(function () use ($ritualBooking, $user, $amount, $note) {
            $ritualBooking->update([
                'amount' => $amount,
                'status' => 'payment_requested',
                'payment_status' => 'pending',
                'payment_method' => 'razorpay',
                'payment_requested_at' => Carbon::now('Asia/Kolkata'),
                'payment_requested_by_astrologer_id' => $user->id,
                'payment_note' => $note,
            ]);

            $ritualBooking->updates()->create([
                'sender_id' => $user->id,
                'sender_role' => 'astrologer',
                'type' => 'payment_request',
                'message' => $note,
                'amount' => $amount,
            ]);
        });

        $notifications->send(
            $ritualBooking->user_id,
            'main',
            'ritual_payment_request',
            'Ritual payment requested',
            $note,
            '/my-bookings',
            ['ritual_booking_id' => $ritualBooking->id, 'amount' => $amount]
        );

        return response()->json([
            'success' => true,
            'message' => 'Payment request sent to the user.',
            'ritual_booking' => $ritualBooking->fresh(['ritual', 'user', 'astrologer.astrologerDetail', 'consultationBooking', 'updates.sender']),
        ]);
    }

    private function isUpcomingBooking(RitualBooking $booking, Carbon $now): bool
    {
        if (in_array($booking->status, ['completed', 'cancelled', 'confirmed'], true) || $booking->payment_status === 'paid') {
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

    private function syncConsultationLifecycle(RitualBooking $booking): RitualBooking
    {
        $consultation = $booking->consultationBooking;
        if (!$consultation) {
            return $booking;
        }

        $changes = [];

        if ($consultation->status === 'completed' || $consultation->session_ended_at) {
            if ($booking->consultation_status !== 'completed') {
                $changes['consultation_status'] = 'completed';
            }
            if ($booking->status === 'consultation_scheduled') {
                $changes['status'] = 'consultation_completed';
            }
        } elseif ($consultation->status === 'in_progress') {
            if ($booking->consultation_status !== 'in_progress') {
                $changes['consultation_status'] = 'in_progress';
            }
        } elseif (in_array($consultation->status, ['cancelled', 'declined'], true)) {
            if ($booking->consultation_status !== 'cancelled') {
                $changes['consultation_status'] = 'cancelled';
            }
            if ($booking->status === 'consultation_scheduled') {
                $changes['status'] = 'cancelled';
            }
        }

        if ($changes !== []) {
            $booking->forceFill($changes)->save();
        }

        return $booking;
    }

    private function resolveRitualExpert(RitualService $ritual): ?User
    {
        if ($ritual->assigned_astrologer_id) {
            $assigned = User::with('astrologerDetail')
                ->where('role', 'astrologer')
                ->whereKey($ritual->assigned_astrologer_id)
                ->first();

            if ($this->isRitualExpertAvailable($assigned)) {
                return $assigned;
            }
        }

        return User::with('astrologerDetail')
            ->where('role', 'astrologer')
            ->whereHas('astrologerDetail', function ($query) {
                $query->where('supports_ritual_booking', true)
                    ->where('supports_chat', true)
                    ->where('is_online', true);
            })
            ->orderBy('id')
            ->first();
    }

    private function isRitualExpertAvailable(?User $user): bool
    {
        $detail = $user?->astrologerDetail;

        return $user
            && $user->role === 'astrologer'
            && (bool) $detail?->supports_ritual_booking
            && (bool) $detail?->supports_chat
            && (bool) $detail?->is_online;
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
            ->whereIn('status', ['confirmed', 'in_progress'])
            ->where('scheduled_at', '<', $endUtc)
            ->where('ends_at', '>', $startUtc)
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

            $slots[] = [
                'label' => $slotStart->format('g:i A'),
                'start' => $slotStart->toIso8601String(),
                'end' => $candidateEnd->toIso8601String(),
                'is_available' => !$isPast && !$this->hasOverlappingBooking($astrologerId, $slotStart, $candidateEnd),
            ];

            $slotStart->addMinutes(30);
        }

        return $slots;
    }
}
