<?php

namespace Tests\Feature;

use App\Models\AstrologerDetail;
use App\Models\Category;
use App\Models\Product;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\ProductReview;
use App\Models\User;
use App\Models\UserAddress;
use App\Services\UserNotificationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CrossPlatformFeaturesTest extends TestCase
{
    use RefreshDatabase;

    public function test_notifications_are_isolated_by_surface(): void
    {
        $user = User::factory()->create(['role' => 'user']);
        $service = app(UserNotificationService::class);
        $service->send($user, 'main', 'profile', 'Main notice', 'Main only');
        $service->send($user, 'shop', 'offer', 'Shop notice', 'Shop only');

        Sanctum::actingAs($user);

        $this->getJson('/api/notifications?surface=main')
            ->assertOk()
            ->assertJsonCount(1, 'data.data')
            ->assertJsonPath('data.data.0.title', 'Main notice');

        $this->getJson('/api/notifications?surface=shop')
            ->assertOk()
            ->assertJsonCount(1, 'data.data')
            ->assertJsonPath('data.data.0.title', 'Shop notice');
    }

    public function test_shipping_is_charged_once_per_distinct_category(): void
    {
        $firstCategory = Category::create(['name' => 'Gemstones', 'shipping_charge' => 80, 'status' => true]);
        $secondCategory = Category::create(['name' => 'Books', 'shipping_charge' => 40, 'status' => true]);
        $firstProduct = Product::create(['category_id' => $firstCategory->id, 'name' => 'Ruby', 'price' => 1000, 'status' => true]);
        $secondProduct = Product::create(['category_id' => $firstCategory->id, 'name' => 'Emerald', 'price' => 500, 'status' => true]);
        $thirdProduct = Product::create(['category_id' => $secondCategory->id, 'name' => 'Panchang', 'price' => 200, 'status' => true]);

        $this->postJson('/api/ecomm/shipping-quote', ['items' => [
            ['id' => $firstProduct->id, 'qty' => 2],
            ['id' => $secondProduct->id, 'qty' => 1],
            ['id' => $thirdProduct->id, 'qty' => 3],
        ]])
            ->assertOk()
            ->assertJsonPath('data.shipping_amount', 120)
            ->assertJsonCount(2, 'data.shipping_breakdown')
            ->assertJsonPath('data.subtotal_amount', 3100)
            ->assertJsonPath('data.tax_amount', 372);
    }

    public function test_offline_and_unsupported_astrologers_reject_bookings(): void
    {
        $astrologer = User::factory()->create(['role' => 'astrologer']);
        AstrologerDetail::create([
            'user_id' => $astrologer->id,
            'chat_price' => 10,
            'call_price' => 15,
            'supports_chat' => true,
            'supports_call' => false,
            'is_online' => false,
        ]);

        $query = http_build_query([
            'astrologer_id' => $astrologer->id,
            'consultation_type' => 'chat',
            'duration' => 10,
            'booking_date' => now()->addDay()->toDateString(),
        ]);
        $this->getJson("/api/bookings/availability?{$query}")
            ->assertStatus(422)
            ->assertJsonPath('message', 'This astrologer is currently unavailable.');

        $astrologer->astrologerDetail()->update(['is_online' => true]);
        $query = str_replace('consultation_type=chat', 'consultation_type=call', $query);
        $this->getJson("/api/bookings/availability?{$query}")
            ->assertStatus(422)
            ->assertJsonPath('message', 'This astrologer is not available for call consultations.');
    }

    public function test_newsletter_sources_and_address_ownership_are_enforced(): void
    {
        $this->postJson('/api/newsletter/subscribe', ['email' => 'reader@example.com', 'source' => 'main'])->assertOk();
        $this->postJson('/api/newsletter/subscribe', ['email' => 'reader@example.com', 'source' => 'shop'])->assertOk();
        $this->assertDatabaseCount('newsletter_subscribers', 2);

        $owner = User::factory()->create(['role' => 'user']);
        $other = User::factory()->create(['role' => 'user']);
        $address = UserAddress::create([
            'user_id' => $owner->id,
            'label' => 'Home',
            'recipient_name' => $owner->name,
            'phone' => '9548046986',
            'address_line' => 'Ujhani',
            'city' => 'Budaun',
            'state' => 'Uttar Pradesh',
            'postal_code' => '243639',
            'country' => 'India',
        ]);

        Sanctum::actingAs($other);
        $this->deleteJson("/api/dashboard/addresses/{$address->id}")->assertForbidden();
        $this->assertDatabaseHas('user_addresses', ['id' => $address->id]);
    }

    public function test_admin_analytics_runs_on_the_test_database_driver(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => 'admin']));

        $this->getJson('/api/admin/analytics?period=month')
            ->assertOk()
            ->assertJsonPath('status', 'success')
            ->assertJsonStructure(['totals', 'series' => ['bookings', 'orders', 'rituals']]);
    }

    public function test_profile_image_upload_works_without_resubmitting_birth_date_or_time(): void
    {
        config(['media.disk' => 's3']);
        Storage::fake('s3');
        $user = User::factory()->create(['role' => 'user', 'date_of_birth' => '1990-01-02', 'time_of_birth' => '08:30:00']);
        Sanctum::actingAs($user);

        $response = $this->post('/api/dashboard/profile/update', [
            'name' => $user->name,
            'profile_image' => UploadedFile::fake()->createWithContent(
                'avatar.png',
                base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=')
            ),
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('status', 'success');

        $this->assertNotEmpty($response->json('data.profile_image'));
        $this->assertCount(1, Storage::disk('s3')->allFiles('user-profiles'));
        $this->assertSame('1990-01-02', substr((string) $user->fresh()->date_of_birth, 0, 10));
    }

    public function test_admin_profile_image_upload_is_stored_on_the_media_disk(): void
    {
        config(['media.disk' => 's3']);
        Storage::fake('s3');
        $admin = User::factory()->create(['role' => 'admin', 'name' => 'Admin User']);
        Sanctum::actingAs($admin);

        $response = $this->post('/api/admin/profile/update', [
            'firstName' => 'Admin',
            'lastName' => 'User',
            'email' => $admin->email,
            'password' => 'NewSecurePassword123',
            'profile_image' => UploadedFile::fake()->createWithContent(
                'admin.png',
                base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=')
            ),
        ]);

        $response->assertOk()->assertJsonPath('success', true);
        $this->assertCount(1, Storage::disk('s3')->allFiles('admin-profiles'));
        $this->assertSame($response->json('user.profile_image'), $admin->fresh()->profile_image);
        $this->assertTrue(Hash::check('NewSecurePassword123', $admin->fresh()->password));
    }

    public function test_duration_price_override_is_used_for_booking_quotes(): void
    {
        $astrologer = User::factory()->create(['role' => 'astrologer']);
        AstrologerDetail::create([
            'user_id' => $astrologer->id,
            'chat_price' => 10,
            'call_price' => 15,
            'chat_duration_prices' => ['10' => 75],
            'supports_chat' => true,
            'supports_call' => true,
            'is_online' => true,
        ]);

        $query = http_build_query([
            'astrologer_id' => $astrologer->id,
            'consultation_type' => 'chat',
            'duration' => 10,
            'booking_date' => now()->addDay()->toDateString(),
        ]);

        $this->getJson("/api/bookings/availability?{$query}")
            ->assertOk()
            ->assertJsonPath('amount', 75)
            ->assertJsonPath('rate_per_minute', 7.5);
    }

    public function test_only_customers_who_ordered_a_product_can_review_it(): void
    {
        $category = Category::create(['name' => 'Reviewable', 'status' => true]);
        $product = Product::create(['category_id' => $category->id, 'name' => 'Ruby', 'price' => 1000, 'status' => true]);
        $customer = User::factory()->create(['role' => 'user']);
        $other = User::factory()->create(['role' => 'user']);
        $order = Order::create([
            'user_id' => $customer->id,
            'order_number' => 'TEST-REVIEW-1',
            'total_amount' => 1000,
            'status' => 'completed',
            'payment_status' => 'paid',
        ]);
        OrderItem::create(['order_id' => $order->id, 'product_id' => $product->id, 'quantity' => 1, 'price' => 1000]);

        Sanctum::actingAs($other);
        $this->postJson("/api/ecomm/products/{$product->id}/reviews", ['rating' => 5])->assertForbidden();

        Sanctum::actingAs($customer);
        $this->postJson("/api/ecomm/products/{$product->id}/reviews", [
            'rating' => 5,
            'title' => 'Authentic product',
            'comment' => 'Received in good condition.',
        ])->assertOk();

        $this->assertDatabaseHas('product_reviews', ['user_id' => $customer->id, 'product_id' => $product->id, 'rating' => 5]);
        $this->getJson("/api/ecomm/products/{$product->id}/reviews")
            ->assertOk()
            ->assertJsonPath('summary.average', 5)
            ->assertJsonPath('summary.count', 1);
    }
}
