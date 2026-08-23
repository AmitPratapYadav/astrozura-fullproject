<?php

namespace App\Services;

use App\Models\Booking;
use Carbon\Carbon;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class SmartChatWhatsAppService
{
    public function sendOtp(string $phone, string $otp): bool
    {
        return $this->sendAuthTemplate($phone, 'otp_login', [
            'otp_code' => $this->cleanTemplateValue($otp),
        ], [
            'type' => 'otp_login',
        ]);
    }

    public function sendBookingConfirmation(Booking $booking): bool
    {
        $booking->loadMissing(['user', 'astrologer']);

        $phone = (string) ($booking->user?->phone ?? '');
        if ($phone === '') {
            Log::warning('SmartChat WhatsApp booking skipped: user phone is missing.', [
                'booking_id' => $booking->id,
            ]);
            return false;
        }

        $type = Str::lower((string) $booking->consultation_type);
        $template = $type === 'chat' ? 'chat_scheduled' : 'call_scheduled';
        $scheduled = $this->bookingDateTime($booking);

        return $this->sendTemplate($phone, $template, [
            $this->cleanTemplateValue($booking->user?->name ?: $booking->user_name ?: 'User'),
            $this->cleanTemplateValue($booking->astrologer?->name ?: $booking->astrologer_name ?: 'Astrologer'),
            $scheduled->format('d M Y'),
            $scheduled->format('g:i A'),
        ], [
            'type' => $template,
            'booking_id' => $booking->id,
        ]);
    }

    public function sendPaymentSuccess(string $phone, string $name, float $amount, string $purpose): bool
    {
        return $this->sendTemplate($phone, 'payment_success', [
            $this->cleanTemplateValue($name ?: 'User'),
            number_format($amount, 2, '.', ''),
            $this->cleanTemplateValue($purpose ?: 'AstroZura service'),
            'AstroZura',
        ], [
            'type' => 'payment_success',
            'purpose' => $purpose,
        ]);
    }

    public function sendOrderReceived(string $phone, string $name, string $orderNumber): bool
    {
        return $this->sendTemplate($phone, 'order_received', [
            $this->cleanTemplateValue($name ?: 'User'),
            $this->cleanTemplateValue($orderNumber),
            'AstroZura',
        ], [
            'type' => 'order_received',
            'order_number' => $orderNumber,
        ]);
    }

    private function sendTemplate(string $phone, string $template, array $parameters, array $context = []): bool
    {
        $payload = $this->basePayload($phone, $template);
        if (!$payload) {
            return false;
        }

        foreach (array_values($parameters) as $index => $value) {
            $payload['parameter_value' . ($index + 1)] = $this->cleanTemplateValue((string) $value);
        }

        return $this->post((string) config('services.smartchat_whatsapp.template_url'), $payload, $context);
    }

    private function sendAuthTemplate(string $phone, string $template, array $parameters, array $context = []): bool
    {
        $payload = $this->basePayload($phone, $template, $template);
        if (!$payload) {
            return false;
        }

        $payload = array_merge($payload, $parameters);

        return $this->post((string) config('services.smartchat_whatsapp.auth_template_url'), $payload, $context);
    }

    private function basePayload(string $phone, string $template, ?string $broadcastName = null): ?array
    {
        if (!$this->isConfigured()) {
            Log::warning('SmartChat WhatsApp skipped: configuration is incomplete.', [
                'template' => $template,
            ]);
            return null;
        }

        $number = $this->normalizeIndianMobile($phone);
        if (!$number) {
            Log::warning('SmartChat WhatsApp skipped: invalid mobile number.', [
                'template' => $template,
            ]);
            return null;
        }

        return [
            'sender_whatsapp_number' => $number,
            'template_name' => $template,
            'broadcast_name' => $broadcastName ?: (string) config('services.smartchat_whatsapp.broadcast_name', 'AstroZura'),
            'url' => '',
        ];
    }

    private function post(string $url, array $payload, array $context): bool
    {
        try {
            $response = Http::timeout((int) config('services.smartchat_whatsapp.timeout', 15))
                ->retry(1, 500)
                ->withOptions([
                    'verify' => filter_var(config('services.smartchat_whatsapp.verify_ssl', true), FILTER_VALIDATE_BOOLEAN),
                ])
                ->withHeaders([
                    'token' => (string) config('services.smartchat_whatsapp.token'),
                    'Content-Type' => 'application/json',
                    'Accept' => 'application/json',
                ])
                ->post($url, $payload);
        } catch (\Throwable $e) {
            report($e);
            Log::warning('SmartChat WhatsApp request failed before response.', $context);
            return false;
        }

        $body = trim($response->body());
        $json = json_decode($body, true);
        $status = is_array($json) ? ($json['status'] ?? $json['message_status'] ?? null) : null;
        $result = is_array($json) ? ($json['result'] ?? null) : null;
        $message = is_array($json) ? Str::lower((string) ($json['message'] ?? $json['messsage'] ?? '')) : '';
        $success = $response->successful()
            && (
                (is_numeric($status) && (int) $status === 200)
                || $result === true
                || Str::lower((string) $result) === 'true'
                || $message === 'success'
                || Str::contains(Str::lower($body), ['message send successfully', '"message_status":"accepted"', '"messages"'])
            );

        $logContext = array_merge($context, [
            'status' => $response->status(),
            'provider_status' => $status,
            'provider_response' => Str::limit($body, 300),
        ]);

        if ($success) {
            Log::info('SmartChat WhatsApp accepted by provider.', $logContext);
        } else {
            Log::warning('SmartChat WhatsApp rejected by provider.', $logContext);
        }

        return $success;
    }

    private function isConfigured(): bool
    {
        return (bool) config('services.smartchat_whatsapp.enabled', false)
            && filled(config('services.smartchat_whatsapp.token'))
            && filled(config('services.smartchat_whatsapp.template_url'))
            && filled(config('services.smartchat_whatsapp.auth_template_url'));
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
