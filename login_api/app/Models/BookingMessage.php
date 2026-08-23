<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BookingMessage extends Model
{
    use HasFactory;

    protected $fillable = [
        'booking_id',
        'sender_id',
        'sender_role',
        'reply_to_message_id',
        'message_type',
        'text',
        'encrypted_body',
        'encryption_iv',
        'encryption_tag',
        'encryption_version',
        'media_url',
        'attachment_name',
        'attachment_mime',
        'attachment_size',
        'client_uuid',
        'zego_message_id',
        'sent_at',
        'read_at',
    ];

    protected $casts = [
        'sent_at' => 'datetime',
        'read_at' => 'datetime',
        'attachment_size' => 'integer',
    ];

    public function booking()
    {
        return $this->belongsTo(Booking::class);
    }

    public function sender()
    {
        return $this->belongsTo(User::class, 'sender_id');
    }

    public function replyTo()
    {
        return $this->belongsTo(self::class, 'reply_to_message_id');
    }
}
