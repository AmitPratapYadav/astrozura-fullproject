<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->string('razorpay_order_id')->nullable()->index();
            $table->string('razorpay_signature')->nullable();
        });

        Schema::table('ritual_bookings', function (Blueprint $table) {
            $table->string('payment_method')->nullable()->after('payment_status');
            $table->string('payment_id')->nullable();
            $table->string('razorpay_order_id')->nullable()->index();
            $table->string('razorpay_signature')->nullable();
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->string('payment_id')->nullable();
            $table->string('razorpay_order_id')->nullable()->index();
            $table->string('razorpay_signature')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('bookings', function (Blueprint $table) {
            $table->dropIndex(['razorpay_order_id']);
            $table->dropColumn(['razorpay_order_id', 'razorpay_signature']);
        });

        Schema::table('ritual_bookings', function (Blueprint $table) {
            $table->dropIndex(['razorpay_order_id']);
            $table->dropColumn(['payment_method', 'payment_id', 'razorpay_order_id', 'razorpay_signature']);
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->dropIndex(['razorpay_order_id']);
            $table->dropColumn(['payment_id', 'razorpay_order_id', 'razorpay_signature']);
        });
    }
};
