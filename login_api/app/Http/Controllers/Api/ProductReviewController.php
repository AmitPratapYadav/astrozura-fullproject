<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\OrderItem;
use App\Models\Product;
use App\Models\ProductReview;
use Illuminate\Http\Request;

class ProductReviewController extends Controller
{
    public function index(Product $product)
    {
        $reviews = $product->reviews()
            ->with('user:id,name,profile_image')
            ->latest()
            ->paginate(20);

        return response()->json([
            'status' => 'success',
            'data' => $reviews,
            'summary' => [
                'average' => round((float) $product->reviews()->avg('rating'), 1),
                'count' => $product->reviews()->count(),
            ],
        ]);
    }

    public function eligibility(Request $request, Product $product)
    {
        return response()->json([
            'status' => 'success',
            'can_review' => $this->hasEligibleOrder($request->user()->id, $product->id),
            'review' => ProductReview::where('user_id', $request->user()->id)
                ->where('product_id', $product->id)
                ->first(),
        ]);
    }

    public function store(Request $request, Product $product)
    {
        abort_unless($this->hasEligibleOrder($request->user()->id, $product->id), 403, 'Only customers who ordered this product can review it.');

        $validated = $request->validate([
            'rating' => 'required|integer|between:1,5',
            'title' => 'nullable|string|max:120',
            'comment' => 'nullable|string|max:2000',
        ]);

        $review = ProductReview::updateOrCreate(
            ['user_id' => $request->user()->id, 'product_id' => $product->id],
            $validated
        );

        return response()->json([
            'status' => 'success',
            'message' => 'Review saved successfully.',
            'data' => $review->load('user:id,name,profile_image'),
        ]);
    }

    private function hasEligibleOrder(int $userId, int $productId): bool
    {
        return OrderItem::query()
            ->where('product_id', $productId)
            ->whereHas('order', fn ($query) => $query
                ->where('user_id', $userId)
                ->where('status', '!=', 'cancelled')
                ->where(fn ($status) => $status
                    ->where('payment_status', 'paid')
                    ->orWhere('status', 'completed')))
            ->exists();
    }
}
