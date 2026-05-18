<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ApiAuthController;
use App\Http\Controllers\Api\EcommController;
use App\Http\Controllers\Api\AdminEcommController;
use App\Http\Controllers\Api\UserDashboardController;
use App\Http\Controllers\Api\AstrologyController;
use App\Http\Controllers\Api\BookingController;
use App\Http\Controllers\Api\SubscriptionController;
use App\Http\Controllers\Api\AdminBookingController;
use App\Http\Controllers\Api\AdminSubscriptionController;
use App\Http\Controllers\Api\RitualController;
use App\Http\Controllers\Api\RitualBookingController;
use App\Http\Controllers\Api\BookingSessionController;
use App\Http\Controllers\Api\BookingMessageController;
use App\Http\Controllers\Api\MediaController;
use App\Http\Controllers\Api\AstrologerReviewController;
use App\Http\Controllers\Api\LiveSessionController;
use App\Http\Controllers\Api\PushNotificationController;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
*/

// Google Auth Routes
Route::get('/auth/google', [ApiAuthController::class, 'redirectToGoogle']);
Route::get('/auth/google/callback', [ApiAuthController::class, 'handleGoogleCallback']);

// Public Auth Routes
Route::post('/send-otp', [ApiAuthController::class, 'sendOtp']);
Route::post('/login', [ApiAuthController::class, 'login']);
Route::post('/register', [ApiAuthController::class, 'register']);
Route::post('/login-password', [ApiAuthController::class, 'loginWithPassword']);
Route::post('/astrologer/login', [ApiAuthController::class, 'astrologerLogin']);
Route::post('/admin/login', [ApiAuthController::class, 'adminLogin']);

// Protected Routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [ApiAuthController::class, 'user']);
    Route::post('/logout', [ApiAuthController::class, 'logout']);
    Route::post('/astrologer/profile/update', [ApiAuthController::class, 'updateAstrologerProfile']);
    Route::get('/admin/profile', [ApiAuthController::class, 'getAdminProfile']);
    Route::post('/admin/profile/update', [ApiAuthController::class, 'updateAdminProfile']);
    Route::post('/bookings', [BookingController::class, 'store']);
    Route::post('/rituals/{ritual}/book', [RitualBookingController::class, 'store']);
    Route::get('/my-ritual-bookings', [RitualBookingController::class, 'myBookings']);
    Route::get('/astrologer/bookings', [BookingController::class, 'astrologerBookings']);
    Route::post('/astrologer/bookings/{id}/complete', [BookingController::class, 'markCompleted']);
    Route::get('/bookings/{booking}/session', [BookingSessionController::class, 'show']);
    Route::post('/bookings/{booking}/session/start', [BookingSessionController::class, 'start']);
    Route::post('/bookings/{booking}/session/end', [BookingSessionController::class, 'end']);
    Route::post('/bookings/{booking}/session/ping', [BookingSessionController::class, 'ping']);
    Route::post('/bookings/{booking}/session/extend', [BookingSessionController::class, 'extend']);
    Route::get('/bookings/{booking}/messages', [BookingMessageController::class, 'index']);
    Route::post('/bookings/{booking}/messages', [BookingMessageController::class, 'store']);
    Route::post('/media/chat-image', [MediaController::class, 'uploadChatImage']);
    Route::get('/live-sessions/current/viewer', [LiveSessionController::class, 'viewer']);
    Route::post('/live-sessions/start', [LiveSessionController::class, 'start']);
    Route::post('/live-sessions/{liveSession}/stop', [LiveSessionController::class, 'stop']);
    Route::post('/live-sessions/{liveSession}/comments', [LiveSessionController::class, 'commentStore']);

    // User Dashboard Routes
    Route::get('/dashboard/profile', [UserDashboardController::class, 'getProfile']);
    Route::post('/dashboard/profile/update', [UserDashboardController::class, 'updateProfile']);
    Route::get('/dashboard/orders', [UserDashboardController::class, 'getOrders']);
    Route::post('/dashboard/orders/store', [UserDashboardController::class, 'storeOrder']);
    Route::get('/dashboard/wishlist', [UserDashboardController::class, 'getWishlist']);
    Route::post('/dashboard/wishlist/toggle', [UserDashboardController::class, 'toggleWishlist']);

    // Booking Routes (auth required)
    Route::get('/my-bookings', [BookingController::class, 'myBookings']);
    Route::get('/my-subscriptions', [SubscriptionController::class, 'mySubscriptions']);
    Route::post('/bookings/{booking}/review', [AstrologerReviewController::class, 'store']);
});

Route::get('/bookings/availability', [BookingController::class, 'getAvailability']);
Route::get('/live-sessions/current', [LiveSessionController::class, 'current']);
Route::get('/live-sessions/{liveSession}/comments', [LiveSessionController::class, 'comments']);
Route::get('/notifications/live/status', [PushNotificationController::class, 'status']);
Route::post('/notifications/live/subscribe', [PushNotificationController::class, 'subscribe']);
Route::post('/notifications/live/unsubscribe', [PushNotificationController::class, 'unsubscribe']);

// Subscription Plans - Public
Route::get('/subscriptions/plans', [SubscriptionController::class, 'getPlans']);
Route::post('/subscriptions/subscribe', [SubscriptionController::class, 'subscribe']);

