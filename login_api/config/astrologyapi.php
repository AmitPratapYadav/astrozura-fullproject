<?php

return [
    'user_id' => env('ASTROLOGY_API_USER_ID'),
    'api_key' => env('ASTROLOGY_API_KEY'),
    'json_base_url' => env('ASTROLOGY_API_JSON_BASE_URL', 'https://json.astrologyapi.com/v1'),
    'pdf_base_url' => env('ASTROLOGY_API_PDF_BASE_URL', 'https://pdf.astrologyapi.com/v1'),
    'default_timezone' => (float) env('ASTROLOGY_API_DEFAULT_TIMEZONE', 5.5),
    'default_language' => env('ASTROLOGY_API_DEFAULT_LANGUAGE', 'en'),
    'horoscope_cache' => [
        'enabled' => filter_var(env('ASTROLOGY_API_HOROSCOPE_CACHE_ENABLED', false), FILTER_VALIDATE_BOOL),
        'prefix' => env('ASTROLOGY_API_HOROSCOPE_CACHE_PREFIX', 'astrologyapi:horoscope'),
    ],
];
