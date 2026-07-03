<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Blog;
use App\Models\BlogCategory;
use App\Support\MediaStorage;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;

class BlogController extends Controller
{
    public function categories(Request $request)
    {
        $query = BlogCategory::query()->orderBy('sort_order')->orderBy('name');

        if (!$this->isAdminRequest($request)) {
            $query->where('status', true);
        }

        $categories = $query->get();
        $this->localize($categories, $request->query('la'));

        return response()->json([
            'status' => 'success',
            'data' => $categories,
        ]);
    }

    public function blogs(Request $request)
    {
        $query = Blog::query()->with('category')->latest('published_at')->latest('id');

        if (!$this->isAdminRequest($request)) {
            $query->where('status', true)
                ->where(function ($builder) {
                    $builder->whereNull('published_at')->orWhere('published_at', '<=', now());
                });
        }

        if ($category = $request->query('category')) {
            $query->whereHas('category', fn ($builder) => $builder->where('slug', $category));
        }

        if ($search = trim((string) $request->query('search', ''))) {
            $query->where(function ($builder) use ($search) {
                $builder->where('title', 'like', "%{$search}%")
                    ->orWhere('excerpt', 'like', "%{$search}%")
                    ->orWhere('author_name', 'like', "%{$search}%");
            });
        }

        $blogs = $query->paginate((int) $request->query('per_page', 12));
        $this->localize(collect($blogs->items()), $request->query('la'));
        $this->localize(collect($blogs->items())->pluck('category')->filter(), $request->query('la'));

        return response()->json([
            'status' => 'success',
            'data' => $blogs,
        ]);
    }

    public function showBlog(Request $request, string $slug)
    {
        $blog = Blog::query()
            ->with('category')
            ->where('slug', $slug)
            ->where('status', true)
            ->where(function ($builder) {
                $builder->whereNull('published_at')->orWhere('published_at', '<=', now());
            })
            ->firstOrFail();

        $blog->increment('views_count');
        $freshBlog = $blog->fresh('category');
        $this->localize(collect([$freshBlog, $freshBlog->category])->filter(), $request->query('la'));

        return response()->json([
            'status' => 'success',
            'data' => $freshBlog,
        ]);
    }

