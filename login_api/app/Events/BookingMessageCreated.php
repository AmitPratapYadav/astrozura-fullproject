<?php

namespace App\Events;

use App\Models\BookingMessage;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class BookingMessageCreated implements ShouldBroadcastNow
{
    use Dispatchable, SerializesModels;

    public function __construct(
        public readonly int $bookingId,
        public readonly array $message
    ) {
    }

    public static function fromMessage(BookingMessage $message, array $serialized): self
    {
        return new self((int) $message->booking_id, $serialized);
    }

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel("booking.{$this->bookingId}");
    }

    public function broadcastAs(): string
    {
        return 'booking.message.created';
    }

    public function broadcastWith(): array
    {
        return [
            'booking_id' => $this->bookingId,
            'message' => $this->message,
        ];
    }
}
