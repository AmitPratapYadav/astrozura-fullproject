<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserRecentProfile extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'profile_label',
        'person_name',
        'gender',
        'date_of_birth',
        'time_of_birth',
        'place_of_birth',
        'coordinates',
        'latitude',
        'longitude',
        'source_module',
        'relation_role',
        'metadata',
        'usage_count',
        'last_used_at',
    ];

    protected $casts = [
        'date_of_birth' => 'date:Y-m-d',
        'latitude' => 'decimal:7',
        'longitude' => 'decimal:7',
        'metadata' => 'array',
        'last_used_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
