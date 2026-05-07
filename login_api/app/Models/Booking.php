<?php

namespace App\Models;

use Carbon\Carbon;
use Carbon\CarbonInterface;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Booking extends Model
{
    use HasFactory;

    protected $fillable = [
        'booking_reference',
        'session_room_id',
        'user_id',
        'astrologer_id',
        'user_name',
        'user_email',
        'astrologer_name',
        'consultation_type',
        'duration',
        'booking_date',
        'booking_time',
        'scheduled_at',
        'ends_at',
        'timezone',
        'amount',
        'status',
        'payment_status',
        'payment_method',
        'payment_id',
        'completed_at',
        'session_started_at',
        'session_ended_at',
        'session_warning_sent_at',
        'session_last_activity_at',
        'session_ended_by',
        'session_end_reason',
        'notes',
        'birth_details',
    ];

    protected $casts = [
        'booking_date' => 'date',
        'scheduled_at' => 'datetime',
        'ends_at' => 'datetime',
        'completed_at' => 'datetime',
        'session_started_at' => 'datetime',
        'session_ended_at' => 'datetime',
        'session_warning_sent_at' => 'datetime',
        'session_last_activity_at' => 'datetime',
        'amount' => 'decimal:2',
        'birth_details' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function astrologer()
    {
        return $this->belongsTo(User::class, 'astrologer_id');
    }

    public function review()
    {
        return $this->hasOne(AstrologerReview::class);
    }

    public function setScheduledAtAttribute($value): void
    {
        $this->attributes['scheduled_at'] = $this->normalizeDateTimeForStorage($value);
    }

    public function setEndsAtAttribute($value): void
    {
        $this->attributes['ends_at'] = $this->normalizeDateTimeForStorage($value);
    }

    public function setCompletedAtAttribute($value): void
    {
        $this->attributes['completed_at'] = $this->normalizeDateTimeForStorage($value);
    }

    public function setSessionStartedAtAttribute($value): void
    {
        $this->attributes['session_started_at'] = $this->normalizeDateTimeForStorage($value);
    }

    public function setSessionEndedAtAttribute($value): void
    {
        $this->attributes['session_ended_at'] = $this->normalizeDateTimeForStorage($value);
    }

    public function setSessionWarningSentAtAttribute($value): void
    {
        $this->attributes['session_warning_sent_at'] = $this->normalizeDateTimeForStorage($value);
    }

    public function setSessionLastActivityAtAttribute($value): void
    {
        $this->attributes['session_last_activity_at'] = $this->normalizeDateTimeForStorage($value);
    }

    private function normalizeDateTimeForStorage($value): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        $dateTime = $value instanceof CarbonInterface
            ? $value->copy()
            : Carbon::parse($value, $this->timezone ?: 'Asia/Kolkata');

        return $dateTime->utc()->format('Y-m-d H:i:s');
    }
}
