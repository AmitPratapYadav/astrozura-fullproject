<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('products', function (Blueprint $table) {
            if (!Schema::hasColumn('products', 'is_new_arrival')) {
                $table->boolean('is_new_arrival')->default(false)->after('is_trending');
            }
            if (!Schema::hasColumn('products', 'guide_blog_id')) {
                $table->foreignId('guide_blog_id')->nullable()->after('category_id')->constrained('blogs')->nullOnDelete();
            }
        });

        Schema::table('blog_categories', function (Blueprint $table) {
            if (!Schema::hasColumn('blog_categories', 'show_on_main')) {
                $table->boolean('show_on_main')->default(true)->after('sort_order');
            }
            if (!Schema::hasColumn('blog_categories', 'show_on_shop')) {
                $table->boolean('show_on_shop')->default(false)->after('show_on_main');
            }
        });

        Schema::table('blogs', function (Blueprint $table) {
            if (!Schema::hasColumn('blogs', 'show_on_main')) {
                $table->boolean('show_on_main')->default(true)->after('status');
            }
            if (!Schema::hasColumn('blogs', 'show_on_shop')) {
                $table->boolean('show_on_shop')->default(false)->after('show_on_main');
            }
        });

        if (!Schema::hasTable('yearly_horoscope_accesses')) {
            Schema::create('yearly_horoscope_accesses', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained()->cascadeOnDelete();
                $table->unsignedSmallInteger('year');
                $table->decimal('amount', 10, 2)->default(10);
                $table->string('payment_status')->default('pending');
                $table->string('payment_method')->nullable();
                $table->string('payment_id')->nullable();
                $table->string('razorpay_order_id')->nullable()->index();
                $table->string('razorpay_signature')->nullable();
                $table->timestamp('access_expires_at')->nullable();
                $table->timestamps();

                $table->index(['user_id', 'year', 'payment_status', 'access_expires_at'], 'yearly_horoscope_active_idx');
            });
        }

        if (Schema::hasTable('categories') && !DB::table('categories')->whereRaw('LOWER(name) = ?', ['gems'])->exists()) {
            DB::table('categories')->insert([
                'name' => 'Gems',
                'shipping_charge' => 0,
                'translations' => json_encode(['hi' => ['name' => 'रत्न']]),
                'status' => 1,
                'created_at' => now(),
                'updated_at' => now(),
            ]);
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('yearly_horoscope_accesses');

        Schema::table('blogs', function (Blueprint $table) {
            foreach (['show_on_main', 'show_on_shop'] as $column) {
                if (Schema::hasColumn('blogs', $column)) {
                    $table->dropColumn($column);
                }
            }
        });

        Schema::table('blog_categories', function (Blueprint $table) {
            foreach (['show_on_main', 'show_on_shop'] as $column) {
                if (Schema::hasColumn('blog_categories', $column)) {
                    $table->dropColumn($column);
                }
            }
        });

        Schema::table('products', function (Blueprint $table) {
            if (Schema::hasColumn('products', 'guide_blog_id')) {
                $table->dropConstrainedForeignId('guide_blog_id');
            }
            if (Schema::hasColumn('products', 'is_new_arrival')) {
                $table->dropColumn('is_new_arrival');
            }
        });
    }
};
