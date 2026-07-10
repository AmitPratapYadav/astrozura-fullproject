<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Blog;
use App\Models\Order;
use App\Models\Product;
use App\Support\MediaStorage;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use App\Services\UserNotificationService;

class AdminEcommController extends Controller
{
    // ======================================
    // CATEGORY MANAGEMENT
    // ======================================
    public function getCategories(Request $request)
    {
        $this->ensureAdmin($request);

        return response()->json([
            'status' => 'success',
            'data' => Category::orderBy('id', 'desc')->get()
        ]);
    }

    public function storeCategory(Request $request)
    {
        $this->ensureAdmin($request);
        $this->normalizeJsonField($request, 'translations');

        $request->validate([
            'name' => 'required|string|max:255|unique:categories,name',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,webp|max:2048',
            'shipping_charge' => 'nullable|numeric|min:0',
            'translations' => 'nullable|array',
        ]);

        $category = new Category();
        $category->name = $request->name;
        $category->shipping_charge = $request->input('shipping_charge', 0);
        $category->translations = $request->input('translations');

        if ($request->hasFile('image')) {
            $category->image = MediaStorage::store($request->file('image'), 'categories');
        }

        $category->status = $request->has('status') ? filter_var($request->status, FILTER_VALIDATE_BOOLEAN) : 1;
        $category->save();

        return response()->json(['status' => 'success', 'message' => 'Category added successfully!', 'data' => $category]);
    }

    public function getCategory(Request $request, $id)
    {
        $this->ensureAdmin($request);

        $category = Category::find($id);
        if (!$category) return response()->json(['status' => 'error', 'message' => 'Category not found'], 404);
        
        return response()->json(['status' => 'success', 'data' => $category]);
    }

    public function updateCategory(Request $request, $id)
    {
        $this->ensureAdmin($request);
        $this->normalizeJsonField($request, 'translations');

        $category = Category::find($id);
        if (!$category) return response()->json(['status' => 'error', 'message' => 'Category not found'], 404);

        $request->validate([
            'name' => ['required', 'string', 'max:255', Rule::unique('categories', 'name')->ignore($category->id)],
            'image' => 'nullable|image|mimes:jpeg,png,jpg,webp|max:2048',
            'shipping_charge' => 'nullable|numeric|min:0',
            'translations' => 'nullable|array',
        ]);

        $category->name = $request->name;
        $category->shipping_charge = $request->input('shipping_charge', $category->shipping_charge);
        if ($request->has('translations')) {
            $category->translations = $request->input('translations');
        }

        if ($request->hasFile('image')) {
            $category->image = MediaStorage::store($request->file('image'), 'categories');
        }

        if ($request->has('status')) {
            $category->status = filter_var($request->status, FILTER_VALIDATE_BOOLEAN) ? 1 : 0;
        }
        
        $category->save();

        return response()->json(['status' => 'success', 'message' => 'Category updated successfully!', 'data' => $category]);
    }

    public function deleteCategory(Request $request, $id)
    {
        $this->ensureAdmin($request);

        $category = Category::find($id);
        if (!$category) return response()->json(['status' => 'error', 'message' => 'Category not found'], 404);
        
        $category->delete();
        return response()->json(['status' => 'success', 'message' => 'Category deleted successfully']);
    }

    // ======================================
    // PRODUCT MANAGEMENT
    // ======================================
    public function getProducts(Request $request)
    {
        $this->ensureAdmin($request);

        return response()->json([
            'status' => 'success',
            'data' => Product::with(['category', 'variants', 'guideBlog'])->orderBy('id', 'desc')->get()
        ]);
    }

    public function storeProduct(Request $request)
    {
        $this->ensureAdmin($request);

        $this->normalizeVariantPayload($request);
        $validated = $request->validate($this->productRules());

        $product = DB::transaction(function () use ($request, $validated) {
            $product = new Product();
            $this->fillProduct($product, $validated);

            if ($request->hasFile('image')) {
                $product->image = MediaStorage::store($request->file('image'), 'products');
            }

            $product->is_trending = $request->has('is_trending') ? filter_var($request->is_trending, FILTER_VALIDATE_BOOLEAN) : 0;
            $product->is_new_arrival = $request->has('is_new_arrival') ? filter_var($request->is_new_arrival, FILTER_VALIDATE_BOOLEAN) : 0;
            $product->status = $request->has('status') ? filter_var($request->status, FILTER_VALIDATE_BOOLEAN) : 1;
            $product->save();
            $this->syncVariants($product, $validated['variants'] ?? []);

            return $product->load(['category', 'variants', 'guideBlog']);
        });

        return response()->json(['status' => 'success', 'message' => 'Product added successfully!', 'data' => $product]);
    }