// Admin API Routes (No auth required for demo, ideally we'd add admin auth middleware)
Route::get('/admin/users', [ApiAuthController::class, 'getAllUsers']);
Route::get('/admin/dashboard-stats', [ApiAuthController::class, 'getAdminDashboardStats']);
Route::post('/admin/astrologers/create', [ApiAuthController::class, 'createAstrologer']);
Route::get('/admin/astrologers', [ApiAuthController::class, 'getAstrologers']);
Route::get('/admin/astrologers/{id}', [ApiAuthController::class, 'getAdminAstrologer']);
Route::post('/admin/astrologers/{id}', [ApiAuthController::class, 'updateAdminAstrologer']);
Route::delete('/admin/astrologers/{id}', [ApiAuthController::class, 'deleteAdminAstrologer']);
Route::get('/admin/search', [ApiAuthController::class, 'adminSearch']);

// Admin Booking Routes
Route::get('/admin/bookings', [AdminBookingController::class, 'index']);
Route::post('/admin/bookings/{id}/status', [AdminBookingController::class, 'updateStatus']);
Route::get('/admin/bookings/stats', [AdminBookingController::class, 'stats']);

// Admin Subscription Routes
Route::get('/admin/subscription-plans', [AdminSubscriptionController::class, 'getPlans']);
Route::post('/admin/subscription-plans', [AdminSubscriptionController::class, 'storePlan']);
Route::post('/admin/subscription-plans/{id}', [AdminSubscriptionController::class, 'updatePlan']);
Route::delete('/admin/subscription-plans/{id}', [AdminSubscriptionController::class, 'deletePlan']);
Route::get('/admin/user-subscriptions', [AdminSubscriptionController::class, 'getUserSubscriptions']);
Route::get('/admin/subscriptions/stats', [AdminSubscriptionController::class, 'stats']);

// Public Astrologer Endpoints
Route::get('/astrologers', [ApiAuthController::class, 'getAstrologers']);
Route::get('/astrologer/{id}', [ApiAuthController::class, 'getAstrologerProfile']);
Route::get('/rituals', [RitualController::class, 'index']);
Route::get('/rituals/{slug}', [RitualController::class, 'show']);

// Public E-Commerce Endpoints
Route::get('/ecomm/categories', [EcommController::class, 'getCategories']);
Route::get('/ecomm/products/trending', [EcommController::class, 'getTrendingProducts']);
Route::get('/ecomm/products', [EcommController::class, 'getAllProducts']);

// Admin E-Commerce Endpoints
Route::get('/admin/ecomm/categories', [AdminEcommController::class, 'getCategories']);
Route::post('/admin/ecomm/categories/create', [AdminEcommController::class, 'storeCategory']);
Route::get('/admin/ecomm/categories/{id}', [AdminEcommController::class, 'getCategory']);
Route::post('/admin/ecomm/categories/update/{id}', [AdminEcommController::class, 'updateCategory']);
Route::delete('/admin/ecomm/categories/{id}', [AdminEcommController::class, 'deleteCategory']);

Route::get('/admin/ecomm/products', [AdminEcommController::class, 'getProducts']);
Route::post('/admin/ecomm/products/create', [AdminEcommController::class, 'storeProduct']);
Route::get('/admin/ecomm/products/{id}', [AdminEcommController::class, 'getProduct']);
Route::post('/admin/ecomm/products/update/{id}', [AdminEcommController::class, 'updateProduct']);
Route::delete('/admin/ecomm/products/{id}', [AdminEcommController::class, 'deleteProduct']);
Route::get('/admin/rituals', [RitualController::class, 'adminIndex']);
Route::post('/admin/rituals', [RitualController::class, 'store']);
Route::post('/admin/rituals/{id}', [RitualController::class, 'update']);
Route::delete('/admin/rituals/{id}', [RitualController::class, 'destroy']);
Route::get('/admin/ritual-bookings', [RitualBookingController::class, 'index']);
Route::post('/admin/ritual-bookings/{ritualBooking}/status', [RitualBookingController::class, 'updateStatus']);

// Astrology API Proxy Endpoints
Route::get('/astrology/horoscope/daily', [AstrologyController::class, 'getDailyHoroscope']);
Route::get('/prokerala/horoscope/{sign}', [AstrologyController::class, 'getDailyHoroscope']);
Route::get('/prokerala/horoscope-weekly/{sign}', [AstrologyController::class, 'getWeeklyHoroscope']);
Route::get('/prokerala/horoscope-monthly/{sign}', [AstrologyController::class, 'getMonthlyHoroscope']);
Route::post('/prokerala/kundli', [AstrologyController::class, 'generateKundli']);
Route::post('/prokerala/kundli/detail-section/{section}', [AstrologyController::class, 'getKundliDetailSection']);
Route::post('/prokerala/kundli/free-pdf', [AstrologyController::class, 'downloadFreeKundliPdf']);
Route::post('/prokerala/matching', [AstrologyController::class, 'matchMaking']);
Route::post('/prokerala/matching/pdf', [AstrologyController::class, 'downloadMatchMakingPdf']);
Route::post('/prokerala/panchang', [AstrologyController::class, 'getPanchang']);
Route::get('/prokerala/location/search', [AstrologyController::class, 'searchLocation']);

// Extended Astrology API Endpoints
Route::post('/prokerala/divisional-charts', [AstrologyController::class, 'getDivisionalCharts']);
Route::post('/prokerala/predictions', [AstrologyController::class, 'getPredictions']);
Route::post('/prokerala/vedic-calculators/{calculator}', [AstrologyController::class, 'getVedicCalculator']);
Route::post('/prokerala/matching-calculators/{calculator}', [AstrologyController::class, 'getMatchingCalculator']);
Route::post('/prokerala/numerology', [AstrologyController::class, 'getNumerology']);
Route::post('/prokerala/sadesati', [AstrologyController::class, 'getSadesati']);
Route::post('/prokerala/lal-kitab', [AstrologyController::class, 'getLalKitab']);
Route::post('/prokerala/tarot', [AstrologyController::class, 'getTarotReading']);
