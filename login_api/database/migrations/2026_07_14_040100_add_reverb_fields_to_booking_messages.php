<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('booking_messages', function (Blueprint $table) {
            $table->foreignId('reply_to_message_id')->nullable()->after('sender_role')->constrained('booking_messages')->nullOnDelete();
            $table->mediumText('encrypted_body')->nullable()->after('text');
            $table->string('encryption_iv', 120)->nullable()->after('encrypted_body');
            $table->string('encryption_tag', 120)->nullable()->after('encryption_iv');
            $table->string('encryption_version', 40)->nullable()->after('encryption_tag');
            $table->string('attachment_name', 255)->nullable()->after('media_url');
            $table->string('attachment_mime', 120)->nullable()->after('attachment_name');
            $table->unsignedBigInteger('attachment_size')->nullable()->after('attachment_mime');
            $table->dateTime('read_at')->nullable()->after('sent_at');
        });
    }

    public function down(): void
    {
        Schema::table('booking_messages', function (Blueprint $table) {
            $table->dropForeign(['reply_to_message_id']);
            $table->dropColumn([
                'reply_to_message_id',
                'encrypted_body',
                'encryption_iv',
                'encryption_tag',
                'encryption_version',
                'attachment_name',
                'attachment_mime',
                'attachment_size',
                'read_at',
            ]);
        });
    }
};
