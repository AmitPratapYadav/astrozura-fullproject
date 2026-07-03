<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('astrologer_details', function (Blueprint $table) {
            $table->json('chat_duration_prices')->nullable()->after('call_price');
            $table->json('call_duration_prices')->nullable()->after('chat_duration_prices');
        });
    }

    public function down(): void
    {
        Schema::table('astrologer_details', function (Blueprint $table) {
            $table->dropColumn(['chat_duration_prices', 'call_duration_prices']);
        });
    }
};
