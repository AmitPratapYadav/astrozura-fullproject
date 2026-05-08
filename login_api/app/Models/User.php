<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    /** @use HasFactory<\Database\Factories\UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name',
        'email',
        'phone',
        'otp',
        'otp_expires_at',
        'password',
        'role',
        'is_profile_complete',
        'provider',
        'provider_id',
        'provider_token',
        'profile_image',
        'date_of_birth',
        'time_of_birth',
        'place_of_birth',
        'gender',
        'latitude',
        'longitude'
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var list<string>
     */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    /**
     * Get the astrologer details associated with the user if role is astrologer.
     */
    public function astrologerDetail()
    {
        return $this->hasOne(AstrologerDetail::class);
    }

    public function bookings()
    {
        return $this->hasMany(Booking::class);
    }

    public function astrologerBookings()
    {
        return $this->hasMany(Booking::class, 'astrologer_id');
    }

    public function givenReviews()
    {
        return $this->hasMany(AstrologerReview::class, 'user_id');
    }

    public function receivedReviews()
    {
        return $this->hasMany(AstrologerReview::class, 'astrologer_id');
    }

    public function pushSubscriptions()
    {
        return $this->hasMany(PushSubscription::class);
    }
}
