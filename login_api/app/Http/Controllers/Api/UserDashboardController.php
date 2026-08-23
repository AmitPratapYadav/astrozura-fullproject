<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Order;
use App\Models\AdminNotification;
use App\Models\Wishlist;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Support\MediaStorage;
use App\Services\ShippingQuoteService;
use App\Services\SmartChatWhatsAppService;
use App\Services\UltronSmsService;
use App\Services\UserNotificationService;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Str;
use Carbon\Carbon;

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
    public function updateProfile(Request $request, UserNotificationService $notifications)
    {
        $user = $request->user();
        $input = $request->all();

        foreach (['date_of_birth', 'time_of_birth', 'place_of_birth', 'gender', 'latitude', 'longitude', 'phone', 'email'] as $field) {
            if (array_key_exists($field, $input) && $input[$field] === '') {
                $input[$field] = null;
            }
        }

        if (!empty($input['date_of_birth'])) {
            try {
                $input['date_of_birth'] = Carbon::parse($input['date_of_birth'])->toDateString();
            } catch (\Throwable $exception) {
                // Let the validator return the date error for unparseable input.
            }
        }

        if (!empty($input['time_of_birth']) && preg_match('/^\d{2}:\d{2}:\d{2}$/', (string) $input['time_of_birth'])) {
            $input['time_of_birth'] = substr((string) $input['time_of_birth'], 0, 5);
        }

        $validator = Validator::make($input, [
            'name' => 'required|string|max:255',
            'phone' => 'nullable|string|max:20|unique:users,phone,' . $user->id,
            'email' => 'nullable|email|unique:users,email,' . $user->id,
            'date_of_birth' => 'nullable|date|before_or_equal:today',
            'time_of_birth' => 'nullable|date_format:H:i',
            'place_of_birth' => 'nullable|string|max:255',
            'gender' => 'nullable|in:Male,Female,Other',
            'latitude' => 'nullable|numeric|between:-90,90',
            'longitude' => 'nullable|numeric|between:-180,180',
            'profile_image' => 'nullable|image|mimes:jpeg,png,jpg,gif,webp|max:4096',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => $validator->errors()->first()
            ], 422);
        }

        $payload = $validator->validated();

        if (empty($payload['place_of_birth'])) {
            $payload['latitude'] = null;
            $payload['longitude'] = null;
        }

        if ($request->hasFile('profile_image')) {
            $payload['profile_image'] = MediaStorage::store($request->file('profile_image'), 'user-profiles');
        }

        $user->update($payload);
        $notifications->send(
            $user,
            'main',
            'profile_updated',
            'Profile updated',
            'Your AstroZura profile details were updated successfully.',
            '/user-profile'
        );

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
        $orders = Order::with(['items.product', 'items.variant'])
            ->where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => $orders
        ]);
    }

    public function getStats(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'status' => 'success',
            'data' => [
                'total_orders' => $user->orders()->count(),
                'pending_orders' => $user->orders()->whereIn('status', ['pending', 'processing'])->count(),
                'wishlist_items' => Wishlist::where('user_id', $user->id)->count(),
            ],
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
    public function storeOrder(
        Request $request,
        ShippingQuoteService $shippingQuotes,
        UserNotificationService $notifications,
        UltronSmsService $sms,
        SmartChatWhatsAppService $whatsapp
    )
    {
        $validator = Validator::make($request->all(), [
            'total_amount' => 'required|numeric',
            'payment_method' => 'required|in:cod,razorpay',
            'shipping_address' => 'required|string',
            'shipping_details' => 'nullable|array',
            'shipping_details.recipient_name' => 'required_with:shipping_details|string|max:255',
            'shipping_details.phone' => 'required_with:shipping_details|string|max:30',
            'shipping_details.address_line' => 'required_with:shipping_details|string|max:500',
            'shipping_details.city' => 'required_with:shipping_details|string|max:120',
            'shipping_details.state' => 'required_with:shipping_details|string|max:120',
            'shipping_details.postal_code' => 'required_with:shipping_details|string|max:20',
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
        return \DB::transaction(function () use ($request, $user, $shippingQuotes, $notifications, $sms, $whatsapp) {
            $quote = $shippingQuotes->quote($request->items, true);
            $resolvedItems = $quote['resolved_items'];
            $total = $quote['total_amount'];

            $order = Order::create([
                'user_id' => $user->id,
                'order_number' => 'ORD-' . strtoupper(Str::random(8)),
                'subtotal_amount' => $quote['subtotal_amount'],
                'shipping_amount' => $quote['shipping_amount'],
                'tax_amount' => $quote['tax_amount'],
                'total_amount' => $total,
                'status' => 'pending',
                'payment_status' => $request->payment_method === 'cod' ? 'unpaid' : 'pending',
                'payment_method' => $request->payment_method,
                'shipping_address' => $request->shipping_address,
                'shipping_breakdown' => $quote['shipping_breakdown'],
                'shipping_details' => $request->shipping_details,
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

            if ($request->payment_method === 'cod') {
                AdminNotification::create([
                    'type' => 'product_order',
                    'title' => 'New product order',
                    'message' => "{$order->order_number} was placed by {$user->name} for Rs " . number_format($total, 2),
                    'route' => '/orders',
                    'data' => ['order_id' => $order->id],
                ]);
            }

            $notifications->send(
                $user,
                'shop',
                'order_placed',
                'Order placed',
                "{$order->order_number} has been placed successfully.",
                "/dashboard/orders/{$order->id}",
                ['order_id' => $order->id]
            );

            $orderSmsSent = $sms->sendOrderReceived(
                (string) ($order->phone ?: $user->phone),
                (string) ($user->name ?: 'User'),
                (string) $order->order_number
            );
            $orderWhatsAppSent = $whatsapp->sendOrderReceived(
                (string) ($order->phone ?: $user->phone),
                (string) ($user->name ?: 'User'),
                (string) $order->order_number
            );
            Log::info('Order received SMS dispatch result.', [
                'order_id' => $order->id,
                'order_number' => $order->order_number,
                'phone_present' => filled($order->phone ?: $user->phone),
                'sent' => $orderSmsSent,
                'whatsapp_sent' => $orderWhatsAppSent,
            ]);

            return response()->json([
                'status' => 'success',
                'message' => 'Order placed successfully',
                'order' => $order->load(['items.product', 'items.variant'])
            ]);
        });
    }
}
