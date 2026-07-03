<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\UserNotificationService;
use Illuminate\Http\Request;

class AdminOfferController extends Controller
{
    public function store(Request $request, UserNotificationService $notifications)
    {
        abort_unless($request->user()?->role === 'admin', 403);

        $validated = $request->validate([
            'title' => 'required|string|max:255',
            'message' => 'required|string|max:2000',
            'action_url' => 'nullable|string|max:500',
            'expires_at' => 'nullable|date|after:now',
        ]);

        $count = $notifications->broadcastToUsers(
            'shop',
            'offer',
            $validated['title'],
            $validated['message'],
            $validated['action_url'] ?? '/allproduct',
            [],
            $validated['expires_at'] ?? null
        );

        return response()->json([
            'status' => 'success',
            'message' => "Offer notification sent to {$count} users.",
            'recipient_count' => $count,
        ]);
    }
}
