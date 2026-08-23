<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class BookingSessionStateChanged implements ShouldBroadcastNow
{
    use Dispatchable, SerializesModels;

    public function __construct(
        public readonly int $bookingId,
        public readonly string $state,
        public readonly array $session
    ) {
    }

    public function broadcastOn(): PrivateChannel
    {
        return new PrivateChannel("booking.{$this->bookingId}");
    }

    public function broadcastAs(): string
    {
        return 'booking.session.changed';
    }

    public function broadcastWith(): array
    {
        return [
            'booking_id' => $this->bookingId,
            'state' => $this->state,
            'session' => $this->session,
        ];
    }
}
