<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Events\BookingMessageCreated;
use App\Events\BookingTypingStatusChanged;
use App\Models\Booking;
use App\Models\BookingMessage;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Http\Request;

class BookingMessageController extends Controller
{
    public function index(Request $request, Booking $booking)
    {
        $user = $request->user();
        $this->authorizeBooking($booking, $user->id);

        $messages = $booking->messages()
            ->with(['sender:id,name', 'replyTo.sender:id,name'])
            ->orderByRaw('COALESCE(sent_at, created_at) asc')
            ->get()
            ->map(fn (BookingMessage $message) => $this->serializeMessage($message));

        return response()->json([
            'success' => true,
            'messages' => $messages,
        ]);
    }

    public function store(Request $request, Booking $booking)
    {
        $user = $request->user();
        $this->authorizeBooking($booking, $user->id);
        $booking = $this->closeExpiredSessionIfNeeded($booking);

        if ($booking->status !== 'in_progress') {
            return response()->json([
                'success' => false,
                'message' => 'Chat becomes active only after the astrologer starts the consultation.',
            ], 422);
        }

        $validated = $request->validate([
            'message_type' => 'required|in:text,image,pdf,video,audio,file',
            'text' => 'nullable|string|max:5000',
            'encrypted_body' => 'nullable|string|max:50000',
            'encryption_iv' => 'nullable|string|max:120',
            'encryption_tag' => 'nullable|string|max:120',
            'encryption_version' => 'nullable|string|max:40',
            'media_url' => 'nullable|string|max:2048|required_unless:message_type,text',
            'attachment_name' => 'nullable|string|max:255',
            'attachment_mime' => 'nullable|string|max:120',
            'attachment_size' => 'nullable|integer|min:0',
            'reply_to_message_id' => 'nullable|integer|exists:booking_messages,id',
            'client_uuid' => 'nullable|string|max:120',
            'zego_message_id' => 'nullable|string|max:255',
            'sent_at' => 'nullable|date',
        ]);

        if ($validated['message_type'] === 'text' && empty($validated['text']) && empty($validated['encrypted_body'])) {
            return response()->json([
                'success' => false,
                'message' => 'Message text is required.',
            ], 422);
        }

        if (!empty($validated['reply_to_message_id'])) {
            $belongsToBooking = BookingMessage::query()
                ->where('booking_id', $booking->id)
                ->where('id', $validated['reply_to_message_id'])
                ->exists();

            if (!$belongsToBooking) {
                return response()->json([
                    'success' => false,
                    'message' => 'The selected reply message belongs to another consultation.',
                ], 422);
            }
        }

        $senderRole = (int) $booking->astrologer_id === (int) $user->id ? 'astrologer' : 'user';
        $isAttachment = $validated['message_type'] !== 'text';

        $attributes = [
            'booking_id' => $booking->id,
            'sender_id' => $user->id,
            'sender_role' => $senderRole,
            'reply_to_message_id' => $validated['reply_to_message_id'] ?? null,
            'message_type' => $validated['message_type'],
            'text' => !$isAttachment ? trim((string) ($validated['text'] ?? '')) : ($validated['text'] ?? null),
            'encrypted_body' => $validated['encrypted_body'] ?? null,
            'encryption_iv' => $validated['encryption_iv'] ?? null,
            'encryption_tag' => $validated['encryption_tag'] ?? null,
            'encryption_version' => $validated['encryption_version'] ?? null,
            'media_url' => $isAttachment ? ($validated['media_url'] ?? null) : null,
            'attachment_name' => $validated['attachment_name'] ?? null,
            'attachment_mime' => $validated['attachment_mime'] ?? null,
            'attachment_size' => $validated['attachment_size'] ?? null,
            'zego_message_id' => $validated['zego_message_id'] ?? null,
            'sent_at' => Carbon::now(),
        ];

        if (!empty($validated['client_uuid'])) {
            $message = BookingMessage::firstOrCreate(
                [
                    'booking_id' => $booking->id,
                    'client_uuid' => $validated['client_uuid'],
                ],
                array_merge($attributes, [
                    'client_uuid' => $validated['client_uuid'],
                ])
            );
        } else {
            $message = BookingMessage::create($attributes);
        }

        $message->loadMissing(['sender:id,name', 'replyTo.sender:id,name']);
        $serialized = $this->serializeMessage($message);
        $this->broadcastMessageCreated($message->booking_id, $serialized);

        return response()->json([
            'success' => true,
            'message' => $serialized,
        ]);
    }

    public function typing(Request $request, Booking $booking)
    {
        $user = $request->user();
        $this->authorizeBooking($booking, $user->id);
        $booking = $this->closeExpiredSessionIfNeeded($booking);

        if ($booking->status !== 'in_progress') {
            return response()->json([
                'success' => false,
                'message' => 'Typing status is available only during a live consultation.',
            ], 422);
        }

        $validated = $request->validate([
            'is_typing' => 'required|boolean',
        ]);

        $senderRole = (int) $booking->astrologer_id === (int) $user->id ? 'astrologer' : 'user';
        $cacheKey = $this->typingCacheKey($booking->id, $user->id);

        if ((bool) $validated['is_typing']) {
            Cache::put($cacheKey, [
                'sender_id' => (string) $user->id,
                'sender_role' => $senderRole,
                'is_typing' => true,
                'sent_at' => now()->valueOf(),
            ], now()->addSeconds(5));
        } else {
            Cache::forget($cacheKey);
        }

        $this->broadcastTypingStatus($booking->id, $user->id, $senderRole, (bool) $validated['is_typing']);

        return response()->json([
            'success' => true,
        ]);
    }