    public function getProduct(Request $request, $id)
    {
        $this->ensureAdmin($request);

        $product = Product::with(['category', 'variants', 'guideBlog'])->find($id);
        if (!$product) return response()->json(['status' => 'error', 'message' => 'Product not found'], 404);
        
        return response()->json(['status' => 'success', 'data' => $product]);
    }

    public function updateProduct(Request $request, $id)
    {
        $this->ensureAdmin($request);

        $product = Product::find($id);
        if (!$product) return response()->json(['status' => 'error', 'message' => 'Product not found'], 404);

        $this->normalizeVariantPayload($request);
        $validated = $request->validate($this->productRules());
        DB::transaction(function () use ($request, $validated, $product) {
            $this->fillProduct($product, $validated);

            if ($request->hasFile('image')) {
                $product->image = MediaStorage::store($request->file('image'), 'products');
            }

            if ($request->has('is_trending')) {
                $product->is_trending = filter_var($request->is_trending, FILTER_VALIDATE_BOOLEAN) ? 1 : 0;
            }
            if ($request->has('is_new_arrival')) {
                $product->is_new_arrival = filter_var($request->is_new_arrival, FILTER_VALIDATE_BOOLEAN) ? 1 : 0;
            }
            if ($request->has('status')) {
                $product->status = filter_var($request->status, FILTER_VALIDATE_BOOLEAN) ? 1 : 0;
            }

            $product->save();
            $this->syncVariants($product, $validated['variants'] ?? []);
        });

        return response()->json([
            'status' => 'success',
            'message' => 'Product updated successfully!',
            'data' => $product->fresh()->load(['category', 'variants', 'guideBlog']),
        ]);
    }

    public function importProducts(Request $request)
    {
        $this->ensureAdmin($request);

        $validated = $request->validate([
            'products' => 'required|array|min:1|max:500',
            'products.*.category' => 'required|string|max:255',
            'products.*.name' => 'required|string|max:255',
            'products.*.price' => 'required|numeric|min:0',
            'products.*.unit' => 'nullable|string|max:100',
            'products.*.description' => 'nullable|string',
            'products.*.specifications' => 'nullable|string',
            'products.*.benefits' => 'nullable|string',
            'products.*.warnings_precautions' => 'nullable|string',
        ]);

        $summary = DB::transaction(function () use ($validated) {
            $created = 0;
            $updated = 0;

            foreach ($validated['products'] as $row) {
                $categoryName = trim($row['category']);
                $category = Category::query()->firstOrCreate(
                    ['name' => $categoryName],
                    ['status' => 1]
                );

                $product = Product::query()->firstOrNew([
                    'category_id' => $category->id,
                    'name' => trim($row['name']),
                ]);
                $wasExisting = $product->exists;

                $product->fill([
                    'price' => $row['price'],
                    'unit' => $this->nullableText($row['unit'] ?? null),
                    'description' => $this->nullableText($row['description'] ?? null),
                    'specifications' => $this->nullableText($row['specifications'] ?? null),
                    'benefits' => $this->nullableText($row['benefits'] ?? null),
                    'warnings_precautions' => $this->nullableText($row['warnings_precautions'] ?? null),
                ]);

                if (!$wasExisting) {
                    $product->status = 1;
                    $product->is_trending = 0;
                }

                $product->save();
                $wasExisting ? $updated++ : $created++;
            }

            return compact('created', 'updated');
        });

        return response()->json([
            'status' => 'success',
            'message' => sprintf(
                'Catalog imported: %d created, %d updated.',
                $summary['created'],
                $summary['updated']
            ),
            'data' => $summary,
        ]);
    }

    public function deleteProduct(Request $request, $id)
    {
        $this->ensureAdmin($request);

        $product = Product::find($id);
        if (!$product) return response()->json(['status' => 'error', 'message' => 'Product not found'], 404);
        
        $product->delete();
        return response()->json(['status' => 'success', 'message' => 'Product deleted successfully']);
    }

    public function getOrders(Request $request)
    {
        $this->ensureAdmin($request);

        return response()->json([
            'status' => 'success',
            'data' => Order::with(['user', 'items.product', 'items.variant'])
                ->latest()
                ->get(),
        ]);
    }

    public function updateOrderStatus(Request $request, Order $order, UserNotificationService $notifications)
    {
        $this->ensureAdmin($request);

        $validated = $request->validate([
            'status' => 'required|in:pending,processing,completed,cancelled',
            'payment_status' => 'nullable|in:unpaid,paid,partially_paid,refunded',
        ]);

        $order->update($validated);
        $notifications->send(
            $order->user_id,
            'shop',
            'order_status',
            'Order status updated',
            "{$order->order_number} is now {$order->status}.",
            "/dashboard/orders/{$order->id}",
            ['order_id' => $order->id, 'status' => $order->status]
        );

        return response()->json([
            'status' => 'success',
            'message' => 'Order updated successfully.',
            'data' => $order->fresh()->load(['user', 'items.product', 'items.variant']),
        ]);
    }

