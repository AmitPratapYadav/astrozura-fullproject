<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LiveSession;
use App\Models\LiveSessionComment;
use App\Services\FirebaseCloudMessagingService;
use App\Support\Zego\ZegoTokenService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class LiveSessionController extends Controller
{
    public function __construct(
        private readonly FirebaseCloudMessagingService $firebaseCloudMessagingService
    ) {
    }

    public function current()
    {
        $session = $this->getCurrentLiveSession();

        return response()->json([
            'success' => true,
            'session' => $session ? $this->serializeSession($session) : null,
        ]);
    }

    public function viewer(Request $request)
    {
        $user = $request->user();
        $session = $this->getCurrentLiveSession();

        if (!$session) {
          return response()->json([
              'success' => false,
              'message' => 'No live broadcast is active right now.',
          ], 404);
        }

        return response()->json([
            'success' => true,
            'session' => $this->serializeSession($session),
            'viewer' => [
                'role' => (int) $session->astrologer_id === (int) $user->id ? 'host' : 'viewer',
                'zego' => $this->buildLiveZegoPayload($user->id, (int) $session->astrologer_id === (int) $user->id ? 'host' : 'viewer'),
            ],
        ]);
    }

    public function start(Request $request)
    {
        $user = $request->user();
        $this->assertCanHost($user);

        $validated = $request->validate([
            'title' => 'nullable|string|max:255',
            'description' => 'nullable|string|max:2000',
        ]);

        $existing = LiveSession::with('astrologer.astrologerDetail')
            ->where('astrologer_id', $user->id)
            ->where('status', 'live')
            ->latest('started_at')
            ->first();

        if ($existing) {
            return response()->json([
                'success' => true,
                'message' => 'Live session already active.',
                'session' => $this->serializeSession($existing),
                'viewer' => [
                    'role' => 'host',
                    'zego' => $this->buildLiveZegoPayload($user->id, 'host'),
                ],
            ]);
        }

        LiveSession::where('status', 'live')->update([
            'status' => 'ended',
            'ended_at' => Carbon::now('Asia/Kolkata'),
        ]);

        $sessionKey = $this->generateSessionKey();

        $session = LiveSession::create([
            'astrologer_id' => $user->id,
            'title' => $validated['title'] ?? ($user->name . "'s Live Guidance Session"),
            'description' => $validated['description'] ?? 'Join the live spiritual session and interact in real time.',
            'room_id' => "astrozura-live-room-{$user->id}-{$sessionKey}",
            'stream_id' => "astrozura-live-stream-{$user->id}-{$sessionKey}",
            'status' => 'live',
            'started_at' => Carbon::now('Asia/Kolkata'),
        ])->load('astrologer.astrologerDetail');

        try {
            $this->firebaseCloudMessagingService->sendLiveStartedNotification($session);
        } catch (\Throwable $exception) {
            report($exception);
        }

        return response()->json([
            'success' => true,
            'message' => 'Live session created.',
            'session' => $this->serializeSession($session),
            'viewer' => [
                'role' => 'host',
                'zego' => $this->buildLiveZegoPayload($user->id, 'host'),
            ],
        ]);
    }

    public function stop(Request $request, LiveSession $liveSession)
    {
        $user = $request->user();
        $this->assertOwnsLiveSession($liveSession, $user->id);

        if ($liveSession->status !== 'live') {
            return response()->json([
                'success' => true,
                'message' => 'Live session already closed.',
                'session' => $this->serializeSession($liveSession->load('astrologer.astrologerDetail')),
            ]);
        }

        $liveSession->update([
            'status' => 'ended',
            'ended_at' => Carbon::now('Asia/Kolkata'),
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Live session stopped.',
            'session' => $this->serializeSession($liveSession->fresh('astrologer.astrologerDetail')),
        ]);
    }

    public function comments(LiveSession $liveSession)
    {
        $comments = $liveSession->comments()
            ->with('user:id,name')
            ->latest()
            ->take(100)
            ->get()
            ->reverse()
            ->values()
            ->map(fn (LiveSessionComment $comment) => $this->serializeComment($comment));

        return response()->json([
            'success' => true,
            'comments' => $comments,
        ]);
    }

    public function commentStore(Request $request, LiveSession $liveSession)
    {
        $user = $request->user();

        if ($liveSession->status !== 'live') {
            return response()->json([
                'success' => false,
                'message' => 'This live session is no longer active.',
            ], 422);
        }

        $validated = $request->validate([
            'message' => 'required|string|max:500',
        ]);

        $comment = LiveSessionComment::create([
            'live_session_id' => $liveSession->id,
            'user_id' => $user->id,
            'message' => trim($validated['message']),
        ]);

        $comment->load('user:id,name');

        return response()->json([
            'success' => true,
            'comment' => $this->serializeComment($comment),
        ]);
    }

    private function getCurrentLiveSession(): ?LiveSession
    {
        return LiveSession::with('astrologer.astrologerDetail')
            ->where('status', 'live')
            ->latest('started_at')
            ->first();
    }

    private function serializeSession(LiveSession $session): array
    {
        return [
            'id' => $session->id,
            'title' => $session->title,
            'description' => $session->description,
            'room_id' => $session->room_id,
            'stream_id' => $session->stream_id,
            'status' => $session->status,
            'started_at' => $session->started_at?->toIso8601String(),
            'ended_at' => $session->ended_at?->toIso8601String(),
            'astrologer' => [
                'id' => $session->astrologer?->id,
                'name' => $session->astrologer?->name,
                'profile_image' => $session->astrologer?->astrologerDetail?->profile_image,
                'specialities' => $session->astrologer?->astrologerDetail?->specialities,
                'languages' => $session->astrologer?->astrologerDetail?->languages,
            ],
        ];
    }

    private function serializeComment(LiveSessionComment $comment): array
    {
        return [
            'id' => $comment->id,
            'message' => $comment->message,
            'created_at' => $comment->created_at?->toIso8601String(),
            'user' => [
                'id' => $comment->user?->id,
                'name' => $comment->user?->name,
            ],
        ];
    }

    private function buildLiveZegoPayload(int $userId, string $role): array
    {
        $project = config('zego.live');
        $appId = (int) ($project['app_id'] ?? 0);
        $secret = (string) ($project['server_secret'] ?? '');

        if ($appId <= 0 || $secret === '') {
            abort(500, 'ZEGO live project is not configured.');
        }

        $zegoUserId = substr("az-live-{$role}-{$userId}", 0, 32);
        $ttl = (int) config('zego.token_ttl', 6 * 60 * 60);

        return [
            'app_id' => $appId,
            'app_sign' => $project['app_sign'] ?? null,
            'server_url' => $project['server_url'] ?? null,
            'secondary_server_url' => $project['secondary_server_url'] ?? null,
            'token' => ZegoTokenService::generateToken04($appId, $zegoUserId, $secret, $ttl),
            'token_expires_in' => $ttl,
            'user_id' => $zegoUserId,
            'user_name' => "{$role}-{$userId}",
            'role' => $role,
        ];
    }

    private function assertCanHost($user): void
    {
        if ($user?->role !== 'astrologer' || !$user->astrologerDetail?->is_featured) {
            abort(403, 'Only featured astrologers can host a live session.');
        }
    }

    private function assertOwnsLiveSession(LiveSession $liveSession, int $userId): void
    {
        if ((int) $liveSession->astrologer_id !== $userId) {
            abort(403, 'You do not own this live session.');
        }
    }

    private function generateSessionKey(): string
    {
        return Carbon::now('Asia/Kolkata')->format('YmdHis') . '-' . Str::lower(Str::random(6));
    }
}
