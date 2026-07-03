<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UserAddress;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class UserAddressController extends Controller
{
    public function index(Request $request)
    {
        $addresses = $request->user()->addresses()->orderByDesc('is_default')->latest()->get();
        $recentOrderAddresses = $request->user()->orders()
            ->whereNotNull('shipping_details')
            ->latest()
            ->limit(5)
            ->pluck('shipping_details')
            ->filter()
            ->unique(fn ($item) => json_encode($item))
            ->values();

        return response()->json([
            'status' => 'success',
            'data' => $addresses,
            'recent_order_addresses' => $recentOrderAddresses,
        ]);
    }

    public function store(Request $request)
    {
        $payload = $this->validateAddress($request);

        $address = DB::transaction(function () use ($request, $payload) {
            if (($payload['is_default'] ?? false) || !$request->user()->addresses()->exists()) {
                $request->user()->addresses()->update(['is_default' => false]);
                $payload['is_default'] = true;
            }

            return $request->user()->addresses()->create($payload);
        });

        return response()->json(['status' => 'success', 'data' => $address], 201);
    }

    public function update(Request $request, UserAddress $address)
    {
        abort_unless((int) $address->user_id === (int) $request->user()->id, 403);
        $payload = $this->validateAddress($request, $address);

        DB::transaction(function () use ($request, $address, $payload): void {
            if ($payload['is_default'] ?? false) {
                $request->user()->addresses()->whereKeyNot($address->id)->update(['is_default' => false]);
            }
            $address->update($payload);
        });

        return response()->json(['status' => 'success', 'data' => $address->fresh()]);
    }

    public function destroy(Request $request, UserAddress $address)
    {
        abort_unless((int) $address->user_id === (int) $request->user()->id, 403);
        $wasDefault = $address->is_default;
        $address->delete();

        if ($wasDefault) {
            $request->user()->addresses()->latest()->first()?->update(['is_default' => true]);
        }

        return response()->json(['status' => 'success']);
    }

    private function validateAddress(Request $request, ?UserAddress $address = null): array
    {
        return $request->validate([
            'label' => 'nullable|string|max:50',
            'recipient_name' => 'required|string|max:255',
            'phone' => 'required|string|max:30',
            'address_line' => 'required|string|max:500',
            'city' => 'required|string|max:120',
            'state' => 'required|string|max:120',
            'postal_code' => 'required|string|max:20',
            'country' => ['nullable', 'string', 'max:120', Rule::in(['India'])],
            'is_default' => 'nullable|boolean',
        ]);
    }
}
