<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Blog extends Model
{
    use HasFactory;

    protected $fillable = [
        'blog_category_id',
        'title',
        'slug',
        'excerpt',
        'cover_image',
        'content_blocks',
        'translations',
        'author_name',
        'status',
        'show_on_main',
        'show_on_shop',
        'published_at',
        'views_count',
        'seo_title',
        'seo_description',
        'seo_keywords',
    ];

    protected $casts = [
        'content_blocks' => 'array',
        'translations' => 'array',
        'status' => 'boolean',
        'show_on_main' => 'boolean',
        'show_on_shop' => 'boolean',
        'published_at' => 'datetime',
        'views_count' => 'integer',
    ];

    public function category()
    {
        return $this->belongsTo(BlogCategory::class, 'blog_category_id');
    }

    public function guidedProducts()
    {
        return $this->hasMany(Product::class, 'guide_blog_id');
    }
}
