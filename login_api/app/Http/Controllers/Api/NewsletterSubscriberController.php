<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\NewsletterSubscriber;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class NewsletterSubscriberController extends Controller
{
    public function store(Request $request)
    {
        $validated = $request->validate([
            'email' => 'required|email|max:255',
            'source' => ['required', Rule::in(['main', 'shop'])],
        ]);

        $subscriber = NewsletterSubscriber::updateOrCreate(
            ['email' => strtolower($validated['email']), 'source' => $validated['source']],
            ['is_active' => true]
        );

        return response()->json([
            'status' => 'success',
            'message' => 'Subscribed successfully.',
            'data' => $subscriber,
        ]);
    }

    public function adminIndex(Request $request)
    {
        abort_unless($request->user()?->role === 'admin', 403);

        $query = NewsletterSubscriber::query()
            ->when($request->filled('source'), fn ($builder) => $builder->where('source', $request->source))
            ->when($request->filled('status'), fn ($builder) => $builder->where('is_active', $request->status === 'active'))
            ->when($request->filled('q'), fn ($builder) => $builder->where('email', 'like', '%' . trim($request->q) . '%'))
            ->when($request->filled('from'), fn ($builder) => $builder->whereDate('created_at', '>=', $request->from))
            ->when($request->filled('to'), fn ($builder) => $builder->whereDate('created_at', '<=', $request->to))
            ->latest();

        return response()->json([
            'status' => 'success',
            'data' => $query->paginate(min((int) $request->input('per_page', 50), 100)),
            'stats' => [
                'total' => NewsletterSubscriber::count(),
                'main' => NewsletterSubscriber::where('source', 'main')->count(),
                'shop' => NewsletterSubscriber::where('source', 'shop')->count(),
                'active' => NewsletterSubscriber::where('is_active', true)->count(),
            ],
        ]);
    }
}
