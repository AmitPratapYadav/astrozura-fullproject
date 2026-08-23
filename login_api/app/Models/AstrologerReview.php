<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AstrologerReview extends Model
{
    use HasFactory;

    protected $fillable = [
        'booking_id',
        'user_id',
        'astrologer_id',
        'rating',
        'review',
        'is_pinned',
        'pinned_at',
        'is_flagged',
        'flag_reason',
        'flagged_at',
        'flagged_by',
    ];

    protected $casts = [
        'is_pinned' => 'boolean',
        'pinned_at' => 'datetime',
        'is_flagged' => 'boolean',
        'flagged_at' => 'datetime',
    ];

    public function booking()
    {
        return $this->belongsTo(Booking::class);
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
