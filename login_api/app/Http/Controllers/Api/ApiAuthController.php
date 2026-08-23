<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Booking;
use App\Models\Category;
use App\Models\Product;
use App\Models\User;
use App\Services\SmartChatWhatsAppService;
use App\Services\UltronSmsService;
use App\Services\UserNotificationService;
use App\Support\MediaStorage;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Laravel\Socialite\Facades\Socialite;

class ApiAuthController extends Controller
{
    public function redirectToGoogle(Request $request)
    {
        $frontend = $request->query('frontend', 'main');
        $frontendUrl = $this->sanitizeFrontendUrl($request->query('frontend_url'));
        $state = $this->encodeOAuthState([
            'frontend' => $frontend,
            'frontend_url' => $frontendUrl,
        ]);

        return Socialite::driver('google')
            ->stateless()
            ->with(['state' => $state])
            ->redirect();
    }

    public function handleGoogleCallback(Request $request)
    {
        $state = $this->decodeOAuthState((string) $request->query('state', ''));
        $frontend = $state['frontend'] ?? 'main';
        $frontendUrl = $state['frontend_url'] ?? $this->resolveFrontendUrl($frontend);

        if (!$request->filled('code')) {
            return redirect($frontendUrl . '/login?error=google_auth_failed');
        }

        try {
            $googleUser = Socialite::driver('google')->stateless()->user();

            $user = User::where('email', $googleUser->email)->first();

            if (!$user) {
                $user = User::create([
                    'name' => $googleUser->name,
                    'email' => $googleUser->email,
                    'role' => 'user',
                    'is_profile_complete' => false,
                    'provider' => 'google',
                    'provider_id' => $googleUser->id,
                    'provider_token' => $googleUser->token,
                ]);
                $this->notifyNewUser($user);
            } else {
                $user->update([
                    'provider' => 'google',
                    'provider_id' => $googleUser->id,
                    'provider_token' => $googleUser->token,
                ]);
            }

            $token = $user->createToken('api-token')->plainTextToken;
            $isNew = !$user->is_profile_complete ? 'true' : 'false';

            return redirect($frontendUrl . '/oauth/callback?token=' . $token . '&is_new=' . $isNew);
        } catch (\Exception $e) {
            report($e);

            return redirect($frontendUrl . '/login?error=google_auth_failed');
        }
    }

