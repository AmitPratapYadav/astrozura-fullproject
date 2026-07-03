<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AstrologerReview;
use App\Models\Booking;
use App\Models\Order;
use App\Models\RitualBooking;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Http\Request;

class AdminAnalyticsController extends Controller
{
    public function overview(Request $request)
    {
        $this->ensureAdmin($request);
        [$from, $to, $bucket] = $this->period($request);

        $bookings = Booking::query()->whereBetween('created_at', [$from, $to]);
        $orders = Order::query()->whereBetween('created_at', [$from, $to]);
        $rituals = RitualBooking::query()->whereBetween('created_at', [$from, $to]);

        return response()->json([
            'status' => 'success',
            'period' => compact('from', 'to', 'bucket'),
            'totals' => [
                'users' => User::where('role', 'user')->whereBetween('created_at', [$from, $to])->count(),
                'bookings' => (clone $bookings)->count(),
                'booking_revenue' => (float) (clone $bookings)->where('payment_status', 'paid')->sum('amount'),
                'platform_commission' => (float) (clone $bookings)->where('payment_status', 'paid')->sum('platform_commission_amount'),
                'orders' => (clone $orders)->count(),
                'order_revenue' => (float) (clone $orders)->where('payment_status', 'paid')->sum('total_amount'),
                'rituals' => (clone $rituals)->count(),
                'ritual_revenue' => (float) (clone $rituals)->where('payment_status', 'paid')->sum('amount'),
            ],
            'series' => [
                'bookings' => $this->series(Booking::query(), $from, $to, $bucket, 'amount', 'payment_status'),
                'orders' => $this->series(Order::query(), $from, $to, $bucket, 'total_amount', 'payment_status'),
                'rituals' => $this->series(RitualBooking::query(), $from, $to, $bucket, 'amount', 'payment_status'),
            ],
        ]);
    }

    public function payments(Request $request)
    {
        $this->ensureAdmin($request);
        [$from, $to] = $this->period($request);

        return response()->json([
            'status' => 'success',
            'consultations' => Booking::with(['user:id,name', 'astrologer:id,name'])
                ->whereBetween('created_at', [$from, $to])
                ->where('payment_status', 'paid')
                ->latest()
                ->paginate(25, ['*'], 'consultations_page'),
            'orders' => Order::with('user:id,name')
                ->whereBetween('created_at', [$from, $to])
                ->where('payment_status', 'paid')
                ->latest()
                ->paginate(25, ['*'], 'orders_page'),
            'rituals' => RitualBooking::with(['user:id,name', 'ritual:id,name'])
                ->whereBetween('created_at', [$from, $to])
                ->where('payment_status', 'paid')
                ->latest()
                ->paginate(25, ['*'], 'rituals_page'),
        ]);
    }

    public function astrologers(Request $request)
    {
        $this->ensureAdmin($request);
        [$from, $to] = $this->period($request);

        $astrologers = User::query()
            ->where('role', 'astrologer')
            ->with('astrologerDetail')
            ->withCount(['astrologerBookings as paid_bookings_count' => fn ($query) => $query
                ->where('payment_status', 'paid')
                ->whereBetween('created_at', [$from, $to])])
            ->withSum(['astrologerBookings as gross_income' => fn ($query) => $query
                ->where('payment_status', 'paid')
                ->whereBetween('created_at', [$from, $to])], 'amount')
            ->withSum(['astrologerBookings as platform_commission' => fn ($query) => $query
                ->where('payment_status', 'paid')
                ->whereBetween('created_at', [$from, $to])], 'platform_commission_amount')
            ->withSum(['astrologerBookings as astrologer_earnings' => fn ($query) => $query
                ->where('payment_status', 'paid')
                ->whereBetween('created_at', [$from, $to])], 'astrologer_earning_amount')
            ->get()
            ->map(function ($astrologer) use ($from, $to) {
                $astrologer->average_rating = round((float) AstrologerReview::query()
                    ->where('astrologer_id', $astrologer->id)
                    ->whereBetween('created_at', [$from, $to])
                    ->avg('rating'), 2);
                return $astrologer;
            });

        return response()->json(['status' => 'success', 'data' => $astrologers]);
    }

    public function astrologer(Request $request, User $astrologer)
    {
        $this->ensureAdmin($request);
        abort_unless($astrologer->role === 'astrologer', 404);
        [$from, $to] = $this->period($request);

        $bookings = Booking::with('user:id,name,email,phone')
            ->where('astrologer_id', $astrologer->id)
            ->whereBetween('created_at', [$from, $to])
            ->latest();

        return response()->json([
            'status' => 'success',
            'astrologer' => $astrologer->load('astrologerDetail'),
            'summary' => [
                'total_bookings' => (clone $bookings)->count(),
                'paid_bookings' => (clone $bookings)->where('payment_status', 'paid')->count(),
                'gross_income' => (float) (clone $bookings)->where('payment_status', 'paid')->sum('amount'),
                'platform_commission' => (float) (clone $bookings)->where('payment_status', 'paid')->sum('platform_commission_amount'),
                'astrologer_earnings' => (float) (clone $bookings)->where('payment_status', 'paid')->sum('astrologer_earning_amount'),
                'average_rating' => round((float) AstrologerReview::where('astrologer_id', $astrologer->id)->avg('rating'), 2),
            ],
            'bookings' => $bookings->paginate(30),
        ]);
    }

    private function period(Request $request): array
    {
        $period = $request->input('period', 'month');
        $to = $request->filled('to') ? Carbon::parse($request->to)->endOfDay() : now()->endOfDay();
        $from = match ($period) {
            'week' => $to->copy()->subDays(6)->startOfDay(),
            'year' => $to->copy()->subYear()->addDay()->startOfDay(),
            'custom' => Carbon::parse($request->input('from', $to->copy()->subMonth()))->startOfDay(),
            default => $to->copy()->subMonth()->addDay()->startOfDay(),
        };
        $bucket = $period === 'year' ? 'month' : 'day';

        return [$from, $to, $bucket];
    }

    private function series(
        Builder $query,
        Carbon $from,
        Carbon $to,
        string $bucket,
        string $amountColumn,
        string $paymentColumn
    ): array {
        $driver = $query->getModel()->getConnection()->getDriverName();
        $dateExpression = match ([$driver, $bucket]) {
            ['sqlite', 'month'] => "strftime('%Y-%m', created_at)",
            ['sqlite', 'day'] => "strftime('%Y-%m-%d', created_at)",
            ['pgsql', 'month'] => "to_char(created_at, 'YYYY-MM')",
            ['pgsql', 'day'] => "to_char(created_at, 'YYYY-MM-DD')",
            default => $bucket === 'month'
                ? "DATE_FORMAT(created_at, '%Y-%m')"
                : 'DATE(created_at)',
        };

        return $query
            ->whereBetween('created_at', [$from, $to])
            ->selectRaw("{$dateExpression} as label")
            ->selectRaw('COUNT(*) as total')
            ->selectRaw("SUM(CASE WHEN {$paymentColumn} = 'paid' THEN {$amountColumn} ELSE 0 END) as revenue")
            ->groupBy('label')
            ->orderBy('label')
            ->get()
            ->toArray();
    }

    private function ensureAdmin(Request $request): void
    {
        abort_unless($request->user()?->role === 'admin', 403);
    }
}
