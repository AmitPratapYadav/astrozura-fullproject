<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RitualService;
use App\Models\User;
use App\Models\Booking;
use App\Support\MediaStorage;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class RitualController extends Controller
{
    public function index(Request $request)
    {
        $query = RitualService::query()
            ->with(['assignedAstrologer.astrologerDetail'])
            ->where('status', true)
            ->orderByDesc('is_popular')
            ->orderBy('name');

        $term = trim((string) $request->query('q', ''));
        if ($term !== '') {
            $query->where(function ($builder) use ($term) {
                $builder->where('name', 'like', '%' . $term . '%')
                    ->orWhere('category', 'like', '%' . $term . '%')
                    ->orWhere('service_type', 'like', '%' . $term . '%')
                    ->orWhere('short_description', 'like', '%' . $term . '%');
            });
        }

        $category = trim((string) $request->query('category', ''));
        if ($category !== '') {
            $query->where('category', $category);
        }

        $rituals = $query->paginate((int) $request->query('per_page', 12));
        $this->localize(collect($rituals->items()), $request->query('la'));

        return response()->json([
            'success' => true,
            'rituals' => $rituals,
            'categories' => RitualService::query()
                ->where('status', true)
                ->whereNotNull('category')
                ->distinct()
                ->pluck('category')
                ->filter()
                ->values(),
        ]);
    }

    public function show(Request $request, string $slug)
    {
        $ritual = RitualService::query()
            ->with(['assignedAstrologer.astrologerDetail'])
            ->where('slug', $slug)
            ->where('status', true)
            ->first();

        if (!$ritual) {
            return response()->json(['success' => false, 'message' => 'Ritual not found.'], 404);
        }

        $recommendedAstrologers = User::query()
            ->with('astrologerDetail')
            ->where('role', 'astrologer')
            ->orderByDesc('created_at')
            ->get()
            ->sortByDesc(fn ($astrologer) => (int) ($astrologer->astrologerDetail->is_featured ?? false) * 100 + (float) ($astrologer->astrologerDetail->rating ?? 0))
            ->take(3)
            ->values();
        $this->appendAvailabilityStatuses($recommendedAstrologers);
        $this->localize(collect([$ritual]), $request->query('la'));

        $similar = RitualService::query()
            ->where('status', true)
            ->where('id', '!=', $ritual->id)
            ->where(function ($builder) use ($ritual) {
                $builder->where('category', $ritual->category)
                    ->orWhere('service_type', $ritual->service_type);
            })
            ->orderByDesc('is_popular')
            ->take(4)
            ->get();
        $this->localize($similar, $request->query('la'));

        return response()->json([
            'success' => true,
            'ritual' => $ritual,
            'recommended_astrologers' => $recommendedAstrologers,
            'similar_rituals' => $similar,
        ]);
    }

    private function appendAvailabilityStatuses($astrologers): void
    {
        $now = Carbon::now('Asia/Kolkata');
        $active = Booking::query()
            ->whereIn('astrologer_id', $astrologers->pluck('id'))
            ->where('payment_status', 'paid')
            ->whereIn('status', ['confirmed', 'in_progress'])
            ->where('scheduled_at', '<=', $now)
            ->where('ends_at', '>=', $now)
            ->get()
            ->keyBy('astrologer_id');

        $astrologers->each(function ($astrologer) use ($active) {
            $booking = $active->get($astrologer->id);
            $astrologer->setAttribute(
                'availability_status',
                !$astrologer->astrologerDetail?->is_online
                    ? 'unavailable'
                    : ($booking ? ($booking->consultation_type === 'call' ? 'on_call' : 'on_chat') : 'available')
            );
        });
    }

    public function adminIndex(Request $request)
    {
        $this->ensureAdmin($request);
        return response()->json([
            'success' => true,
            'rituals' => RitualService::query()
                ->with(['assignedAstrologer.astrologerDetail'])
                ->latest()
                ->get(),
        ]);
    }

    public function store(Request $request)
    {
        $this->ensureAdmin($request);
        $validated = $this->validateRitual($request);

        $slug = Str::slug($validated['name']);
        $baseSlug = $slug;
        $counter = 2;
        while (RitualService::where('slug', $slug)->exists()) {
            $slug = $baseSlug . '-' . $counter;
            $counter++;
        }

        $ritual = RitualService::create($this->buildRitualPayload($request, $validated, $slug));

        return response()->json([
            'success' => true,
            'message' => 'Ritual created successfully.',
            'ritual' => $ritual->load('assignedAstrologer.astrologerDetail'),
        ]);
    }

    public function update(Request $request, int $id)
    {
        $this->ensureAdmin($request);
        $ritual = RitualService::find($id);

        if (!$ritual) {
            return response()->json(['success' => false, 'message' => 'Ritual not found.'], 404);
        }

        $validated = $this->validateRitual($request);
        $slug = $ritual->slug;

        if ($ritual->name !== $validated['name']) {
            $slug = Str::slug($validated['name']);
            $baseSlug = $slug;
            $counter = 2;
            while (RitualService::where('slug', $slug)->where('id', '!=', $ritual->id)->exists()) {
                $slug = $baseSlug . '-' . $counter;
                $counter++;
            }
        }

        $ritual->update($this->buildRitualPayload($request, $validated, $slug, $ritual));

        return response()->json([
            'success' => true,
            'message' => 'Ritual updated successfully.',
            'ritual' => $ritual->fresh()->load('assignedAstrologer.astrologerDetail'),
        ]);
    }

    public function destroy(Request $request, int $id)
    {
        $this->ensureAdmin($request);
        $ritual = RitualService::find($id);

        if (!$ritual) {
            return response()->json(['success' => false, 'message' => 'Ritual not found.'], 404);
        }

        $ritual->delete();

        return response()->json([
            'success' => true,
            'message' => 'Ritual deleted successfully.',
        ]);
    }

    private function validateRitual(Request $request): array
    {
        return $request->validate([
            'name' => 'required|string|max:255',
            'service_type' => 'required|string|max:120',
            'category' => 'required|string|max:120',
            'short_description' => 'required|string|max:500',
            'description' => 'nullable|string',
            'benefits' => 'nullable|string',
            'materials_required' => 'nullable|string',
            'ideal_timing' => 'nullable|string|max:255',
            'duration_label' => 'required|string|max:120',
            'mode' => 'nullable|string|max:120',
            'price' => 'nullable|numeric|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,webp|max:3072',
            'is_popular' => 'nullable|boolean',
            'status' => 'nullable|boolean',
            'assigned_astrologer_id' => 'nullable|exists:users,id',
            'steps' => 'nullable|string',
            'materials' => 'nullable|string',
            'faqs' => 'nullable|string',
            'mantras' => 'nullable|string',
            'translations' => 'nullable|string',
        ]);
    }

    private function buildRitualPayload(Request $request, array $validated, string $slug, ?RitualService $ritual = null): array
    {
        $imagePath = $ritual?->image;
        if ($request->hasFile('image')) {
            $imagePath = MediaStorage::store($request->file('image'), 'rituals');
        }

        return [
            'name' => $validated['name'],
            'slug' => $slug,
            'service_type' => $validated['service_type'],
            'category' => $validated['category'],
            'short_description' => $validated['short_description'],
            'description' => $validated['description'] ?? null,
            'benefits' => $validated['benefits'] ?? null,
            'materials_required' => $validated['materials_required'] ?? null,
            'ideal_timing' => $validated['ideal_timing'] ?? null,
            'duration_label' => $validated['duration_label'],
            'mode' => $validated['mode'] ?? null,
            'price' => $validated['price'] ?? 0,
            'image' => $imagePath,
            'is_popular' => filter_var($request->input('is_popular', false), FILTER_VALIDATE_BOOLEAN),
            'status' => filter_var($request->input('status', true), FILTER_VALIDATE_BOOLEAN),
            'assigned_astrologer_id' => $validated['assigned_astrologer_id'] ?? null,
            'steps' => $this->parseLineItems($request->input('steps')),
            'materials' => $this->parseLineItems($request->input('materials')),
            'faqs' => $this->parseFaqItems($request->input('faqs')),
            'mantras' => $this->parseLineItems($request->input('mantras')),
            'translations' => $this->decodeTranslations(
                $validated['translations'] ?? null,
                $ritual?->translations
            ),
        ];
    }

    private function decodeTranslations(?string $value, ?array $fallback = null): ?array
    {
        if (!$value) {
            return $fallback;
        }

        $decoded = json_decode($value, true);
        return is_array($decoded) ? $decoded : $fallback;
    }

    private function localize($models, ?string $language): void
    {
        if ($language !== 'hi') {
            return;
        }

        foreach ($models as $model) {
            foreach (($model?->translations['hi'] ?? []) as $field => $value) {
                if ($value !== null && $value !== '') {
                    $model->setAttribute($field, $value);
                }
            }
        }
    }

    private function ensureAdmin(Request $request): void
    {
        abort_unless($request->user()?->role === 'admin', 403);
    }

    private function parseLineItems(?string $value): array
    {
        if (!$value) {
            return [];
        }

        return collect(preg_split('/\r\n|\r|\n/', $value))
            ->map(fn ($line) => trim((string) $line))
            ->filter()
            ->values()
            ->all();
    }

    private function parseFaqItems(?string $value): array
    {
        if (!$value) {
            return [];
        }

        return collect(preg_split('/\r\n|\r|\n/', $value))
            ->map(function ($line) {
                [$question, $answer] = array_pad(explode('|', (string) $line, 2), 2, '');
                return [
                    'question' => trim($question),
                    'answer' => trim($answer),
                ];
            })
            ->filter(fn ($item) => $item['question'] !== '' && $item['answer'] !== '')
            ->values()
            ->all();
    }
}
