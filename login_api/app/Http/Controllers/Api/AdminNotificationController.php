<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AdminNotification;
use Illuminate\Http\Request;

class AdminNotificationController extends Controller
{
    public function index(Request $request)
    {
        $this->ensureAdmin($request);

        return response()->json([
            'success' => true,
            'unread_count' => AdminNotification::whereNull('read_at')->count(),
            'notifications' => AdminNotification::latest()->limit(30)->get(),
        ]);
    }

    public function markRead(Request $request, AdminNotification $adminNotification)
    {
        $this->ensureAdmin($request);
        $adminNotification->update(['read_at' => now()]);

        return response()->json(['success' => true]);
    }

    public function markAllRead(Request $request)
    {
        $this->ensureAdmin($request);
        AdminNotification::whereNull('read_at')->update(['read_at' => now()]);

        return response()->json(['success' => true]);
    }

    private function ensureAdmin(Request $request): void
    {
        abort_unless($request->user()?->role === 'admin', 403, 'Admin access required.');
    }
}
