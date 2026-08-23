<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AdminNotification;
use App\Models\Booking;
use App\Models\Order;
use App\Models\RitualBooking;
use App\Models\YearlyHoroscopeAccess;
use App\Services\SmartChatWhatsAppService;
use App\Services\UltronSmsService;
use App\Services\UserNotificationService;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Validation\Rule;

class RazorpayPaymentController extends Controller
{
    public function config()
    {
        return response()->json([
            'success' => true,
            'enabled' => $this->isConfigured(),
            'key_id' => config('services.razorpay.key_id'),
        ]);
    }

    public function createOrder(Request $request)
    {
        $validated = $request->validate([
            'purpose' => ['required', Rule::in(['consultation', 'ritual', 'product', 'yearly_horoscope'])],
            'record_id' => 'required|integer',
        ]);

        if (!$this->isConfigured()) {
            return response()->json([
                'success' => false,
                'message' => 'Razorpay is not configured yet. Please contact support.',
            ], 503);
        }

        $record = $this->findOwnedRecord(
            $validated['purpose'],
            (int) $validated['record_id'],
            (int) $request->user()->id
        );

        if ($record->payment_status === 'paid') {
            return response()->json([
                'success' => false,
                'message' => 'This payment has already been completed.',
            ], 422);
        }

        $amount = $this->recordAmount($record);
        if ($amount < 1) {
            return response()->json([
                'success' => false,
                'message' => 'The payable amount must be at least Rs 1.',
            ], 422);
        }

        $response = Http::withBasicAuth(
            config('services.razorpay.key_id'),
            config('services.razorpay.key_secret')
        )->acceptJson()->post('https://api.razorpay.com/v1/orders', [
            'amount' => (int) round($amount * 100),
            'currency' => 'INR',
            'receipt' => substr($validated['purpose'] . '-' . $record->getKey(), 0, 40),
            'notes' => [
                'purpose' => $validated['purpose'],
                'record_id' => (string) $record->getKey(),
                'user_id' => (string) $request->user()->id,
            ],
        ]);

        if (!$response->successful()) {
            report(new \RuntimeException('Razorpay order creation failed: ' . $response->body()));

            return response()->json([
                'success' => false,
                'message' => 'Unable to initialize Razorpay payment.',
            ], 502);
        }

        $razorpayOrder = $response->json();
        $record->update([
            'payment_method' => 'razorpay',
            'razorpay_order_id' => $razorpayOrder['id'],
        ]);

        return response()->json([
            'success' => true,
            'key_id' => config('services.razorpay.key_id'),
            'order' => $razorpayOrder,
        ]);
    }

    public function verify(Request $request)
    {
        $validated = $request->validate([
            'purpose' => ['required', Rule::in(['consultation', 'ritual', 'product', 'yearly_horoscope'])],
            'record_id' => 'required|integer',
            'razorpay_order_id' => 'required|string',
            'razorpay_payment_id' => 'required|string',
            'razorpay_signature' => 'required|string',
        ]);

        $record = $this->findOwnedRecord(
            $validated['purpose'],
            (int) $validated['record_id'],
            (int) $request->user()->id
        );

        if (!hash_equals((string) $record->razorpay_order_id, $validated['razorpay_order_id'])) {
            return response()->json(['success' => false, 'message' => 'Payment order mismatch.'], 422);
        }

        $expected = hash_hmac(
            'sha256',
            $validated['razorpay_order_id'] . '|' . $validated['razorpay_payment_id'],
            (string) config('services.razorpay.key_secret')
        );

        if (!hash_equals($expected, $validated['razorpay_signature'])) {
            return response()->json(['success' => false, 'message' => 'Payment verification failed.'], 422);
        }

        $this->markPaid(
            $record,
            $validated['purpose'],
            $validated['razorpay_payment_id'],
            $validated['razorpay_signature']
        );

        return response()->json([
            'success' => true,
            'message' => 'Payment verified successfully.',
            'record' => $record->fresh(),
        ]);
    }

