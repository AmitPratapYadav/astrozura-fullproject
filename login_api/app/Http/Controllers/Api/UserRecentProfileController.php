<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UserRecentProfile;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;

class UserRecentProfileController extends Controller
{
    public function index(Request $request)
    {
        $query = UserRecentProfile::where('user_id', $request->user()->id)
            ->orderByDesc('last_used_at')
            ->orderByDesc('updated_at');

        if ($request->filled('relation_role')) {
            $query->where('relation_role', $request->string('relation_role'));
        }

        return response()->json([
            'status' => 'success',
            'data' => $query->limit(80)->get(),
        ]);
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'profile_label' => ['nullable', 'string', 'max:120'],
            'person_name' => ['nullable', 'string', 'max:120'],
            'gender' => ['nullable', 'string', 'max:30'],
            'date_of_birth' => ['nullable', 'date'],
            'time_of_birth' => ['nullable', 'string', 'max:20'],
            'place_of_birth' => ['nullable', 'string', 'max:255'],
            'coordinates' => ['nullable', 'string', 'max:80'],
            'source_module' => ['nullable', 'string', 'max:120'],
            'relation_role' => ['nullable', 'string', 'max:30'],
            'metadata' => ['nullable', 'array'],
        ]);

        $coordinates = $this->parseCoordinates($data['coordinates'] ?? null);
        $now = now();

        $profile = UserRecentProfile::where('user_id', $request->user()->id)
            ->when(!empty($data['date_of_birth']), fn ($query) => $query->whereDate('date_of_birth', $data['date_of_birth']))
            ->when(!empty($data['time_of_birth']), fn ($query) => $query->where('time_of_birth', $this->normaliseTime($data['time_of_birth'])))
            ->when(!empty($data['coordinates']), fn ($query) => $query->where('coordinates', $data['coordinates']))
            ->first();

        $payload = array_merge($data, [
            'user_id' => $request->user()->id,
            'time_of_birth' => $this->normaliseTime($data['time_of_birth'] ?? null),
            'latitude' => $coordinates['latitude'],
            'longitude' => $coordinates['longitude'],
            'last_used_at' => $now,
        ]);

        if ($profile) {
            $profile->fill(array_filter($payload, fn ($value) => $value !== null && $value !== ''));
            $profile->usage_count = $profile->usage_count + 1;
            $profile->last_used_at = $now;
            $profile->save();
        } else {
            $profile = UserRecentProfile::create($payload);
        }

        return response()->json([
            'status' => 'success',
            'data' => $profile->fresh(),
        ]);
    }

    public function update(Request $request, UserRecentProfile $profile)
    {
        $this->authorizeProfile($request, $profile);

        $data = $request->validate([
            'profile_label' => ['nullable', 'string', 'max:120'],
            'person_name' => ['nullable', 'string', 'max:120'],
            'gender' => ['nullable', 'string', 'max:30'],
            'date_of_birth' => ['nullable', 'date'],
            'time_of_birth' => ['nullable', 'string', 'max:20'],
            'place_of_birth' => ['nullable', 'string', 'max:255'],
            'coordinates' => ['nullable', 'string', 'max:80'],
            'relation_role' => ['nullable', 'string', 'max:30'],
            'metadata' => ['nullable', 'array'],
        ]);

        if (array_key_exists('time_of_birth', $data)) {
            $data['time_of_birth'] = $this->normaliseTime($data['time_of_birth']);
        }

        if (array_key_exists('coordinates', $data)) {
            $coordinates = $this->parseCoordinates($data['coordinates']);
            $data['latitude'] = $coordinates['latitude'];
            $data['longitude'] = $coordinates['longitude'];
        }

        $profile->update($data);

        return response()->json([
            'status' => 'success',
            'data' => $profile->fresh(),
        ]);
    }

    public function destroy(Request $request, UserRecentProfile $profile)
    {
        $this->authorizeProfile($request, $profile);
        $profile->delete();

        return response()->json(['status' => 'success']);
    }

    private function authorizeProfile(Request $request, UserRecentProfile $profile): void
    {
        abort_unless($profile->user_id === $request->user()->id, 403);
    }

    private function parseCoordinates(?string $coordinates): array
    {
        if (!$coordinates) {
            return ['latitude' => null, 'longitude' => null];
        }

        [$latitude, $longitude] = array_pad(array_map('trim', explode(',', $coordinates)), 2, null);

        return [
            'latitude' => is_numeric($latitude) ? $latitude : null,
            'longitude' => is_numeric($longitude) ? $longitude : null,
        ];
    }

    private function normaliseTime(?string $time): ?string
    {
        if (!$time) {
            return null;
        }

        try {
            return Carbon::parse($time)->format('H:i');
        } catch (\Throwable) {
            return substr($time, 0, 5);
        }
    }
}
