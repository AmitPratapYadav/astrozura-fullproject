<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class ProductVariant extends Model
{
    use HasFactory;

    protected $fillable = [
        'product_id',
        'title',
        'sku',
        'option_values',
        'price',
        'compare_at_price',
        'stock_quantity',
        'image',
        'status',
        'position',
    ];

    protected function casts(): array
    {
        return [
            'option_values' => 'array',
            'price' => 'decimal:2',
            'compare_at_price' => 'decimal:2',
            'stock_quantity' => 'integer',
            'status' => 'boolean',
            'position' => 'integer',
        ];
    }

    public function product()
    {
        return $this->belongsTo(Product::class);
    }
}
