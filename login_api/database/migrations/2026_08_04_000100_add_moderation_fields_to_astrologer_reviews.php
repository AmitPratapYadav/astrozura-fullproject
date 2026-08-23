<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('astrologer_reviews', function (Blueprint $table) {
            if (!Schema::hasColumn('astrologer_reviews', 'is_pinned')) {
                $table->boolean('is_pinned')->default(false)->after('review');
            }
            if (!Schema::hasColumn('astrologer_reviews', 'pinned_at')) {
                $table->timestamp('pinned_at')->nullable()->after('is_pinned');
            }
            if (!Schema::hasColumn('astrologer_reviews', 'is_flagged')) {
                $table->boolean('is_flagged')->default(false)->after('pinned_at');
            }
            if (!Schema::hasColumn('astrologer_reviews', 'flag_reason')) {
                $table->text('flag_reason')->nullable()->after('is_flagged');
            }
            if (!Schema::hasColumn('astrologer_reviews', 'flagged_at')) {
                $table->timestamp('flagged_at')->nullable()->after('flag_reason');
            }
            if (!Schema::hasColumn('astrologer_reviews', 'flagged_by')) {
                $table->foreignId('flagged_by')->nullable()->after('flagged_at')->constrained('users')->nullOnDelete();
            }
            $table->index(['astrologer_id', 'is_pinned', 'created_at'], 'astro_reviews_pin_idx');
            $table->index(['is_flagged', 'created_at'], 'astro_reviews_flag_idx');
        });
    }

    public function down(): void
    {
        Schema::table('astrologer_reviews', function (Blueprint $table) {
            $table->dropIndex('astro_reviews_pin_idx');
            $table->dropIndex('astro_reviews_flag_idx');
            if (Schema::hasColumn('astrologer_reviews', 'flagged_by')) {
                $table->dropConstrainedForeignId('flagged_by');
            }
            $table->dropColumn(array_filter([
                Schema::hasColumn('astrologer_reviews', 'is_pinned') ? 'is_pinned' : null,
                Schema::hasColumn('astrologer_reviews', 'pinned_at') ? 'pinned_at' : null,
                Schema::hasColumn('astrologer_reviews', 'is_flagged') ? 'is_flagged' : null,
                Schema::hasColumn('astrologer_reviews', 'flag_reason') ? 'flag_reason' : null,
                Schema::hasColumn('astrologer_reviews', 'flagged_at') ? 'flagged_at' : null,
            ]));
        });
    }
};
