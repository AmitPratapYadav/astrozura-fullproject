<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_recent_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('profile_label')->nullable();
            $table->string('person_name')->nullable();
            $table->string('gender', 30)->nullable();
            $table->date('date_of_birth')->nullable();
            $table->string('time_of_birth', 20)->nullable();
            $table->string('place_of_birth')->nullable();
            $table->string('coordinates')->nullable();
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();
            $table->string('source_module')->nullable();
            $table->string('relation_role', 30)->nullable();
            $table->json('metadata')->nullable();
            $table->unsignedInteger('usage_count')->default(1);
            $table->timestamp('last_used_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'last_used_at']);
            $table->index(['user_id', 'relation_role']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_recent_profiles');
    }
};
