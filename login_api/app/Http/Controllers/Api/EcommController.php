<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Http\Request;
use App\Services\ShippingQuoteService;

class EcommController extends Controller
{
    /**
     * Get all active categories
     */
    public function getCategories(Request $request)
    {
        $categories = Category::where('status', 1)->get();
        $this->localize($categories, $request->query('la'));
        
        return response()->json([
            'status' => 'success',
            'data' => $categories
        ]);
    }

    /**
     * Get trending products for the homepage
     */
    public function getTrendingProducts(Request $request)
    {
        $products = Product::where('status', 1)
                           ->whereHas('category', fn ($query) => $query->where('status', 1))
                           ->where('is_trending', 1)
                           ->with(['category', 'activeVariants'])
                           ->withAvg('reviews', 'rating')
                           ->withCount('reviews')
                           ->get();
        $this->localize($products, $request->query('la'));
        $this->localize($products->pluck('category')->filter(), $request->query('la'));
        
        return response()->json([
            'status' => 'success',
            'data' => $products
        ]);
    }

    /**
     * Get all active products (used for featured/general listing)
     */
    public function getAllProducts(Request $request)
    {
        $products = Product::where('status', 1)
                           ->whereHas('category', fn ($query) => $query->where('status', 1))
                           ->with(['category', 'activeVariants'])
                           ->withAvg('reviews', 'rating')
                           ->withCount('reviews')
                           ->when($request->filled('q'), function ($query) use ($request) {
                               $term = trim($request->query('q'));
                               $query->where(function ($builder) use ($term) {
                                   $builder->where('name', 'like', "%{$term}%")
                                       ->orWhere('description', 'like', "%{$term}%");
                               });
                           })
                           ->when($request->filled('category'), fn ($query) => $query->where('category_id', $request->query('category')))
                           ->latest()
                           ->get();
        $this->localize($products, $request->query('la'));
        $this->localize($products->pluck('category')->filter(), $request->query('la'));
        
        return response()->json([
            'status' => 'success',
            'data' => $products
        ]);
    }

    /**
     * Get one active product for the public shop.
     */
    public function getProduct(Request $request, $id)
    {
        $product = Product::where('status', 1)
            ->whereHas('category', fn ($query) => $query->where('status', 1))
            ->with(['category', 'activeVariants'])
            ->withAvg('reviews', 'rating')
            ->withCount('reviews')
            ->find($id);

        if (!$product) {
            return response()->json([
                'status' => 'error',
                'message' => 'Product not found',
            ], 404);
        }
        $this->localize(collect([$product, $product->category])->filter(), $request->query('la'));

        return response()->json([
            'status' => 'success',
            'data' => $product,
        ]);
    }

    public function shippingQuote(Request $request, ShippingQuoteService $shippingQuotes)
    {
        $validated = $request->validate([
            'items' => 'required|array|min:1',
            'items.*.id' => 'required|exists:products,id',
            'items.*.variant_id' => 'nullable|exists:product_variants,id',
            'items.*.qty' => 'required|integer|min:1',
        ]);

        $quote = $shippingQuotes->quote($validated['items']);
        unset($quote['resolved_items']);

        return response()->json(['status' => 'success', 'data' => $quote]);
    }

    private function localize($models, ?string $language): void
    {
        if ($language !== 'hi') {
            return;
        }

        foreach ($models as $model) {
            if (!$model) {
                continue;
            }

            $translations = $model->translations['hi'] ?? [];
            foreach ($translations as $field => $value) {
                if ($value !== null && $value !== '') {
                    $model->setAttribute($field, $value);
                }
            }
        }
    }
}
