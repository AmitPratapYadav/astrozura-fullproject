<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('booking_messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('booking_id')->constrained()->cascadeOnDelete();
            $table->foreignId('sender_id')->constrained('users')->cascadeOnDelete();
            $table->string('sender_role', 30);
            $table->string('message_type', 20);
            $table->text('text')->nullable();
            $table->string('media_url', 2048)->nullable();
            $table->string('client_uuid', 120)->nullable();
            $table->string('zego_message_id', 255)->nullable();
            $table->dateTime('sent_at')->nullable();
            $table->timestamps();

            $table->index(['booking_id', 'sent_at']);
            $table->unique(['booking_id', 'client_uuid']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('booking_messages');
    }
};
