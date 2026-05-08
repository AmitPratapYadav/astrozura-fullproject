<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\BookingMessage;
use Carbon\Carbon;
use Illuminate\Http\Request;

class BookingMessageController extends Controller
{
    public function index(Request $request, Booking $booking)
    {
        $user = $request->user();
        $this->authorizeBooking($booking, $user->id);

        $messages = $booking->messages()
            ->with('sender:id,name')
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

        $validated = $request->validate([
            'message_type' => 'required|in:text,image',
            'text' => 'nullable|string|max:5000|required_if:message_type,text',
            'media_url' => 'nullable|string|max:2048|required_if:message_type,image',
            'client_uuid' => 'nullable|string|max:120',
            'zego_message_id' => 'nullable|string|max:255',
            'sent_at' => 'nullable|date',
        ]);

        $senderRole = (int) $booking->astrologer_id === (int) $user->id ? 'astrologer' : 'user';

        $attributes = [
            'booking_id' => $booking->id,
            'sender_id' => $user->id,
            'sender_role' => $senderRole,
            'message_type' => $validated['message_type'],
            'text' => $validated['message_type'] === 'text' ? trim((string) ($validated['text'] ?? '')) : null,
            'media_url' => $validated['message_type'] === 'image' ? ($validated['media_url'] ?? null) : null,
            'zego_message_id' => $validated['zego_message_id'] ?? null,
            'sent_at' => !empty($validated['sent_at'])
                ? Carbon::parse($validated['sent_at'], $booking->timezone ?: 'Asia/Kolkata')
                : Carbon::now($booking->timezone ?: 'Asia/Kolkata'),
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

        $message->loadMissing('sender:id,name');

        return response()->json([
            'success' => true,
            'message' => $this->serializeMessage($message),
        ]);
    }

    private function authorizeBooking(Booking $booking, int $userId): void
    {
        if ((int) $booking->user_id !== $userId && (int) $booking->astrologer_id !== $userId) {
            abort(403, 'You are not allowed to access this consultation.');
        }
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
            'media_url' => $message->media_url,
            'timestamp' => optional($message->sent_at ?? $message->created_at)?->valueOf(),
        ];
    }
}
