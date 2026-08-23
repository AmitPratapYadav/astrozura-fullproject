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
            if (!Schema::hasColumn('astrologer_details', 'supports_ritual_booking')) {
                $table->boolean('supports_ritual_booking')->default(false)->after('supports_palm_reading');
            }
        });

        DB::table('astrologer_details')
            ->where(function ($query) {
                $query->where('specialities', 'like', '%ritual%')
                    ->orWhere('specialities', 'like', '%pooja%')
                    ->orWhere('specialities', 'like', '%puja%')
                    ->orWhere('specialities', 'like', '%anusthan%');
            })
            ->update(['supports_ritual_booking' => true]);

        $assignedAstrologerIds = DB::table('ritual_services')
            ->whereNotNull('assigned_astrologer_id')
            ->pluck('assigned_astrologer_id')
            ->filter()
            ->unique()
            ->values();

        if ($assignedAstrologerIds->isNotEmpty()) {
            DB::table('astrologer_details')
                ->whereIn('user_id', $assignedAstrologerIds)
                ->update(['supports_ritual_booking' => true]);
        }

        Schema::table('ritual_bookings', function (Blueprint $table) {
            if (!Schema::hasColumn('ritual_bookings', 'consultation_booking_id')) {
                $table->foreignId('consultation_booking_id')->nullable()->after('astrologer_id')->constrained('bookings')->nullOnDelete();
            }
            if (!Schema::hasColumn('ritual_bookings', 'consultation_status')) {
                $table->string('consultation_status')->nullable()->after('consultation_booking_id');
            }
            if (!Schema::hasColumn('ritual_bookings', 'payment_requested_at')) {
                $table->timestamp('payment_requested_at')->nullable()->after('payment_status');
            }
            if (!Schema::hasColumn('ritual_bookings', 'payment_requested_by_astrologer_id')) {
                $table->foreignId('payment_requested_by_astrologer_id')->nullable()->after('payment_requested_at')->constrained('users')->nullOnDelete();
            }
            if (!Schema::hasColumn('ritual_bookings', 'payment_note')) {
                $table->text('payment_note')->nullable()->after('payment_requested_by_astrologer_id');
            }
            if (!Schema::hasColumn('ritual_bookings', 'paid_at')) {
                $table->timestamp('paid_at')->nullable()->after('payment_note');
            }
        });
    }

    public function down(): void
    {
        Schema::table('ritual_bookings', function (Blueprint $table) {
            if (Schema::hasColumn('ritual_bookings', 'consultation_booking_id')) {
                $table->dropConstrainedForeignId('consultation_booking_id');
            }
            if (Schema::hasColumn('ritual_bookings', 'payment_requested_by_astrologer_id')) {
                $table->dropConstrainedForeignId('payment_requested_by_astrologer_id');
            }

            $columns = array_values(array_filter([
                Schema::hasColumn('ritual_bookings', 'consultation_status') ? 'consultation_status' : null,
                Schema::hasColumn('ritual_bookings', 'payment_requested_at') ? 'payment_requested_at' : null,
                Schema::hasColumn('ritual_bookings', 'payment_note') ? 'payment_note' : null,
                Schema::hasColumn('ritual_bookings', 'paid_at') ? 'paid_at' : null,
            ]));

            if ($columns !== []) {
                $table->dropColumn($columns);
            }
        });

        Schema::table('astrologer_details', function (Blueprint $table) {
            if (Schema::hasColumn('astrologer_details', 'supports_ritual_booking')) {
                $table->dropColumn('supports_ritual_booking');
            }
        });
    }
};
