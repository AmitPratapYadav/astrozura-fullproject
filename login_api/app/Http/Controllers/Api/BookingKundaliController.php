<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Services\AstrologyApiService;
use Illuminate\Http\Client\Response;
use Illuminate\Http\Request;

class BookingKundaliController extends Controller
{
    public function __construct(private readonly AstrologyApiService $astrologyApi)
    {
    }

    public function show(Request $request, Booking $booking)
    {
        $this->authorizeBooking($request, $booking);

        $birthDetails = is_array($booking->birth_details) ? $booking->birth_details : [];
        $date = $birthDetails['date_of_birth'] ?? $birthDetails['dob'] ?? null;
        $time = $birthDetails['time_of_birth'] ?? $birthDetails['birth_time'] ?? null;
        $coordinates = $birthDetails['coordinates'] ?? null;

        if (!$coordinates && isset($birthDetails['latitude'], $birthDetails['longitude'])) {
            $coordinates = $birthDetails['latitude'] . ',' . $birthDetails['longitude'];
        }

        if (!$date || !$time || !$coordinates) {
            return response()->json([
                'status' => 'error',
                'message' => 'Birth date, time, or coordinates are missing for this booking.',
            ], 422);
        }

        $datetime = $this->buildIsoDatetime((string) $date, (string) $time);
        $language = (string) $request->query('la', 'en');
        $payload = $this->buildBirthPayload($datetime, (string) $coordinates, $request->query('ayanamsa', 1));
        $charts = collect($this->chartOptions())->map(function (array $chartOption) use ($payload, $language) {
            $chart = $this->safeAstrologyRequest('horo_chart_image/' . $chartOption['id'], array_merge($payload, [
                'chartType' => 'north',
                'image_type' => 'svg',
            ]), $language);

            return [
                'status' => $chart['status'],
                'chart_id' => $chartOption['id'],
                'label' => $chartOption['label'],
                'chart_svg' => $chart['data']['svg'] ?? null,
                'message' => $chart['message'] ?? null,
            ];
        })->values()->all();

        $providerPayload = [
            'birth_details' => $this->safeAstrologyRequest('birth_details', $payload, $language),
            'astro_details' => $this->safeAstrologyRequest('astro_details', $payload, $language),
            'planets' => $this->safeAstrologyRequest('planets', $payload, $language),
            'manglik' => $this->safeAstrologyRequest('manglik', $payload, $language),
            'pitra_dosha_report' => $this->safeAstrologyRequest('pitra_dosha_report', $payload, $language),
            'kalsarpa_details' => $this->safeAstrologyRequest('kalsarpa_details', $payload, $language),
            'current_vdasha_all' => $this->safeAstrologyRequest('current_vdasha_all', $payload, $language),
            'daily_nakshatra_prediction' => $this->safeAstrologyRequest('daily_nakshatra_prediction', $payload, $language),
            'basic_gem_suggestion' => $this->safeAstrologyRequest('basic_gem_suggestion', $payload, $language),
            'rudraksha_suggestion' => $this->safeAstrologyRequest('rudraksha_suggestion', $payload, $language),
            'puja_suggestion' => $this->safeAstrologyRequest('puja_suggestion', $payload, $language),
            'kp_planets' => $this->safeAstrologyRequest('kp_planets', $payload, $language),
            'kp_house_cusps' => $this->safeAstrologyRequest('kp_house_cusps', $payload, $language),
            'kp_birth_chart' => $this->safeAstrologyRequest('kp_birth_chart', $payload, $language),
            'kp_house_significator' => $this->safeAstrologyRequest('kp_house_significator', $payload, $language),
            'kp_planet_significator' => $this->safeAstrologyRequest('kp_planet_significator', $payload, $language),
            'current_yogini_dasha' => $this->safeAstrologyRequest('current_yogini_dasha', $payload, $language),
            'major_yogini_dasha' => $this->safeAstrologyRequest('major_yogini_dasha', $payload, $language),
            'sub_yogini_dasha' => $this->safeAstrologyRequest('sub_yogini_dasha', $payload, $language),
        ];

        return response()->json([
            'status' => 'success',
            'data' => [
                'booking_id' => $booking->id,
                'birth_details' => $birthDetails,
                'requested_datetime' => $datetime,
                'planets' => $providerPayload['planets']['data'] ?? [],
                'astro_details' => $providerPayload['astro_details']['data'] ?? [],
                'charts' => $charts,
                'doshas' => [
                    'mangal' => $providerPayload['manglik']['data'] ?? null,
                    'pitra' => $providerPayload['pitra_dosha_report']['data'] ?? null,
                    'kaal_sarp' => $providerPayload['kalsarpa_details']['data'] ?? null,
                ],
                'dasha' => $providerPayload['current_vdasha_all']['data'] ?? null,
                'predictions' => $providerPayload['daily_nakshatra_prediction']['data'] ?? null,
                'gemstones' => $providerPayload['basic_gem_suggestion']['data'] ?? null,
                'rudraksha' => $providerPayload['rudraksha_suggestion']['data'] ?? null,
                'puja_suggestions' => $providerPayload['puja_suggestion']['data'] ?? null,
                'kp' => [
                    'planets' => $providerPayload['kp_planets']['data'] ?? null,
                    'house_cusps' => $providerPayload['kp_house_cusps']['data'] ?? null,
                    'birth_chart' => $providerPayload['kp_birth_chart']['data'] ?? null,
                    'house_significator' => $providerPayload['kp_house_significator']['data'] ?? null,
                    'planet_significator' => $providerPayload['kp_planet_significator']['data'] ?? null,
                ],
                'yogini_dasha' => [
                    'current' => $providerPayload['current_yogini_dasha']['data'] ?? null,
                    'major' => $providerPayload['major_yogini_dasha']['data'] ?? null,
                    'sub' => $providerPayload['sub_yogini_dasha']['data'] ?? null,
                ],
                'provider_payload' => collect($providerPayload)->map(fn ($item) => $item['data'] ?? null)->all(),
            ],
        ]);
    }

