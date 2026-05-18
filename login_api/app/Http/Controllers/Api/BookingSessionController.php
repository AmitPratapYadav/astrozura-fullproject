<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Support\Zego\ZegoTokenService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class BookingSessionController extends Controller
{
    private array $closedStatuses = ['completed', 'cancelled', 'declined'];
    private array $extensionDurations = [5, 10, 15, 20, 30];

    public function show(Request $request, Booking $booking)
    {
        $user = $request->user();
        $this->authorizeBooking($booking, $user->id);

        $booking = $this->closeExpiredSessionIfNeeded($booking);
        $booking = $this->ensureSessionRoomId($booking->fresh(['user', 'astrologer.astrologerDetail']));
        $session = $this->buildSessionPayload($booking, $user->id);

        return response()->json([
            'success' => true,
            'booking' => $booking,
            'session' => $session,
        ]);
    }

    public function start(Request $request, Booking $booking)
    {
        $user = $request->user();
        $this->authorizeBooking($booking, $user->id);
        $booking = $this->closeExpiredSessionIfNeeded($booking);

        if ((int) $booking->astrologer_id !== (int) $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Only the astrologer can start this consultation.',
            ], 403);
        }

        if (in_array($booking->status, $this->closedStatuses, true)) {
            return response()->json([
                'success' => false,
                'message' => 'This consultation is already closed.',
            ], 422);
        }

        $timezone = $booking->timezone ?: 'Asia/Kolkata';
        $now = Carbon::now($timezone);
        $startWindow = optional($booking->scheduled_at)?->copy()->subMinutes(config('zego.session.join_grace_before_minutes', 10));
        $endWindow = optional($booking->ends_at)?->copy()->addMinutes(config('zego.session.join_grace_after_minutes', 15));

        if (!$this->isSessionTestMode() && (!$startWindow || !$endWindow || !$now->betweenIncluded($startWindow, $endWindow))) {
            return response()->json([
                'success' => false,
                'message' => 'This consultation can only be started near the booked slot.',
            ], 422);
        }

        $booking = $this->ensureSessionRoomId($booking);
        $booking->update([
            'status' => 'in_progress',
            'session_started_at' => $booking->session_started_at ?: $now,
            'session_ended_at' => null,
            'session_end_reason' => null,
            'session_ended_by' => null,
            'session_last_activity_at' => $now,
        ]);

        $booking = $booking->fresh(['user', 'astrologer.astrologerDetail']);

        return response()->json([
            'success' => true,
            'message' => 'Consultation started.',
            'booking' => $booking,
            'session' => $this->buildSessionPayload($booking, $user->id),
        ]);
    }

    public function end(Request $request, Booking $booking)
    {
        $user = $request->user();
        $this->authorizeBooking($booking, $user->id);
        $booking = $this->closeExpiredSessionIfNeeded($booking);

        if ((int) $booking->astrologer_id !== (int) $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Only the astrologer can end this consultation.',
            ], 403);
        }

        if (in_array($booking->status, $this->closedStatuses, true)) {
            return response()->json([
                'success' => true,
                'message' => 'Consultation already closed.',
                'booking' => $booking->fresh(['user', 'astrologer.astrologerDetail']),
                'session' => $this->buildSessionPayload($booking, $user->id),
            ]);
        }

        if ($booking->status !== 'in_progress') {
            return response()->json([
                'success' => false,
                'message' => 'Only a live consultation can be completed.',
            ], 422);
        }

        $timezone = $booking->timezone ?: 'Asia/Kolkata';
        $now = Carbon::now($timezone);

        $booking->update([
            'status' => 'completed',
            'completed_at' => $now,
            'session_ended_at' => $now,
            'session_end_reason' => 'manual_end',
            'session_ended_by' => "astrologer:{$user->id}",
            'session_last_activity_at' => $now,
        ]);

        $booking = $booking->fresh(['user', 'astrologer.astrologerDetail']);

        return response()->json([
            'success' => true,
            'message' => 'Consultation ended.',
            'booking' => $booking,
            'session' => $this->buildSessionPayload($booking, $user->id),
        ]);
    }

    public function ping(Request $request, Booking $booking)
    {
        $user = $request->user();
        $this->authorizeBooking($booking, $user->id);
        $booking = $this->closeExpiredSessionIfNeeded($booking);

        if (in_array($booking->status, $this->closedStatuses, true)) {
            return response()->json([
                'success' => true,
                'message' => 'Session already closed.',
                'booking' => $booking->fresh(['user', 'astrologer.astrologerDetail']),
                'session' => $this->buildSessionPayload($booking, $user->id),
            ]);
        }

        $booking->update([
            'session_last_activity_at' => Carbon::now($booking->timezone ?: 'Asia/Kolkata'),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Session ping recorded.',
            'booking' => $booking->fresh(['user', 'astrologer.astrologerDetail']),
            'session' => $this->buildSessionPayload($booking->fresh(['user', 'astrologer.astrologerDetail']), $user->id),
        ]);
    }

    public function extend(Request $request, Booking $booking)
    {
        $user = $request->user();
        $this->authorizeBooking($booking, $user->id);
        $booking = $this->closeExpiredSessionIfNeeded($booking);

        if ((int) $booking->user_id !== (int) $user->id) {
            return response()->json([
                'success' => false,
                'message' => 'Only the customer can extend this consultation.',
            ], 403);
        }

        if ($booking->status !== 'in_progress') {
            return response()->json([
                'success' => false,
                'message' => 'Only a live consultation can be extended.',
            ], 422);
        }

        $validated = $request->validate([
            'duration' => ['required', 'integer', Rule::in($this->extensionDurations)],
            'payment_method' => 'nullable|string|max:50',
        ]);

        $timezone = $booking->timezone ?: 'Asia/Kolkata';
        $booking = $booking->fresh(['astrologer.astrologerDetail', 'user']);
        $currentEnd = $booking->ends_at?->copy()->timezone($timezone);

        if (!$currentEnd) {
            return response()->json([
                'success' => false,
                'message' => 'This consultation does not have a scheduled end time.',
            ], 422);
        }

        $duration = (int) $validated['duration'];
        $newEnd = $currentEnd->copy()->addMinutes($duration);

        if (!$this->isAstrologerAvailableForExtension($booking, $currentEnd, $newEnd)) {
            return response()->json([
                'success' => false,
                'message' => 'The astrologer has another booking after this session, so this consultation cannot be extended by that duration.',
            ], 422);
        }

        $rate = $booking->consultation_type === 'chat'
            ? (float) ($booking->astrologer?->astrologerDetail?->chat_price ?? 0)
            : (float) ($booking->astrologer?->astrologerDetail?->call_price ?? 0);
        $extensionAmount = $rate * $duration;
        $now = Carbon::now($timezone);

        $booking->update([
            'duration' => (int) $booking->duration + $duration,
            'ends_at' => $newEnd,
            'amount' => (float) $booking->amount + $extensionAmount,
            'payment_status' => 'paid',
            'payment_method' => $validated['payment_method'] ?? 'mock_extension',
            'session_warning_sent_at' => null,
            'session_last_activity_at' => $now,
        ]);

        $booking = $booking->fresh(['user', 'astrologer.astrologerDetail']);

        return response()->json([
            'success' => true,
            'message' => "Consultation extended by {$duration} minutes.",
            'extension' => [
                'duration' => $duration,
                'amount' => $extensionAmount,
                'rate_per_minute' => $rate,
            ],
            'booking' => $booking,
            'session' => $this->buildSessionPayload($booking, $user->id),
        ]);
    }

    private function authorizeBooking(Booking $booking, int $userId): void
    {
        if ((int) $booking->user_id !== $userId && (int) $booking->astrologer_id !== $userId) {
            abort(403, 'You are not allowed to access this consultation.');
        }
    }

    private function ensureSessionRoomId(Booking $booking): Booking
    {
        if (!empty($booking->session_room_id)) {
            return $booking;
        }

        $reference = $booking->booking_reference ?: 'booking-' . $booking->id;
        $slug = strtolower(preg_replace('/[^a-zA-Z0-9_-]+/', '-', $reference));
        $roomId = substr("astrozura-{$slug}", 0, 120);

        $booking->session_room_id = $roomId;
        $booking->save();

        return $booking;
    }

    private function closeExpiredSessionIfNeeded(Booking $booking): Booking
    {
        if (!in_array($booking->status, ['confirmed', 'in_progress'], true) || !$booking->ends_at) {
            return $booking;
        }

        $now = Carbon::now($booking->timezone ?: 'Asia/Kolkata');
        $endsAt = $booking->ends_at->copy()->timezone($booking->timezone ?: 'Asia/Kolkata');

        if ($endsAt->greaterThan($now)) {
            return $booking;
        }

        $booking->update([
            'status' => 'completed',
            'completed_at' => $booking->completed_at ?: $now,
            'session_ended_at' => $booking->session_ended_at ?: $now,
            'session_end_reason' => $booking->session_end_reason ?: 'time_limit_reached',
            'session_ended_by' => $booking->session_ended_by ?: 'system',
            'session_last_activity_at' => $now,
        ]);

        return $booking->fresh();
    }

    private function isAstrologerAvailableForExtension(Booking $booking, Carbon $from, Carbon $to): bool
    {
        return !Booking::query()
            ->where('astrologer_id', $booking->astrologer_id)
            ->where('id', '!=', $booking->id)
            ->whereIn('status', ['confirmed', 'in_progress'])
            ->where(function ($query) use ($from, $to) {
                $query->where('scheduled_at', '<', $to->copy()->utc())
                    ->where('ends_at', '>', $from->copy()->utc());
            })
            ->exists();
    }

    private function buildSessionPayload(Booking $booking, int $viewerId): array
    {
        $timezone = $booking->timezone ?: 'Asia/Kolkata';
        $now = Carbon::now($timezone);
        $testingMode = $this->isSessionTestMode();
        $joinGraceBefore = config('zego.session.join_grace_before_minutes', 10);
        $joinGraceAfter = config('zego.session.join_grace_after_minutes', 15);
        $lowTimeWarningSeconds = config('zego.session.low_time_warning_seconds', 120);

        $scheduledAt = $booking->scheduled_at?->copy()->timezone($timezone);
        $endsAt = $booking->ends_at?->copy()->timezone($timezone);
        $joinStartsAt = $testingMode
            ? ($booking->created_at?->copy()->timezone($timezone) ?: $scheduledAt?->copy()->subDay())
            : $scheduledAt?->copy()->subMinutes($joinGraceBefore);
        $joinEndsAt = $testingMode
            ? $endsAt?->copy()->addDay()
            : $endsAt?->copy()->addMinutes($joinGraceAfter);

        $remainingSeconds = $endsAt ? max(0, $now->diffInSeconds($endsAt, false)) : 0;
        $isAstrologer = (int) $booking->astrologer_id === $viewerId;
        $isUser = (int) $booking->user_id === $viewerId;
        $isLive = $booking->status === 'in_progress';
        $isClosed = in_array($booking->status, $this->closedStatuses, true);
        $withinJoinWindow = $testingMode
            ? !$isClosed
            : ($joinStartsAt && $joinEndsAt ? $now->betweenIncluded($joinStartsAt, $joinEndsAt) : false);
        $canStart = $isAstrologer && !$isClosed && !$isLive && $withinJoinWindow;
        $canJoin = !$isClosed && $withinJoinWindow;
        $canEnd = $isAstrologer && $isLive && !$isClosed;
        $needsLowTimeWarning = $isLive && $remainingSeconds > 0 && $remainingSeconds <= $lowTimeWarningSeconds;
        $extension = $this->buildExtensionPayload($booking, $viewerId, $endsAt, $isLive, $isClosed);

        $zegoUserId = $this->buildZegoUserId($viewerId, $isAstrologer ? 'astro' : 'user');
        $zegoUserName = $this->buildZegoUserName($booking, $viewerId);
        $baseRoomId = $booking->session_room_id;

        return [
            'state' => $isClosed ? 'closed' : ($isLive ? 'live' : ($canJoin ? 'ready' : 'scheduled')),
            'is_live' => $isLive,
            'test_mode' => $testingMode,
            'can_start' => $canStart,
            'can_join' => $canJoin,
            'can_end' => $canEnd,
            'remaining_seconds' => $remainingSeconds,
            'needs_low_time_warning' => $needsLowTimeWarning,
            'extension' => $extension,
            'server_now' => $now->toIso8601String(),
            'scheduled_at' => $scheduledAt?->toIso8601String(),
            'scheduled_end_at' => $endsAt?->toIso8601String(),
            'join_window' => [
                'starts_at' => $joinStartsAt?->toIso8601String(),
                'ends_at' => $joinEndsAt?->toIso8601String(),
            ],
            'started_at' => $booking->session_started_at?->toIso8601String(),
            'ended_at' => $booking->session_ended_at?->toIso8601String(),
            'ended_by' => $booking->session_ended_by,
            'end_reason' => $booking->session_end_reason,
            'rooms' => [
                'session' => $baseRoomId,
                'chat' => "{$baseRoomId}-chat",
                'call' => "{$baseRoomId}-call",
                'stream' => "{$baseRoomId}-stream-{$viewerId}",
            ],
            'viewer' => [
                'role' => $isAstrologer ? 'astrologer' : 'user',
                'zego_user_id' => $zegoUserId,
                'zego_user_name' => $zegoUserName,
            ],
            'zego' => [
                'chat' => $this->buildZegoProjectPayload('chat', $zegoUserId, $zegoUserName),
                'call' => $this->buildZegoProjectPayload('call', $zegoUserId, $zegoUserName),
            ],
        ];
    }

    private function buildExtensionPayload(Booking $booking, int $viewerId, ?Carbon $endsAt, bool $isLive, bool $isClosed): array
    {
        $isCustomer = (int) $booking->user_id === $viewerId;
        $rate = $booking->consultation_type === 'chat'
            ? (float) ($booking->astrologer?->astrologerDetail?->chat_price ?? 0)
            : (float) ($booking->astrologer?->astrologerDetail?->call_price ?? 0);

        if (!$isCustomer || !$isLive || $isClosed || !$endsAt) {
            return [
                'can_extend' => false,
                'rate_per_minute' => $rate,
                'options' => [],
            ];
        }

        $options = collect($this->extensionDurations)
            ->map(function (int $duration) use ($booking, $endsAt, $rate) {
                $newEnd = $endsAt->copy()->addMinutes($duration);
                $isAvailable = $this->isAstrologerAvailableForExtension($booking, $endsAt, $newEnd);

                return [
                    'duration' => $duration,
                    'amount' => $rate * $duration,
                    'new_end_at' => $newEnd->toIso8601String(),
                    'is_available' => $isAvailable,
                ];
            })
            ->values()
            ->all();

        return [
            'can_extend' => collect($options)->contains(fn (array $option) => $option['is_available']),
            'rate_per_minute' => $rate,
            'options' => $options,
        ];
    }

    private function buildZegoProjectPayload(string $projectKey, string $userId, string $userName): ?array
    {
        $project = config("zego.{$projectKey}");
        $appId = (int) ($project['app_id'] ?? 0);
        $secret = (string) ($project['server_secret'] ?? '');

        if ($appId <= 0 || $secret === '') {
            return null;
        }

        $ttl = (int) config('zego.token_ttl', 6 * 60 * 60);
        $token = ZegoTokenService::generateToken04($appId, $userId, $secret, $ttl);

        return [
            'app_id' => $appId,
            'app_sign' => $project['app_sign'] ?? null,
            'server_url' => $project['server_url'] ?? null,
            'secondary_server_url' => $project['secondary_server_url'] ?? null,
            'token' => $token,
            'token_expires_in' => $ttl,
            'user_id' => $userId,
            'user_name' => $userName,
        ];
    }

    private function buildZegoUserId(int $userId, string $role): string
    {
        return substr("az-{$role}-{$userId}", 0, 32);
    }

    private function buildZegoUserName(Booking $booking, int $viewerId): string
    {
        if ((int) $booking->astrologer_id === $viewerId) {
            return $booking->astrologer_name ?: "Astrologer {$viewerId}";
        }

        return $booking->user_name ?: "User {$viewerId}";
    }

    private function isSessionTestMode(): bool
    {
        return (bool) config('zego.session.test_mode', false);
    }
}
