<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PushSubscription;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class PushNotificationController extends Controller
{
    public function status(Request $request)
    {
        $token = (string) $request->query('token', '');

        if ($token === '') {
            return response()->json([
                'success' => true,
                'subscribed' => false,
            ]);
        }

        $subscription = PushSubscription::query()
            ->where('token', $token)
            ->where('channel', 'live')
            ->where('is_active', true)
            ->first();

        return response()->json([
            'success' => true,
            'subscribed' => (bool) $subscription,
        ]);
    }

    public function subscribe(Request $request)
    {
        $validated = $request->validate([
            'token' => 'required|string|max:512',
            'permission' => 'nullable|string|max:32',
        ]);

        $user = Auth::guard('sanctum')->user();

        $subscription = PushSubscription::updateOrCreate(
            ['token' => $validated['token']],
            [
                'user_id' => $user?->id,
                'channel' => 'live',
                'platform' => 'web',
                'permission' => $validated['permission'] ?? 'granted',
                'is_active' => true,
                'user_agent' => $request->userAgent(),
                'last_seen_at' => now(),
            ]
        );

        return response()->json([
            'success' => true,
            'subscribed' => true,
            'subscription_id' => $subscription->id,
        ]);
    }

    public function unsubscribe(Request $request)
    {
        $validated = $request->validate([
            'token' => 'required|string|max:512',
        ]);

        PushSubscription::query()
            ->where('token', $validated['token'])
            ->update([
                'is_active' => false,
                'last_seen_at' => now(),
            ]);

        return response()->json([
            'success' => true,
            'subscribed' => false,
        ]);
    }
}
