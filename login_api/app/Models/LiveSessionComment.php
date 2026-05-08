<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class LiveSessionComment extends Model
{
    use HasFactory;

    protected $fillable = [
        'live_session_id',
        'user_id',
        'message',
    ];

    public function liveSession()
    {
        return $this->belongsTo(LiveSession::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
