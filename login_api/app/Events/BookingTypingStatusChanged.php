<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class BookingTypingStatusChanged implements ShouldBroadcastNow
{
    use Dispatchable, SerializesModels;

    public function __construct(
        public readonly int $bookingId,
        public readonly int $senderId,
        public readonly string $senderRole,
        public readonly bool $isTyping
    ) {
    }

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel("booking.{$this->bookingId}");
    }

    public function broadcastAs(): string
    {
        return 'booking.typing';
    }

    public function broadcastWith(): array
    {
        return [
            'booking_id' => $this->bookingId,
            'sender_id' => (string) $this->senderId,
            'sender_role' => $this->senderRole,
            'is_typing' => $this->isTyping,
            'sent_at' => now()->valueOf(),
        ];
    }
}
