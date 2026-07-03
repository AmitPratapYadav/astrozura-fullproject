<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Mailgun, Postmark, AWS and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    'google' => [
        'client_id' => env('GOOGLE_CLIENT_ID'),
        'android_client_id' => env('GOOGLE_ANDROID_CLIENT_ID'),
        'mobile_client_ids' => array_filter(array_map('trim', explode(',', env('GOOGLE_MOBILE_CLIENT_IDS', '')))),
        'client_secret' => env('GOOGLE_CLIENT_SECRET'),
        'redirect' => env('GOOGLE_REDIRECT_URL'),
    ],

    'razorpay' => [
        'key_id' => env('RAZORPAY_KEY_ID'),
        'key_secret' => env('RAZORPAY_KEY_SECRET'),
        'webhook_secret' => env('RAZORPAY_WEBHOOK_SECRET'),
        'merchant_id' => env('RAZORPAY_MERCHANT_ID'),
    ],

    'ultron_sms' => [
        'base_url' => env('ULTRON_SMS_BASE_URL', 'https://ultronsms.com/api/mt/SendSMS'),
        'user' => env('ULTRON_SMS_USER'),
        'password' => env('ULTRON_SMS_PASSWORD'),
        'sender_id' => env('ULTRON_SMS_SENDER_ID', 'ASTZRA'),
        'channel' => env('ULTRON_SMS_CHANNEL', 'Trans'),
        'route' => env('ULTRON_SMS_ROUTE', '02'),
        'peid' => env('ULTRON_SMS_PEID'),
        'dcs' => env('ULTRON_SMS_DCS', '0'),
        'flashsms' => env('ULTRON_SMS_FLASHSMS', '0'),
        'templates' => [
            'otp' => env('ULTRON_SMS_TEMPLATE_OTP'),
            'call_booking' => env('ULTRON_SMS_TEMPLATE_CALL_BOOKING'),
            'chat_booking' => env('ULTRON_SMS_TEMPLATE_CHAT_BOOKING'),
        ],
    ],

];