    private function ensureAdmin(Request $request): void
    {
        abort_unless($request->user()?->role === 'admin', 403, 'Admin access required.');
    }

    private function productRules(): array
    {
        return [
            'category_id' => 'required|exists:categories,id',
            'guide_blog_id' => 'nullable|exists:blogs,id',
            'name' => 'required|string|max:255',
            'price' => 'required|numeric|min:0',
            'unit' => 'nullable|string|max:100',
            'description' => 'nullable|string',
            'benefits' => 'nullable|string',
            'specifications' => 'nullable|string',
            'warnings_precautions' => 'nullable|string',
            'bead_count' => 'nullable|string|max:255',
            'bead_size' => 'nullable|string|max:255',
            'seed_type' => 'nullable|string|max:255',
            'thread_type' => 'nullable|string|max:255',
            'origin' => 'nullable|string|max:255',
            'option_names' => 'nullable|array|max:3',
            'option_names.*' => 'required|string|max:50',
            'variants' => 'nullable|array|max:250',
            'variants.*.id' => 'nullable|integer',
            'variants.*.title' => 'required_with:variants|string|max:255',
            'variants.*.sku' => 'nullable|string|max:100',
            'variants.*.option_values' => 'nullable|array',
            'variants.*.price' => 'required_with:variants|numeric|min:0',
            'variants.*.compare_at_price' => 'nullable|numeric|min:0',
            'variants.*.stock_quantity' => 'nullable|integer|min:0',
            'variants.*.status' => 'nullable|boolean',
            'variants.*.position' => 'nullable|integer|min:0',
            'image' => 'nullable|image|mimes:jpeg,png,jpg,webp|max:2048',
            'translations' => 'nullable|array',
        ];
    }

    private function fillProduct(Product $product, array $validated): void
    {
        $product->fill([
            'category_id' => $validated['category_id'],
            'guide_blog_id' => $validated['guide_blog_id'] ?? null,
            'name' => trim($validated['name']),
            'price' => $validated['price'],
            'unit' => $this->nullableText($validated['unit'] ?? null),
            'description' => $this->nullableText($validated['description'] ?? null),
            'benefits' => $this->nullableText($validated['benefits'] ?? null),
            'specifications' => $this->nullableText($validated['specifications'] ?? null),
            'warnings_precautions' => $this->nullableText($validated['warnings_precautions'] ?? null),
            'bead_count' => $this->nullableText($validated['bead_count'] ?? null),
            'bead_size' => $this->nullableText($validated['bead_size'] ?? null),
            'seed_type' => $this->nullableText($validated['seed_type'] ?? null),
            'thread_type' => $this->nullableText($validated['thread_type'] ?? null),
            'origin' => $this->nullableText($validated['origin'] ?? null),
            'translations' => $validated['translations'] ?? $product->translations,
            'option_names' => array_values($validated['option_names'] ?? []),
        ]);
    }

    private function normalizeVariantPayload(Request $request): void
    {
        foreach (['option_names', 'variants', 'translations'] as $key) {
            $this->normalizeJsonField($request, $key);
        }
    }

    private function normalizeJsonField(Request $request, string $key): void
    {
        $value = $request->input($key);
        if (is_string($value)) {
            $decoded = json_decode($value, true);
            $request->merge([$key => is_array($decoded) ? $decoded : []]);
        }
    }

    private function syncVariants(Product $product, array $variants): void
    {
        $keptIds = [];

        foreach (array_values($variants) as $position => $variantData) {
            $variantId = isset($variantData['id']) ? (int) $variantData['id'] : null;
            $variant = $variantId
                ? $product->variants()->whereKey($variantId)->first()
                : $product->variants()->make();

            if (!$variant) {
                continue;
            }

            $variant->fill([
                'title' => trim($variantData['title']),
                'sku' => $this->nullableText($variantData['sku'] ?? null),
                'option_values' => $variantData['option_values'] ?? [],
                'price' => $variantData['price'],
                'compare_at_price' => $variantData['compare_at_price'] ?? null,
                'stock_quantity' => $variantData['stock_quantity'] ?? 0,
                'status' => array_key_exists('status', $variantData) ? (bool) $variantData['status'] : true,
                'position' => $variantData['position'] ?? $position,
            ]);
            $variant->save();
            $keptIds[] = $variant->id;
        }

        $product->variants()
            ->when($keptIds, fn ($query) => $query->whereNotIn('id', $keptIds))
            ->delete();

        if ($variants !== []) {
            $lowestPrice = $product->variants()->where('status', true)->min('price');
            if ($lowestPrice !== null && (float) $product->price !== (float) $lowestPrice) {
                $product->update(['price' => $lowestPrice]);
            }
        }
    }

    private function nullableText(mixed $value): ?string
    {
        if ($value === null) {
            return null;
        }

        $value = trim((string) $value);

        return $value === '' ? null : $value;
    }
}
