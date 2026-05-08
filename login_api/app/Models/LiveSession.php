<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LiveSession extends Model
{
    use HasFactory;

    protected $fillable = [
        'astrologer_id',
        'title',
        'description',
        'room_id',
        'stream_id',
        'status',
        'started_at',
        'ended_at',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'ended_at' => 'datetime',
    ];

    public function astrologer()
    {
        return $this->belongsTo(User::class, 'astrologer_id');
    }

    public function comments()
    {
        return $this->hasMany(LiveSessionComment::class);
    }
}
