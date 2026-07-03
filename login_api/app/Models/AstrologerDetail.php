<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class AstrologerDetail extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'experience_years',
        'languages',
        'specialities',
        'about_bio',
        'chat_price',
        'call_price',
        'chat_duration_prices',
        'call_duration_prices',
        'supports_chat',
        'supports_call',
        'is_online',
        'chat_commission_percentage',
        'call_commission_percentage',
        'translations',
        'rating',
        'total_reviews',
        'profile_image',
        'is_featured',
    ];

    protected $casts = [
        'is_featured' => 'boolean',
        'chat_duration_prices' => 'array',
        'call_duration_prices' => 'array',
        'supports_chat' => 'boolean',
        'supports_call' => 'boolean',
        'is_online' => 'boolean',
        'chat_commission_percentage' => 'decimal:2',
        'call_commission_percentage' => 'decimal:2',
        'translations' => 'array',
        'rating' => 'decimal:1',
        'total_reviews' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
