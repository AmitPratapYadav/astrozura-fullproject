<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Category extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'image',
        'shipping_charge',
        'translations',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'shipping_charge' => 'decimal:2',
            'translations' => 'array',
            'status' => 'boolean',
        ];
    }

    public function products()
    {
        return $this->hasMany(Product::class);
    }
}
