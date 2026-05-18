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
            'chart_types' => 'nullable|array',
            'chart_types.*' => 'string',
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

            $chartTypes = $request->input('chart_types');
            if (!is_array($chartTypes) || empty($chartTypes)) {
                $chartTypes = array_column($this->d1ToD16ChartTypes(), 'value');
            }

            $chartType = $request->input('chart_type', $chartTypes[0] ?? 'rasi');
            $chartStyle = $request->input('chart_style', 'north-indian');
            $chartSeries = $this->buildChartSeries(
                $birthPayload,
                $chartTypes,
                $chartStyle,
                in_array($language, ['en', 'hi'], true) ? $language : 'en'
            );
            $primaryChart = collect($chartSeries)->firstWhere('chart_id', $this->mapChartId($chartType));
            $fallbackChart = collect($chartSeries)->firstWhere('status', 'success');
            $chartSvg = $primaryChart['chart_svg'] ?? $fallbackChart['chart_svg'] ?? null;
            $sunPlanet = $this->findPlanetByName($planets, 'Sun');
            $moonPlanet = $this->findPlanetByName($planets, 'Moon');
            $dashaSummary = $this->formatCurrentVdashaSummary($dashaAll);
            $detailedReport = $this->buildDetailedKundliReport($birthPayload, $language, $chartStyle, $chartSeries, [
                'birth_details' => $birthDetails,
                'astro_details' => $astroDetails,
                'planets' => $planets,
                'current_vdasha_all' => $dashaAll,
                'simple_manglik' => $manglik,
            ]);

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
                    'charts' => $chartSeries,
                    'requested_datetime' => $this->normalizeIsoDatetime($request->input('datetime')),
                    'effective_datetime' => $this->normalizeIsoDatetime($request->input('datetime')),
                    'warning' => !empty($warnings) ? implode(' ', $warnings) : null,
                    'chart_meta' => [
                        'chart_type' => $this->mapChartId($chartType),
                        'chart_types' => array_map(fn ($item) => $item['chart_id'], $chartSeries),
                        'chart_style' => $chartStyle,
                    ],
                    'dasha_summary' => $dashaSummary,
                    'detailed_report' => $detailedReport,
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
            $obstructions = $this->safeAstrologyRequest('match_obstructions', $matchPayload, $language);
            $planetDetails = $this->safeAstrologyRequest('match_planet_details', $matchPayload, $language);
            $makingReport = $this->safeAstrologyRequest('match_making_report', $matchPayload, $language);
            $dashakootPoints = $this->safeAstrologyRequest('match_dashakoot_points', $matchPayload, $language);
            $percentage = $this->safeAstrologyRequest('match_percentage', $matchPayload, $language);

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
                    'provider_sections' => [
                        [
                            'id' => 'match-basic',
                            'title' => 'Match Birth and Astro Details',
                            'summary' => 'Birth, astro and planet details returned by Astrology API.',
                            'items' => [
                                'match_birth_details' => ['status' => 'success', 'endpoint' => 'match_birth_details', 'data' => $birth],
                                'match_astro_details' => ['status' => 'success', 'endpoint' => 'match_astro_details', 'data' => $astro],
                                'match_planet_details' => $planetDetails,
                            ],
                        ],
                        [
                            'id' => 'match-scoring',
                            'title' => 'Match Scoring',
                            'summary' => 'Ashtakoot, Dashakoot and match percentage modules.',
                            'items' => [
                                'match_ashtakoot_points' => ['status' => 'success', 'endpoint' => 'match_ashtakoot_points', 'data' => $points],
                                'match_dashakoot_points' => $dashakootPoints,
                                'match_percentage' => $percentage,
                            ],
                        ],
                        [
                            'id' => 'match-reports',
                            'title' => 'Match Reports and Obstructions',
                            'summary' => 'Detailed compatibility reports, obstruction checks and Manglik report.',
                            'items' => [
                                'match_obstructions' => $obstructions,
                                'match_manglik_report' => ['status' => 'success', 'endpoint' => 'match_manglik_report', 'data' => $manglik],
                                'match_making_report' => $makingReport,
                                'match_making_detailed_report' => ['status' => 'success', 'endpoint' => 'match_making_detailed_report', 'data' => $report],
                            ],
                        ],
                    ],
                ],
                'meta' => [
                    'provider' => 'astrologyapi',
                    'provider_payload' => [
                        'match_birth_details' => $birth,
                        'match_astro_details' => $astro,
                        'match_ashtakoot_points' => $points,
                        'match_obstructions' => $obstructions['data'],
                        'match_planet_details' => $planetDetails['data'],
                        'match_making_detailed_report' => $report,
                        'match_making_report' => $makingReport['data'],
                        'match_manglik_report' => $manglik,
                        'match_dashakoot_points' => $dashakootPoints['data'],
                        'match_percentage' => $percentage['data'],
                    ],
                ],
            ]);
        } catch (\Throwable $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 200);
        }
    }

    public function downloadMatchMakingPdf(Request $request)
    {
        $request->validate([
            'boy_name' => 'required|string|max:255',
            'boy_coordinates' => 'required|string',
            'boy_dob' => 'required|string',
            'boy_place' => 'nullable|string|max:255',
            'girl_name' => 'required|string|max:255',
            'girl_coordinates' => 'required|string',
            'girl_dob' => 'required|string',
            'girl_place' => 'nullable|string|max:255',
            'la' => 'nullable|string',
        ]);

        try {
            $language = $this->resolveRequestedLanguage($request, ['en', 'hi'], 'en');
            $appUrl = rtrim((string) config('app.url', 'https://astrozura.cloud'), '/');
            $boy = $this->buildPdfPersonPayload('m', (string) $request->input('boy_name'), (string) $request->input('boy_dob'), (string) $request->input('boy_coordinates'), (string) $request->input('boy_place', ''));
            $girl = $this->buildPdfPersonPayload('f', (string) $request->input('girl_name'), (string) $request->input('girl_dob'), (string) $request->input('girl_coordinates'), (string) $request->input('girl_place', ''));

            $pdfPayload = array_merge($boy, $girl, [
                'language' => $language,
                'ashtakoot' => 'true',
                'dashakoot' => 'true',
                'papasamyam' => 'true',
                'chart_style' => 'NORTH_INDIAN',
                'footer_link' => $appUrl,
                'logo_url' => $appUrl . '/favicon.ico',
                'company_name' => 'Astro Zura',
                'company_info' => 'Astro Zura personalized Vedic compatibility report generated for testing.',
                'domain_url' => $appUrl,
                'company_email' => 'support@astrozura.cloud',
                'company_landline' => '+91-0000000000',
                'company_mobile' => '+91-0000000000',
            ]);

            $response = $this->astrologyApi->pdfForm('match_making_pdf', $pdfPayload, $language);
            if (!$response->successful()) {
                return response()->json([
                    'status' => 'error',
                    'message' => $this->extractAstrologyApiError($response, 'Unable to generate match-making PDF.'),
                ], 200);
            }

            $providerPayload = $response->json();
            $pdfUrl = $providerPayload['pdf_url'] ?? null;
            if (!$pdfUrl) {
                return response()->json([
                    'status' => 'error',
                    'message' => $providerPayload['msg'] ?? 'Astrology API did not return a downloadable PDF URL.',
                    'provider_response' => $providerPayload,
                ], 200);
            }

            $pdfFile = Http::timeout(45)->get($pdfUrl);
            if (!$pdfFile->successful()) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'The PDF URL was generated, but Astro Zura could not fetch the PDF file.',
                    'pdf_url' => $pdfUrl,
                ], 200);
            }

            $filename = preg_replace('/[^a-z0-9\-]+/i', '-', strtolower($request->input('boy_name') . '-' . $request->input('girl_name') . '-match-report'));
            $filename = trim((string) $filename, '-') ?: 'astrozura-match-report';

            return response($pdfFile->body(), 200, [
                'Content-Type' => 'application/pdf',
                'Content-Disposition' => 'attachment; filename="' . $filename . '.pdf"',
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

            $astrologyGeoResults = $this->searchAstrologyGeoLocations($q);
            if (!empty($astrologyGeoResults)) {
                return response()->json(['status' => 'success', 'data' => $astrologyGeoResults]);
            }

            $openStreetMapResults = $this->searchOpenStreetMapLocations($q, $language);
            if (!empty($openStreetMapResults)) {
                return response()->json(['status' => 'success', 'data' => $openStreetMapResults]);
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
            'ayanamsa' => 'nullable',
            'la' => 'nullable|string',
        ]);

        try {
            $language = $this->resolveRequestedLanguage($request, ['en', 'hi', 'ma', 'bn', 'ta', 'te', 'ml', 'kn'], 'en');
            $birthPayload = $this->buildBirthPayload($request->input('datetime'), $request->input('coordinates'), $request->input('ayanamsa'));

            $providerItems = [
                'basic_panchang_sunrise' => $this->safeAstrologyRequest('basic_panchang/sunrise', $birthPayload, $language),
                'basic_panchang' => $this->safeAstrologyRequest('basic_panchang', $birthPayload, $language),
                'advanced_panchang_sunrise' => $this->safeAstrologyRequest('advanced_panchang/sunrise', $birthPayload, $language),
                'advanced_panchang' => $this->safeAstrologyRequest('advanced_panchang', $birthPayload, $language),
                'planet_panchang_sunrise' => $this->safeAstrologyRequest('planet_panchang/sunris', $birthPayload, $language),
                'planet_panchang' => $this->safeAstrologyRequest('planet_panchang', $birthPayload, $language),
                'chaughadiya_muhurta' => $this->safeAstrologyRequest('chaughadiya_muhurta', $birthPayload, $language),
                'hora_muhurta' => $this->safeAstrologyRequest('hora_muhurta', $birthPayload, $language),
                'hora_muhurta_dinman' => $this->safeAstrologyRequest('hora_muhurta_dinman', $birthPayload, $language),
                'panchang_chart' => $this->safeAstrologyRequest('panchang_chart', $birthPayload, $language),
                'panchang_chart_sunrise' => $this->safeAstrologyRequest('panchang_chart/sunrise', $birthPayload, $language),
                'tamil_month_panchang' => $this->safeAstrologyRequest('tamil_month_panchang', $birthPayload, $language),
                'tamil_panchang' => $this->safeAstrologyRequest('tamil_panchang', $birthPayload, $language),
            ];

            $advanced = $providerItems['advanced_panchang']['data']
                ?? $providerItems['advanced_panchang_sunrise']['data']
                ?? [];
            $basic = $providerItems['basic_panchang']['data']
                ?? $providerItems['basic_panchang_sunrise']['data']
                ?? [];
            $hora = $providerItems['hora_muhurta']['data'] ?? [];
            $chaughadiya = $providerItems['chaughadiya_muhurta']['data'] ?? [];

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
                        'basic' => $basic,
                        'advanced' => $advanced,
                    ],
                    'provider_sections' => [
                        [
                            'id' => 'panchang-core',
                            'title' => 'Basic and Advanced Panchang',
                            'summary' => 'Basic, sunrise-based and advanced Panchang responses.',
                            'items' => [
                                'basic_panchang_sunrise' => $providerItems['basic_panchang_sunrise'],
                                'basic_panchang' => $providerItems['basic_panchang'],
                                'advanced_panchang_sunrise' => $providerItems['advanced_panchang_sunrise'],
                                'advanced_panchang' => $providerItems['advanced_panchang'],
                            ],
                        ],
                        [
                            'id' => 'panchang-planets-chart',
                            'title' => 'Planet Panchang and Charts',
                            'summary' => 'Planet Panchang and Panchang chart modules.',
                            'items' => [
                                'planet_panchang_sunrise' => $providerItems['planet_panchang_sunrise'],
                                'planet_panchang' => $providerItems['planet_panchang'],
                                'panchang_chart' => $providerItems['panchang_chart'],
                                'panchang_chart_sunrise' => $providerItems['panchang_chart_sunrise'],
                            ],
                        ],
                        [
                            'id' => 'panchang-muhurta',
                            'title' => 'Muhurta and Day/Night Timing',
                            'summary' => 'Chaughadiya, Hora and Dinman modules, including day/night period data where returned.',
                            'items' => [
                                'chaughadiya_muhurta' => $providerItems['chaughadiya_muhurta'],
                                'hora_muhurta' => $providerItems['hora_muhurta'],
                                'hora_muhurta_dinman' => $providerItems['hora_muhurta_dinman'],
                            ],
                        ],
                        [
                            'id' => 'panchang-tamil',
                            'title' => 'Tamil Panchang',
                            'summary' => 'Tamil month and daily Panchang responses.',
                            'items' => [
                                'tamil_month_panchang' => $providerItems['tamil_month_panchang'],
                                'tamil_panchang' => $providerItems['tamil_panchang'],
                            ],
                        ],
                    ],
                    'provider_payload' => collect($providerItems)->map(fn ($item) => $item['data'])->all(),
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
            'chart_type' => 'nullable|string',
            'chart_types' => 'nullable|array',
            'chart_types.*' => 'string',
            'chart_style' => 'nullable|string|in:north-indian,south-indian,east-indian',
            'la' => 'nullable|string',
        ]);

        try {
            $language = $this->resolveRequestedLanguage($request, ['en', 'hi'], 'en');
            $payload = $this->buildBirthPayload($request->input('datetime'), $request->input('coordinates'));
            $chartStyle = $request->input('chart_style', 'north-indian');
            $chartTypes = $request->input('chart_types');

            if (is_array($chartTypes) && !empty($chartTypes)) {
                return response()->json([
                    'status' => 'success',
                    'data' => [
                        'charts' => $this->buildChartSeries($payload, $chartTypes, $chartStyle, $language),
                    ],
                ]);
            }

            $chartType = $request->input('chart_type', 'rasi');

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

    public function getKundliDetailSection(Request $request, string $section)
    {
        $request->validate([
            'datetime' => 'required|string',
            'coordinates' => 'required|string',
            'ayanamsa' => 'nullable',
            'chart_style' => 'nullable|string|in:north-indian,south-indian,east-indian',
            'la' => 'nullable|string',
        ]);

        try {
            $language = $this->resolveRequestedLanguage($request, ['en', 'hi', 'ma', 'bn', 'ta', 'te', 'ml', 'kn'], 'en');
            $payload = $this->buildBirthPayload($request->input('datetime'), $request->input('coordinates'), $request->input('ayanamsa'));
            $chartStyle = $request->input('chart_style', 'north-indian');
            $sectionData = $this->buildDetailedKundliSection($section, $payload, $language, $chartStyle);

            return response()->json([
                'status' => 'success',
                'data' => $sectionData,
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
            $chartStyle = (string) $request->input('chart_style', 'north-indian');
            $localizedLanguage = in_array($language, ['en', 'hi'], true) ? $language : 'en';
            $planet = $this->mapPlanetNameFromId((int) $request->input('planet', 0));
            $segment = fn ($value) => rawurlencode(trim((string) $value));
            $optionalRequest = fn (string $key, string $endpoint, bool $enabled) => $enabled
                ? $this->safeAstrologyRequest($endpoint, $payload, $language)
                : [
                    'status' => 'error',
                    'endpoint' => $endpoint,
                    'message' => "Enter {$key} to load this parameterized module.",
                    'data' => null,
                ];
            $varshaphalYear = (int) ($request->input('varshaphal_year') ?: $request->input('year') ?: now('Asia/Kolkata')->format('Y'));
            $varshaphalPayload = array_merge($payload, [
                'year' => $varshaphalYear,
                'varshaphal_year' => $varshaphalYear,
            ]);

            $sections = match ($calculator) {
                'mangal-dosha' => [[
                    'id' => 'mangal-dosha',
                    'title' => 'Mangal Dosha',
                    'summary' => 'Simple and detailed Manglik calculations from Astrology API.',
                    'items' => [
                        'simple_manglik' => $this->safeAstrologyRequest('simple_manglik', $payload, $language),
                        'manglik' => $this->safeAstrologyRequest('manglik', $payload, $language),
                    ],
                ]],
                'kaal-sarp-dosha' => [[
                    'id' => 'kaal-sarp-dosha',
                    'title' => 'Kaal Sarp Dosha',
                    'summary' => 'Kaal Sarp dosha presence, type and interpretation.',
                    'items' => [
                        'kalsarpa_details' => $this->safeAstrologyRequest('kalsarpa_details', $payload, $language),
                    ],
                ]],
                'sade-sati' => [[
                    'id' => 'sade-sati',
                    'title' => 'Sade-Sati',
                    'summary' => 'Current status, life timeline and remedies in one report.',
                    'items' => [
                        'sadhesati_current_status' => $this->safeAstrologyRequest('sadhesati_current_status', $payload, $language),
                        'sadhesati_life_details' => $this->safeAstrologyRequest('sadhesati_life_details', $payload, $language),
                        'sadhesati_remedies' => $this->safeAstrologyRequest('sadhesati_remedies', $payload, $language),
                    ],
                ]],
                'pitra-dosha' => [[
                    'id' => 'pitra-dosha',
                    'title' => 'Pitra Dosha',
                    'summary' => 'Pitra dosha report from the subscribed Vedic API.',
                    'items' => [
                        'pitra_dosha_report' => $this->safeAstrologyRequest('pitra_dosha_report', $payload, $language),
                    ],
                ]],
                'puja-suggestion' => [[
                    'id' => 'puja-suggestion',
                    'title' => 'Puja Suggestion',
                    'summary' => 'Recommended puja and spiritual remedies.',
                    'items' => [
                        'puja_suggestion' => $this->safeAstrologyRequest('puja_suggestion', $payload, $language),
                    ],
                ]],
                'basic-gem-suggestion' => [[
                    'id' => 'basic-gem-suggestion',
                    'title' => 'Gemstone Suggestion',
                    'summary' => 'Basic gemstone recommendations from the horoscope.',
                    'items' => [
                        'basic_gem_suggestion' => $this->safeAstrologyRequest('basic_gem_suggestion', $payload, $language),
                    ],
                ]],
                'rudraksha-suggestion' => [[
                    'id' => 'rudraksha-suggestion',
                    'title' => 'Rudraksha Suggestion',
                    'summary' => 'Rudraksha recommendation based on birth details.',
                    'items' => [
                        'rudraksha_suggestion' => $this->safeAstrologyRequest('rudraksha_suggestion', $payload, $language),
                    ],
                ]],
                'planet-position' => [[
                    'id' => 'planet-position',
                    'title' => 'Planet Position',
                    'summary' => 'Planets, extended planets and D1 chart output.',
                    'items' => [
                        'planets' => $this->safeAstrologyRequest('planets', $payload, $language),
                        'planets_extended' => $this->safeAstrologyRequest('planets/extended', $payload, $language),
                        'd1_chart' => $this->safeAstrologyRequest(
                            'horo_chart_image/D1',
                            array_merge($payload, [
                                'chartType' => $this->mapChartStyle($chartStyle),
                                'image_type' => 'svg',
                            ]),
                            $localizedLanguage
                        ),
                    ],
                ]],
                'birth-details' => [$this->buildDetailedKundliSection('basic-astro-details', $payload, $language, $chartStyle)],
                'daily-nakshatra-predictions' => [[
                    'id' => 'daily-nakshatra-predictions',
                    'title' => 'Daily Nakshatra Predictions',
                    'summary' => 'Previous, current, next and consolidated daily Nakshatra prediction modules.',
                    'items' => [
                        'daily_nakshatra_prediction_previous' => $this->safeAstrologyRequest('daily_nakshatra_prediction/previous', $payload, $language),
                        'daily_nakshatra_prediction' => $this->safeAstrologyRequest('daily_nakshatra_prediction', $payload, $language),
                        'daily_nakshatra_prediction_next' => $this->safeAstrologyRequest('daily_nakshatra_prediction/next', $payload, $language),
                        'daily_nakshatra_consolidated' => $this->safeAstrologyRequest('daily_nakshatra_consolidated', $payload, $language),
                    ],
                ]],
                'dasha-periods', 'vimshottari-dasha' => [[
                    'id' => 'vimshottari-dasha',
                    'title' => 'Vimshottari Dasha',
                    'summary' => 'All core Vimshottari dasha modules plus optional nested dasha endpoints.',
                    'items' => [
                        'current_vdasha_all' => $this->safeAstrologyRequest('current_vdasha_all', $payload, $language),
                        'major_vdasha' => $this->safeAstrologyRequest('major_vdasha', $payload, $language),
                        'current_vdasha' => $this->safeAstrologyRequest('current_vdasha', $payload, $language),
                        'current_vdasha_date' => $this->safeAstrologyRequest('current_vdasha_date', $payload, $language),
                        'sub_vdasha' => $optionalRequest('Mahadasha', 'sub_vdasha/' . $segment($request->input('mahadasha')), filled($request->input('mahadasha'))),
                        'sub_sub_vdasha' => $optionalRequest('Mahadasha and Antardasha', 'sub_sub_vdasha/' . $segment($request->input('mahadasha')) . '/' . $segment($request->input('antardasha')), filled($request->input('mahadasha')) && filled($request->input('antardasha'))),
                        'sub_sub_sub_vdasha' => $optionalRequest('Mahadasha, Antardasha and Pratyantardasha', 'sub_sub_sub_vdasha/' . $segment($request->input('mahadasha')) . '/' . $segment($request->input('antardasha')) . '/' . $segment($request->input('pratyantardasha')), filled($request->input('mahadasha')) && filled($request->input('antardasha')) && filled($request->input('pratyantardasha'))),
                        'sub_sub_sub_sub_vdasha' => $optionalRequest('Mahadasha, Antardasha, Pratyantardasha and Sookshma Dasha', 'sub_sub_sub_sub_vdasha/' . $segment($request->input('mahadasha')) . '/' . $segment($request->input('antardasha')) . '/' . $segment($request->input('pratyantardasha')) . '/' . $segment($request->input('sookshma_dasha')), filled($request->input('mahadasha')) && filled($request->input('antardasha')) && filled($request->input('pratyantardasha')) && filled($request->input('sookshma_dasha'))),
                    ],
                ]],
                'char-dasha' => [[
                    'id' => 'char-dasha',
                    'title' => 'Char Dasha',
                    'summary' => 'Major/current Char Dasha plus optional sub-period modules.',
                    'items' => [
                        'major_chardasha' => $this->safeAstrologyRequest('major_chardasha', $payload, $language),
                        'current_chardasha' => $this->safeAstrologyRequest('current_chardasha', $payload, $language),
                        'sub_chardasha' => $optionalRequest('Mahadasha', 'sub_chardasha/' . $segment($request->input('mahadasha')), filled($request->input('mahadasha'))),
                        'sub_sub_chardasha' => $this->safeAstrologyRequest('sub_sub_chardasha', $payload, $language),
                    ],
                ]],
                'yogini-dasha' => [[
                    'id' => 'yogini-dasha',
                    'title' => 'Yogini Dasha',
                    'summary' => 'Major, current and sub Yogini Dasha modules.',
                    'items' => [
                        'major_yogini_dasha' => $this->safeAstrologyRequest('major_yogini_dasha', $payload, $language),
                        'sub_yogini_dasha' => $this->safeAstrologyRequest('sub_yogini_dasha', $payload, $language),
                        'current_yogini_dasha' => $this->safeAstrologyRequest('current_yogini_dasha', $payload, $language),
                        'sub_yogini_dasha_by_cycle' => $optionalRequest('Dasha cycle and Dasha name', 'sub_yogini_dasha/' . $segment($request->input('dasha_cycle')) . '/' . $segment($request->input('dasha_name')), filled($request->input('dasha_cycle')) && filled($request->input('dasha_name'))),
                    ],
                ]],
                'varshaphal' => [[
                    'id' => 'varshaphal',
                    'title' => 'Varshaphal',
                    'summary' => 'Year chart, month chart, details, planets, muntha, dasha, bala, saham and yoga.',
                    'items' => [
                        'varshaphal_year_chart' => $this->safeAstrologyRequest('varshaphal_year_chart', $varshaphalPayload, $localizedLanguage),
                        'varshaphal_month_chart' => $this->safeAstrologyRequest('varshaphal_month_chart', $varshaphalPayload, $localizedLanguage),
                        'varshaphal_details' => $this->safeAstrologyRequest('varshaphal_details', $varshaphalPayload, $localizedLanguage),
                        'varshaphal_planets' => $this->safeAstrologyRequest('varshaphal_planets', $varshaphalPayload, $localizedLanguage),
                        'varshaphal_muntha' => $this->safeAstrologyRequest('varshaphal_muntha', $varshaphalPayload, $localizedLanguage),
                        'varshaphal_mudda_dasha' => $this->safeAstrologyRequest('varshaphal_mudda_dasha', $varshaphalPayload, $localizedLanguage),
                        'varshaphal_panchavargeeya_bala' => $this->safeAstrologyRequest('varshaphal_panchavargeeya_bala', $varshaphalPayload, $localizedLanguage),
                        'varshaphal_harsha_bala' => $this->safeAstrologyRequest('varshaphal_harsha_bala', $varshaphalPayload, $localizedLanguage),
                        'varshaphal_saham_points' => $this->safeAstrologyRequest('varshaphal_saham_points', $varshaphalPayload, $localizedLanguage),
                        'varshaphal_yoga' => $this->safeAstrologyRequest('varshaphal_yoga', $varshaphalPayload, $localizedLanguage),
                    ],
                ]],
                'kp' => [[
                    'id' => 'kp',
                    'title' => 'Krishnamurti Paddhati',
                    'summary' => 'KP planets, house cusps, birth chart and house significator modules.',
                    'items' => [
                        'kp_planets' => $this->safeAstrologyRequest('kp_planets', $payload, $localizedLanguage),
                        'kp_house_cusps' => $this->safeAstrologyRequest('kp_house_cusps', $payload, $localizedLanguage),
                        'kp_birth_chart' => $this->safeAstrologyRequest('kp_birth_chart', $payload, $localizedLanguage),
                        'kp_house_significator' => $this->safeAstrologyRequest('kp_house_significator', $payload, $localizedLanguage),
                    ],
                ]],
                'planet-relationship' => [[
                    'id' => 'planet-relationship',
                    'title' => 'Planet Relationship',
                    'summary' => 'Panchadha maitri relationship data.',
                    'items' => [
                        'panchada_maitri' => $this->safeAstrologyRequest('panchada_maitri', $payload, $language),
                    ],
                ]],
                'ashtakavarga', 'sarvashtakavarga' => [[
                    'id' => 'ashtakavarga',
                    'title' => 'Ashtakvarga',
                    'summary' => 'Selected planet Ashtakvarga and Sarvashtakavarga together.',
                    'items' => [
                        'planet_ashtak_' . strtolower($planet) => $this->safeAstrologyRequest('planet_ashtak/' . $planet, $payload, $localizedLanguage),
                        'sarvashtak' => $this->safeAstrologyRequest('sarvashtak', $payload, $localizedLanguage),
                    ],
                ]],
                'gowri-nalla-neram' => [[
                    'id' => 'gowri-nalla-neram',
                    'title' => 'Gowri Nalla Neram',
                    'summary' => 'Chaughadiya muhurta windows for the selected date and place.',
                    'items' => [
                        'chaughadiya_muhurta' => $this->safeAstrologyRequest('chaughadiya_muhurta', $payload, $language),
                    ],
                ]],
                'papasamyam', 'yoga', 'gowri-nalla-neram', 'sudarshana-chakra', 'chandrashtama-periods' => throw new \RuntimeException('This calculator does not have a direct Astrology API equivalent in the current integration.'),
                default => throw new \RuntimeException('Unsupported Vedic calculator.'),
            };

            $providerPayload = collect($sections)
                ->flatMap(fn ($section) => $section['items'] ?? [])
                ->all();

            return response()->json([
                'status' => 'success',
                'data' => [
                    'calculator' => $calculator,
                    'provider_sections' => $sections,
                    'provider_payload' => $providerPayload,
                ],
            ]);
        } catch (\Throwable $e) {
            return response()->json(['status' => 'error', 'message' => $e->getMessage()], 200);
        }
    }

    public function getTarotReading(Request $request)
    {
        $request->validate([
            'type' => 'nullable|string|in:general,yes-no',
            'question' => 'nullable|string|max:500',
            'love' => 'nullable|integer|min:1|max:78',
            'career' => 'nullable|integer|min:1|max:78',
            'finance' => 'nullable|integer|min:1|max:78',
            'tarot_id' => 'nullable|integer|min:1|max:22',
            'la' => 'nullable|string',
        ]);

        try {
            $language = $this->resolveRequestedLanguage($request, ['en'], 'en');
            $type = strtolower((string) $request->input('type', 'general'));

            if ($type === 'yes-no') {
                $tarotId = (int) ($request->input('tarot_id') ?: random_int(1, 22));
                $payload = ['tarot_id' => $tarotId];
                $reading = $this->requestOrFail('yes_no_tarot', $payload, $language);

                return response()->json([
                    'status' => 'success',
                    'data' => [
                        'type' => 'yes-no',
                        'question' => $request->input('question'),
                        'cards' => ['tarot_id' => $tarotId],
                        'reading' => $reading,
                        'provider_payload' => $reading,
                    ],
                ]);
            }

            $payload = [
                'love' => (int) ($request->input('love') ?: random_int(1, 78)),
                'career' => (int) ($request->input('career') ?: random_int(1, 78)),
                'finance' => (int) ($request->input('finance') ?: random_int(1, 78)),
            ];
            $reading = $this->requestOrFail('tarot_predictions', $payload, $language);

            return response()->json([
                'status' => 'success',
                'data' => [
                    'type' => 'general',
                    'cards' => $payload,
                    'reading' => $reading,
                    'provider_payload' => $reading,
                ],
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
            $payload = [
                'day' => (int) $date->format('d'),
                'month' => (int) $date->format('m'),
                'year' => (int) $date->format('Y'),
                'name' => $name,
            ];

            $sections = [
                [
                    'id' => 'numerology-core',
                    'title' => 'Numerology Core',
                    'summary' => 'Number table, full numerology report and daily prediction modules.',
                    'items' => [
                        'numero_table' => $this->safeAstrologyRequest('numero_table', $payload, $language),
                        'numero_report' => $this->safeAstrologyRequest('numero_report', $payload, $language),
                        'numero_prediction_daily' => $this->safeAstrologyRequest('numero_prediction/daily', $payload, $language),
                    ],
                ],
                [
                    'id' => 'numerology-guidance',
                    'title' => 'Favourable Guidance',
                    'summary' => 'Favourable time, vastu, fasts, lord and mantra modules.',
                    'items' => [
                        'numero_fav_time' => $this->safeAstrologyRequest('numero_fav_time', $payload, $language),
                        'numero_place_vastu' => $this->safeAstrologyRequest('numero_place_vastu', $payload, $language),
                        'numero_fasts_report' => $this->safeAstrologyRequest('numero_fasts_report', $payload, $language),
                        'numero_fav_lord' => $this->safeAstrologyRequest('numero_fav_lord', $payload, $language),
                        'numero_fav_mantra' => $this->safeAstrologyRequest('numero_fav_mantra', $payload, $language),
                    ],
                ],
            ];

            $providerPayload = collect($sections)
                ->flatMap(fn ($section) => $section['items'] ?? [])
                ->all();

            return response()->json([
                'status' => 'success',
                'data' => [
                    'calculator' => $request->input('calculator'),
                    'system' => $request->input('system'),
                    'full_name' => $name,
                    'birth_date' => $date->toDateString(),
                    'provider_sections' => $sections,
                    'provider_payload' => $providerPayload,
                    'report' => $providerPayload['numero_report']['data'] ?? null,
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
            $payload = $this->buildBirthPayload($request->input('datetime'), $request->input('coordinates'), $request->input('ayanamsa'));
            $planets = ['Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn', 'Rahu', 'Ketu'];
            $sections = [[
                'id' => 'lalkitab',
                'title' => 'Lal Kitab',
                'summary' => 'Horoscope, debts, houses, planets and planet-wise remedies from Astrology API.',
                'items' => array_merge(
                    [
                        'lalkitab_horoscope' => $this->safeAstrologyRequest('lalkitab_horoscope', $payload, $language),
                        'lalkitab_debts' => $this->safeAstrologyRequest('lalkitab_debts', $payload, $language),
                        'lalkitab_houses' => $this->safeAstrologyRequest('lalkitab_houses', $payload, $language),
                        'lalkitab_planets' => $this->safeAstrologyRequest('lalkitab_planets', $payload, $language),
                    ],
                    collect($planets)->mapWithKeys(fn ($planet) => [
                        'lalkitab_remedies_' . strtolower($planet) => $this->safeAstrologyRequest('lalkitab_remedies/' . $planet, $payload, $language),
                    ])->all()
                ),
            ]];

            $providerPayload = collect($sections)
                ->flatMap(fn ($section) => $section['items'] ?? [])
                ->all();

            return response()->json([
                'status' => 'success',
                'data' => [
                    'provider_sections' => $sections,
                    'provider_payload' => $providerPayload,
                    'horoscope' => $providerPayload['lalkitab_horoscope']['data'] ?? null,
                    'debts' => $providerPayload['lalkitab_debts']['data'] ?? null,
                    'houses' => $providerPayload['lalkitab_houses']['data'] ?? null,
                    'planets' => $providerPayload['lalkitab_planets']['data'] ?? null,
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

    private function safeAstrologyRequest(string $path, array $payload, string $language = 'en'): array
    {
        try {
            return [
                'status' => 'success',
                'endpoint' => $path,
                'data' => $this->requestOrFail($path, $payload, $language),
            ];
        } catch (\Throwable $exception) {
            return [
                'status' => 'error',
                'endpoint' => $path,
                'message' => $exception->getMessage(),
                'data' => null,
            ];
        }
    }

    private function buildDetailedKundliReport(array $payload, string $language, string $chartStyle, array $chartSeries, array $preloaded = []): array
    {
        return [
            $this->buildDetailedKundliSection('basic-astro-details', $payload, $language, $chartStyle, $preloaded),
            [
                'id' => 'charts',
                'title' => 'Horoscope Charts',
                'summary' => 'D1-D16 horoscope chart images returned together.',
                'items' => [
                    'divisional_charts' => [
                        'status' => 'success',
                        'endpoint' => 'horo_chart_image/:chartId',
                        'data' => [
                            'chart_style' => $chartStyle,
                            'charts' => $chartSeries,
                        ],
                    ],
                ],
            ],
            $this->buildDetailedKundliSection('ashtakvarga', $payload, $language, $chartStyle, [], false),
            $this->buildDetailedKundliSection('vimshottari-dasha', $payload, $language, $chartStyle, $preloaded),
            $this->buildDetailedKundliSection('char-yogini-dasha', $payload, $language, $chartStyle, [], false),
            $this->buildDetailedKundliSection('life-reports', $payload, $language, $chartStyle, [], false),
            $this->buildDetailedKundliSection('dosha', $payload, $language, $chartStyle, $preloaded),
            $this->buildDetailedKundliSection('suggestions-remedies', $payload, $language, $chartStyle, [], false),
            $this->buildDetailedKundliSection('lalkitab', $payload, $language, $chartStyle, [], false),
            $this->buildDetailedKundliSection('kp', $payload, $language, $chartStyle, [], false),
            $this->buildDetailedKundliSection('biorhythm', $payload, $language, $chartStyle, [], false),
            $this->buildDetailedKundliSection('varshaphal', $payload, $language, $chartStyle, [], false),
        ];
    }

    private function buildDetailedKundliSection(string $section, array $payload, string $language, string $chartStyle = 'north-indian', array $preloaded = [], bool $hydrate = true): array
    {
        $section = strtolower($section);
        $localizedLanguage = in_array($language, ['en', 'hi'], true) ? $language : 'en';
        $planets = ['Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn', 'Rahu', 'Ketu'];
        $currentYear = (int) now('Asia/Kolkata')->format('Y');
        $varshaphalPayload = array_merge($payload, [
            'year' => $currentYear,
            'varshaphal_year' => $currentYear,
        ]);
        $pending = fn (string $endpoint) => [
            'status' => 'pending',
            'endpoint' => $endpoint,
            'message' => 'Open this section to load this module.',
            'data' => null,
        ];
        $request = fn (string $endpoint, ?array $requestPayload = null, ?string $requestLanguage = null) =>
            $hydrate ? $this->safeAstrologyRequest($endpoint, $requestPayload ?? $payload, $requestLanguage ?? $language) : $pending($endpoint);
        $preloadedItem = fn (string $key, string $endpoint) => array_key_exists($key, $preloaded)
            ? ['status' => 'success', 'endpoint' => $endpoint, 'data' => $preloaded[$key]]
            : $request($endpoint);

        return match ($section) {
            'basic-astro-details' => [
                'id' => 'basic-astro-details',
                'title' => 'Basic Astro Details',
                'summary' => 'Birth details, astro details, planets, bhav madhya, ghat chakra, ayanamsha and planet nature.',
                'items' => [
                    'birth_details' => $preloadedItem('birth_details', 'birth_details'),
                    'astro_details' => $preloadedItem('astro_details', 'astro_details'),
                    'planets' => $preloadedItem('planets', 'planets'),
                    'planets_extended' => $request('planets/extended'),
                    'bhav_madhya' => $request('bhav_madhya'),
                    'ghat_chakra' => $request('ghat_chakra'),
                    'ayanamsha' => $request('ayanamsha'),
                    'planet_nature' => $request('planet_nature'),
                ],
            ],
            'ashtakvarga' => [
                'id' => 'ashtakvarga',
                'title' => 'Ashtakvarga',
                'summary' => 'Planet-wise Ashtakvarga and Sarvashtakavarga.',
                'items' => array_merge(
                    collect($planets)->mapWithKeys(fn ($planet) => [
                        'planet_ashtak_' . strtolower($planet) => $request('planet_ashtak/' . $planet, $payload, $localizedLanguage),
                    ])->all(),
                    ['sarvashtak' => $request('sarvashtak', $payload, $localizedLanguage)]
                ),
            ],
            'vimshottari-dasha' => [
                'id' => 'vimshottari-dasha',
                'title' => 'Vimshottari Dasha',
                'summary' => 'Current and major Vimshottari dasha periods.',
                'items' => [
                    'current_vdasha_all' => $preloadedItem('current_vdasha_all', 'current_vdasha_all'),
                    'major_vdasha' => $request('major_vdasha'),
                    'current_vdasha' => $request('current_vdasha'),
                    'current_vdasha_date' => $request('current_vdasha_date'),
                ],
            ],
            'char-yogini-dasha' => [
                'id' => 'char-yogini-dasha',
                'title' => 'Char and Yogini Dasha',
                'summary' => 'Major/current Char Dasha and Yogini Dasha modules.',
                'items' => [
                    'major_chardasha' => $request('major_chardasha'),
                    'current_chardasha' => $request('current_chardasha'),
                    'major_yogini_dasha' => $request('major_yogini_dasha'),
                    'sub_yogini_dasha' => $request('sub_yogini_dasha'),
                    'current_yogini_dasha' => $request('current_yogini_dasha'),
                ],
            ],
            'life-reports' => [
                'id' => 'life-reports',
                'title' => 'Life Reports',
                'summary' => 'Ascendant, nakshatra, house and rashi reports.',
                'items' => array_merge(
                    [
                        'general_ascendant_report' => $request('general_ascendant_report'),
                        'general_nakshatra_report' => $request('general_nakshatra_report'),
                    ],
                    collect($planets)->mapWithKeys(fn ($planet) => [
                        'house_report_' . strtolower($planet) => $request('general_house_report/' . $planet),
                        'rashi_report_' . strtolower($planet) => $request('general_rashi_report/' . $planet),
                    ])->all()
                ),
            ],
            'dosha' => [
                'id' => 'dosha',
                'title' => 'Dosha Analysis',
                'summary' => 'Manglik, Kalsarpa, Sadesati and Pitra Dosha modules.',
                'items' => [
                    'simple_manglik' => $preloadedItem('simple_manglik', 'simple_manglik'),
                    'manglik' => $request('manglik'),
                    'kalsarpa_details' => $request('kalsarpa_details'),
                    'sadhesati_current_status' => $request('sadhesati_current_status'),
                    'sadhesati_life_details' => $request('sadhesati_life_details'),
                    'pitra_dosha_report' => $request('pitra_dosha_report'),
                ],
            ],
            'suggestions-remedies' => [
                'id' => 'suggestions-remedies',
                'title' => 'Suggestions and Remedies',
                'summary' => 'Puja, gemstone, rudraksha and Sadesati remedies.',
                'items' => [
                    'puja_suggestion' => $request('puja_suggestion'),
                    'basic_gem_suggestion' => $request('basic_gem_suggestion'),
                    'rudraksha_suggestion' => $request('rudraksha_suggestion'),
                    'sadhesati_remedies' => $request('sadhesati_remedies'),
                ],
            ],
            'lalkitab' => [
                'id' => 'lalkitab',
                'title' => 'Lal Kitab',
                'summary' => 'Lal Kitab horoscope, debts, houses, planets and planet remedies.',
                'items' => array_merge(
                    [
                        'lalkitab_horoscope' => $request('lalkitab_horoscope'),
                        'lalkitab_debts' => $request('lalkitab_debts'),
                        'lalkitab_houses' => $request('lalkitab_houses'),
                        'lalkitab_planets' => $request('lalkitab_planets'),
                    ],
                    collect($planets)->mapWithKeys(fn ($planet) => [
                        'lalkitab_remedies_' . strtolower($planet) => $request('lalkitab_remedies/' . $planet),
                    ])->all()
                ),
            ],
            'kp' => [
                'id' => 'kp',
                'title' => 'Krishnamurti Paddhati',
                'summary' => 'KP planets, house cusps, birth chart and significators.',
                'items' => [
                    'kp_planets' => $request('kp_planets', $payload, $localizedLanguage),
                    'kp_house_cusps' => $request('kp_house_cusps', $payload, $localizedLanguage),
                    'kp_birth_chart' => $request('kp_birth_chart', $payload, $localizedLanguage),
                    'kp_house_significator' => $request('kp_house_significator', $payload, $localizedLanguage),
                    'kp_planet_significator' => $request('kp_planet_significator', $payload, $localizedLanguage),
                ],
            ],
            'biorhythm' => [
                'id' => 'biorhythm',
                'title' => 'Biorhythm',
                'summary' => 'Physical/emotional/intellectual and moon biorhythm modules.',
                'items' => [
                    'biorhythm' => $request('biorhythm', $payload, $localizedLanguage),
                    'moon_biorhythm' => $request('moon_biorhythm', $payload, $localizedLanguage),
                ],
            ],
            'varshaphal' => [
                'id' => 'varshaphal',
                'title' => 'Varshaphal',
                'summary' => 'Annual chart, planets, muntha, mudda dasha, bala, saham and yoga modules for the current year.',
                'items' => [
                    'varshaphal_year_chart' => $request('varshaphal_year_chart', $varshaphalPayload, $localizedLanguage),
                    'varshaphal_month_chart' => $request('varshaphal_month_chart', $varshaphalPayload, $localizedLanguage),
                    'varshaphal_details' => $request('varshaphal_details', $varshaphalPayload, $localizedLanguage),
                    'varshaphal_planets' => $request('varshaphal_planets', $varshaphalPayload, $localizedLanguage),
                    'varshaphal_muntha' => $request('varshaphal_muntha', $varshaphalPayload, $localizedLanguage),
                    'varshaphal_mudda_dasha' => $request('varshaphal_mudda_dasha', $varshaphalPayload, $localizedLanguage),
                    'varshaphal_panchavargeeya_bala' => $request('varshaphal_panchavargeeya_bala', $varshaphalPayload, $localizedLanguage),
                    'varshaphal_harsha_bala' => $request('varshaphal_harsha_bala', $varshaphalPayload, $localizedLanguage),
                    'varshaphal_saham_points' => $request('varshaphal_saham_points', $varshaphalPayload, $localizedLanguage),
                    'varshaphal_yoga' => $request('varshaphal_yoga', $varshaphalPayload, $localizedLanguage),
                ],
            ],
            default => throw new \InvalidArgumentException('Unknown Kundli detail section.'),
        };
    }

    private function legacyBuildDetailedKundliReport(array $payload, string $language, string $chartStyle, array $chartSeries): array
    {
        $localizedLanguage = in_array($language, ['en', 'hi'], true) ? $language : 'en';
        $planets = ['Sun', 'Moon', 'Mars', 'Mercury', 'Jupiter', 'Venus', 'Saturn', 'Rahu', 'Ketu'];
        $currentYear = (int) now('Asia/Kolkata')->format('Y');
        $varshaphalPayload = array_merge($payload, [
            'year' => $currentYear,
            'varshaphal_year' => $currentYear,
        ]);

        return [
            [
                'id' => 'basic-astro-details',
                'title' => 'Basic Astro Details',
                'summary' => 'Birth details, astro details, planets, bhav madhya, ghat chakra, ayanamsha and planet nature.',
                'items' => [
                    'birth_details' => $this->safeAstrologyRequest('birth_details', $payload, $language),
                    'astro_details' => $this->safeAstrologyRequest('astro_details', $payload, $language),
                    'planets' => $this->safeAstrologyRequest('planets', $payload, $language),
                    'planets_extended' => $this->safeAstrologyRequest('planets/extended', $payload, $language),
                    'bhav_madhya' => $this->safeAstrologyRequest('bhav_madhya', $payload, $language),
                    'ghat_chakra' => $this->safeAstrologyRequest('ghat_chakra', $payload, $language),
                    'ayanamsha' => $this->safeAstrologyRequest('ayanamsha', $payload, $language),
                    'planet_nature' => $this->safeAstrologyRequest('planet_nature', $payload, $language),
                ],
            ],
            [
                'id' => 'charts',
                'title' => 'Horoscope Charts',
                'summary' => 'D1-D16 horoscope chart images returned together.',
                'items' => [
                    'divisional_charts' => [
                        'status' => 'success',
                        'endpoint' => 'horo_chart_image/:chartId',
                        'data' => [
                            'chart_style' => $chartStyle,
                            'charts' => $chartSeries,
                        ],
                    ],
                ],
            ],
            [
                'id' => 'ashtakvarga',
                'title' => 'Ashtakvarga',
                'summary' => 'Planet-wise Ashtakvarga and Sarvashtakavarga.',
                'items' => array_merge(
                    collect($planets)->mapWithKeys(fn ($planet) => [
                        'planet_ashtak_' . strtolower($planet) => $this->safeAstrologyRequest('planet_ashtak/' . $planet, $payload, $localizedLanguage),
                    ])->all(),
                    [
                        'sarvashtak' => $this->safeAstrologyRequest('sarvashtak', $payload, $localizedLanguage),
                    ]
                ),
            ],
            [
                'id' => 'vimshottari-dasha',
                'title' => 'Vimshottari Dasha',
                'summary' => 'Current and major Vimshottari dasha periods.',
                'items' => [
                    'current_vdasha_all' => $this->safeAstrologyRequest('current_vdasha_all', $payload, $language),
                    'major_vdasha' => $this->safeAstrologyRequest('major_vdasha', $payload, $language),
                    'current_vdasha' => $this->safeAstrologyRequest('current_vdasha', $payload, $language),
                    'current_vdasha_date' => $this->safeAstrologyRequest('current_vdasha_date', $payload, $language),
                ],
            ],
            [
                'id' => 'char-yogini-dasha',
                'title' => 'Char and Yogini Dasha',
                'summary' => 'Major/current Char Dasha and Yogini Dasha modules.',
                'items' => [
                    'major_chardasha' => $this->safeAstrologyRequest('major_chardasha', $payload, $language),
                    'current_chardasha' => $this->safeAstrologyRequest('current_chardasha', $payload, $language),
                    'major_yogini_dasha' => $this->safeAstrologyRequest('major_yogini_dasha', $payload, $language),
                    'sub_yogini_dasha' => $this->safeAstrologyRequest('sub_yogini_dasha', $payload, $language),
                    'current_yogini_dasha' => $this->safeAstrologyRequest('current_yogini_dasha', $payload, $language),
                ],
            ],
            [
                'id' => 'life-reports',
                'title' => 'Life Reports',
                'summary' => 'Ascendant, nakshatra, house and rashi reports.',
                'items' => array_merge(
                    [
                        'general_ascendant_report' => $this->safeAstrologyRequest('general_ascendant_report', $payload, $language),
                        'general_nakshatra_report' => $this->safeAstrologyRequest('general_nakshatra_report', $payload, $language),
                    ],
                    collect($planets)->mapWithKeys(fn ($planet) => [
                        'house_report_' . strtolower($planet) => $this->safeAstrologyRequest('general_house_report/' . $planet, $payload, $language),
                        'rashi_report_' . strtolower($planet) => $this->safeAstrologyRequest('general_rashi_report/' . $planet, $payload, $language),
                    ])->all()
                ),
            ],
            [
                'id' => 'dosha',
                'title' => 'Dosha Analysis',
                'summary' => 'Manglik, Kalsarpa, Sadesati and Pitra Dosha modules.',
                'items' => [
                    'simple_manglik' => $this->safeAstrologyRequest('simple_manglik', $payload, $language),
                    'manglik' => $this->safeAstrologyRequest('manglik', $payload, $language),
                    'kalsarpa_details' => $this->safeAstrologyRequest('kalsarpa_details', $payload, $language),
                    'sadhesati_current_status' => $this->safeAstrologyRequest('sadhesati_current_status', $payload, $language),
                    'sadhesati_life_details' => $this->safeAstrologyRequest('sadhesati_life_details', $payload, $language),
                    'pitra_dosha_report' => $this->safeAstrologyRequest('pitra_dosha_report', $payload, $language),
                ],
            ],
            [
                'id' => 'suggestions-remedies',
                'title' => 'Suggestions and Remedies',
                'summary' => 'Puja, gemstone, rudraksha and Sadesati remedies.',
                'items' => [
                    'puja_suggestion' => $this->safeAstrologyRequest('puja_suggestion', $payload, $language),
                    'basic_gem_suggestion' => $this->safeAstrologyRequest('basic_gem_suggestion', $payload, $language),
                    'rudraksha_suggestion' => $this->safeAstrologyRequest('rudraksha_suggestion', $payload, $language),
                    'sadhesati_remedies' => $this->safeAstrologyRequest('sadhesati_remedies', $payload, $language),
                ],
            ],
            [
                'id' => 'lalkitab',
                'title' => 'Lal Kitab',
                'summary' => 'Lal Kitab horoscope, debts, houses, planets and planet remedies.',
                'items' => array_merge(
                    [
                        'lalkitab_horoscope' => $this->safeAstrologyRequest('lalkitab_horoscope', $payload, $language),
                        'lalkitab_debts' => $this->safeAstrologyRequest('lalkitab_debts', $payload, $language),
                        'lalkitab_houses' => $this->safeAstrologyRequest('lalkitab_houses', $payload, $language),
                        'lalkitab_planets' => $this->safeAstrologyRequest('lalkitab_planets', $payload, $language),
                    ],
                    collect($planets)->mapWithKeys(fn ($planet) => [
                        'lalkitab_remedies_' . strtolower($planet) => $this->safeAstrologyRequest('lalkitab_remedies/' . $planet, $payload, $language),
                    ])->all()
                ),
            ],
            [
                'id' => 'kp',
                'title' => 'Krishnamurti Paddhati',
                'summary' => 'KP planets, house cusps, birth chart and significators.',
                'items' => [
                    'kp_planets' => $this->safeAstrologyRequest('kp_planets', $payload, $localizedLanguage),
                    'kp_house_cusps' => $this->safeAstrologyRequest('kp_house_cusps', $payload, $localizedLanguage),
                    'kp_birth_chart' => $this->safeAstrologyRequest('kp_birth_chart', $payload, $localizedLanguage),
                    'kp_house_significator' => $this->safeAstrologyRequest('kp_house_significator', $payload, $localizedLanguage),
                    'kp_planet_significator' => $this->safeAstrologyRequest('kp_planet_significator', $payload, $localizedLanguage),
                ],
            ],
            [
                'id' => 'biorhythm',
                'title' => 'Biorhythm',
                'summary' => 'Physical/emotional/intellectual and moon biorhythm modules.',
                'items' => [
                    'biorhythm' => $this->safeAstrologyRequest('biorhythm', $payload, $localizedLanguage),
                    'moon_biorhythm' => $this->safeAstrologyRequest('moon_biorhythm', $payload, $localizedLanguage),
                ],
            ],
            [
                'id' => 'varshaphal',
                'title' => 'Varshaphal',
                'summary' => 'Annual chart, planets, muntha, mudda dasha, bala, saham and yoga modules for the current year.',
                'items' => [
                    'varshaphal_year_chart' => $this->safeAstrologyRequest('varshaphal_year_chart', $varshaphalPayload, $localizedLanguage),
                    'varshaphal_month_chart' => $this->safeAstrologyRequest('varshaphal_month_chart', $varshaphalPayload, $localizedLanguage),
                    'varshaphal_details' => $this->safeAstrologyRequest('varshaphal_details', $varshaphalPayload, $localizedLanguage),
                    'varshaphal_planets' => $this->safeAstrologyRequest('varshaphal_planets', $varshaphalPayload, $localizedLanguage),
                    'varshaphal_muntha' => $this->safeAstrologyRequest('varshaphal_muntha', $varshaphalPayload, $localizedLanguage),
                    'varshaphal_mudda_dasha' => $this->safeAstrologyRequest('varshaphal_mudda_dasha', $varshaphalPayload, $localizedLanguage),
                    'varshaphal_panchavargeeya_bala' => $this->safeAstrologyRequest('varshaphal_panchavargeeya_bala', $varshaphalPayload, $localizedLanguage),
                    'varshaphal_harsha_bala' => $this->safeAstrologyRequest('varshaphal_harsha_bala', $varshaphalPayload, $localizedLanguage),
                    'varshaphal_saham_points' => $this->safeAstrologyRequest('varshaphal_saham_points', $varshaphalPayload, $localizedLanguage),
                    'varshaphal_yoga' => $this->safeAstrologyRequest('varshaphal_yoga', $varshaphalPayload, $localizedLanguage),
                ],
            ],
        ];
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
        $date = new \DateTimeImmutable($this->normalizeIsoDatetime($datetime));
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

    private function buildPdfPersonPayload(string $prefix, string $name, string $datetime, string $coordinates, string $place): array
    {
        $birth = $this->buildBirthPayload($datetime, $coordinates);
        $nameParts = preg_split('/\s+/', trim($name)) ?: [];
        $firstName = $nameParts[0] ?? $name;
        $lastName = count($nameParts) > 1 ? implode(' ', array_slice($nameParts, 1)) : '';

        return [
            "{$prefix}_first_name" => $firstName,
            "{$prefix}_last_name" => $lastName,
            "{$prefix}_day" => $birth['day'],
            "{$prefix}_month" => $birth['month'],
            "{$prefix}_year" => $birth['year'],
            "{$prefix}_hour" => $birth['hour'],
            "{$prefix}_minute" => $birth['min'],
            "{$prefix}_min" => $birth['min'],
            "{$prefix}_latitude" => $birth['lat'],
            "{$prefix}_longitude" => $birth['lon'],
            "{$prefix}_lat" => $birth['lat'],
            "{$prefix}_lon" => $birth['lon'],
            "{$prefix}_timezone" => $birth['tzone'],
            "{$prefix}_tzone" => $birth['tzone'],
            "{$prefix}_place" => $place,
        ];
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
            'panchamsa', 'd5' => 'D5',
            'shashtamsa', 'd6' => 'D6',
            'saptamsa', 'd7' => 'D7',
            'ashtamsa', 'd8' => 'D8',
            'navamsa', 'd9' => 'D9',
            'dasamsa', 'd10' => 'D10',
            'rudramsa', 'd11' => 'D11',
            'dwadasamsa', 'd12' => 'D12',
            'trayodashamsa', 'd13' => 'D13',
            'chaturdashamsa', 'd14' => 'D14',
            'panchdashamsa', 'd15' => 'D15',
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

    private function d1ToD16ChartTypes(): array
    {
        return [
            ['value' => 'rasi', 'chart_id' => 'D1', 'label' => 'D1 - Rasi Chart'],
            ['value' => 'hora', 'chart_id' => 'D2', 'label' => 'D2 - Hora Chart'],
            ['value' => 'drekkana', 'chart_id' => 'D3', 'label' => 'D3 - Drekkana Chart'],
            ['value' => 'chaturthamsa', 'chart_id' => 'D4', 'label' => 'D4 - Chaturthamsa Chart'],
            ['value' => 'panchamsa', 'chart_id' => 'D5', 'label' => 'D5 - Panchamsa Chart'],
            ['value' => 'shashtamsa', 'chart_id' => 'D6', 'label' => 'D6 - Shashtamsa Chart'],
            ['value' => 'saptamsa', 'chart_id' => 'D7', 'label' => 'D7 - Saptamsa Chart'],
            ['value' => 'ashtamsa', 'chart_id' => 'D8', 'label' => 'D8 - Ashtamsa Chart'],
            ['value' => 'navamsa', 'chart_id' => 'D9', 'label' => 'D9 - Navamsa Chart'],
            ['value' => 'dasamsa', 'chart_id' => 'D10', 'label' => 'D10 - Dasamsa Chart'],
            ['value' => 'rudramsa', 'chart_id' => 'D11', 'label' => 'D11 - Rudramsa Chart'],
            ['value' => 'dwadasamsa', 'chart_id' => 'D12', 'label' => 'D12 - Dwadasamsa Chart'],
            ['value' => 'trayodashamsa', 'chart_id' => 'D13', 'label' => 'D13 - Trayodashamsa Chart'],
            ['value' => 'chaturdashamsa', 'chart_id' => 'D14', 'label' => 'D14 - Chaturdashamsa Chart'],
            ['value' => 'panchdashamsa', 'chart_id' => 'D15', 'label' => 'D15 - Panchdashamsa Chart'],
            ['value' => 'shodasamsa', 'chart_id' => 'D16', 'label' => 'D16 - Shodasamsa Chart'],
        ];
    }

    private function chartLabelForId(string $chartId): string
    {
        foreach ($this->d1ToD16ChartTypes() as $chart) {
            if ($chart['chart_id'] === $chartId) {
                return $chart['label'];
            }
        }

        return $chartId . ' Chart';
    }

    private function buildChartSeries(array $payload, array $chartTypes, string $chartStyle, string $language): array
    {
        $seen = [];
        $charts = [];

        foreach ($chartTypes as $chartType) {
            $chartId = $this->mapChartId((string) $chartType);

            if (isset($seen[$chartId])) {
                continue;
            }

            $seen[$chartId] = true;

            try {
                $response = $this->requestOrFail(
                    'horo_chart_image/' . $chartId,
                    array_merge($payload, [
                        'chartType' => $this->mapChartStyle($chartStyle),
                        'image_type' => 'svg',
                    ]),
                    $language
                );

                $charts[] = [
                    'status' => 'success',
                    'chart_type' => (string) $chartType,
                    'chart_id' => $chartId,
                    'label' => $this->chartLabelForId($chartId),
                    'chart_svg' => $response['svg'] ?? null,
                    'chart_data' => $response,
                ];
            } catch (\Throwable $exception) {
                $charts[] = [
                    'status' => 'error',
                    'chart_type' => (string) $chartType,
                    'chart_id' => $chartId,
                    'label' => $this->chartLabelForId($chartId),
                    'chart_svg' => null,
                    'message' => $exception->getMessage(),
                ];
            }
        }

        return $charts;
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

        $normalizedQuery = preg_match('/\bindia\b/i', $query) ? $query : "{$query}, India";
        $response = Http::timeout(20)->get('https://maps.googleapis.com/maps/api/geocode/json', [
            'address' => $normalizedQuery,
            'key' => $apiKey,
            'language' => $language,
            'region' => 'in',
            'components' => 'country:IN',
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

    private function searchAstrologyGeoLocations(string $query): array
    {
        $response = $this->astrologyApi->json('geo_details', [
            'place' => $query,
            'maxRows' => 8,
        ], 'en');

        if (!$response->successful()) {
            return [];
        }

        $payload = $response->json();
        $rows = is_array($payload) ? $payload : ($payload['data'] ?? []);

        return collect($rows)
            ->map(function ($row) {
                $latitude = $row['latitude'] ?? $row['lat'] ?? null;
                $longitude = $row['longitude'] ?? $row['lon'] ?? $row['lng'] ?? null;
                $name = $row['full_name'] ?? $row['place_name'] ?? $row['name'] ?? $row['place'] ?? '';

                if (is_array($name)) {
                    $name = implode(', ', array_filter($name));
                }

                return [
                    'name' => trim((string) $name),
                    'coordinates' => [
                        'latitude' => is_numeric($latitude) ? (float) $latitude : null,
                        'longitude' => is_numeric($longitude) ? (float) $longitude : null,
                    ],
                ];
            })
            ->filter(fn ($item) => $item['name'] !== '' && $item['coordinates']['latitude'] !== null && $item['coordinates']['longitude'] !== null)
            ->values()
            ->all();
    }

    private function searchOpenStreetMapLocations(string $query, string $language = 'en'): array
    {
        $response = Http::timeout(15)
            ->withHeaders([
                'User-Agent' => 'AstroZura/1.0 (support@astrozura.cloud)',
                'Accept-Language' => $language,
            ])
            ->get('https://nominatim.openstreetmap.org/search', [
                'q' => preg_match('/\bindia\b/i', $query) ? $query : "{$query}, India",
                'format' => 'jsonv2',
                'addressdetails' => 1,
                'countrycodes' => 'in',
                'limit' => 6,
            ]);

        if (!$response->successful()) {
            return [];
        }

        return collect($response->json())
            ->map(function ($row) {
                return [
                    'name' => $row['display_name'] ?? '',
                    'coordinates' => [
                        'latitude' => isset($row['lat']) ? (float) $row['lat'] : null,
                        'longitude' => isset($row['lon']) ? (float) $row['lon'] : null,
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
        $datetime = trim($datetime);
        $datetime = preg_replace('/T(\d{2}:\d{2}:\d{2}):\d{2}([+-]\d{2}:\d{2}|Z)$/', 'T$1$2', $datetime) ?? $datetime;

        try {
            return (new \DateTimeImmutable($datetime))->format('Y-m-d\TH:i:sP');
        } catch (\Throwable) {
            throw new \InvalidArgumentException('Invalid datetime format. Use ISO 8601, for example 1990-05-12T10:30:00+05:30.');
        }
    }
}
