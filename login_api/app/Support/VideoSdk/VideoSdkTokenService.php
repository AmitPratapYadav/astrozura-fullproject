<?php

namespace App\Support\VideoSdk;

class VideoSdkTokenService
{
    public static function generateToken(string $apiKey, string $secret, int $ttl, array $claims = []): string
    {
        $header = [
            'alg' => 'HS256',
            'typ' => 'JWT',
        ];

        $now = time();
        $payload = array_merge([
            'apikey' => $apiKey,
            'permissions' => ['allow_join'],
            'version' => 2,
            'roles' => ['rtc'],
            'iat' => $now,
            'exp' => $now + $ttl,
        ], $claims);

        $segments = [
            self::base64UrlEncode(json_encode($header, JSON_UNESCAPED_SLASHES)),
            self::base64UrlEncode(json_encode($payload, JSON_UNESCAPED_SLASHES)),
        ];

        $signature = hash_hmac('sha256', implode('.', $segments), $secret, true);
        $segments[] = self::base64UrlEncode($signature);

        return implode('.', $segments);
    }

    private static function base64UrlEncode(string $value): string
    {
        return rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
    }
}
