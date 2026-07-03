<?php

namespace App\Services;

use App\Models\Product;
use App\Models\ProductVariant;
use Illuminate\Validation\ValidationException;

class ShippingQuoteService
{
    public function quote(array $items, bool $lockStock = false): array
    {
        $resolved = collect($items)->map(function (array $item) use ($lockStock) {
            $productQuery = Product::query()
                ->with('category')
                ->whereKey($item['id'])
                ->where('status', true)
                ->whereHas('category', fn ($query) => $query->where('status', true));

            if ($lockStock) {
                $productQuery->lockForUpdate();
            }

            $product = $productQuery->firstOrFail();
            $variant = null;
            $quantity = (int) ($item['qty'] ?? 1);

            if (!empty($item['variant_id'])) {
                $variantQuery = ProductVariant::query()
                    ->whereKey($item['variant_id'])
                    ->where('product_id', $product->id)
                    ->where('status', true);

                if ($lockStock) {
                    $variantQuery->lockForUpdate();
                }

                $variant = $variantQuery->firstOrFail();
                if ($variant->stock_quantity < $quantity) {
                    throw ValidationException::withMessages([
                        'items' => "Insufficient stock for {$product->name} - {$variant->title}.",
                    ]);
                }
            } elseif ($product->activeVariants()->exists()) {
                throw ValidationException::withMessages([
                    'items' => "Please select an option for {$product->name}.",
                ]);
            }

            return [
                'product' => $product,
                'variant' => $variant,
                'quantity' => $quantity,
                'price' => (float) ($variant?->price ?? $product->price),
                'category_id' => $product->category_id,
                'category_name' => $product->category?->name ?: 'Uncategorized',
                'shipping_charge' => (float) ($product->category?->shipping_charge ?? 0),
            ];
        });

        $subtotal = round($resolved->sum(fn ($item) => $item['price'] * $item['quantity']), 2);
        $breakdown = $resolved
            ->unique('category_id')
            ->values()
            ->map(fn ($item) => [
                'category_id' => $item['category_id'],
                'category_name' => $item['category_name'],
                'amount' => round($item['shipping_charge'], 2),
            ])
            ->all();
        $shipping = round(collect($breakdown)->sum('amount'), 2);
        $tax = round($subtotal * 0.12, 2);

        return [
            'resolved_items' => $resolved,
            'subtotal_amount' => $subtotal,
            'shipping_amount' => $shipping,
            'tax_amount' => $tax,
            'total_amount' => round($subtotal + $shipping + $tax, 2),
            'shipping_breakdown' => $breakdown,
        ];
    }
}
