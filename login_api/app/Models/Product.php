<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'category_id',
        'name',
        'description',
        'benefits',
        'price',
        'unit',
        'specifications',
        'warnings_precautions',
        'image',
        'bead_count',
        'bead_size',
        'seed_type',
        'thread_type',
        'origin',
        'option_names',
        'is_trending',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'price' => 'decimal:2',
            'option_names' => 'array',
            'is_trending' => 'boolean',
            'status' => 'boolean',
        ];
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function variants()
    {
        return $this->hasMany(ProductVariant::class)->orderBy('position');
    }

    public function activeVariants()
    {
        return $this->hasMany(ProductVariant::class)
            ->where('status', true)
            ->orderBy('position');
    }
}
