<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RitualBookingUpdate extends Model
{
    use HasFactory;

    protected $fillable = [
        'ritual_booking_id',
        'sender_id',
        'sender_role',
        'type',
        'message',
        'amount',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
    ];

    public function ritualBooking()
    {
        return $this->belongsTo(RitualBooking::class);
    }

    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }
}
