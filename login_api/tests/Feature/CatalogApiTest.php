<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Product;
use App\Models\ProductVariant;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CatalogApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_public_catalog_only_returns_active_products_in_active_categories(): void
    {
        $activeCategory = Category::create(['name' => 'Active', 'status' => true]);
        $inactiveCategory = Category::create(['name' => 'Inactive', 'status' => false]);

        $visibleProduct = Product::create([
            'category_id' => $activeCategory->id,
            'name' => 'Visible product',
            'price' => 100,
            'status' => true,
        ]);

        Product::create([
            'category_id' => $activeCategory->id,
            'name' => 'Inactive product',
            'price' => 100,
            'status' => false,
        ]);

        Product::create([
            'category_id' => $inactiveCategory->id,
            'name' => 'Hidden category product',
            'price' => 100,
            'status' => true,
        ]);

        ProductVariant::create([
            'product_id' => $visibleProduct->id,
            'title' => 'Small',
            'sku' => 'VISIBLE-S',
            'option_values' => ['Size' => 'Small'],
            'price' => 95,
            'stock_quantity' => 5,
            'status' => true,
        ]);

        ProductVariant::create([
            'product_id' => $visibleProduct->id,
            'title' => 'Large',
            'sku' => 'HIDDEN-L',
            'option_values' => ['Size' => 'Large'],
            'price' => 105,
            'stock_quantity' => 5,
            'status' => false,
        ]);

        $this->getJson('/api/ecomm/products')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.name', 'Visible product')
            ->assertJsonCount(1, 'data.0.active_variants')
            ->assertJsonPath('data.0.active_variants.0.sku', 'VISIBLE-S');
    }

    public function test_admin_catalog_routes_require_an_admin_user(): void
    {
        $this->getJson('/api/admin/ecomm/products')->assertUnauthorized();

        Sanctum::actingAs(User::factory()->create(['role' => 'user']));
        $this->getJson('/api/admin/ecomm/products')->assertForbidden();

        Sanctum::actingAs(User::factory()->create(['role' => 'admin']));
        $this->getJson('/api/admin/ecomm/products')
            ->assertOk()
            ->assertJsonPath('status', 'success');
    }
}