    public function mobileGoogleLogin(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id_token' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        $response = Http::acceptJson()
            ->timeout(10)
            ->get('https://oauth2.googleapis.com/tokeninfo', [
                'id_token' => $request->id_token,
            ]);

        if (!$response->successful()) {
            return response()->json(['success' => false, 'message' => 'Google token could not be verified.'], 401);
        }

        $payload = $response->json();
        $audience = (string) ($payload['aud'] ?? '');
        $email = (string) ($payload['email'] ?? '');
        $googleId = (string) ($payload['sub'] ?? '');

        $allowedAudiences = array_values(array_filter(array_unique(array_merge(
            [
                config('services.google.android_client_id'),
                config('services.google.client_id'),
            ],
            config('services.google.mobile_client_ids', [])
        ))));

        if ($audience === '' || !in_array($audience, $allowedAudiences, true)) {
            return response()->json(['success' => false, 'message' => 'Google token audience is not allowed.'], 401);
        }

        $emailVerified = filter_var($payload['email_verified'] ?? false, FILTER_VALIDATE_BOOLEAN);
        if ($email === '' || !$emailVerified) {
            return response()->json(['success' => false, 'message' => 'Google account email is not verified.'], 401);
        }

        $user = User::where('email', $email)->first();
        $isNewUser = false;

        if (!$user) {
            $user = User::create([
                'name' => (string) ($payload['name'] ?? strtok($email, '@')),
                'email' => $email,
                'role' => 'user',
                'is_profile_complete' => false,
                'provider' => 'google',
                'provider_id' => $googleId,
            ]);
            $isNewUser = true;
            $this->notifyNewUser($user);
        } else {
            $user->update([
                'provider' => 'google',
                'provider_id' => $googleId,
            ]);
            $isNewUser = !$user->is_profile_complete;
        }

        $token = $user->createToken('api-token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Logged in successfully',
            'token' => $token,
            'user' => $user,
            'is_new_user' => $isNewUser,
        ]);
    }

    public function sendOtp(Request $request, UltronSmsService $sms, SmartChatWhatsAppService $whatsapp)
    {
        $validator = Validator::make($request->all(), [
            'identifier' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        $identifier = $request->identifier;
        $isEmail = filter_var($identifier, FILTER_VALIDATE_EMAIL);

        $user = User::firstOrCreate(
            [$isEmail ? 'email' : 'phone' => $identifier],
            ['name' => 'User ' . Str::random(5), 'role' => 'user']
        );
        if ($user->wasRecentlyCreated) {
            $this->notifyNewUser($user);
        }

        $otp = rand(100000, 999999);
        $user->otp = $otp;
        $user->otp_expires_at = now()->addMinutes(10);
        $user->save();

        $smsSent = false;
        $whatsappSent = false;
        if (!$isEmail) {
            $smsSent = $sms->sendOtp($identifier, (string) $otp);
            $whatsappSent = $whatsapp->sendOtp($identifier, (string) $otp);
        }

        if (!$isEmail && !$smsSent && !$whatsappSent && app()->environment('production')) {
            return response()->json([
                'success' => false,
                'message' => 'OTP could not be sent. Please try again shortly.',
            ], 503);
        }

        $payload = [
            'success' => true,
            'message' => $isEmail ? 'OTP generated successfully.' : (($smsSent || $whatsappSent) ? 'OTP sent successfully.' : 'OTP generated successfully. Messaging is not configured in this environment.'),
            'identifier' => $identifier,
        ];

        if (config('app.debug')) {
            $payload['dev_otp'] = $otp;
        }

        return response()->json($payload);
    }

    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'identifier' => 'required|string',
            'otp' => 'required|numeric',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        $identifier = $request->identifier;
        $field = filter_var($identifier, FILTER_VALIDATE_EMAIL) ? 'email' : 'phone';
        $user = User::where($field, $identifier)->first();

        if (!$user || $user->otp != $request->otp || now()->greaterThan($user->otp_expires_at)) {
            return response()->json(['success' => false, 'message' => 'Invalid or expired OTP.'], 401);
        }

        $user->otp = null;
        $user->otp_expires_at = null;
        $user->save();

        $token = $user->createToken('api-token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Logged in successfully',
            'token' => $token,
            'user' => $user,
            'is_new_user' => !$user->is_profile_complete,
        ]);
    }

    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'firstName' => 'required|string|max:255',
            'lastName' => 'nullable|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        $user = User::create([
            'name' => trim($request->firstName . ' ' . $request->lastName),
            'email' => $request->email,
            'password' => bcrypt($request->password),
            'role' => 'user',
            'is_profile_complete' => false,
        ]);
        $this->notifyNewUser($user);

        $token = $user->createToken('api-token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Registered successfully',
            'token' => $token,
            'user' => $user,
            'is_new_user' => true,
        ]);
    }

    public function loginWithPassword(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        if (!Auth::attempt($request->only('email', 'password'))) {
            return response()->json(['success' => false, 'message' => 'Invalid email or password.'], 401);
        }

        $user = User::where('email', $request->email)->firstOrFail();
        $token = $user->createToken('api-token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Logged in successfully',
            'token' => $token,
            'user' => $user,
            'is_new_user' => !$user->is_profile_complete,
        ]);
    }

    public function astrologerLogin(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        if (!Auth::attempt($request->only('email', 'password'))) {
            return response()->json(['success' => false, 'message' => 'Invalid email or password.'], 401);
        }

        $user = User::where('email', $request->email)->firstOrFail();

        if ($user->role !== 'astrologer') {
            Auth::logout();
            return response()->json(['success' => false, 'message' => 'Unauthorized Access. Astrologer account required.'], 403);
        }

        $token = $user->createToken('api-token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Logged in as Astrologer successfully',
            'token' => $token,
            'user' => $user->load('astrologerDetail'),
        ]);
    }

    public function adminLogin(Request $request)
    {
        $this->ensureAdminAccount();

        $validator = Validator::make($request->all(), [
            'email' => 'required|string|email',
            'password' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        if (!Auth::attempt($request->only('email', 'password'))) {
            return response()->json(['success' => false, 'message' => 'Invalid email or password.'], 401);
        }

        $user = User::where('email', $request->email)->firstOrFail();

        if ($user->role !== 'admin') {
            Auth::logout();
            return response()->json(['success' => false, 'message' => 'Unauthorized Access. Admin account required.'], 403);
        }

        $token = $user->createToken('admin-token')->plainTextToken;

        return response()->json([
            'success' => true,
            'message' => 'Logged in as Admin successfully',
            'token' => $token,
            'user' => $user,
        ]);
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json([
            'success' => true,
            'message' => 'Logged out successfully',
        ]);
    }

    public function user(Request $request)
    {
        return response()->json([
            'success' => true,
            'user' => $request->user()->load('astrologerDetail'),
        ]);
    }

    public function getAllUsers(Request $request)
    {
        $this->ensureAdmin($request);
        $users = User::where('role', 'user')->orderBy('created_at', 'desc')->get();

        return response()->json([
            'success' => true,
            'users' => $users,
        ]);
    }

    public function getAdminUser(Request $request, User $user)
    {
        $this->ensureAdmin($request);
        abort_unless($user->role === 'user', 404);

        return response()->json([
            'success' => true,
            'user' => $user->load([
                'orders' => fn ($query) => $query->with('items.product')->latest(),
                'bookings' => fn ($query) => $query->with('astrologer:id,name')->latest(),
                'ritualBookings' => fn ($query) => $query->with('ritual:id,name')->latest(),
            ]),
            'summary' => [
                'orders' => $user->orders()->count(),
                'consultations' => $user->bookings()->count(),
                'rituals' => $user->ritualBookings()->count(),
                'order_spend' => (float) $user->orders()->where('payment_status', 'paid')->sum('total_amount'),
                'consultation_spend' => (float) $user->bookings()->where('payment_status', 'paid')->sum('amount'),
            ],
        ]);
    }

    public function getAdminDashboardStats(Request $request)
    {
        $this->ensureAdmin($request);
        $totalUsers = User::where('role', 'user')->count();
        $totalAstrologers = User::where('role', 'astrologer')->count();
        $totalBookings = Booking::count();
        $revenue = Booking::where('payment_status', 'paid')->sum('amount');

        return response()->json([
            'success' => true,
            'stats' => [
                'total_users' => $totalUsers,
                'total_astrologers' => $totalAstrologers,
                'bookings' => $totalBookings,
                'revenue' => 'Rs ' . number_format((float) $revenue, 2),
            ],
        ]);
    }

    public function getAdminProfile(Request $request)
    {
        $user = $request->user();

        if (!$user || $user->role !== 'admin') {
            return response()->json(['success' => false, 'message' => 'Unauthorized Access. Admin account required.'], 403);
        }

        return response()->json([
            'success' => true,
            'user' => $user,
        ]);
    }

    public function updateAdminProfile(Request $request)
    {
        $user = $request->user();

        if (!$user || $user->role !== 'admin') {
            return response()->json(['success' => false, 'message' => 'Unauthorized Access. Admin account required.'], 403);
        }

        $validator = Validator::make($request->all(), [
            'firstName' => 'required|string|max:255',
            'lastName' => 'nullable|string|max:255',
            'email' => ['required', 'string', 'email', 'max:255', Rule::unique('users', 'email')->ignore($user->id)],
            'phone' => ['nullable', 'string', 'max:20', Rule::unique('users', 'phone')->ignore($user->id)],
            'password' => 'nullable|string|min:6',
            'profile_image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:5120',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        $user->name = trim($request->firstName . ' ' . $request->lastName);
        $user->email = $request->email;
        $user->phone = $request->phone;

        if ($request->filled('password')) {
            $user->password = bcrypt($request->password);
        }

        if ($request->hasFile('profile_image')) {
            $user->profile_image = MediaStorage::store($request->file('profile_image'), 'admin-profiles');
        }

        $user->save();

        return response()->json([
            'success' => true,
            'message' => 'Admin profile updated successfully',
            'user' => $user->fresh(),
        ]);
    }

    public function adminSearch(Request $request)
    {
        $this->ensureAdmin($request);
        $term = trim((string) $request->query('q', ''));

        if ($term === '') {
            return response()->json(['success' => true, 'results' => []]);
        }

        $like = '%' . $term . '%';
        $results = collect();

        $results = $results->merge(
            Booking::query()
                ->where(function ($query) use ($like) {
                    $query->where('booking_reference', 'like', $like)
                        ->orWhere('user_name', 'like', $like)
                        ->orWhere('astrologer_name', 'like', $like);
                })
                ->latest()
                ->limit(5)
                ->get()
                ->map(fn ($booking) => [
                    'type' => 'booking',
                    'title' => $booking->booking_reference ?: 'Booking #' . $booking->id,
                    'subtitle' => $booking->user_name . ' with ' . $booking->astrologer_name,
                    'route' => '/bookings',
                ])
        );

        $results = $results->merge(
            User::query()
                ->where(function ($query) use ($like) {
                    $query->where('name', 'like', $like)->orWhere('email', 'like', $like);
                })
                ->whereIn('role', ['user', 'astrologer'])
                ->latest()
                ->limit(5)
                ->get()
                ->map(fn ($user) => [
                    'type' => $user->role,
                    'title' => $user->name,
                    'subtitle' => $user->email,
                    'route' => $user->role === 'astrologer' ? '/astrologers' : '/users',
                ])
        );

        $results = $results->merge(
            Product::query()
                ->where('name', 'like', $like)
                ->latest()
                ->limit(5)
                ->get()
                ->map(fn ($product) => [
                    'type' => 'product',
                    'title' => $product->name,
                    'subtitle' => 'Product',
                    'route' => '/products',
                ])
        );

        $results = $results->merge(
            Category::query()
                ->where('name', 'like', $like)
                ->latest()
                ->limit(5)
                ->get()
                ->map(fn ($category) => [
                    'type' => 'category',
                    'title' => $category->name,
                    'subtitle' => 'Category',
                    'route' => '/categories',
                ])
        );

        return response()->json([
            'success' => true,
            'results' => $results->take(12)->values(),
        ]);
    }

    public function createAstrologer(Request $request)
    {
        $this->ensureAdmin($request);
        $this->normalizeTranslations($request);
        $request->merge([
            'is_featured' => filter_var($request->input('is_featured', false), FILTER_VALIDATE_BOOLEAN),
            'supports_chat' => filter_var($request->input('supports_chat', true), FILTER_VALIDATE_BOOLEAN),
            'supports_call' => filter_var($request->input('supports_call', true), FILTER_VALIDATE_BOOLEAN),
            'is_online' => filter_var($request->input('is_online', true), FILTER_VALIDATE_BOOLEAN),
            'supports_palm_reading' => filter_var($request->input('supports_palm_reading', false), FILTER_VALIDATE_BOOLEAN),
            'supports_ritual_booking' => filter_var($request->input('supports_ritual_booking', false), FILTER_VALIDATE_BOOLEAN),
        ]);

        $validator = Validator::make($request->all(), [
            'firstName' => 'required|string|max:255',
            'lastName' => 'nullable|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:6',
            'experience_years' => 'required|numeric',
            'languages' => 'nullable|string',
            'specialities' => 'nullable|string',
            'chat_price' => 'required|numeric',
            'call_price' => 'required|numeric',
            'chat_duration_prices' => 'nullable|array',
            'chat_duration_prices.*' => 'nullable|numeric|min:0',
            'call_duration_prices' => 'nullable|array',
            'call_duration_prices.*' => 'nullable|numeric|min:0',
            'supports_chat' => 'nullable|boolean',
            'supports_call' => 'nullable|boolean',
            'is_online' => 'nullable|boolean',
            'supports_palm_reading' => 'nullable|boolean',
            'supports_ritual_booking' => 'nullable|boolean',
            'chat_commission_percentage' => 'nullable|numeric|between:0,100',
            'call_commission_percentage' => 'nullable|numeric|between:0,100',
            'translations' => 'nullable|array',
            'about_bio' => 'nullable|string',
            'profile_image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:2048',
            'is_featured' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        $user = User::create([
            'name' => trim($request->firstName . ' ' . $request->lastName),
            'email' => $request->email,
            'password' => bcrypt($request->password),
            'role' => 'astrologer',
            'is_profile_complete' => true,
        ]);

        $profileImagePath = null;
        if ($request->hasFile('profile_image')) {
            $profileImagePath = MediaStorage::store($request->file('profile_image'), 'astrologers');
            $user->update(['profile_image' => $profileImagePath]);
        }

        $user->astrologerDetail()->create([
            'experience_years' => $request->experience_years,
            'languages' => $request->languages,
            'specialities' => $request->specialities,
            'chat_price' => $request->chat_price,
            'call_price' => $request->call_price,
            'chat_duration_prices' => $request->input('chat_duration_prices'),
            'call_duration_prices' => $request->input('call_duration_prices'),
            'supports_chat' => $request->boolean('supports_chat', true),
            'supports_call' => $request->boolean('supports_call', true),
            'is_online' => $request->boolean('is_online', true),
            'supports_palm_reading' => $request->boolean('supports_palm_reading'),
            'supports_ritual_booking' => $request->boolean('supports_ritual_booking'),
            'chat_commission_percentage' => $request->input('chat_commission_percentage', 20),
            'call_commission_percentage' => $request->input('call_commission_percentage', 20),
            'translations' => $request->input('translations'),
            'about_bio' => $request->about_bio,
            'profile_image' => $profileImagePath,
            'is_featured' => $request->boolean('is_featured'),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Astrologer created successfully',
            'user' => $user->load('astrologerDetail'),
        ]);
    }

    public function getAstrologers(Request $request)
    {
        $term = trim((string) $request->query('q', ''));
        $type = $request->query('type');
        $specialty = $request->query('specialty');

        $astrologers = User::with('astrologerDetail')
            ->where('role', 'astrologer')
            ->when($type === 'chat', fn ($query) => $query->whereHas('astrologerDetail', fn ($detail) => $detail->where('supports_chat', true)))
            ->when($type === 'call', fn ($query) => $query->whereHas('astrologerDetail', fn ($detail) => $detail->where('supports_call', true)))
            ->when($specialty === 'palm-reading', fn ($query) => $query->whereHas('astrologerDetail', fn ($detail) => $detail->where('supports_palm_reading', true)))
            ->when($term !== '', function ($query) use ($term) {
                $query->where(function ($builder) use ($term) {
                    $builder->where('name', 'like', '%' . $term . '%')
                        ->orWhereHas('astrologerDetail', function ($detailQuery) use ($term) {
                            $detailQuery->where('languages', 'like', '%' . $term . '%')
                                ->orWhere('specialities', 'like', '%' . $term . '%')
                                ->orWhere('about_bio', 'like', '%' . $term . '%');
                        });
                });
            })
            ->get()
            ->sortByDesc(fn ($astrologer) => (int) ($astrologer->astrologerDetail->is_featured ?? false) * 100 + (float) ($astrologer->astrologerDetail->rating ?? 0))
            ->values();

        $this->appendAvailabilityStatuses($astrologers);
        $this->localizeAstrologers($astrologers, $request->query('la'));

        return response()->json([
            'success' => true,
            'astrologers' => $astrologers,
        ]);
    }

    public function getAstrologerProfile(Request $request, $id)
    {
        $hasPinnedReviews = Schema::hasColumn('astrologer_reviews', 'is_pinned')
            && Schema::hasColumn('astrologer_reviews', 'pinned_at');

        $astrologer = User::with([
                'astrologerDetail',
                'receivedReviews' => function ($query) use ($hasPinnedReviews) {
                    if ($hasPinnedReviews) {
                        $query
                            ->orderByDesc('is_pinned')
                            ->orderByDesc('pinned_at');
                    }

                    $query->latest()
                        ->with('user:id,name,profile_image');
                },
            ])
            ->where('role', 'astrologer')
            ->where('id', $id)
            ->first();

        if (!$astrologer) {
            return response()->json(['success' => false, 'message' => 'Astrologer not found'], 404);
        }

        $this->appendAvailabilityStatuses(collect([$astrologer]));
        $this->localizeAstrologers(collect([$astrologer]), $request->query('la'));

        return response()->json([
            'success' => true,
            'astrologer' => $astrologer,
        ]);
    }

    public function getAdminAstrologer(Request $request, int $id)
    {
        $this->ensureAdmin($request);
        $astrologer = User::with('astrologerDetail')
            ->where('role', 'astrologer')
            ->find($id);

        if (!$astrologer) {
            return response()->json(['success' => false, 'message' => 'Astrologer not found'], 404);
        }

        return response()->json([
            'success' => true,
            'astrologer' => $astrologer,
        ]);
    }

    private function appendAvailabilityStatuses($astrologers): void
    {
        $ids = $astrologers->pluck('id')->filter()->values();
        if ($ids->isEmpty()) {
            return;
        }

        $now = Carbon::now('UTC');
        $activeBookings = Booking::query()
            ->whereIn('astrologer_id', $ids)
            ->whereIn('status', ['confirmed', 'in_progress'])
            ->where('payment_status', 'paid')
            ->where('scheduled_at', '<=', $now)
            ->where('ends_at', '>=', $now)
            ->orderByRaw("CASE WHEN status = 'in_progress' THEN 0 ELSE 1 END")
            ->get()
            ->groupBy('astrologer_id');

        $astrologers->each(function (User $astrologer) use ($activeBookings): void {
            $booking = $activeBookings->get($astrologer->id)?->first();
            $status = !$astrologer->astrologerDetail?->is_online
                ? 'unavailable'
                : match ($booking?->consultation_type) {
                    'call' => 'on_call',
                    'chat' => 'on_chat',
                    default => 'available',
                };

            $astrologer->setAttribute('availability_status', $status);
        });
    }

    public function updateAdminAstrologer(Request $request, int $id)
    {
        $this->ensureAdmin($request);
        $this->normalizeTranslations($request);
        $user = User::with('astrologerDetail')
            ->where('role', 'astrologer')
            ->find($id);

        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Astrologer not found'], 404);
        }

        $request->merge([
            'is_featured' => filter_var($request->input('is_featured', false), FILTER_VALIDATE_BOOLEAN),
            'supports_chat' => filter_var($request->input('supports_chat', true), FILTER_VALIDATE_BOOLEAN),
            'supports_call' => filter_var($request->input('supports_call', true), FILTER_VALIDATE_BOOLEAN),
            'is_online' => filter_var($request->input('is_online', true), FILTER_VALIDATE_BOOLEAN),
            'supports_palm_reading' => filter_var($request->input('supports_palm_reading', false), FILTER_VALIDATE_BOOLEAN),
            'supports_ritual_booking' => filter_var($request->input('supports_ritual_booking', false), FILTER_VALIDATE_BOOLEAN),
        ]);

        $validator = Validator::make($request->all(), [
            'firstName' => 'required|string|max:255',
            'lastName' => 'nullable|string|max:255',
            'email' => ['required', 'string', 'email', 'max:255', Rule::unique('users', 'email')->ignore($user->id)],
            'password' => 'nullable|string|min:6',
            'experience_years' => 'required|numeric',
            'languages' => 'nullable|string',
            'specialities' => 'nullable|string',
            'chat_price' => 'required|numeric',
            'call_price' => 'required|numeric',
            'chat_duration_prices' => 'nullable|array',
            'chat_duration_prices.*' => 'nullable|numeric|min:0',
            'call_duration_prices' => 'nullable|array',
            'call_duration_prices.*' => 'nullable|numeric|min:0',
            'supports_chat' => 'nullable|boolean',
            'supports_call' => 'nullable|boolean',
            'is_online' => 'nullable|boolean',
            'supports_palm_reading' => 'nullable|boolean',
            'supports_ritual_booking' => 'nullable|boolean',
            'chat_commission_percentage' => 'nullable|numeric|between:0,100',
            'call_commission_percentage' => 'nullable|numeric|between:0,100',
            'translations' => 'nullable|array',
            'about_bio' => 'nullable|string',
            'profile_image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:2048',
            'is_featured' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        $user->name = trim($request->firstName . ' ' . $request->lastName);
        $user->email = $request->email;

        if ($request->filled('password')) {
            $user->password = bcrypt($request->password);
        }

        $user->save();

        $profileImagePath = $user->astrologerDetail?->profile_image;
        if ($request->hasFile('profile_image')) {
            $profileImagePath = MediaStorage::store($request->file('profile_image'), 'astrologers');
            $user->profile_image = $profileImagePath;
            $user->save();
        }

        $user->astrologerDetail()->updateOrCreate(
            ['user_id' => $user->id],
            [
                'experience_years' => $request->experience_years,
                'languages' => $request->languages,
                'specialities' => $request->specialities,
                'chat_price' => $request->chat_price,
                'call_price' => $request->call_price,
                'chat_duration_prices' => $request->input('chat_duration_prices'),
                'call_duration_prices' => $request->input('call_duration_prices'),
                'supports_chat' => $request->boolean('supports_chat', true),
                'supports_call' => $request->boolean('supports_call', true),
                'is_online' => $request->boolean('is_online', true),
                'supports_palm_reading' => $request->boolean('supports_palm_reading'),
                'supports_ritual_booking' => $request->boolean('supports_ritual_booking'),
                'chat_commission_percentage' => $request->input('chat_commission_percentage', 20),
                'call_commission_percentage' => $request->input('call_commission_percentage', 20),
                'translations' => $request->input('translations'),
                'about_bio' => $request->about_bio,
                'profile_image' => $profileImagePath,
                'is_featured' => $request->boolean('is_featured'),
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Astrologer updated successfully',
            'astrologer' => $user->fresh()->load('astrologerDetail'),
        ]);
    }

    public function deleteAdminAstrologer(Request $request, int $id)
    {
        $this->ensureAdmin($request);
        $user = User::with('astrologerDetail')
            ->where('role', 'astrologer')
            ->find($id);

        if (!$user) {
            return response()->json(['success' => false, 'message' => 'Astrologer not found'], 404);
        }

        Booking::where('astrologer_id', $user->id)->update(['astrologer_id' => null]);
        $user->astrologerDetail()?->delete();
        $user->delete();

        return response()->json([
            'success' => true,
            'message' => 'Astrologer deleted successfully',
        ]);
    }

    public function updateAstrologerProfile(Request $request)
    {
        $this->normalizeTranslations($request);
        $user = $request->user();

        if ($user->role !== 'astrologer') {
            return response()->json(['success' => false, 'message' => 'Unauthorized Access. Astrologer account required.'], 403);
        }

        $request->merge([
            'is_featured' => filter_var($request->input('is_featured', false), FILTER_VALIDATE_BOOLEAN),
        ]);

        $validator = Validator::make($request->all(), [
            'firstName' => 'required|string|max:255',
            'lastName' => 'nullable|string|max:255',
            'email' => ['required', 'string', 'email', 'max:255', Rule::unique('users', 'email')->ignore($user->id)],
            'password' => 'nullable|string|min:6',
            'experience_years' => 'required|numeric',
            'languages' => 'nullable|string',
            'specialities' => 'nullable|string',
            'chat_price' => 'required|numeric',
            'call_price' => 'required|numeric',
            'translations' => 'nullable|array',
            'about_bio' => 'nullable|string',
            'profile_image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:2048',
            'is_featured' => 'nullable|boolean',
        ]);

        if ($validator->fails()) {
            return response()->json(['success' => false, 'message' => $validator->errors()->first()], 422);
        }

        $user->name = trim($request->firstName . ' ' . $request->lastName);
        $user->email = $request->email;

        if ($request->filled('password')) {
            $user->password = bcrypt($request->password);
        }

        $user->save();

        $profileImagePath = $user->astrologerDetail?->profile_image;
        if ($request->hasFile('profile_image')) {
            $profileImagePath = MediaStorage::store($request->file('profile_image'), 'astrologers');
            $user->profile_image = $profileImagePath;
            $user->save();
        }

        $user->astrologerDetail()->updateOrCreate(
            ['user_id' => $user->id],
            [
                'experience_years' => $request->experience_years,
                'languages' => $request->languages,
                'specialities' => $request->specialities,
                'chat_price' => $request->chat_price,
                'call_price' => $request->call_price,
                'translations' => $request->input('translations', $user->astrologerDetail?->translations),
                'about_bio' => $request->about_bio,
                'profile_image' => $profileImagePath,
                'is_featured' => $request->boolean('is_featured'),
            ]
        );

        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully',
            'user' => $user->fresh()->load('astrologerDetail'),
        ]);
    }

    public function updateAstrologerAvailability(Request $request)
    {
        $user = $request->user();
        abort_unless($user?->role === 'astrologer', 403);
        $validated = $request->validate(['is_online' => 'required|boolean']);

        $detail = $user->astrologerDetail()->updateOrCreate(
            ['user_id' => $user->id],
            ['is_online' => $validated['is_online']]
        );

        return response()->json([
            'success' => true,
            'message' => $detail->is_online ? 'You are now available.' : 'You are now offline.',
            'user' => $user->fresh()->load('astrologerDetail'),
        ]);
    }

    private function localizeAstrologers($astrologers, ?string $language): void
    {
        if ($language !== 'hi') {
            return;
        }

        foreach ($astrologers as $astrologer) {
            $translations = $astrologer->astrologerDetail?->translations['hi'] ?? [];
            foreach ($translations as $field => $value) {
                if ($value !== null && $value !== '') {
                    $astrologer->astrologerDetail->setAttribute($field, $value);
                }
            }
        }
    }

    private function normalizeTranslations(Request $request): void
    {
        foreach (['translations', 'chat_duration_prices', 'call_duration_prices'] as $field) {
            $value = $request->input($field);
            if (is_string($value)) {
                $decoded = json_decode($value, true);
                $request->merge([$field => is_array($decoded) ? $decoded : null]);
            }
        }
    }

    private function ensureAdminAccount(): void
    {
        User::firstOrCreate(
            ['email' => 'admin@astrozura.com'],
            [
                'name' => 'Astro Zura Admin',
                'password' => bcrypt('123456'),
                'role' => 'admin',
                'is_profile_complete' => true,
            ]
        );
    }

    private function ensureAdmin(Request $request): void
    {
        abort_unless($request->user()?->role === 'admin', 403);
    }

    private function notifyNewUser(User $user): void
    {
        app(UserNotificationService::class)->send(
            $user,
            'main',
            'account_created',
            'Welcome to AstroZura',
            'Your AstroZura account has been created successfully.',
            '/dashboard'
        );
    }

    private function resolveFrontendUrl(string $frontend): string
    {
        $productionUrl = $frontend === 'ecomm' ? 'https://shop.astrozura.com' : 'https://astrozura.com';
        $configuredUrl = $frontend === 'ecomm'
            ? env('FRONTEND_ECOMM_URL', $productionUrl)
            : env('FRONTEND_MAIN_URL', $productionUrl);
        $configuredHost = parse_url((string) $configuredUrl, PHP_URL_HOST);

        if (app()->environment('production') && (
            in_array($configuredHost, ['localhost', '127.0.0.1', '::1'], true)
            || Str::contains((string) $configuredHost, 'astrozura.cloud')
        )) {
            return $productionUrl;
        }

        return rtrim((string) $configuredUrl, '/');
    }

    private function sanitizeFrontendUrl(?string $frontendUrl): ?string
    {
        if (!$frontendUrl) {
            return null;
        }

        $normalizedUrl = rtrim($frontendUrl, '/');
        $host = parse_url($normalizedUrl, PHP_URL_HOST);

        if (app()->environment('production') && (
            in_array($host, ['localhost', '127.0.0.1', '::1'], true)
            || Str::contains((string) $host, 'astrozura.cloud')
        )) {
            return null;
        }

        return $this->isAllowedFrontendUrl($normalizedUrl) ? $normalizedUrl : null;
    }

    private function isAllowedFrontendUrl(string $frontendUrl): bool
    {
        return in_array($frontendUrl, $this->allowedFrontendUrls(), true);
    }

    private function allowedFrontendUrls(): array
    {
        $configuredUrls = array_map(
            static fn (string $url) => rtrim(trim($url), '/'),
            array_filter(explode(',', (string) env('FRONTEND_ALLOWED_URLS', '')))
        );

        return array_values(array_unique(array_filter([
            env('FRONTEND_MAIN_URL'),
            env('FRONTEND_ECOMM_URL'),
            'http://127.0.0.1:5173',
            'http://localhost:5173',
            'http://127.0.0.1:5174',
            'http://localhost:5174',
            'https://astrozura.com',
            'https://admin.astrozura.com',
            'https://shop.astrozura.com',
            ...$configuredUrls,
        ])));
    }

    private function encodeOAuthState(array $state): string
    {
        return rtrim(strtr(base64_encode(json_encode($state, JSON_UNESCAPED_SLASHES)), '+/', '-_'), '=');
    }

    private function decodeOAuthState(string $state): array
    {
        if ($state === '') {
            return [];
        }

        $decoded = base64_decode(strtr($state, '-_', '+/'), true);
        if ($decoded === false) {
            return [];
        }

        $payload = json_decode($decoded, true);

        if (!is_array($payload)) {
            return [];
        }

        if (isset($payload['frontend_url'])) {
            $payload['frontend_url'] = $this->sanitizeFrontendUrl($payload['frontend_url']);
        }

        return $payload;
    }
}
