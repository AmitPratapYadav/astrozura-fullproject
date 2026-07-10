<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class BlogCategory extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'slug',
        'image',
        'translations',
        'status',
        'sort_order',
        'show_on_main',
        'show_on_shop',
    ];

    protected $casts = [
        'status' => 'boolean',
        'sort_order' => 'integer',
        'show_on_main' => 'boolean',
        'show_on_shop' => 'boolean',
        'translations' => 'array',
    ];

    public function blogs()
    {
        return $this->hasMany(Blog::class);
    }
}