    public function markRead(Request $request, Booking $booking)
    {
        $user = $request->user();
        $this->authorizeBooking($booking, $user->id);

        $readAt = now();

        $messageIds = $booking->messages()
            ->where('sender_id', '!=', $user->id)
            ->whereNull('read_at')
            ->pluck('id');

        if ($messageIds->isNotEmpty()) {
            BookingMessage::query()
                ->whereIn('id', $messageIds)
                ->update(['read_at' => $readAt]);
        }

        return response()->json([
            'success' => true,
            'read_at' => $readAt->valueOf(),
            'message_ids' => $messageIds->values(),
        ]);
    }

    public function typingStatus(Request $request, Booking $booking)
    {
        $user = $request->user();
        $this->authorizeBooking($booking, $user->id);

        $counterpartId = (int) $booking->user_id === (int) $user->id
            ? (int) $booking->astrologer_id
            : (int) $booking->user_id;

        $typing = Cache::get($this->typingCacheKey($booking->id, $counterpartId));

        return response()->json([
            'success' => true,
            'is_typing' => (bool) ($typing['is_typing'] ?? false),
            'sender_id' => $typing['sender_id'] ?? null,
            'sender_role' => $typing['sender_role'] ?? null,
            'sent_at' => $typing['sent_at'] ?? null,
        ]);
    }

    private function typingCacheKey(int $bookingId, int $userId): string
    {
        return "booking:{$bookingId}:typing:{$userId}";
    }

    private function broadcastMessageCreated(int $bookingId, array $message): void
    {
        try {
            BookingMessageCreated::dispatch($bookingId, $message);
        } catch (\Throwable $exception) {
            Log::warning('Booking message broadcast failed.', [
                'booking_id' => $bookingId,
                'message_id' => $message['id'] ?? null,
                'error' => $exception->getMessage(),
            ]);
        }
    }

    private function broadcastTypingStatus(int $bookingId, int $senderId, string $senderRole, bool $isTyping): void
    {
        try {
            BookingTypingStatusChanged::dispatch($bookingId, $senderId, $senderRole, $isTyping);
        } catch (\Throwable $exception) {
            Log::warning('Booking typing broadcast failed.', [
                'booking_id' => $bookingId,
                'sender_id' => $senderId,
                'sender_role' => $senderRole,
                'is_typing' => $isTyping,
                'error' => $exception->getMessage(),
            ]);
        }
    }

    private function authorizeBooking(Booking $booking, int $userId): void
    {
        if ((int) $booking->user_id !== $userId && (int) $booking->astrologer_id !== $userId) {
            abort(403, 'You are not allowed to access this consultation.');
        }
    }

    private function closeExpiredSessionIfNeeded(Booking $booking): Booking
    {
        if (!in_array($booking->status, ['confirmed', 'in_progress'], true) || !$booking->ends_at) {
            return $booking;
        }

        $timezone = $booking->timezone ?: 'Asia/Kolkata';
        $now = Carbon::now($timezone);

        if ($booking->ends_at->copy()->timezone($timezone)->greaterThan($now)) {
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

    private function serializeMessage(BookingMessage $message): array
    {
        return [
            'id' => $message->id,
            'client_uuid' => $message->client_uuid,
            'zego_message_id' => $message->zego_message_id,
            'sender_user_id' => (string) $message->sender_id,
            'sender_name' => $message->sender?->name,
            'sender_role' => $message->sender_role,
            'message_type' => $message->message_type,
            'text' => $message->text,
            'encrypted_body' => $message->encrypted_body,
            'encryption_iv' => $message->encryption_iv,
            'encryption_tag' => $message->encryption_tag,
            'encryption_version' => $message->encryption_version,
            'media_url' => $message->media_url,
            'attachment_name' => $message->attachment_name,
            'attachment_mime' => $message->attachment_mime,
            'attachment_size' => $message->attachment_size,
            'read_at' => optional($message->read_at)?->valueOf(),
            'reply_to_message' => $message->replyTo ? [
                'id' => $message->replyTo->id,
                'sender_name' => $message->replyTo->sender?->name,
                'sender_role' => $message->replyTo->sender_role,
                'message_type' => $message->replyTo->message_type,
                'text' => $message->replyTo->text,
                'encrypted_body' => $message->replyTo->encrypted_body,
                'encryption_iv' => $message->replyTo->encryption_iv,
                'encryption_tag' => $message->replyTo->encryption_tag,
                'encryption_version' => $message->replyTo->encryption_version,
                'attachment_name' => $message->replyTo->attachment_name,
            ] : null,
            'timestamp' => optional($message->sent_at ?? $message->created_at)?->valueOf(),
        ];
    }
}
