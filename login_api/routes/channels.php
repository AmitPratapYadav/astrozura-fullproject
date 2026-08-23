<?php

use App\Models\Booking;
use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('booking.{bookingId}', function ($user, int $bookingId) {
    $booking = Booking::query()->find($bookingId);

    if (!$booking) {
        return false;
    }

    if ((int) $booking->user_id !== (int) $user->id && (int) $booking->astrologer_id !== (int) $user->id) {
        return false;
    }

    return [
        'id' => $user->id,
        'name' => $user->name,
        'role' => (int) $booking->astrologer_id === (int) $user->id ? 'astrologer' : 'user',
    ];
});
