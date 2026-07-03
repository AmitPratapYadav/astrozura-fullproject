<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UserNotification;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class UserNotificationController extends Controller
{
    public function index(Request $request)
    {
        $validated = $request->validate([
            'surface' => ['required', Rule::in(['main', 'shop'])],
            'unread' => 'nullable|boolean',
            'per_page' => 'nullable|integer|min:1|max:100',
        ]);

        $query = UserNotification::query()
            ->where('user_id', $request->user()->id)
            ->where('surface', $validated['surface'])
            ->where(fn ($builder) => $builder->whereNull('expires_at')->orWhere('expires_at', '>', now()))
            ->when($request->boolean('unread'), fn ($builder) => $builder->whereNull('read_at'))
            ->latest();

        $notifications = $query->paginate($validated['per_page'] ?? 20);
        $unreadCount = UserNotification::query()
            ->where('user_id', $request->user()->id)
            ->where('surface', $validated['surface'])
            ->whereNull('read_at')
            ->where(fn ($builder) => $builder->whereNull('expires_at')->orWhere('expires_at', '>', now()))
            ->count();

        return response()->json([
            'status' => 'success',
            'data' => $notifications,
            'unread_count' => $unreadCount,
        ]);
    }

    public function markRead(Request $request, UserNotification $notification)
    {
        abort_unless((int) $notification->user_id === (int) $request->user()->id, 403);
        $notification->update(['read_at' => $notification->read_at ?: now()]);

        return response()->json(['status' => 'success', 'data' => $notification->fresh()]);
    }

    public function markAllRead(Request $request)
    {
        $validated = $request->validate([
            'surface' => ['required', Rule::in(['main', 'shop'])],
        ]);

        UserNotification::query()
            ->where('user_id', $request->user()->id)
            ->where('surface', $validated['surface'])
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json(['status' => 'success']);
    }
}