    private function chartOptions(): array
    {
        return [
            ['id' => 'chalit', 'label' => 'Chalit Chart'],
            ['id' => 'SUN', 'label' => 'Sun Chart'],
            ['id' => 'MOON', 'label' => 'Moon Chart'],
            ['id' => 'D1', 'label' => 'D1 - Birth Chart'],
            ['id' => 'D2', 'label' => 'D2 - Hora Chart'],
            ['id' => 'D3', 'label' => 'D3 - Dreshkan Chart'],
            ['id' => 'D4', 'label' => 'D4 - Chaturthamsha Chart'],
            ['id' => 'D5', 'label' => 'D5 - Panchmansha Chart'],
            ['id' => 'D7', 'label' => 'D7 - Saptamansha Chart'],
            ['id' => 'D8', 'label' => 'D8 - Ashtamansha Chart'],
            ['id' => 'D9', 'label' => 'D9 - Navamansha Chart'],
            ['id' => 'D10', 'label' => 'D10 - Dashamansha Chart'],
            ['id' => 'D12', 'label' => 'D12 - Dwadashamsha Chart'],
            ['id' => 'D16', 'label' => 'D16 - Shodashamsha Chart'],
            ['id' => 'D20', 'label' => 'D20 - Vishamansha Chart'],
            ['id' => 'D24', 'label' => 'D24 - Chaturvimshamsha Chart'],
            ['id' => 'D27', 'label' => 'D27 - Bhamsha Chart'],
            ['id' => 'D30', 'label' => 'D30 - Trishamansha Chart'],
            ['id' => 'D40', 'label' => 'D40 - Khavedamsha Chart'],
            ['id' => 'D45', 'label' => 'D45 - Akshvedansha Chart'],
            ['id' => 'D60', 'label' => 'D60 - Shashtyamsha Chart'],
        ];
    }

    private function authorizeBooking(Request $request, Booking $booking): void
    {
        $user = $request->user();
        abort_unless($user, 401);

        if ($user->role === 'admin') {
            return;
        }

        abort_unless(
            (int) $booking->astrologer_id === (int) $user->id,
            403,
            'Only the assigned astrologer can access this Kundali.'
        );
    }

    private function safeAstrologyRequest(string $path, array $payload, string $language = 'en'): array
    {
        try {
            $response = $this->astrologyApi->json($path, $payload, $language);

            if (!$response->successful()) {
                return [
                    'status' => 'error',
                    'message' => $this->extractAstrologyApiError($response, 'Unable to load this Kundali section.'),
                    'data' => null,
                ];
            }

            return [
                'status' => 'success',
                'data' => $response->json(),
            ];
        } catch (\Throwable $exception) {
            return [
                'status' => 'error',
                'message' => $exception->getMessage(),
                'data' => null,
            ];
        }
    }

    private function buildBirthPayload(string $datetime, string $coordinates, mixed $ayanamsa = null): array
    {
        $date = new \DateTimeImmutable($datetime);
        [$lat, $lon] = $this->splitCoordinates($coordinates);

        $payload = [
            'day' => (int) $date->format('d'),
            'month' => (int) $date->format('m'),
            'year' => (int) $date->format('Y'),
            'hour' => (int) $date->format('H'),
            'min' => (int) $date->format('i'),
            'lat' => $lat,
            'lon' => $lon,
            'tzone' => round($date->getOffset() / 3600, 2),
        ];

        $payload['ayanamsha'] = match ((string) ($ayanamsa ?? '1')) {
            '3', 'kp_old', 'KP_OLD' => 'KP_OLD',
            '5', 'kp_new', 'KP_NEW' => 'KP_NEW',
            default => 'LAHIRI',
        };

        return $payload;
    }

    private function splitCoordinates(string $coordinates): array
    {
        $parts = array_map('trim', explode(',', $coordinates));
        if (count($parts) !== 2 || !is_numeric($parts[0]) || !is_numeric($parts[1])) {
            throw new \InvalidArgumentException('Invalid coordinates format. Expected "latitude,longitude".');
        }

        return [(float) $parts[0], (float) $parts[1]];
    }

    private function buildIsoDatetime(string $date, string $time): string
    {
        $cleanTime = preg_replace('/[^0-9:]/', '', $time) ?: '00:00';
        $parts = explode(':', $cleanTime);
        $hour = str_pad((string) (int) ($parts[0] ?? 0), 2, '0', STR_PAD_LEFT);
        $minute = str_pad((string) (int) ($parts[1] ?? 0), 2, '0', STR_PAD_LEFT);

        return "{$date}T{$hour}:{$minute}:00+05:30";
    }

    private function extractAstrologyApiError(Response $response, string $fallback): string
    {
        $payload = $response->json();
        if (is_array($payload)) {
            foreach (['message', 'msg', 'error'] as $key) {
                if (!empty($payload[$key])) {
                    return is_array($payload[$key]) ? json_encode($payload[$key]) : (string) $payload[$key];
                }
            }
        }

        return $fallback;
    }
}
