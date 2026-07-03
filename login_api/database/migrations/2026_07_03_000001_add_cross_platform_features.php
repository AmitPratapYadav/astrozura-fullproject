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
            $table->boolean('supports_chat')->default(true)->after('call_price');
            $table->boolean('supports_call')->default(true)->after('supports_chat');
            $table->boolean('is_online')->default(true)->after('supports_call');
            $table->decimal('chat_commission_percentage', 5, 2)->default(20)->after('is_online');
            $table->decimal('call_commission_percentage', 5, 2)->default(20)->after('chat_commission_percentage');
            $table->json('translations')->nullable()->after('call_commission_percentage');
        });

        Schema::table('categories', function (Blueprint $table) {
            $table->decimal('shipping_charge', 10, 2)->default(0)->after('image');
            $table->json('translations')->nullable()->after('shipping_charge');
        });

        Schema::table('products', function (Blueprint $table) {
            $table->json('translations')->nullable()->after('image');
        });

        Schema::table('ritual_services', function (Blueprint $table) {
            $table->json('translations')->nullable()->after('mantras');
        });

        Schema::table('blog_categories', function (Blueprint $table) {
            $table->json('translations')->nullable()->after('image');
        });

        Schema::table('blogs', function (Blueprint $table) {
            $table->json('translations')->nullable()->after('content_blocks');
        });

        Schema::table('bookings', function (Blueprint $table) {
            $table->decimal('commission_percentage', 5, 2)->nullable()->after('amount');
            $table->decimal('platform_commission_amount', 10, 2)->default(0)->after('commission_percentage');
            $table->decimal('astrologer_earning_amount', 10, 2)->default(0)->after('platform_commission_amount');
            $table->unsignedBigInteger('reassigned_from_astrologer_id')->nullable()->after('astrologer_id');
            $table->timestamp('reassigned_at')->nullable()->after('reassigned_from_astrologer_id');
        });

        Schema::table('orders', function (Blueprint $table) {
            $table->decimal('subtotal_amount', 10, 2)->default(0)->after('order_number');
            $table->decimal('shipping_amount', 10, 2)->default(0)->after('subtotal_amount');
            $table->decimal('tax_amount', 10, 2)->default(0)->after('shipping_amount');
            $table->json('shipping_breakdown')->nullable()->after('shipping_address');
            $table->json('shipping_details')->nullable()->after('shipping_breakdown');
        });

        Schema::create('user_addresses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('label')->default('Home');
            $table->string('recipient_name');
            $table->string('phone', 30);
            $table->string('address_line');
            $table->string('city');
            $table->string('state');
            $table->string('postal_code', 20);
            $table->string('country')->default('India');
            $table->boolean('is_default')->default(false);
            $table->timestamps();
            $table->index(['user_id', 'is_default']);
        });

        Schema::create('user_notifications', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->enum('surface', ['main', 'shop']);
            $table->string('type');
            $table->string('title');
            $table->text('message');
            $table->string('action_url')->nullable();
            $table->json('data')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamps();
            $table->index(['user_id', 'surface', 'read_at']);
            $table->index(['surface', 'expires_at']);
        });

        Schema::create('newsletter_subscribers', function (Blueprint $table) {
            $table->id();
            $table->string('email');
            $table->enum('source', ['main', 'shop']);
            $table->boolean('is_active')->default(true);
            $table->timestamps();
            $table->unique(['email', 'source']);
            $table->index(['source', 'is_active']);
        });

        DB::table('astrologer_details')
            ->whereNotNull('profile_image')
            ->orderBy('id')
            ->chunkById(250, function ($details): void {
                foreach ($details as $detail) {
                    DB::table('users')
                        ->where('id', $detail->user_id)
                        ->where('role', 'astrologer')
                        ->whereNull('profile_image')
                        ->update(['profile_image' => $detail->profile_image]);
                }
            });

        DB::table('bookings')->orderBy('id')->chunkById(250, function ($bookings): void {
            foreach ($bookings as $booking) {
                $detail = DB::table('astrologer_details')->where('user_id', $booking->astrologer_id)->first();
                $percentage = (float) (
                    $booking->consultation_type === 'call'
                        ? ($detail->call_commission_percentage ?? 20)
                        : ($detail->chat_commission_percentage ?? 20)
                );
                $commission = round((float) $booking->amount * $percentage / 100, 2);
                DB::table('bookings')->where('id', $booking->id)->update([
                    'commission_percentage' => $percentage,
                    'platform_commission_amount' => $commission,
                    'astrologer_earning_amount' => round((float) $booking->amount - $commission, 2),
                ]);
            }
        });

        DB::table('orders')->where('subtotal_amount', 0)->update([
            'subtotal_amount' => DB::raw('total_amount'),
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('newsletter_subscribers');
        Schema::dropIfExists('user_notifications');
        Schema::dropIfExists('user_addresses');

        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn([
                'subtotal_amount',
                'shipping_amount',
                'tax_amount',
                'shipping_breakdown',
                'shipping_details',
            ]);
        });

        Schema::table('bookings', function (Blueprint $table) {
            $table->dropColumn([
                'commission_percentage',
                'platform_commission_amount',
                'astrologer_earning_amount',
                'reassigned_from_astrologer_id',
                'reassigned_at',
            ]);
        });

        Schema::table('blogs', fn (Blueprint $table) => $table->dropColumn('translations'));
        Schema::table('blog_categories', fn (Blueprint $table) => $table->dropColumn('translations'));
        Schema::table('ritual_services', fn (Blueprint $table) => $table->dropColumn('translations'));
        Schema::table('products', fn (Blueprint $table) => $table->dropColumn('translations'));
        Schema::table('categories', fn (Blueprint $table) => $table->dropColumn(['shipping_charge', 'translations']));
        Schema::table('astrologer_details', fn (Blueprint $table) => $table->dropColumn([
            'supports_chat',
            'supports_call',
            'is_online',
            'chat_commission_percentage',
            'call_commission_percentage',
            'translations',
        ]));
    }
};
