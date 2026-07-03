<?php

namespace App\Services;

use App\Models\Booking;
use Carbon\Carbon;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class UltronSmsService
{
    public function sendOtp(string $phone, string $otp): bool
    {
        $templateId = $this->templateId('otp');
        if (!$templateId) {
            Log::warning('Ultron OTP SMS skipped: DLT template id is missing.');
            return false;
        }

        $text = "Dear User, your AstroZura login OTP is {$otp}. Do not share it with anyone. Valid for 10 minutes. Team AstroZura.";

        return $this->send($phone, $text, $templateId, ['type' => 'otp']);
    }

    public function sendBookingConfirmation(Booking $booking): bool
    {
        $booking->loadMissing(['user', 'astrologer']);

        $type = Str::lower((string) $booking->consultation_type);
        $templateKey = $type === 'chat' ? 'chat_booking' : 'call_booking';
        $templateId = $this->templateId($templateKey);

        if (!$templateId) {
            Log::warning('Ultron booking SMS skipped: DLT template id is missing.', [
                'booking_id' => $booking->id,
                'template' => $templateKey,
            ]);
            return false;
        }

        $phone = (string) ($booking->user?->phone ?? '');
        if ($phone === '') {
            Log::warning('Ultron booking SMS skipped: user phone is missing.', [
                'booking_id' => $booking->id,
            ]);
            return false;
        }

        $userName = $this->cleanTemplateValue($booking->user?->name ?: $booking->user_name ?: 'User');
        $astrologerName = $this->cleanTemplateValue($booking->astrologer?->name ?: $booking->astrologer_name ?: 'Astrologer');
        $scheduled = $this->bookingDateTime($booking);
        $date = $scheduled->format('d M Y');
        $time = $scheduled->format('g:i A');

        if ($type === 'chat') {
            $text = "Dear {$userName}, your chat session with astrologer {$astrologerName} is scheduled on {$date} at {$time}. Team AstroZura.";
        } else {
            $text = "Dear {$userName}, your call with astrologer {$astrologerName} is scheduled on {$date} at {$time}. Team AstroZura.";
        }

        return $this->send($phone, $text, $templateId, [
            'type' => $templateKey,
            'booking_id' => $booking->id,
        ]);
    }

    private function send(string $phone, string $text, string $templateId, array $context = []): bool
    {
        if (!$this->isConfigured()) {
            Log::warning('Ultron SMS skipped: credentials are incomplete.', $context);
            return false;
        }

        $number = $this->normalizeIndianMobile($phone);
        if (!$number) {
            Log::warning('Ultron SMS skipped: invalid mobile number.', $context);
            return false;
        }

        try {
            $response = Http::timeout(12)
                ->retry(1, 500)
                ->get((string) config('services.ultron_sms.base_url'), [
                    'user' => config('services.ultron_sms.user'),
                    'password' => config('services.ultron_sms.password'),
                    'senderid' => config('services.ultron_sms.sender_id'),
                    'channel' => config('services.ultron_sms.channel'),
                    'DCS' => config('services.ultron_sms.dcs'),
                    'flashsms' => config('services.ultron_sms.flashsms'),
                    'number' => $number,
                    'text' => $text,
                    'route' => config('services.ultron_sms.route'),
                    'peid' => config('services.ultron_sms.peid'),
                    'DLTTemplateId' => $templateId,
                ]);
        } catch (\Throwable $e) {
            report($e);
            Log::warning('Ultron SMS request failed before response.', $context);
            return false;
        }

        $body = trim($response->body());
        $looksFailed = Str::contains(Str::lower($body), ['error', 'fail', 'invalid', 'denied']);
        $success = $response->successful() && !$looksFailed;

        Log::info($success ? 'Ultron SMS accepted by provider.' : 'Ultron SMS rejected by provider.', array_merge($context, [
            'status' => $response->status(),
            'template_id' => $templateId,
            'provider_response' => Str::limit($body, 200),
        ]));

        return $success;
    }

    private function isConfigured(): bool
    {
        return filled(config('services.ultron_sms.base_url'))
            && filled(config('services.ultron_sms.user'))
            && filled(config('services.ultron_sms.password'))
            && filled(config('services.ultron_sms.sender_id'))
            && filled(config('services.ultron_sms.route'))
            && filled(config('services.ultron_sms.peid'));
    }

    private function templateId(string $key): ?string
    {
        $templateId = config("services.ultron_sms.templates.{$key}");

        return filled($templateId) ? (string) $templateId : null;
    }

    private function normalizeIndianMobile(string $phone): ?string
    {
        $digits = preg_replace('/\D+/', '', $phone) ?: '';

        if (strlen($digits) === 10) {
            return '91' . $digits;
        }

        if (strlen($digits) === 11 && str_starts_with($digits, '0')) {
            return '91' . substr($digits, 1);
        }

        if (strlen($digits) === 12 && str_starts_with($digits, '91')) {
            return $digits;
        }

        return null;
    }

    private function bookingDateTime(Booking $booking): Carbon
    {
        $timezone = $booking->timezone ?: 'Asia/Kolkata';

        if ($booking->scheduled_at) {
            return $booking->scheduled_at->copy()->timezone($timezone);
        }

        return Carbon::parse(trim($booking->booking_date . ' ' . $booking->booking_time), $timezone);
    }

    private function cleanTemplateValue(string $value): string
    {
        return trim(preg_replace('/\s+/', ' ', $value) ?: '');
    }
}
