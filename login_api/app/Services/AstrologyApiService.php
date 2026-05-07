<?php

namespace App\Services;

use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Http;

class AstrologyApiService
{
    public function json(string $path, array $payload = [], ?string $language = null): Response
    {
        return $this->request(
            rtrim((string) config('astrologyapi.json_base_url'), '/') . '/' . ltrim($path, '/'),
            $payload,
            $language
        );
    }

    public function pdf(string $path, array $payload = [], ?string $language = null): Response
    {
        return $this->request(
            rtrim((string) config('astrologyapi.pdf_base_url'), '/') . '/' . ltrim($path, '/'),
            $payload,
            $language
        );
    }

    protected function request(string $url, array $payload, ?string $language): Response
    {
        $userId = (string) config('astrologyapi.user_id');
        $apiKey = (string) config('astrologyapi.api_key');

        if ($userId === '' || $apiKey === '') {
            throw new \RuntimeException('Astrology API credentials are not configured. Set ASTROLOGY_API_USER_ID and ASTROLOGY_API_KEY.');
        }

        $headers = [
            'Accept' => 'application/json',
            'Content-Type' => 'application/json',
            'Accept-Language' => $language ?: (string) config('astrologyapi.default_language', 'en'),
        ];

        return Http::withBasicAuth($userId, $apiKey)
            ->withHeaders($headers)
            ->timeout(30)
            ->asJson()
            ->post($url, $payload);
    }
}
