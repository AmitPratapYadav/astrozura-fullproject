<?php

namespace App\Services;

use App\Models\LiveSession;
use App\Models\PushSubscription;
use Carbon\Carbon;
use Google\Auth\Credentials\ServiceAccountCredentials;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FirebaseCloudMessagingService
{
    public function sendLiveStartedNotification(LiveSession $session): void
    {
        $subscriptions = PushSubscription::query()
            ->where('channel', 'live')
            ->where('platform', 'web')
            ->where('is_active', true)
            ->get();

        if ($subscriptions->isEmpty() || !$this->isConfigured()) {
            return;
        }

        $hostName = $session->astrologer?->name ?: 'Featured astrologer';
        $title = 'Astro Zura Live Started';
        $body = "{$hostName} is now live. Join the spiritual session now.";

        foreach ($subscriptions as $subscription) {
            $this->sendToToken(
                $subscription,
                $title,
                $body,
                [
                    'type' => 'live_started',
                    'session_id' => (string) $session->id,
                    'astrologer_id' => (string) $session->astrologer_id,
                ]
            );
        }
    }

    public function isConfigured(): bool
    {
        $projectId = (string) config('firebase.project_id');
        $credentialsPath = (string) config('firebase.credentials_path');

        return $projectId !== '' && $credentialsPath !== '' && is_file($credentialsPath);
    }

    private function sendToToken(PushSubscription $subscription, string $title, string $body, array $data = []): void
    {
        $projectId = (string) config('firebase.project_id');
        $link = (string) config('firebase.web_push_link', 'http://localhost:5173/live');
        $icon = (string) config('firebase.web_push_icon', '/vite.svg');
        $badge = (string) config('firebase.web_push_badge', '/vite.svg');

        try {
            $response = Http::withToken($this->getAccessToken())
                ->acceptJson()
                ->post("https://fcm.googleapis.com/v1/projects/{$projectId}/messages:send", [
                    'message' => [
                        'token' => $subscription->token,
                        'notification' => [
                            'title' => $title,
                            'body' => $body,
                        ],
                        'data' => array_merge($data, [
                            'title' => $title,
                            'body' => $body,
                            'link' => $link,
                        ]),
                        'webpush' => [
                            'headers' => [
                                'Urgency' => 'high',
                            ],
                            'notification' => [
                                'title' => $title,
                                'body' => $body,
                                'icon' => $icon,
                                'badge' => $badge,
                                'tag' => 'astrozura-live-session',
                                'requireInteraction' => true,
                                'data' => [
                                    'link' => $link,
                                ],
                            ],
                            'fcm_options' => [
                                'link' => $link,
                            ],
                        ],
                    ],
                ]);

            if ($response->successful()) {
                $subscription->forceFill([
                    'last_notified_at' => Carbon::now(),
                    'last_seen_at' => Carbon::now(),
                ])->save();
                return;
            }

            $errorStatus = data_get($response->json(), 'error.status');

            if (in_array($errorStatus, ['NOT_FOUND', 'INVALID_ARGUMENT', 'UNREGISTERED'], true)) {
                $subscription->forceFill([
                    'is_active' => false,
                ])->save();
            }

            Log::warning('FCM live notification failed', [
                'subscription_id' => $subscription->id,
                'status' => $response->status(),
                'error' => $response->json(),
            ]);
        } catch (\Throwable $exception) {
            Log::error('FCM live notification exception', [
                'subscription_id' => $subscription->id,
                'message' => $exception->getMessage(),
            ]);
        }
    }

    private function getAccessToken(): string
    {
        $cacheKey = 'firebase.fcm.access_token';
        $cached = Cache::get($cacheKey);

        if (is_array($cached) && !empty($cached['access_token']) && !empty($cached['expires_at'])) {
            $expiresAt = Carbon::parse($cached['expires_at']);
            if ($expiresAt->isFuture()) {
                return (string) $cached['access_token'];
            }
        }

        $credentials = new ServiceAccountCredentials(
            (string) config('firebase.messaging_scope'),
            (string) config('firebase.credentials_path')
        );

        $tokenData = $credentials->fetchAuthToken();
        $accessToken = $tokenData['access_token'] ?? null;

        if (!$accessToken) {
            throw new \RuntimeException('Firebase access token could not be generated.');
        }

        $expiresIn = max(((int) ($tokenData['expires_in'] ?? 3600)) - 120, 300);
        $expiresAt = Carbon::now()->addSeconds($expiresIn);

        Cache::put($cacheKey, [
            'access_token' => $accessToken,
            'expires_at' => $expiresAt->toIso8601String(),
        ], $expiresIn);

        return (string) $accessToken;
    }
}
