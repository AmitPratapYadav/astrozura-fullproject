<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Blog;
use App\Models\BlogCategory;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // User::factory(10)->create();

        User::factory()->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
        ]);

        $category = BlogCategory::firstOrCreate(
            ['slug' => 'vedic-astrology'],
            [
                'name' => 'Vedic Astrology',
                'status' => true,
                'sort_order' => 1,
            ]
        );

        Blog::firstOrCreate(
            ['slug' => 'how-to-read-your-daily-panchang'],
            [
                'blog_category_id' => $category->id,
                'title' => 'How to Read Your Daily Panchang',
                'excerpt' => 'A simple guide to the daily Panchang elements and how they support better timing decisions.',
                'content_blocks' => [
                    [
                        'type' => 'paragraph',
                        'text' => 'Daily Panchang combines tithi, nakshatra, yoga, karana and planetary timing windows to describe the quality of a day.',
                    ],
                    [
                        'type' => 'heading',
                        'text' => 'Start with the core elements',
                    ],
                    [
                        'type' => 'paragraph',
                        'text' => 'Review the tithi and nakshatra first, then use auspicious and inauspicious timings to plan important tasks.',
                    ],
                ],
                'author_name' => 'AstroZura Team',
                'status' => true,
                'published_at' => now(),
                'seo_title' => 'How to Read Daily Panchang',
                'seo_description' => 'Learn the basic Panchang elements and how to read them.',
            ]
        );
    }
}