    public function adminStoreCategory(Request $request, MediaStorage $mediaStorage)
    {
        $this->ensureAdmin($request);

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'slug' => 'nullable|string|max:255',
            'image' => 'nullable|image|max:4096',
            'status' => 'nullable',
            'sort_order' => 'nullable|integer|min:0',
            'translations' => 'nullable|string',
        ]);

        if ($request->hasFile('image')) {
            $validated['image'] = $mediaStorage->store($request->file('image'), 'blogs/categories');
        }

        $validated['slug'] = $this->uniqueSlug(BlogCategory::class, $validated['slug'] ?: $validated['name']);
        $validated['status'] = $request->boolean('status', true);
        $validated['sort_order'] = (int) ($validated['sort_order'] ?? 0);
        $validated['translations'] = $this->decodeTranslations($validated['translations'] ?? null);

        return response()->json([
            'status' => 'success',
            'data' => BlogCategory::create($validated),
        ], 201);
    }

    public function adminUpdateCategory(Request $request, MediaStorage $mediaStorage, int $id)
    {
        $this->ensureAdmin($request);
        $category = BlogCategory::findOrFail($id);

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'slug' => 'nullable|string|max:255',
            'image' => 'nullable|image|max:4096',
            'status' => 'nullable',
            'sort_order' => 'nullable|integer|min:0',
            'translations' => 'nullable|string',
        ]);

        if ($request->hasFile('image')) {
            $validated['image'] = $mediaStorage->store($request->file('image'), 'blogs/categories');
        }

        $validated['slug'] = $this->uniqueSlug(BlogCategory::class, $validated['slug'] ?: $validated['name'], $category->id);
        $validated['status'] = $request->boolean('status', true);
        $validated['sort_order'] = (int) ($validated['sort_order'] ?? 0);
        $validated['translations'] = $this->decodeTranslations($validated['translations'] ?? null);
        $category->update($validated);

        return response()->json(['status' => 'success', 'data' => $category->fresh()]);
    }

    public function adminDeleteCategory(Request $request, int $id)
    {
        $this->ensureAdmin($request);
        BlogCategory::findOrFail($id)->delete();

        return response()->json(['status' => 'success']);
    }

    public function adminShowBlog(Request $request, int $id)
    {
        $this->ensureAdmin($request);

        return response()->json([
            'status' => 'success',
            'data' => Blog::with('category')->findOrFail($id),
        ]);
    }

    public function adminStoreBlog(Request $request, MediaStorage $mediaStorage)
    {
        $this->ensureAdmin($request);
        $payload = $this->validatedBlogPayload($request, $mediaStorage);
        $payload['slug'] = $this->uniqueSlug(Blog::class, $payload['slug'] ?: $payload['title']);

        return response()->json([
            'status' => 'success',
            'data' => Blog::create($payload)->load('category'),
        ], 201);
    }

    public function adminUpdateBlog(Request $request, MediaStorage $mediaStorage, int $id)
    {
        $this->ensureAdmin($request);
        $blog = Blog::findOrFail($id);
        $payload = $this->validatedBlogPayload($request, $mediaStorage, $blog);
        $payload['slug'] = $this->uniqueSlug(Blog::class, $payload['slug'] ?: $payload['title'], $blog->id);
        $blog->update($payload);

        return response()->json([
            'status' => 'success',
            'data' => $blog->fresh('category'),
        ]);
    }

    public function adminDeleteBlog(Request $request, int $id)
    {
        $this->ensureAdmin($request);
        Blog::findOrFail($id)->delete();

        return response()->json(['status' => 'success']);
    }

    private function validatedBlogPayload(Request $request, MediaStorage $mediaStorage, ?Blog $blog = null): array
    {
        $validated = $request->validate([
            'blog_category_id' => 'nullable|exists:blog_categories,id',
            'title' => 'required|string|max:255',
            'slug' => 'nullable|string|max:255',
            'excerpt' => 'nullable|string',
            'cover_image' => 'nullable|image|max:8192',
            'content_blocks' => 'nullable|string',
            'translations' => 'nullable|string',
            'author_name' => 'nullable|string|max:255',
            'status' => 'nullable',
            'published_at' => 'nullable|date',
            'seo_title' => 'nullable|string|max:255',
            'seo_description' => 'nullable|string',
            'seo_keywords' => 'nullable|string',
            'block_images' => 'nullable|array',
            'block_images.*' => 'nullable|image|max:8192',
        ]);

        if ($request->hasFile('cover_image')) {
            $validated['cover_image'] = $mediaStorage->store($request->file('cover_image'), 'blogs/covers');
        } elseif ($blog) {
            $validated['cover_image'] = $blog->cover_image;
        }

        $blocks = json_decode((string) ($validated['content_blocks'] ?? '[]'), true);
        if (!is_array($blocks)) {
            $blocks = [];
        }

        foreach ($request->file('block_images', []) as $index => $file) {
            if ($file && isset($blocks[$index])) {
                $blocks[$index]['url'] = $mediaStorage->store($file, 'blogs/content');
            }
        }

        $validated['content_blocks'] = array_values(array_filter($blocks, function ($block) {
            return is_array($block) && !empty($block['type']);
        }));
        $validated['translations'] = $this->decodeTranslations($validated['translations'] ?? null);
        $validated['status'] = $request->boolean('status', false);
        $validated['published_at'] = !empty($validated['published_at'])
            ? Carbon::parse($validated['published_at'])
            : null;

        unset($validated['block_images']);

        return $validated;
    }

    private function uniqueSlug(string $modelClass, string $source, ?int $ignoreId = null): string
    {
        $base = Str::slug($source) ?: Str::random(8);
        $slug = $base;
        $counter = 2;

        while ($modelClass::query()
            ->where('slug', $slug)
            ->when($ignoreId, fn ($builder) => $builder->whereKeyNot($ignoreId))
            ->exists()
        ) {
            $slug = "{$base}-{$counter}";
            $counter++;
        }

        return $slug;
    }

    private function ensureAdmin(Request $request): void
    {
        abort_unless($request->user()?->role === 'admin', 403, 'Admin access required.');
    }

    private function isAdminRequest(Request $request): bool
    {
        return $request->user()?->role === 'admin';
    }

    private function decodeTranslations(?string $value): ?array
    {
        if (!$value) {
            return null;
        }

        $decoded = json_decode($value, true);
        return is_array($decoded) ? $decoded : null;
    }

    private function localize($models, ?string $language): void
    {
        if ($language !== 'hi') {
            return;
        }

        foreach ($models as $model) {
            $translations = $model?->translations['hi'] ?? [];
            foreach ($translations as $field => $value) {
                if ($value !== null && $value !== '') {
                    $model->setAttribute($field, $value);
                }
            }
        }
    }
}