    public function webhook(Request $request)
    {
        $secret = (string) config('services.razorpay.webhook_secret');
        $signature = (string) $request->header('X-Razorpay-Signature');

        if ($secret === '' || $signature === '') {
            return response()->json(['success' => false], 401);
        }

        $expected = hash_hmac('sha256', $request->getContent(), $secret);
        if (!hash_equals($expected, $signature)) {
            return response()->json(['success' => false], 401);
        }

        $payload = $request->json()->all();
        if (($payload['event'] ?? null) !== 'payment.captured') {
            return response()->json(['success' => true]);
        }

        $payment = $payload['payload']['payment']['entity'] ?? [];
        $orderId = $payment['order_id'] ?? null;
        $paymentId = $payment['id'] ?? null;

        if (!$orderId || !$paymentId) {
            return response()->json(['success' => true]);
        }

        foreach ([
            'consultation' => Booking::class,
            'ritual' => RitualBooking::class,
            'product' => Order::class,
            'yearly_horoscope' => YearlyHoroscopeAccess::class,
        ] as $purpose => $modelClass) {
            $record = $modelClass::where('razorpay_order_id', $orderId)->first();
            if ($record) {
                $this->markPaid($record, $purpose, $paymentId, $signature);
                break;
            }
        }

        return response()->json(['success' => true]);
    }

    private function isConfigured(): bool
    {
        return filled(config('services.razorpay.key_id'))
            && filled(config('services.razorpay.key_secret'));
    }

    private function findOwnedRecord(string $purpose, int $recordId, int $userId): Model
    {
        $modelClass = match ($purpose) {
            'consultation' => Booking::class,
            'ritual' => RitualBooking::class,
            'product' => Order::class,
            'yearly_horoscope' => YearlyHoroscopeAccess::class,
        };

        return $modelClass::whereKey($recordId)->where('user_id', $userId)->firstOrFail();
    }

    private function recordAmount(Model $record): float
    {
        return (float) ($record instanceof Order ? $record->total_amount : $record->amount);
    }

    private function markPaid(Model $record, string $purpose, string $paymentId, ?string $signature = null): void
    {
        $sendBookingSms = false;
        $sendPaymentSms = false;

        DB::transaction(function () use ($record, $purpose, $paymentId, $signature, &$sendBookingSms, &$sendPaymentSms) {
            $record->refresh();
            if ($record->payment_status === 'paid') {
                return;
            }

            $updates = [
                'payment_status' => 'paid',
                'payment_method' => 'razorpay',
                'payment_id' => $paymentId,
                'razorpay_signature' => $signature,
            ];

            if ($record instanceof Booking) {
                $updates['status'] = 'confirmed';
                $sendBookingSms = true;
            } elseif ($record instanceof RitualBooking) {
                $updates['status'] = 'confirmed';
                $updates['paid_at'] = now('Asia/Kolkata');
            } elseif ($record instanceof YearlyHoroscopeAccess) {
                $updates['access_expires_at'] = now('Asia/Kolkata')->addHours(12);
            }

            $record->update($updates);
            $sendPaymentSms = true;
            $this->createNotification($record, $purpose);
        });

        if ($sendBookingSms && $record instanceof Booking) {
            $booking = $record->fresh(['user', 'astrologer']);
            if ($booking instanceof Booking) {
                app(UltronSmsService::class)->sendBookingConfirmation($booking);
                app(SmartChatWhatsAppService::class)->sendBookingConfirmation($booking);
            }
        }

        if ($sendPaymentSms) {
            $freshRecord = $record->fresh();
            if ($freshRecord) {
                $recipient = $this->paymentSmsRecipient($freshRecord);
                if ($recipient['phone'] !== '') {
                    app(UltronSmsService::class)->sendPaymentSuccess(
                        $recipient['phone'],
                        $recipient['name'],
                        $this->recordAmount($freshRecord),
                        $this->paymentPurposeLabel($purpose, $freshRecord)
                    );
                    app(SmartChatWhatsAppService::class)->sendPaymentSuccess(
                        $recipient['phone'],
                        $recipient['name'],
                        $this->recordAmount($freshRecord),
                        $this->paymentPurposeLabel($purpose, $freshRecord)
                    );
                }
            }
        }

        if ($record->user_id) {
            $surface = $purpose === 'product' ? 'shop' : 'main';
            $actionUrl = match ($purpose) {
                'product' => "/dashboard/orders/{$record->id}",
                'yearly_horoscope' => '/rashifal?period=yearly',
                default => '/my-bookings',
            };
            app(UserNotificationService::class)->send(
                $record->user_id,
                $surface,
                "{$purpose}_payment",
                'Payment received',
                'Your payment was confirmed successfully.',
                $actionUrl,
                ['purpose' => $purpose, 'record_id' => $record->id]
            );
        }
    }

