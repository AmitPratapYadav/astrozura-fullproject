<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RitualBooking extends Model
{
    use HasFactory;

    protected $fillable = [
        'booking_reference',
        'user_id',
        'ritual_service_id',
        'astrologer_id',
        'devotee_name',
        'devotee_email',
        'devotee_phone',
        'preferred_date',
        'preferred_time',
        'confirmed_date',
        'confirmed_time',
        'timezone',
        'venue_type',
        'location_address',
        'location_city',
        'location_state',
        'location_pincode',
        'expense_acknowledged',
        'notes',
        'admin_response',
        'admin_response_at',
        'birth_details',
        'amount',
        'status',
        'payment_status',
        'payment_method',
        'payment_id',
        'razorpay_order_id',
        'razorpay_signature',
    ];

    protected $casts = [
        'preferred_date' => 'date',
        'confirmed_date' => 'date',
        'expense_acknowledged' => 'boolean',
        'admin_response_at' => 'datetime',
        'birth_details' => 'array',
        'amount' => 'decimal:2',
    ];

    public function ritual()
    {
        return $this->belongsTo(RitualService::class, 'ritual_service_id');
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function astrologer()
    {
        return $this->belongsTo(User::class, 'astrologer_id');
    }
}
