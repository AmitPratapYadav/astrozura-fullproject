<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Http\Request;

class EcommController extends Controller
{
    /**
     * Get all active categories
     */
    public function getCategories()
    {
        $categories = Category::where('status', 1)->get();
        
        return response()->json([
            'status' => 'success',
            'data' => $categories
        ]);
    }

    /**
     * Get trending products for the homepage
     */
    public function getTrendingProducts()
    {
        $products = Product::where('status', 1)
                           ->whereHas('category', fn ($query) => $query->where('status', 1))
                           ->where('is_trending', 1)
                           ->with(['category', 'activeVariants'])
                           ->get();
        
        return response()->json([
            'status' => 'success',
            'data' => $products
        ]);
    }

    /**
     * Get all active products (used for featured/general listing)
     */
    public function getAllProducts()
    {
        $products = Product::where('status', 1)
                           ->whereHas('category', fn ($query) => $query->where('status', 1))
                           ->with(['category', 'activeVariants'])
                           ->latest()
                           ->get();
        
        return response()->json([
            'status' => 'success',
            'data' => $products
        ]);
    }

    /**
     * Get one active product for the public shop.
     */
    public function getProduct($id)
    {
        $product = Product::where('status', 1)
            ->whereHas('category', fn ($query) => $query->where('status', 1))
            ->with(['category', 'activeVariants'])
            ->find($id);

        if (!$product) {
            return response()->json([
                'status' => 'error',
                'message' => 'Product not found',
            ], 404);
        }

        return response()->json([
            'status' => 'success',
            'data' => $product,
        ]);
    }
}
