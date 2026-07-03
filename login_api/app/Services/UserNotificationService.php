<?php

namespace App\Services;

use App\Models\User;
use App\Models\UserNotification;
use Illuminate\Support\Carbon;

class UserNotificationService
{
    public function send(
        int|User $user,
        string $surface,
        string $type,
        string $title,
        string $message,
        ?string $actionUrl = null,
        array $data = [],
        Carbon|string|null $expiresAt = null
    ): UserNotification {
        $userId = $user instanceof User ? $user->id : $user;

        return UserNotification::create([
            'user_id' => $userId,
            'surface' => $surface,
            'type' => $type,
            'title' => $title,
            'message' => $message,
            'action_url' => $actionUrl,
            'data' => $data ?: null,
            'expires_at' => $expiresAt,
        ]);
    }

    public function broadcastToUsers(
        string $surface,
        string $type,
        string $title,
        string $message,
        ?string $actionUrl = null,
        array $data = [],
        Carbon|string|null $expiresAt = null
    ): int {
        $count = 0;

        User::query()
            ->where('role', 'user')
            ->select('id')
            ->chunkById(250, function ($users) use (
                &$count,
                $surface,
                $type,
                $title,
                $message,
                $actionUrl,
                $data,
                $expiresAt
            ): void {
                $now = now();
                $rows = $users->map(fn ($user) => [
                    'user_id' => $user->id,
                    'surface' => $surface,
                    'type' => $type,
                    'title' => $title,
                    'message' => $message,
                    'action_url' => $actionUrl,
                    'data' => $data ? json_encode($data) : null,
                    'expires_at' => $expiresAt,
                    'created_at' => $now,
                    'updated_at' => $now,
                ])->all();

                UserNotification::insert($rows);
                $count += count($rows);
            });

        return $count;
    }
}
