<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Services\SmartChatWhatsAppService;
use App\Services\UltronSmsService;
use App\Services\UserNotificationService;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AdminBookingController extends Controller
{
    // Get all bookings with optional filters
    public function index(Request $request)
    {
        $this->ensureAdmin($request);
        $query = Booking::with(['user', 'astrologer.astrologerDetail'])->orderByDesc('scheduled_at');

        if ($request->search) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('user_name', 'like', "%$search%")
                  ->orWhere('user_email', 'like', "%$search%")
                  ->orWhere('astrologer_name', 'like', "%$search%")
                  ->orWhere('consultation_type', 'like', "%$search%")
                  ->orWhere('status', 'like', "%$search%");
            });
        }

        if ($request->status) {
            $query->where('status', $request->status);
        }

        if ($request->type) {
            $query->where('consultation_type', $request->type);
        }

        $bookings = $query->get();

        return response()->json(['success' => true, 'bookings' => $bookings]);
    }

    // Update booking status (e.g. confirm, complete, cancel)
    public function updateStatus(
        Request $request,
        $id,
        UltronSmsService $sms,
        SmartChatWhatsAppService $whatsapp,
        UserNotificationService $notifications
    )
    {
        $this->ensureAdmin($request);
        $validated = $request->validate([
            'status' => ['required', Rule::in(['payment_pending', 'pending', 'confirmed', 'in_progress', 'completed', 'cancelled', 'declined'])],
        ]);
        $booking = Booking::with(['user', 'astrologer'])->findOrFail($id);
        $wasConfirmed = $booking->status === 'confirmed';
        $payload = ['status' => $validated['status']];

        if ($request->status === 'completed') {
            $payload['completed_at'] = now('Asia/Kolkata');
        }

        $booking->update($payload);
        $booking->refresh();

        if (!$wasConfirmed && $booking->status === 'confirmed' && $booking->payment_status === 'paid') {
            $sms->sendBookingConfirmation($booking);
            $whatsapp->sendBookingConfirmation($booking);
        }

        if ($booking->user_id) {
            $notifications->send(
                $booking->user_id,
                'main',
                'booking_status',
                'Consultation status updated',
                "{$booking->booking_reference} is now {$booking->status}.",
                '/my-bookings',
                ['booking_id' => $booking->id, 'status' => $booking->status]
            );
        }

        return response()->json(['success' => true, 'message' => 'Booking status updated', 'booking' => $booking]);
    }

    // Stats for dashboard
    public function stats(Request $request)
    {
        $this->ensureAdmin($request);
        return response()->json([
            'success' => true,
            'total'     => Booking::count(),
            'pending'   => Booking::whereIn('status', ['pending', 'confirmed', 'in_progress'])->count(),
            'completed' => Booking::where('status', 'completed')->count(),
            'revenue'   => Booking::where('payment_status', 'paid')->sum('amount'),
        ]);
    }

    public function reassign(Request $request, int $id, UserNotificationService $notifications)
    {
        $this->ensureAdmin($request);
        $validated = $request->validate([
            'astrologer_id' => [
                'required',
                'integer',
                Rule::exists('users', 'id')->where(fn ($query) => $query->where('role', 'astrologer')),
            ],
            'reason' => 'nullable|string|max:1000',
        ]);

        $booking = Booking::with(['user', 'astrologer'])->findOrFail($id);
        $astrologer = User::with('astrologerDetail')->findOrFail($validated['astrologer_id']);
        $detail = $astrologer->astrologerDetail;

        abort_if(!$detail?->is_online, 422, 'The selected astrologer is offline.');
        abort_if($booking->consultation_type === 'chat' && !$detail->supports_chat, 422, 'The selected astrologer does not accept chat bookings.');
        abort_if($booking->consultation_type === 'call' && !$detail->supports_call, 422, 'The selected astrologer does not accept call bookings.');

        $hasConflict = Booking::query()
            ->where('astrologer_id', $astrologer->id)
            ->whereKeyNot($booking->id)
            ->whereIn('status', ['confirmed', 'in_progress'])
            ->where('scheduled_at', '<', $booking->ends_at)
            ->where('ends_at', '>', $booking->scheduled_at)
            ->exists();
        abort_if($hasConflict, 422, 'The selected astrologer already has a booking in this time window.');

        $commissionPercentage = (float) (
            $booking->consultation_type === 'chat'
                ? $detail->chat_commission_percentage
                : $detail->call_commission_percentage
        );
        $platformCommission = round((float) $booking->amount * $commissionPercentage / 100, 2);
        $previousAstrologerId = $booking->astrologer_id;

        DB::transaction(function () use (
            $booking,
            $astrologer,
            $previousAstrologerId,
            $commissionPercentage,
            $platformCommission,
            $validated
        ): void {
            $booking->update([
                'reassigned_from_astrologer_id' => $previousAstrologerId,
                'reassigned_at' => now(),
                'astrologer_id' => $astrologer->id,
                'astrologer_name' => $astrologer->name,
                'commission_percentage' => $commissionPercentage,
                'platform_commission_amount' => $platformCommission,
                'astrologer_earning_amount' => round((float) $booking->amount - $platformCommission, 2),
                'notes' => trim(implode("\n", array_filter([
                    $booking->notes,
                    isset($validated['reason']) ? 'Reassignment: ' . $validated['reason'] : null,
                ]))),
            ]);
        });

        if ($booking->user_id) {
            $notifications->send(
                $booking->user_id,
                'main',
                'booking_reassigned',
                'Your astrologer has changed',
                "{$booking->booking_reference} is now assigned to {$astrologer->name}.",
                '/my-bookings',
                ['booking_id' => $booking->id, 'astrologer_id' => $astrologer->id]
            );
        }
        $notifications->send(
            $astrologer,
            'main',
            'booking_assigned',
            'New consultation assigned',
            "{$booking->booking_reference} has been assigned to you.",
            '/astrologer/dashboard',
            ['booking_id' => $booking->id]
        );

        return response()->json([
            'success' => true,
            'message' => 'Booking reassigned successfully.',
            'booking' => $booking->fresh()->load(['user', 'astrologer.astrologerDetail']),
        ]);
    }

    private function ensureAdmin(Request $request): void
    {
        abort_unless($request->user()?->role === 'admin', 403);
    }
}
