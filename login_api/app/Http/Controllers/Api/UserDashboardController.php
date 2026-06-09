<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\AdminNotification;
use App\Models\Wishlist;
use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;

class UserDashboardController extends Controller
{
    /**
     * Get the authenticated user's profile.
     */
    public function getProfile(Request $request)
    {
        return response()->json([
            'status' => 'success',
            'data' => $request->user()
        ]);
    }

    /**
     * Update the authenticated user's profile.
     */
    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:20|unique:users,phone,' . $user->id,
            'email' => 'nullable|email|unique:users,email,' . $user->id,
            'date_of_birth' => 'nullable|date',
            'time_of_birth' => 'nullable|date_format:H:i',
            'place_of_birth' => 'nullable|string|max:255',
            'gender' => 'nullable|in:Male,Female,Other',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first()
            ], 422);
        }

        $payload = collect($validator->validated())
            ->map(function ($value) {
                return $value === '' ? null : $value;
            })
            ->toArray();

        if (empty($payload['place_of_birth'])) {
            $payload['latitude'] = null;
            $payload['longitude'] = null;
        }

        $user->update($payload);

        return response()->json([
            'status' => 'success',
            'message' => 'Profile updated successfully',
            'data' => $user->fresh()
        ]);
    }

    /**
     * Get the authenticated user's orders.
     */
    public function getOrders(Request $request)
    {
        $orders = Order::with('items.product')
            ->where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $orders
        ]);
    }

    /**
     * Get the authenticated user's wishlist.
     */
    public function getWishlist(Request $request)
    {
        $wishlist = Wishlist::with(['product' => function ($query) {
            $query->with('activeVariants');
        }])
            ->where('user_id', $request->user()->id)
            ->get()
            ->pluck('product');

        return response()->json([
            'status' => 'success',
            'data' => $wishlist
        ]);
    }

    /**
     * Toggle a product in the user's wishlist.
     */
    public function toggleWishlist(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'product_id' => 'required|exists:products,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first()
            ], 422);
        }

        $user = $request->user();
        $productId = $request->product_id;

        $exists = Wishlist::where('user_id', $user->id)
            ->where('product_id', $productId)
            ->first();

        if ($exists) {
            $exists->delete();
            $message = 'Removed from wishlist';
            $inWishlist = false;
        } else {
            Wishlist::create([
                'user_id' => $user->id,
                'product_id' => $productId
            ]);
            $message = 'Added to wishlist';
            $inWishlist = true;
        }

        return response()->json([
            'status' => 'success',
            'message' => $message,
            'in_wishlist' => $inWishlist
        ]);
    }

    /**
     * Store a new order from checkout.
     */
    public function storeOrder(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'total_amount' => 'required|numeric',
            'payment_method' => 'required|string',
            'shipping_address' => 'required|string',
            'phone' => 'required|string',
            'items' => 'required|array|min:1',
            'items.*.id' => 'required|exists:products,id',
            'items.*.variant_id' => 'nullable|exists:product_variants,id',
            'items.*.qty' => 'required|integer|min:1',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first()
            ], 422);
        }

        $user = $request->user();
        
        // Use database transaction
        return \DB::transaction(function () use ($request, $user) {
            $resolvedItems = collect($request->items)->map(function (array $item) {
                $product = Product::query()
                    ->whereKey($item['id'])
                    ->where('status', true)
                    ->whereHas('category', fn ($query) => $query->where('status', true))
                    ->firstOrFail();

                $variant = null;
                if (!empty($item['variant_id'])) {
                    $variant = ProductVariant::query()
                        ->whereKey($item['variant_id'])
                        ->where('product_id', $product->id)
                        ->where('status', true)
                        ->lockForUpdate()
                        ->firstOrFail();

                    if ($variant->stock_quantity < (int) $item['qty']) {
                        abort(422, "Insufficient stock for {$product->name} - {$variant->title}.");
                    }
                } elseif ($product->activeVariants()->exists()) {
                    abort(422, "Please select an option for {$product->name}.");
                }

                return [
                    'product' => $product,
                    'variant' => $variant,
                    'quantity' => (int) $item['qty'],
                    'price' => (float) ($variant?->price ?? $product->price),
                ];
            });

            $subtotal = $resolvedItems->sum(fn ($item) => $item['price'] * $item['quantity']);
            $shipping = $subtotal > 500 ? 0 : 40;
            $total = round($subtotal + $shipping + ($subtotal * 0.12), 2);

            $order = Order::create([
                'user_id' => $user->id,
                'order_number' => 'ORD-' . strtoupper(Str::random(8)),
                'total_amount' => $total,
                'status' => 'pending',
                'payment_status' => $request->payment_method === 'cod' ? 'unpaid' : 'paid',
                'payment_method' => $request->payment_method,
                'shipping_address' => $request->shipping_address,
                'phone' => $request->phone,
                'notes' => $request->notes,
            ]);

            foreach ($resolvedItems as $item) {
                $order->items()->create([
                    'product_id' => $item['product']->id,
                    'product_variant_id' => $item['variant']?->id,
                    'variant_title' => $item['variant']?->title,
                    'sku' => $item['variant']?->sku,
                    'quantity' => $item['quantity'],
                    'price' => $item['price'],
                ]);

                if ($item['variant']) {
                    $item['variant']->decrement('stock_quantity', $item['quantity']);
                }
            }

            AdminNotification::create([
                'type' => 'product_order',
                'title' => 'New product order',
                'message' => "{$order->order_number} was placed by {$user->name} for Rs " . number_format($total, 2),
                'route' => '/orders',
                'data' => ['order_id' => $order->id],
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'Order placed successfully',
                'order' => $order->load(['items.product', 'items.variant'])
            ]);
        });
    }
}
