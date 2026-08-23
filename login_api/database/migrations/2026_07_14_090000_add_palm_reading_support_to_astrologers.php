<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('astrologer_details', function (Blueprint $table) {
            if (!Schema::hasColumn('astrologer_details', 'supports_palm_reading')) {
                $table->boolean('supports_palm_reading')->default(false)->after('is_online');
            }
        });

        DB::table('astrologer_details')
            ->where('specialities', 'like', '%palm%')
            ->update(['supports_palm_reading' => true]);

        Schema::table('bookings', function (Blueprint $table) {
            if (!Schema::hasColumn('bookings', 'service_context')) {
                $table->string('service_context', 80)->nullable()->after('consultation_type');
            }
        });
    }

    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            if (Schema::hasColumn('bookings', 'service_context')) {
                $table->dropColumn('service_context');
            }
        });

        Schema::table('astrologer_details', function (Blueprint $table) {
            if (Schema::hasColumn('astrologer_details', 'supports_palm_reading')) {
                $table->dropColumn('supports_palm_reading');
            }
        });
    }
};
