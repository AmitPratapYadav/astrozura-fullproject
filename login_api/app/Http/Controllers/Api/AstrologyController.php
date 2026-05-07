<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\AstrologyApiService;
use Illuminate\Http\Client\Response;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

class AstrologyController extends Controller
{
    public function __construct(private readonly AstrologyApiService $astrologyApi)
    {
    }

    public function getDailyHoroscope(Request $request, $sign = null)
    {
        try {
            $sign = strtolower((string) ($sign ?: $request->query('sign', '')));
            if ($sign === '') {
                return response()->json(['status' => 'error', 'message' => 'Sign is required.'], 400);
            }

            $day = strtolower((string) $request->query('day', 'today'));
            $path = match ($day) {
                'tomorrow' => "sun_sign_prediction/daily/next/{$sign}",
                'yesterday' => "sun_sign_prediction/daily/previous/{$sign}",
                default => "sun_sign_prediction/daily/{$sign}",
            };

            $language = $this->resolveRequestedLanguage($request, ['en'], 'en');
            $timezone = (float) config('astrologyapi.default_timezone', 5.5);
            $cacheKey = $this->buildHoroscopeCacheKey('daily', [
                'sign' => $sign,
                'day' => $day,
                'language' => $language,
                'timezone' => $timezone,
                'date' => $this->resolveHoroscopeTargetDate($day)->toDateString(),
            ]);

            if ($this->isHoroscopeCacheEnabled()) {
                $cachedPayload = Cache::get($cacheKey);
                if (is_array($cachedPayload)) {
                    return response()->json([
                        'status' => 'success',
                        'data' => $cachedPayload,
                    ]);
                }
            }

            $response = $this->astrologyApi->json($path, [
                'timezone' => $timezone,
            ], $language);

            if (!$response->successful()) {
                return response()->json([
                    'status' => 'error',
                    'message' => $this->extractAstrologyApiError($response, 'Failed to fetch horoscope data from Astrology API.'),
                ], 200);
            }

            $payload = $response->json();
            $prediction = $payload['prediction'] ?? [];
            $responsePayload = [
                'daily_prediction' => [
                    'personal' => $prediction['personal_life'] ?? $payload['prediction'] ?? 'No personal insights available.',
                    'profession' => $prediction['profession'] ?? 'No career insights available.',
                    'health' => $prediction['health'] ?? 'No health insights available.',
                    'emotions' => $prediction['emotions'] ?? $prediction['luck'] ?? 'No emotional insights available.',
                    'travel' => $prediction['travel'] ?? null,
                    'luck' => $prediction['luck'] ?? null,
                ],
                'scores' => [
                    'love' => isset($prediction['emotions_rating']) ? (int) $prediction['emotions_rating'] * 10 : 60,
                    'career' => isset($prediction['profession_rating']) ? (int) $prediction['profession_rating'] * 10 : 60,
                    'health' => isset($prediction['health_rating']) ? (int) $prediction['health_rating'] * 10 : 60,
                ],
                'status_label' => 'Favorable',
                'display_date' => $payload['prediction_date'] ?? now('Asia/Kolkata')->format('d M Y'),
                'sign' => $sign,
                'day' => $day,
                'language' => $language,
                'supported_languages' => ['en'],
                'date' => $payload['prediction_date'] ?? null,
                'provider_payload' => $payload,
            ];

            if ($this->isHoroscopeCacheEnabled()) {
                Cache::put($cacheKey, $responsePayload, $this->dailyHoroscopeCacheExpiry($day));
            }

            return response()->json([
                'status' => 'success',
                'data' => $responsePayload,
            ]);
        } catch (\Throwable $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 200);
        }
    }

    public function getWeeklyHoroscope(Request $request, $sign = null)
    {
        return response()->json([
            'status' => 'error',
            'message' => 'Astrology API does not expose a weekly horoscope endpoint in the current plan. Daily and monthly horoscope routes are available.',
        ], 200);
    }

    public function getMonthlyHoroscope(Request $request, $sign = null)
    {
        try {
            $sign = strtolower((string) ($sign ?: $request->query('sign', '')));
            if ($sign === '') {
                return response()->json(['status' => 'error', 'message' => 'Sign is required.'], 400);
            }

            $language = $this->resolveRequestedLanguage($request, ['en'], 'en');
            $timezone = (float) config('astrologyapi.default_timezone', 5.5);
            $monthKey = now('Asia/Kolkata')->format('Y-m');
            $cacheKey = $this->buildHoroscopeCacheKey('monthly', [
                'sign' => $sign,
                'language' => $language,
                'timezone' => $timezone,
                'month' => $monthKey,
            ]);

            if ($this->isHoroscopeCacheEnabled()) {
                $cachedPayload = Cache::get($cacheKey);
                if (is_array($cachedPayload)) {
                    return response()->json([
                        'status' => 'success',
                        'data' => $cachedPayload,
                    ]);
                }
            }

            $response = $this->astrologyApi->json("horoscope_prediction/monthly/{$sign}", [
                'timezone' => $timezone,
            ], $language);

            if (!$response->successful()) {
                return response()->json([
                    'status' => 'error',
                    'message' => $this->extractAstrologyApiError($response, 'Monthly horoscope unavailable.'),
                ], 200);
            }

            $payload = $response->json();
            $prediction = $payload['prediction'] ?? null;
            $responsePayload = [
                'daily_prediction' => [
                    'personal' => is_array($prediction) ? ($prediction['personal_life'] ?? 'No monthly insights available.') : (string) $prediction,
                    'profession' => is_array($prediction) ? ($prediction['profession'] ?? 'No monthly career insights available.') : null,
                    'health' => is_array($prediction) ? ($prediction['health'] ?? 'No monthly health insights available.') : null,
                    'emotions' => is_array($prediction) ? ($prediction['emotions'] ?? $prediction['luck'] ?? 'No monthly emotional insights available.') : null,
                ],
                'scores' => [
                    'love' => isset($prediction['emotions_rating']) ? (int) $prediction['emotions_rating'] * 10 : 60,
                    'career' => isset($prediction['profession_rating']) ? (int) $prediction['profession_rating'] * 10 : 60,
                    'health' => isset($prediction['health_rating']) ? (int) $prediction['health_rating'] * 10 : 60,
                ],
                'status_label' => 'Favorable',
                'display_date' => now('Asia/Kolkata')->format('F Y'),
                'sign' => $sign,
                'day' => 'monthly',
                'language' => $language,
                'provider_payload' => $payload,
            ];

            if ($this->isHoroscopeCacheEnabled()) {
                Cache::put($cacheKey, $responsePayload, $this->monthlyHoroscopeCacheExpiry());
            }

            return response()->json([
                'status' => 'success',
                'data' => $responsePayload,
            ]);
        } catch (\Throwable $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 200);
        }
    }

    public function generateKundli(Request $request)
    {
        $request->validate([
            'datetime' => 'required|string',
            'coordinates' => 'required|string',
            'ayanamsa' => 'nullable',
            'chart_type' => 'nullable|string',
            'chart_style' => 'nullable|string|in:north-indian,south-indian,east-indian',
            'la' => 'nullable|string',
        ]);

        try {
            $language = $this->resolveRequestedLanguage($request, ['en', 'hi', 'ma', 'bn', 'ta', 'te', 'ml', 'kn'], 'en');
            $birthPayload = $this->buildBirthPayload($request->input('datetime'), $request->input('coordinates'), $request->input('ayanamsa'));
            $warnings = [];

            $birthDetails = $this->requestOrFail('birth_details', $birthPayload, $language);
            $astroDetails = $this->requestOrFail('astro_details', $birthPayload, $language);
            $planets = $this->requestOrFail('planets', $birthPayload, $language);
            $dashaAll = $this->requestOrFail('current_vdasha_all', $birthPayload, $language);
            $manglik = null;
            try {
                $manglik = $this->requestOrFail('simple_manglik', $birthPayload, $language);
            } catch (\Throwable $exception) {
                $warnings[] = 'Manglik analysis is not available on the current Astrology API plan, so the chart was generated without that module.';
            }

            $chartType = $request->input('chart_type', 'rasi');
            $chartStyle = $request->input('chart_style', 'north-indian');
            $chartResponse = $this->requestOrFail(
                'horo_chart_image/' . $this->mapChartId($chartType),
                array_merge($birthPayload, [
                    'chartType' => $this->mapChartStyle($chartStyle),
                    'image_type' => 'svg',
                ]),
                in_array($language, ['en', 'hi'], true) ? $language : 'en'
            );

            $chartSvg = $chartResponse['svg'] ?? null;
            $sunPlanet = $this->findPlanetByName($planets, 'Sun');
            $moonPlanet = $this->findPlanetByName($planets, 'Moon');
            $dashaSummary = $this->formatCurrentVdashaSummary($dashaAll);

            $kundli = [
                'nakshatra_details' => [
                    'nakshatra' => [
                        'name' => $astroDetails['Naksahtra'] ?? null,
                        'pada' => $astroDetails['Charan'] ?? null,
                        'lord' => [
                            'name' => $astroDetails['NaksahtraLord'] ?? null,
                        ],
                    ],
                    'chandra_rasi' => [
                        'name' => $moonPlanet['sign'] ?? ($astroDetails['sign'] ?? null),
                        'lord' => [
                            'name' => $moonPlanet['signLord'] ?? ($astroDetails['SignLord'] ?? null),
                        ],
                    ],
                    'soorya_rasi' => [
                        'name' => $sunPlanet['sign'] ?? null,
                        'lord' => [
                            'name' => $sunPlanet['signLord'] ?? null,
                        ],
                    ],
                    'zodiac' => [
                        'name' => $sunPlanet['sign'] ?? null,
                    ],
                    'additional_info' => [
                        'birth_stone' => null,
                        'ganam' => $astroDetails['Gan'] ?? null,
                        'nadi' => $astroDetails['Nadi'] ?? null,
                        'animal_sign' => $astroDetails['Yoni'] ?? null,
                        'syllables' => $astroDetails['name_alphabet'] ?? null,
                        'best_direction' => null,
                    ],
                ],
                'mangal_dosha' => [
                    'has_dosha' => (bool) ($manglik['is_present'] ?? false),
                    'type' => ($manglik['is_present'] ?? false) ? 'Manglik' : null,
                    'description' => $manglik['msg'] ?? ($manglik === null ? 'Manglik analysis is unavailable on the current Astrology API plan.' : null),
                    'exceptions' => !empty($manglik['is_cancelled']) ? ['Manglik Dosha cancellation conditions are present in the chart.'] : [],
                    'remedies' => [],
                ],
                'yoga_details' => [],
                'dasha_balance' => [
                    'lord' => [
                        'name' => $dashaSummary['current_mahadasha']['name'] ?? null,
                    ],
                    'description' => isset($dashaSummary['current_mahadasha']['start'], $dashaSummary['current_mahadasha']['end'])
                        ? 'Current Maha Dasha from ' . $dashaSummary['current_mahadasha']['start'] . ' to ' . $dashaSummary['current_mahadasha']['end']
                        : 'Dasha balance generated from current Vimshottari Dasha data.',
                ],
            ];

            return response()->json([
                'status' => 'success',
                'data' => [
                    'kundli' => $kundli,
                    'chart' => is_string($chartSvg) ? $chartSvg : null,
                    'requested_datetime' => $this->normalizeIsoDatetime($request->input('datetime')),
                    'effective_datetime' => $this->normalizeIsoDatetime($request->input('datetime')),
                    'warning' => !empty($warnings) ? implode(' ', $warnings) : null,
                    'chart_meta' => [
                        'chart_type' => $chartType,
                        'chart_style' => $chartStyle,
                    ],
                    'dasha_summary' => $dashaSummary,
                    'language' => $language,
                    'supported_languages' => ['en', 'hi', 'ma', 'bn', 'ta', 'te', 'ml', 'kn'],
                    'provider_payload' => [
                        'birth_details' => $birthDetails,
                        'astro_details' => $astroDetails,
                        'planets' => $planets,
                        'current_vdasha_all' => $dashaAll,
                        'simple_manglik' => $manglik,
                    ],
                ],
            ]);
        } catch (\Throwable $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 200);
        }
    }

    public function downloadFreeKundliPdf(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'gender' => 'required|in:Male,Female,Other,male,female,other',
            'date_of_birth' => 'required|date',
            'time_of_birth' => 'required|date_format:H:i',
            'place_of_birth' => 'required|string|max:255',
            'coordinates' => 'required|string',
            'la' => 'nullable|string',
        ]);

        try {
            $language = $this->resolveRequestedLanguage($request, ['en', 'hi', 'bn', 'ma', 'ta', 'te', 'kn', 'ml'], 'en');
            $birthPayload = $this->buildBirthPayload(
                $request->input('date_of_birth') . 'T' . $request->input('time_of_birth') . ':00+05:30',
                $request->input('coordinates')
            );

            $appUrl = rtrim((string) config('app.url', 'http://127.0.0.1:8000'), '/');
            $pdfPayload = [
                'name' => trim((string) $request->input('name')),
                'gender' => strtolower((string) $request->input('gender')),
                'day' => $birthPayload['day'],
                'month' => $birthPayload['month'],
                'year' => $birthPayload['year'],
                'hour' => $birthPayload['hour'],
                'min' => $birthPayload['min'],
                'lat' => $birthPayload['lat'],
                'lon' => $birthPayload['lon'],
                'tzone' => $birthPayload['tzone'],
                'language' => $language,
                'place' => $request->input('place_of_birth'),
                'chart_style' => 'NORTH_INDIAN',
                'footer_link' => $appUrl,
                'logo_url' => $appUrl . '/favicon.ico',
                'company_name' => 'Astro Zura',
                'company_info' => 'Astro Zura personalized Vedic chart preview generated for local testing.',
                'domain_url' => $appUrl,
                'company_email' => 'support@astrozura.cloud',
                'company_landline' => '+91-0000000000',
                'company_mobile' => '+91-0000000000',
            ];

            $response = $this->astrologyApi->pdf('basic_horoscope_pdf', $pdfPayload, $language);
            if (!$response->successful()) {
                return response()->json([
                    'status' => 'error',
                    'message' => $this->extractAstrologyApiError($response, 'Unable to generate kundli PDF.'),
                ], 200);
            }

            $pdfUrl = $response->json('pdf_url');
            if (!$pdfUrl) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Astrology API did not return a downloadable PDF URL.',
                ], 200);
            }

            $pdfFile = Http::timeout(30)->get($pdfUrl);
            if (!$pdfFile->successful()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'The PDF URL was generated, but Astro Zura could not fetch the PDF file.',
                ], 200);
            }

            $filename = preg_replace('/[^a-z0-9\-]+/i', '-', strtolower((string) $request->input('name')));
            $filename = trim($filename, '-') ?: 'astrozura-kundli';

            return response($pdfFile->body(), 200, [
                'Content-Type' => 'application/pdf',
                'Content-Disposition' => 'attachment; filename="' . $filename . '.pdf"',
            ]);
        } catch (\Throwable $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 200);
        }
    }

    public function matchMaking(Request $request)
    {
        $request->validate([
            'girl_coordinates' => 'required|string',
            'girl_dob' => 'required|string',
            'boy_coordinates' => 'required|string',
            'boy_dob' => 'required|string',
            'ayanamsa' => 'nullable',
            'la' => 'nullable|string',
        ]);

        try {
            $language = $this->resolveRequestedLanguage($request, ['en', 'hi', 'ma', 'bn', 'ta', 'te', 'ml', 'kn'], 'en');
            $matchPayload = $this->buildMatchPayload(
                $request->input('boy_dob'),
                $request->input('boy_coordinates'),
                $request->input('girl_dob'),
                $request->input('girl_coordinates'),
                $request->input('ayanamsa')
            );

            $birth = $this->requestOrFail('match_birth_details', $matchPayload, $language);
            $astro = $this->requestOrFail('match_astro_details', $matchPayload, $language);
            $points = $this->requestOrFail('match_ashtakoot_points', $matchPayload, $language);
            $report = $this->requestOrFail('match_making_detailed_report', $matchPayload, $language);
            $manglik = $this->requestOrFail('match_manglik_report', $matchPayload, $language);

            $gunaRows = [];
            foreach (['varna', 'vashya', 'tara', 'yoni', 'maitri', 'gan', 'bhakut', 'nadi'] as $key) {
                $item = $report['ashtakoota'][$key] ?? $points[$key] ?? null;
                if (!$item) {
                    continue;
                }

                $gunaRows[] = [
                    'id' => $key,
                    'name' => ucfirst($key),
                    'girl_koot' => $item['female_koot_attribute'] ?? null,
                    'boy_koot' => $item['male_koot_attribute'] ?? null,
                    'obtained_points' => $item['received_points'] ?? 0,
                    'maximum_points' => $item['total_points'] ?? 0,
                    'description' => $item['description'] ?? null,
                ];
            }

            $receivedPoints = $report['ashtakoota']['total']['received_points'] ?? null;
            $maximumPoints = $report['ashtakoota']['total']['total_points'] ?? 36;
            $messageText = $report['conclusion']['match_report']
                ?? $report['ashtakoota']['conclusion']['report']
                ?? null;

            return response()->json([
                'status' => 'success',
                'data' => [
                    'boy_info' => $this->mapMatchPerson(
                        $astro['male_astro_details'] ?? [],
                        $birth['male_astro_details'] ?? [],
                        'male'
                    ),
                    'girl_info' => $this->mapMatchPerson(
                        $astro['female_astro_details'] ?? [],
                        $birth['female_astro_details'] ?? [],
                        'female'
                    ),
                    'boy_mangal_dosha_details' => [
                        'has_dosha' => ($manglik['male_percentage'] ?? 0) > 0,
                        'dosha_type' => 'Manglik',
                        'description' => 'Manglik influence score: ' . ($manglik['male_percentage'] ?? 0) . '%',
                    ],
                    'girl_mangal_dosha_details' => [
                        'has_dosha' => ($manglik['female_percentage'] ?? 0) > 0,
                        'dosha_type' => 'Manglik',
                        'description' => 'Manglik influence score: ' . ($manglik['female_percentage'] ?? 0) . '%',
                    ],
                    'guna_milan' => [
                        'total_points' => $receivedPoints,
                        'maximum_points' => $maximumPoints,
                        'guna' => $gunaRows,
                    ],
                    'message' => [
                        'type' => $this->resolveCompatibilityType($receivedPoints, $maximumPoints),
                        'description' => $messageText ?: 'Compatibility analysis generated from Astrology API.',
                    ],
                    'exceptions' => array_values(array_filter([
                        (($report['rajju_dosha']['status'] ?? true) === false) ? 'Rajju dosha check returned a negative compatibility signal.' : null,
                        (($report['vedha_dosha']['status'] ?? false) === true) ? 'Vedha dosha is present in this compatibility review.' : null,
                        (($report['manglik']['status'] ?? true) === false) ? 'Manglik analysis reduced the compatibility outcome.' : null,
                    ])),
                ],
                'meta' => [
                    'provider' => 'astrologyapi',
                    'provider_payload' => [
                        'match_birth_details' => $birth,
                        'match_astro_details' => $astro,
                        'match_ashtakoot_points' => $points,
                        'match_making_detailed_report' => $report,
                        'match_manglik_report' => $manglik,
                    ],
                ],
            ]);
        } catch (\Throwable $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 200);
        }
    }

    public function searchLocation(Request $request)
    {
        $q = trim((string) $request->get('q', ''));
        if ($q === '') {
            return response()->json(['status' => 'success', 'data' => []]);
        }

        $language = $this->resolveRequestedLanguage(
            $request,
            ['en', 'hi', 'ta', 'te', 'ml', 'gu', 'bn', 'ma', 'kn'],
            'en',
            'language'
        );

        try {
            $googleResults = $this->searchGoogleLocations($q, $language);
            if (!empty($googleResults)) {
                return response()->json(['status' => 'success', 'data' => $googleResults]);
            }

            return response()->json([
                'status' => 'success',
                'data' => $this->searchFallbackLocations($q),
            ]);
        } catch (\Throwable $e) {
            return response()->json([
                'status' => 'success',
                'data' => $this->searchFallbackLocations($q),
                'message' => $e->getMessage(),
            ]);
        }
    }

    public function getPanchang(Request $request)
    {
        $request->validate([
            'datetime' => 'required|string',
            'coordinates' => 'required|string',
            'la' => 'nullable|string',
        ]);

        try {
            $language = $this->resolveRequestedLanguage($request, ['en', 'hi', 'ma', 'bn', 'ta', 'te', 'ml', 'kn'], 'en');
            $birthPayload = $this->buildBirthPayload($request->input('datetime'), $request->input('coordinates'));

            $advanced = $this->requestOrFail('advanced_panchang', $birthPayload, $language);
            $hora = $this->requestOrFail('hora_muhurta', $birthPayload, $language);
            $chaughadiya = $this->requestOrFail('chaughadiya_muhurta', $birthPayload, $language);

            $reference = Carbon::parse($this->normalizeIsoDatetime($request->input('datetime')));
            $requestedDate = $reference->format('Y-m-d');

            $tithiEntry = $this->buildPanchangEntry($advanced['tithi']['details'] ?? null, $advanced['tithi']['end_time_ms'] ?? null, $reference, 'tithi_name');
            $nakshatraEntry = $this->buildPanchangEntry($advanced['nakshatra']['details'] ?? null, $advanced['nakshatra']['end_time_ms'] ?? null, $reference, 'nak_name');
            $karanaEntry = $this->buildPanchangEntry($advanced['karan']['details'] ?? null, $advanced['karan']['end_time_ms'] ?? null, $reference, 'karan_name');
            $yogaEntry = $this->buildPanchangEntry($advanced['yog']['details'] ?? null, $advanced['yog']['end_time_ms'] ?? null, $reference, 'yog_name');

            $auspicious = [];
            if (!empty($advanced['abhijit_muhurta']['start']) && !empty($advanced['abhijit_muhurta']['end'])) {
                $auspicious[] = $this->buildTimedPeriod('Abhijit Muhurta', $advanced['abhijit_muhurta']['start'], $advanced['abhijit_muhurta']['end'], $requestedDate);
            }

            foreach ($this->mapChaughadiyaPeriods($chaughadiya, $requestedDate, ['Amrit', 'Shubh', 'Labh', 'Char']) as $period) {
                $auspicious[] = $period;
            }

            $inauspicious = array_values(array_filter([
                $this->buildTimedPeriod('Rahu Kaal', $advanced['rahukaal']['start'] ?? null, $advanced['rahukaal']['end'] ?? null, $requestedDate),
                $this->buildTimedPeriod('Gulik Kaal', $advanced['guliKaal']['start'] ?? null, $advanced['guliKaal']['end'] ?? null, $requestedDate),
                $this->buildTimedPeriod('Yamghant Kaal', $advanced['yamghant_kaal']['start'] ?? null, $advanced['yamghant_kaal']['end'] ?? null, $requestedDate),
            ]));

            return response()->json([
                'status' => 'success',
                'data' => [
                    'requested_datetime' => $reference->toIso8601String(),
                    'summary' => [
                        'vaara' => $advanced['day'] ?? null,
                        'sunrise' => $this->combineDateAndTime($requestedDate, $advanced['sunrise'] ?? null),
                        'sunset' => $this->combineDateAndTime($requestedDate, $advanced['sunset'] ?? null),
                        'moonrise' => $this->combineDateAndTime($requestedDate, $advanced['moonrise'] ?? null),
                        'moonset' => $this->combineDateAndTime($requestedDate, $advanced['moonset'] ?? null),
                        'current_tithi' => $tithiEntry,
                        'current_nakshatra' => $nakshatraEntry,
                        'current_karana' => $karanaEntry,
                        'current_yoga' => $yogaEntry,
                    ],
                    'panchang' => [
                        'tithi' => array_values(array_filter([$tithiEntry])),
                        'nakshatra' => array_values(array_filter([$nakshatraEntry])),
                        'karana' => array_values(array_filter([$karanaEntry])),
                        'yoga' => array_values(array_filter([$yogaEntry])),
                        'auspicious_period' => array_values($auspicious),
                        'inauspicious_period' => array_values($inauspicious),
                        'hora' => $hora['hora'] ?? null,
                        'chaughadiya' => $chaughadiya['chaughadiya'] ?? null,
                        'advanced' => $advanced,
                    ],
                ],
            ]);
        } catch (\Throwable $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 200);
        }
    }

    public function getDivisionalCharts(Request $request)
    {
        $request->validate([
            'datetime' => 'required|string',
            'coordinates' => 'required|string',
            'chart_type' => 'required|string',
            'chart_style' => 'nullable|string|in:north-indian,south-indian,east-indian',
            'la' => 'nullable|string',
        ]);

        try {
            $language = $this->resolveRequestedLanguage($request, ['en', 'hi'], 'en');
            $payload = $this->buildBirthPayload($request->input('datetime'), $request->input('coordinates'));
            $chartType = $request->input('chart_type', 'rasi');
            $chartStyle = $request->input('chart_style', 'north-indian');

            $response = $this->requestOrFail(
                'horo_chart_image/' . $this->mapChartId($chartType),
                array_merge($payload, [
                    'chartType' => $this->mapChartStyle($chartStyle),
                    'image_type' => 'svg',
                ]),
                $language
            );

            return response()->json([
                'status' => 'success',
                'data' => [
                    'chart_svg' => $response['svg'] ?? null,
                    'chart_data' => $response,
                ],
            ]);
        } catch (\Throwable $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 200);
        }
    }

    public function getPredictions(Request $request)
    {
        $request->validate([
            'datetime' => 'required|string',
            'coordinates' => 'required|string',
            'type' => 'required|string',
            'la' => 'nullable|string',
        ]);

        try {
            $language = $this->resolveRequestedLanguage($request, ['en', 'hi', 'ma', 'bn', 'ta', 'te', 'ml', 'kn'], 'en');
            $payload = $this->buildBirthPayload($request->input('datetime'), $request->input('coordinates'));
            $nakshatra = $this->requestOrFail('daily_nakshatra_prediction', $payload, $language);
            $type = strtolower((string) $request->input('type'));

            $mapped = [
                'career' => ['title' => 'Profession', 'description' => $nakshatra['profession'] ?? null],
                'love-and-relationship' => ['title' => 'Personal Life', 'description' => $nakshatra['personal_life'] ?? null],
                'health' => ['title' => 'Health', 'description' => $nakshatra['health'] ?? null],
                'finance' => ['title' => 'Luck', 'description' => $nakshatra['luck'] ?? null],
                'education' => ['title' => 'Travel', 'description' => $nakshatra['travel'] ?? null],
            ];

            $selected = $mapped[$type] ?? ['title' => 'Prediction', 'description' => $nakshatra['prediction'] ?? null];

            return response()->json([
                'status' => 'success',
                'data' => [
                    $selected,
                    ['title' => 'Emotions', 'description' => $nakshatra['emotions'] ?? null],
                ],
            ]);
        } catch (\Throwable $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 200);
        }
    }

    public function getVedicCalculator(Request $request, string $calculator)
    {
        try {
            $language = $this->resolveRequestedLanguage($request, ['en', 'hi', 'ma', 'bn', 'ta', 'te', 'ml', 'kn'], 'en');
            $payload = $this->buildBirthPayload($request->input('datetime'), $request->input('coordinates'), $request->input('ayanamsa'));

            $result = match ($calculator) {
                'mangal-dosha' => $this->requestOrFail('simple_manglik', $payload, $language),
                'kaal-sarp-dosha' => $this->requestOrFail('kalsarpa_details', $payload, $language),
                'planet-position' => $this->requestOrFail('planets', $payload, $language),
                'sade-sati' => [
                    'current_status' => $this->requestOrFail('sadhesati_current_status', $payload, $language),
                    'life_details' => $this->requestOrFail('sadhesati_life_details', $payload, $language),
                ],
                'dasha-periods' => $this->requestOrFail('current_vdasha_all', $payload, $language),
                'planet-relationship' => $this->requestOrFail('panchada_maitri', $payload, $language),
                'ashtakavarga' => $this->requestOrFail('planet_ashtak/' . $this->mapPlanetNameFromId((int) $request->input('planet', 0)), $payload, $language),
                'sarvashtakavarga' => $this->requestOrFail('sarvashtak', $payload, $language),
                'gowri-nalla-neram' => $this->requestOrFail('chaughadiya_muhurta', $payload, $language),
                'birth-details' => [
                    'birth_details' => $this->requestOrFail('birth_details', $payload, $language),
                    'astro_details' => $this->requestOrFail('astro_details', $payload, $language),
                ],
                'papasamyam', 'yoga', 'sudarshana-chakra', 'chandrashtama-periods' => throw new \RuntimeException('This calculator does not have a direct Astrology API equivalent in the current integration.'),
                default => throw new \RuntimeException('Unsupported Vedic calculator.'),
            };

            return response()->json([
                'status' => 'success',
                'data' => $result,
            ]);
        } catch (\Throwable $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 200);
        }
    }

    public function getMatchingCalculator(Request $request, string $calculator)
    {
        try {
            $language = $this->resolveRequestedLanguage($request, ['en', 'hi', 'ma', 'bn', 'ta', 'te', 'ml', 'kn'], 'en');

            if (in_array($calculator, ['nakshatra-porutham', 'thirumana-porutham', 'porutham', 'papasamyam-check'], true)) {
                $request->validate([
                    'girl_coordinates' => 'required|string',
                    'girl_dob' => 'required|string',
                    'boy_coordinates' => 'required|string',
                    'boy_dob' => 'required|string',
                ]);

                $payload = $this->buildMatchPayload(
                    $request->input('boy_dob'),
                    $request->input('boy_coordinates'),
                    $request->input('girl_dob'),
                    $request->input('girl_coordinates'),
                    $request->input('ayanamsa')
                );

                $result = match ($calculator) {
                    'papasamyam-check' => $this->requestOrFail('papasamyam_details', $payload, $language),
                    'porutham', 'nakshatra-porutham', 'thirumana-porutham' => $this->requestOrFail('match_making_detailed_report', $payload, $language),
                };

                return response()->json(['status' => 'success', 'data' => $result]);
            }

            return response()->json(['status' => 'error', 'message' => 'Unsupported matching calculator.'], 404);
        } catch (\Throwable $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 200);
        }
    }

    public function getNumerology(Request $request)
    {
        $request->validate([
            'calculator' => 'nullable|string',
            'system' => 'nullable|string',
            'date_of_birth' => 'nullable|date',
            'time_of_birth' => 'nullable|date_format:H:i',
            'first_name' => 'nullable|string|max:255',
            'middle_name' => 'nullable|string|max:255',
            'last_name' => 'nullable|string|max:255',
            'name' => 'nullable|string|max:255',
            'reference_year' => 'nullable|integer|min:1900|max:2100',
        ]);

        try {
            $language = $this->resolveRequestedLanguage($request, ['en'], 'en');
            $dateOfBirth = $request->input('date_of_birth');
            if (!$dateOfBirth) {
                throw new \InvalidArgumentException('Date of birth is required for the current Astrology API numerology integration.');
            }

            $name = trim((string) ($request->input('name')
                ?: collect([
                    $request->input('first_name'),
                    $request->input('middle_name'),
                    $request->input('last_name'),
                ])->filter()->implode(' ')));

            if ($name === '') {
                $name = 'Astro Zura User';
            }

            $date = Carbon::parse($dateOfBirth);
            $result = $this->requestOrFail('numero_report', [
                'day' => (int) $date->format('d'),
                'month' => (int) $date->format('m'),
                'year' => (int) $date->format('Y'),
                'name' => $name,
            ], $language);

            return response()->json([
                'status' => 'success',
                'data' => [
                    'calculator' => $request->input('calculator'),
                    'system' => $request->input('system'),
                    'full_name' => $name,
                    'report' => $result,
                ],
            ]);
        } catch (\Throwable $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 200);
        }
    }

    public function getSadesati(Request $request)
    {
        $request->validate([
            'datetime' => 'required|string',
            'coordinates' => 'required|string',
            'la' => 'nullable|string',
        ]);

        try {
            $language = $this->resolveRequestedLanguage($request, ['en', 'hi', 'ma', 'bn', 'ta', 'te', 'ml', 'kn'], 'en');
            $payload = $this->buildBirthPayload($request->input('datetime'), $request->input('coordinates'));
            $status = $this->requestOrFail('sadhesati_current_status', $payload, $language);
            $details = $this->requestOrFail('sadhesati_life_details', $payload, $language);

            return response()->json([
                'status' => 'success',
                'data' => [
                    'is_sadesati_active' => (bool) ($status['is_sadhesati'] ?? $status['status'] ?? false),
                    'description' => $status['bot_response'] ?? $status['status_text'] ?? 'Sade Sati details generated from Astrology API.',
                    'transits' => collect($details)->map(function ($entry) {
                        return [
                            'phase' => $entry['type'] ?? null,
                            'name' => $entry['type'] ?? null,
                            'start' => $this->parseLooseDate($entry['date'] ?? null),
                            'end' => $this->parseMillis($entry['millisecond'] ?? null),
                            'summary' => $entry['summary'] ?? null,
                        ];
                    })->values()->all(),
                ],
            ]);
        } catch (\Throwable $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 200);
        }
    }

    public function getLalKitab(Request $request)
    {
        $request->validate([
            'datetime' => 'required|string',
            'coordinates' => 'required|string',
            'la' => 'nullable|string',
        ]);

        try {
            $language = $this->resolveRequestedLanguage($request, ['en', 'hi'], 'en');
            $payload = $this->buildBirthPayload($request->input('datetime'), $request->input('coordinates'));

            $horoscope = $this->requestOrFail('lalkitab_horoscope', $payload, $language);
            $planets = $this->requestOrFail('lalkitab_planets', $payload, $language);
            $houses = $this->requestOrFail('lalkitab_houses', $payload, $language);

            $remedies = collect($planets)
                ->map(function ($planet) {
                    $label = trim((string) ($planet['planet'] ?? 'Planet'));
                    $position = trim((string) ($planet['position'] ?? '-'));
                    $nature = trim((string) ($planet['nature'] ?? '-'));
                    $rashi = trim((string) ($planet['rashi'] ?? '-'));
                    return "{$label}: {$nature} influence in {$rashi} ({$position}).";
                })
                ->filter()
                ->values()
                ->all();

            return response()->json([
                'status' => 'success',
                'data' => [
                    'remedies' => $remedies,
                    'horoscope' => $horoscope,
                    'houses' => $houses,
                    'planets' => $planets,
                ],
            ]);
        } catch (\Throwable $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 200);
        }
    }

    private function requestOrFail(string $path, array $payload, string $language = 'en')
    {
        $response = $this->astrologyApi->json($path, $payload, $language);
        if (!$response->successful()) {
            throw new \RuntimeException($this->extractAstrologyApiError($response, "Astrology API request failed for {$path}."));
        }

        return $response->json();
    }

    private function isHoroscopeCacheEnabled(): bool
    {
        return (bool) config('astrologyapi.horoscope_cache.enabled', false);
    }

    private function buildHoroscopeCacheKey(string $scope, array $parts): string
    {
        $prefix = trim((string) config('astrologyapi.horoscope_cache.prefix', 'astrologyapi:horoscope'), ':');
        $normalized = collect($parts)
            ->map(fn ($value, $key) => $key . '=' . strtolower((string) $value))
            ->implode(':');

        return "{$prefix}:{$scope}:{$normalized}";
    }

    private function resolveHoroscopeTargetDate(string $day): Carbon
    {
        $now = now('Asia/Kolkata');

        return match ($day) {
            'tomorrow' => $now->copy()->addDay(),
            'yesterday' => $now->copy()->subDay(),
            default => $now->copy(),
        };
    }

    private function dailyHoroscopeCacheExpiry(string $day): Carbon
    {
        $now = now('Asia/Kolkata');

        return match ($day) {
            'tomorrow' => $now->copy()->addDay()->endOfDay(),
            'yesterday' => $now->copy()->endOfDay(),
            default => $now->copy()->endOfDay(),
        };
    }

    private function monthlyHoroscopeCacheExpiry(): Carbon
    {
        return now('Asia/Kolkata')->endOfMonth()->endOfDay();
    }

    private function buildBirthPayload(string $datetime, string $coordinates, mixed $ayanamsa = null): array
    {
        $date = new \DateTimeImmutable($datetime);
        [$lat, $lon] = $this->splitCoordinates($coordinates);
        $offsetSeconds = $date->getOffset();
        $timezone = round($offsetSeconds / 3600, 2);

        $payload = [
            'day' => (int) $date->format('d'),
            'month' => (int) $date->format('m'),
            'year' => (int) $date->format('Y'),
            'hour' => (int) $date->format('H'),
            'min' => (int) $date->format('i'),
            'lat' => $lat,
            'lon' => $lon,
            'tzone' => $timezone,
        ];

        $ayanamsha = $this->mapAyanamsha($ayanamsa);
        if ($ayanamsha !== null) {
            $payload['ayanamsha'] = $ayanamsha;
        }

        return $payload;
    }

    private function buildMatchPayload(string $maleDatetime, string $maleCoordinates, string $femaleDatetime, string $femaleCoordinates, mixed $ayanamsa = null): array
    {
        $male = $this->buildBirthPayload($maleDatetime, $maleCoordinates, $ayanamsa);
        $female = $this->buildBirthPayload($femaleDatetime, $femaleCoordinates, $ayanamsa);

        $payload = [
            'm_day' => $male['day'],
            'm_month' => $male['month'],
            'm_year' => $male['year'],
            'm_hour' => $male['hour'],
            'm_min' => $male['min'],
            'm_lat' => $male['lat'],
            'm_lon' => $male['lon'],
            'm_tzone' => $male['tzone'],
            'f_day' => $female['day'],
            'f_month' => $female['month'],
            'f_year' => $female['year'],
            'f_hour' => $female['hour'],
            'f_min' => $female['min'],
            'f_lat' => $female['lat'],
            'f_lon' => $female['lon'],
            'f_tzone' => $female['tzone'],
        ];

        $ayanamsha = $this->mapAyanamsha($ayanamsa);
        if ($ayanamsha !== null) {
            $payload['ayanamsha'] = $ayanamsha;
        }

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

    private function mapAyanamsha(mixed $ayanamsa): ?string
    {
        return match ((string) ($ayanamsa ?? '1')) {
            '1', 'lahiri', 'LAHIRI' => 'LAHIRI',
            '3', 'kp_old', 'KP_OLD' => 'KP_OLD',
            '5', 'kp_new', 'KP_NEW' => 'KP_NEW',
            default => 'LAHIRI',
        };
    }

    private function mapChartId(string $chartType): string
    {
        return match (strtolower($chartType)) {
            'rasi', 'lagna', 'd1' => 'D1',
            'hora', 'd2' => 'D2',
            'drekkana', 'd3' => 'D3',
            'chaturthamsa', 'd4' => 'D4',
            'saptamsa', 'd7' => 'D7',
            'navamsa', 'd9' => 'D9',
            'dasamsa', 'd10' => 'D10',
            'dwadasamsa', 'd12' => 'D12',
            'shodasamsa', 'd16' => 'D16',
            'vimsamsa', 'd20' => 'D20',
            'chaturvimsamsa', 'd24' => 'D24',
            'bhamsa', 'd27' => 'D27',
            'trimsamsa', 'd30' => 'D30',
            'khavedamsa', 'd40' => 'D40',
            'akshavedamsa', 'd45' => 'D45',
            'shastiamsa', 'd60' => 'D60',
            default => 'D1',
        };
    }

    private function mapChartStyle(string $chartStyle): string
    {
        return match (strtolower($chartStyle)) {
            'south-indian' => 'south',
            'east-indian' => 'east',
            default => 'north',
        };
    }

    private function findPlanetByName(array $planets, string $name): ?array
    {
        foreach ($planets as $planet) {
            if (strcasecmp((string) ($planet['name'] ?? ''), $name) === 0) {
                return $planet;
            }
        }

        return null;
    }

    private function formatCurrentVdashaSummary(array $payload): array
    {
        $major = collect($payload['major']['dasha_period'] ?? []);
        $minor = collect($payload['minor']['dasha_period'] ?? []);
        $subMinor = collect($payload['sub_minor']['dasha_period'] ?? []);
        $currentMajor = $this->findCurrentLooseDasha($major);
        $currentMinor = $this->findCurrentLooseDasha($minor);
        $currentSubMinor = $this->findCurrentLooseDasha($subMinor);

        return [
            'current_mahadasha' => $currentMajor,
            'current_antardasha' => $currentMinor,
            'current_pratyantardasha' => $currentSubMinor,
            'next_mahadasha' => $major
                ->map(fn ($period) => $this->formatLooseDashaPeriod($period))
                ->filter(fn ($period) => !empty($period['start']) && Carbon::parse($period['start'])->isFuture())
                ->take(4)
                ->values()
                ->all(),
        ];
    }

    private function findCurrentLooseDasha($periods): ?array
    {
        $now = now('Asia/Kolkata');

        foreach ($periods as $period) {
            $formatted = $this->formatLooseDashaPeriod($period);
            if (!$formatted['start'] || !$formatted['end']) {
                continue;
            }

            if ($now->betweenIncluded(Carbon::parse($formatted['start']), Carbon::parse($formatted['end']))) {
                return $formatted;
            }
        }

        return $periods->isNotEmpty() ? $this->formatLooseDashaPeriod($periods->first()) : null;
    }

    private function formatLooseDashaPeriod(array $period): array
    {
        return [
            'name' => $period['planet'] ?? $period['dasha_name'] ?? null,
            'start' => $this->parseLooseDate($period['start'] ?? $period['start_date'] ?? null),
            'end' => $this->parseLooseDate($period['end'] ?? $period['end_date'] ?? null),
        ];
    }

    private function parseLooseDate(?string $value): ?string
    {
        if (!$value) {
            return null;
        }

        $value = trim(preg_replace('/\s+/', ' ', $value));
        foreach (['j-n-Y H:i', 'j-n-Y G:i', 'j-n-Y'] as $format) {
            $parsed = \DateTimeImmutable::createFromFormat($format, $value, new \DateTimeZone('Asia/Kolkata'));
            if ($parsed instanceof \DateTimeImmutable) {
                return $parsed->format('Y-m-d\TH:i:sP');
            }
        }

        try {
            return Carbon::parse($value, 'Asia/Kolkata')->toIso8601String();
        } catch (\Throwable) {
            return null;
        }
    }

    private function parseMillis(mixed $value): ?string
    {
        if ($value === null || $value === '') {
            return null;
        }

        return Carbon::createFromTimestampMs((int) $value, 'Asia/Kolkata')->toIso8601String();
    }

    private function buildPanchangEntry(?array $details, mixed $endTimeMs, Carbon $reference, string $nameKey): ?array
    {
        if (!$details) {
            return null;
        }

        return [
            'name' => $details[$nameKey] ?? null,
            'start' => $reference->copy()->startOfDay()->toIso8601String(),
            'end' => $this->parseMillis($endTimeMs),
            'description' => $details['summary'] ?? $details['meaning'] ?? $details['special'] ?? null,
            'lord' => !empty($details['ruler']) ? ['name' => $details['ruler']] : null,
            'paksha' => $details['special'] ?? null,
        ];
    }

    private function buildTimedPeriod(?string $label, ?string $start, ?string $end, string $date): ?array
    {
        if (!$label || !$start || !$end) {
            return null;
        }

        return [
            'name' => $label,
            'start' => $this->combineDateAndTime($date, $start),
            'end' => $this->combineDateAndTime($date, $end),
        ];
    }

    private function combineDateAndTime(string $date, ?string $time): ?string
    {
        if (!$time) {
            return null;
        }

        $parts = array_map('trim', explode(':', str_replace(' ', '', $time)));
        if (count($parts) < 2) {
            return null;
        }

        $hour = str_pad((string) max(0, min(23, (int) $parts[0])), 2, '0', STR_PAD_LEFT);
        $minute = str_pad((string) max(0, min(59, (int) $parts[1])), 2, '0', STR_PAD_LEFT);
        $second = str_pad((string) max(0, min(59, (int) ($parts[2] ?? 0))), 2, '0', STR_PAD_LEFT);

        return Carbon::parse("{$date} {$hour}:{$minute}:{$second}", 'Asia/Kolkata')->toIso8601String();
    }

    private function mapChaughadiyaPeriods(array $payload, string $date, array $allowed): array
    {
        $periods = [];

        foreach (['day', 'night'] as $segment) {
            foreach (($payload['chaughadiya'][$segment] ?? []) as $entry) {
                if (!in_array($entry['muhurta'] ?? '', $allowed, true)) {
                    continue;
                }

                $times = preg_split('/\s*-\s*/', (string) ($entry['time'] ?? ''));
                if (count($times) !== 2) {
                    continue;
                }

                $periods[] = [
                    'name' => $entry['muhurta'],
                    'start' => $this->combineDateAndTime($date, $times[0]),
                    'end' => $this->combineDateAndTime($date, $times[1]),
                ];
            }
        }

        return $periods;
    }

    private function mapMatchPerson(array $astro, array $birth, string $gender): array
    {
        return [
            'nakshatra' => [
                'name' => $astro['Naksahtra'] ?? null,
                'pada' => $astro['Charan'] ?? null,
                'lord' => [
                    'name' => $astro['NaksahtraLord'] ?? null,
                ],
            ],
            'rasi' => [
                'name' => $astro['sign'] ?? null,
                'lord' => [
                    'name' => $astro['SignLord'] ?? null,
                ],
            ],
            'koot' => [
                'varna' => $astro['Varna'] ?? null,
                'gana' => $astro['Gan'] ?? null,
                'nadi' => $astro['Nadi'] ?? null,
            ],
            'birth' => array_merge($birth, ['gender' => $gender]),
        ];
    }

    private function resolveCompatibilityType(?int $receivedPoints, int $maximumPoints): string
    {
        if ($receivedPoints === null || $maximumPoints <= 0) {
            return 'average';
        }

        $ratio = $receivedPoints / $maximumPoints;

        return match (true) {
            $ratio >= 0.7 => 'good',
            $ratio >= 0.45 => 'average',
            default => 'bad',
        };
    }

    private function mapPlanetNameFromId(int $planetId): string
    {
        return match ($planetId) {
            0 => 'sun',
            1 => 'moon',
            2 => 'mars',
            3 => 'mercury',
            4 => 'jupiter',
            5 => 'venus',
            6 => 'saturn',
            default => 'sun',
        };
    }

    private function extractAstrologyApiError(Response $response, string $fallback): string
    {
        $json = $response->json();

        if (is_array($json)) {
            $candidates = [
                $json['message'] ?? null,
                $json['description'] ?? null,
                $json['error'] ?? null,
            ];

            foreach ($candidates as $candidate) {
                if (is_string($candidate) && trim($candidate) !== '') {
                    return trim($candidate);
                }
            }
        }

        $body = trim((string) $response->body());
        return $body !== '' ? $body : $fallback;
    }

    private function searchGoogleLocations(string $query, string $language = 'en'): array
    {
        $apiKey = env('GOOGLE_MAPS_API_KEY');
        if (!$apiKey) {
            return [];
        }

        $response = Http::timeout(20)->get('https://maps.googleapis.com/maps/api/geocode/json', [
            'address' => $query,
            'key' => $apiKey,
            'language' => $language,
        ]);

        if (!$response->successful()) {
            return [];
        }

        return collect($response->json('results', []))
            ->take(5)
            ->map(function ($result) {
                return [
                    'name' => $result['formatted_address'] ?? '',
                    'coordinates' => [
                        'latitude' => $result['geometry']['location']['lat'] ?? null,
                        'longitude' => $result['geometry']['location']['lng'] ?? null,
                    ],
                ];
            })
            ->filter(fn ($item) => $item['name'] !== '' && $item['coordinates']['latitude'] !== null && $item['coordinates']['longitude'] !== null)
            ->values()
            ->all();
    }

    private function searchFallbackLocations(string $query): array
    {
        $fallbacks = [
            ['name' => 'Gandhinagar, Gujarat, India', 'coordinates' => ['latitude' => 23.21, 'longitude' => 72.63]],
            ['name' => 'Ahmedabad, Gujarat, India', 'coordinates' => ['latitude' => 23.02, 'longitude' => 72.57]],
            ['name' => 'Delhi, India', 'coordinates' => ['latitude' => 28.61, 'longitude' => 77.20]],
            ['name' => 'Mumbai, Maharashtra, India', 'coordinates' => ['latitude' => 19.07, 'longitude' => 72.87]],
            ['name' => 'Bangalore, Karnataka, India', 'coordinates' => ['latitude' => 12.97, 'longitude' => 77.59]],
            ['name' => 'Pune, Maharashtra, India', 'coordinates' => ['latitude' => 18.52, 'longitude' => 73.85]],
            ['name' => 'Surat, Gujarat, India', 'coordinates' => ['latitude' => 21.17, 'longitude' => 72.83]],
            ['name' => 'Hyderabad, Telangana, India', 'coordinates' => ['latitude' => 17.38, 'longitude' => 78.48]],
            ['name' => 'Chennai, Tamil Nadu, India', 'coordinates' => ['latitude' => 13.08, 'longitude' => 80.27]],
            ['name' => 'Kolkata, West Bengal, India', 'coordinates' => ['latitude' => 22.57, 'longitude' => 88.36]],
        ];

        return array_values(array_filter($fallbacks, fn ($city) => stripos($city['name'], $query) !== false));
    }

    private function resolveRequestedLanguage(
        Request $request,
        array $supportedLanguages,
        string $default = 'en',
        string $primaryField = 'la'
    ): string {
        $candidate = strtolower((string) (
            $request->input($primaryField)
            ?? $request->query($primaryField)
            ?? $request->input('language')
            ?? $request->query('language')
            ?? $default
        ));

        return in_array($candidate, $supportedLanguages, true) ? $candidate : $default;
    }

    private function normalizeIsoDatetime(string $datetime): string
    {
        try {
            return (new \DateTimeImmutable($datetime))->format('Y-m-d\TH:i:sP');
        } catch (\Throwable) {
            throw new \InvalidArgumentException('Invalid datetime format. Use ISO 8601, for example 1990-05-12T10:30:00+05:30.');
        }
    }
}
