<?php

return [
    'live' => [
        'enabled' => env('VIDEOSDK_LIVE_ENABLED', false),
        'api_key' => env('VIDEOSDK_API_KEY'),
        'secret' => env('VIDEOSDK_SECRET'),
        'token_ttl' => env('VIDEOSDK_TOKEN_TTL', 2 * 60 * 60),
    ],
];
