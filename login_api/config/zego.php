<?php

return [
    'token_ttl' => (int) env('ZEGO_TOKEN_TTL', 6 * 60 * 60),
    'session' => [
        'test_mode' => filter_var(
            env('ZEGO_SESSION_TEST_MODE', env('APP_ENV', 'production') === 'local' ? 'true' : 'false'),
            FILTER_VALIDATE_BOOLEAN
        ),
        'join_grace_before_minutes' => (int) env('ZEGO_JOIN_GRACE_BEFORE_MINUTES', 10),
        'join_grace_after_minutes' => (int) env('ZEGO_JOIN_GRACE_AFTER_MINUTES', 15),
        'low_time_warning_seconds' => (int) env('ZEGO_LOW_TIME_WARNING_SECONDS', 120),
    ],
    'chat' => [
        'app_id' => (int) env('ZEGO_CHAT_APP_ID', 0),
        'app_sign' => env('ZEGO_CHAT_APP_SIGN'),
        'server_secret' => env('ZEGO_CHAT_SERVER_SECRET'),
        'server_url' => env('ZEGO_CHAT_SERVER_URL'),
        'secondary_server_url' => env('ZEGO_CHAT_SECONDARY_SERVER_URL'),
    ],
    'call' => [
        'app_id' => (int) env('ZEGO_CALL_APP_ID', 0),
        'app_sign' => env('ZEGO_CALL_APP_SIGN'),
        'server_secret' => env('ZEGO_CALL_SERVER_SECRET'),
        'server_url' => env('ZEGO_CALL_SERVER_URL'),
        'secondary_server_url' => env('ZEGO_CALL_SECONDARY_SERVER_URL'),
    ],
    'live' => [
        'app_id' => (int) env('ZEGO_LIVE_APP_ID', 0),
        'app_sign' => env('ZEGO_LIVE_APP_SIGN'),
        'server_secret' => env('ZEGO_LIVE_SERVER_SECRET'),
        'server_url' => env('ZEGO_LIVE_SERVER_URL'),
        'secondary_server_url' => env('ZEGO_LIVE_SECONDARY_SERVER_URL'),
    ],
];
