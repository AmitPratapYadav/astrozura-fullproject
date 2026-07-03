<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class RitualService extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'slug',
        'service_type',
        'category',
        'short_description',
        'description',
        'benefits',
        'materials_required',
        'ideal_timing',
        'duration_label',
        'mode',
        'price',
        'image',
        'is_popular',
        'status',
        'steps',
        'materials',
        'faqs',
        'mantras',
        'translations',
        'assigned_astrologer_id',
    ];

    protected $casts = [
        'price' => 'decimal:2',
        'is_popular' => 'boolean',
        'status' => 'boolean',
        'steps' => 'array',
        'materials' => 'array',
        'faqs' => 'array',
        'mantras' => 'array',
        'translations' => 'array',
    ];

    public function assignedAstrologer()
    {
        return $this->belongsTo(User::class, 'assigned_astrologer_id');
    }

    public function bookings()
    {
        return $this->hasMany(RitualBooking::class, 'ritual_service_id');
    }
}
