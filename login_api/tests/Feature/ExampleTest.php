<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ExampleTest extends TestCase
{
    use RefreshDatabase;

    /**
     * A basic test example.
     */
    public function test_the_public_catalog_categories_endpoint_is_available(): void
    {
        $response = $this->getJson('/api/ecomm/categories');

        $response
            ->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure(['data']);
    }
}