    private function paymentSmsRecipient(Model $record): array
    {
        $record->loadMissing('user');

        if ($record instanceof RitualBooking) {
            return [
                'phone' => (string) ($record->devotee_phone ?? $record->user?->phone ?? ''),
                'name' => (string) ($record->devotee_name ?? $record->user?->name ?? 'User'),
            ];
        }

        if ($record instanceof Order) {
            return [
                'phone' => (string) ($record->phone ?? $record->user?->phone ?? ''),
                'name' => (string) ($record->user?->name ?? 'User'),
            ];
        }

        if ($record instanceof Booking) {
            return [
                'phone' => (string) ($record->user?->phone ?? ''),
                'name' => (string) ($record->user?->name ?? $record->user_name ?? 'User'),
            ];
        }

        return [
            'phone' => (string) ($record->user?->phone ?? ''),
            'name' => (string) ($record->user?->name ?? 'User'),
        ];
    }

    private function paymentPurposeLabel(string $purpose, Model $record): string
    {
        return match ($purpose) {
            'consultation' => $record instanceof Booking
                ? ucfirst((string) $record->consultation_type) . ' consultation'
                : 'consultation',
            'ritual' => 'Pooja Anusthan',
            'product' => $record instanceof Order ? "order {$record->order_number}" : 'shop order',
            'yearly_horoscope' => 'yearly horoscope',
            default => 'AstroZura service',
        };
    }

    private function createNotification(Model $record, string $purpose): void
    {
        if ($purpose === 'consultation') {
            AdminNotification::create([
                'type' => 'consultation_booking',
                'title' => 'New consultation booking',
                'message' => "{$record->user_name} booked a {$record->consultation_type} session with {$record->astrologer_name}.",
                'route' => '/bookings',
                'data' => ['booking_id' => $record->id],
            ]);
            return;
        }

        if ($purpose === 'ritual') {
            $record->loadMissing('ritual');
            AdminNotification::create([
                'type' => 'ritual_booking',
                'title' => 'New ritual booking',
                'message' => "{$record->devotee_name} requested {$record->ritual?->name}.",
                'route' => '/ritual-bookings',
                'data' => ['ritual_booking_id' => $record->id],
            ]);
            return;
        }

        if ($purpose === 'yearly_horoscope') {
            AdminNotification::create([
                'type' => 'yearly_horoscope_payment',
                'title' => 'Yearly horoscope unlocked',
                'message' => "A user purchased yearly horoscope access for {$record->year}.",
                'route' => '/reports',
                'data' => ['yearly_horoscope_access_id' => $record->id],
            ]);
            return;
        }

        $record->loadMissing('user');
        AdminNotification::create([
            'type' => 'product_order',
            'title' => 'New product order',
            'message' => "{$record->order_number} was paid by {$record->user?->name} for Rs " . number_format($record->total_amount, 2),
            'route' => '/orders',
            'data' => ['order_id' => $record->id],
        ]);
    }
}
