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
        'rating',
        'total_reviews',
        'profile_image',
        'is_featured',
    ];

    protected $casts = [
        'is_featured' => 'boolean',
        'rating' => 'decimal:1',
        'total_reviews' => 'integer',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
