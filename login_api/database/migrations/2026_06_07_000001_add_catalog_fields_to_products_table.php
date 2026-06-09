<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->string('unit')->nullable()->after('price');
            $table->longText('specifications')->nullable()->after('benefits');
            $table->longText('warnings_precautions')->nullable()->after('specifications');
        });
    }

    public function down(): void
    {
        Schema::table('products', function (Blueprint $table) {
            $table->dropColumn([
                'unit',
                'specifications',
                'warnings_precautions',
            ]);
        });
    }
};
