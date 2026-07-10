<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Product extends Model
{
    use HasFactory;

    protected $fillable = [
        'category_id',
        'guide_blog_id',
        'name',
        'description',
        'benefits',
        'price',
        'unit',
        'specifications',
        'warnings_precautions',
        'image',
        'translations',
        'bead_count',
        'bead_size',
        'seed_type',
        'thread_type',
        'origin',
        'option_names',
        'is_trending',
        'is_new_arrival',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'price' => 'decimal:2',
            'option_names' => 'array',
            'translations' => 'array',
            'is_trending' => 'boolean',
            'is_new_arrival' => 'boolean',
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

    public function reviews()
    {
        return $this->hasMany(ProductReview::class);
    }

    public function guideBlog()
    {
        return $this->belongsTo(Blog::class, 'guide_blog_id');
    }
}
