<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('live_sessions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('astrologer_id')->constrained('users')->cascadeOnDelete();
            $table->string('title')->nullable();
            $table->text('description')->nullable();
            $table->string('room_id')->unique();
            $table->string('stream_id')->unique();
            $table->string('status', 20)->default('live');
            $table->dateTime('started_at')->nullable();
            $table->dateTime('ended_at')->nullable();
            $table->timestamps();

            $table->index(['status', 'started_at']);
        });

        Schema::create('live_session_comments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('live_session_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->text('message');
            $table->timestamps();

            $table->index(['live_session_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('live_session_comments');
        Schema::dropIfExists('live_sessions');
    }
};
