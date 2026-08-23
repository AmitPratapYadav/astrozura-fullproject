<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\LiveSession;
use App\Models\LiveSessionComment;
use App\Services\FirebaseCloudMessagingService;
use App\Support\VideoSdk\VideoSdkTokenService;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
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
                'provider' => $this->buildLiveProviderPayload($session, $user->id, (int) $session->astrologer_id === (int) $user->id ? 'host' : 'viewer'),
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
                    'provider' => $this->buildLiveProviderPayload($existing, $user->id, 'host'),
                ],
            ]);
        }

        LiveSession::where('status', 'live')->update([
            'status' => 'ended',
            'ended_at' => Carbon::now('Asia/Kolkata'),
        ]);

        $sessionKey = $this->generateSessionKey();
        $roomId = $this->createVideoSdkRoomId();

        $session = LiveSession::create([
            'astrologer_id' => $user->id,
            'title' => $validated['title'] ?? ($user->name . "'s Live Guidance Session"),
            'description' => $validated['description'] ?? 'Join the live spiritual session and interact in real time.',
            'room_id' => $roomId,
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
                'provider' => $this->buildLiveProviderPayload($session, $user->id, 'host'),
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

    private function buildLiveProviderPayload(LiveSession $session, int $userId, string $role): array
    {
        if (!(bool) config('videosdk.live.enabled')) {
            abort(500, 'VideoSDK live streaming is not enabled.');
        }

        return [
            'name' => 'videosdk',
            'videosdk' => $this->buildLiveVideoSdkPayload($session, $userId, $role),
        ];
    }

    private function buildLiveVideoSdkPayload(LiveSession $session, int $userId, string $role): array
    {
        $apiKey = (string) config('videosdk.live.api_key');
        $secret = (string) config('videosdk.live.secret');
        if ($apiKey === '' || $secret === '') {
            abort(500, 'VideoSDK live project is not configured.');
        }

        $ttl = (int) config('videosdk.live.token_ttl', 2 * 60 * 60);
        $participantId = substr("az-live-{$role}-{$userId}", 0, 32);

        return [
            'api_base_url' => 'https://api.videosdk.live',
            'room_id' => $session->room_id,
            'participant_id' => $participantId,
            'role' => $role,
            'mode' => $role === 'host' ? 'SEND_AND_RECV' : 'RECV_ONLY',
            'token' => VideoSdkTokenService::generateToken($apiKey, $secret, $ttl, [
                'roomId' => $session->room_id,
                'participantId' => $participantId,
            ]),
            'token_expires_in' => $ttl,
        ];
    }

    private function createVideoSdkRoomId(): string
    {
        $apiKey = (string) config('videosdk.live.api_key');
        $secret = (string) config('videosdk.live.secret');

        if (!(bool) config('videosdk.live.enabled') || $apiKey === '' || $secret === '') {
            abort(500, 'VideoSDK live project is not configured.');
        }

        $ttl = (int) config('videosdk.live.token_ttl', 2 * 60 * 60);
        $token = VideoSdkTokenService::generateToken($apiKey, $secret, $ttl, [
            'roles' => ['crawler'],
        ]);

        $response = Http::withHeaders(['Authorization' => $token])
            ->acceptJson()
            ->asJson()
            ->timeout(15)
            ->post('https://api.videosdk.live/v2/rooms', []);

        if (!$response->successful()) {
            report(new \RuntimeException('VideoSDK room creation failed: ' . $response->body()));
            abort(502, 'VideoSDK live room could not be created.');
        }

        $roomId = $response->json('roomId') ?? $response->json('room_id') ?? $response->json('id');

        if (!is_string($roomId) || trim($roomId) === '') {
            report(new \RuntimeException('VideoSDK room creation returned no room id: ' . $response->body()));
            abort(502, 'VideoSDK live room response was invalid.');
        }

        return $roomId;
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
