<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ritual_booking_updates', function (Blueprint $table) {
            $table->id();
            $table->foreignId('ritual_booking_id')->constrained('ritual_bookings')->cascadeOnDelete();
            $table->foreignId('sender_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('sender_role')->default('astrologer');
            $table->string('type')->default('reply');
            $table->text('message')->nullable();
            $table->decimal('amount', 10, 2)->nullable();
            $table->timestamps();

            $table->index(['ritual_booking_id', 'type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ritual_booking_updates');
    }
};
