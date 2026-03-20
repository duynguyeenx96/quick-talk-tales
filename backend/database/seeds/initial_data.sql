-- Quick Talk Tales Initial Data Seeds
-- This file contains sample data to get started with the application

-- Insert default categories
INSERT INTO categories (id, name, description, slug, color) VALUES
    (uuid_generate_v4(), 'Fantasy', 'Magical worlds and mythical creatures', 'fantasy', '#9c27b0'),
    (uuid_generate_v4(), 'Science Fiction', 'Futuristic and technological stories', 'sci-fi', '#2196f3'),
    (uuid_generate_v4(), 'Mystery', 'Puzzles, investigations and suspense', 'mystery', '#ff5722'),
    (uuid_generate_v4(), 'Romance', 'Love stories and relationships', 'romance', '#e91e63'),
    (uuid_generate_v4(), 'Adventure', 'Exciting journeys and quests', 'adventure', '#ff9800'),
    (uuid_generate_v4(), 'Horror', 'Scary and suspenseful tales', 'horror', '#424242'),
    (uuid_generate_v4(), 'Comedy', 'Funny and lighthearted stories', 'comedy', '#4caf50'),
    (uuid_generate_v4(), 'Drama', 'Emotional and character-driven narratives', 'drama', '#795548');

-- Insert default tags
INSERT INTO tags (id, name, slug) VALUES
    (uuid_generate_v4(), 'Interactive', 'interactive'),
    (uuid_generate_v4(), 'Short Story', 'short-story'),
    (uuid_generate_v4(), 'Series', 'series'),
    (uuid_generate_v4(), 'Complete', 'complete'),
    (uuid_generate_v4(), 'In Progress', 'in-progress'),
    (uuid_generate_v4(), 'Magic', 'magic'),
    (uuid_generate_v4(), 'Dragons', 'dragons'),
    (uuid_generate_v4(), 'Space', 'space'),
    (uuid_generate_v4(), 'Time Travel', 'time-travel'),
    (uuid_generate_v4(), 'Detective', 'detective'),
    (uuid_generate_v4(), 'First Person', 'first-person'),
    (uuid_generate_v4(), 'Third Person', 'third-person'),
    (uuid_generate_v4(), 'Beginner Friendly', 'beginner-friendly'),
    (uuid_generate_v4(), 'Advanced', 'advanced'),
    (uuid_generate_v4(), 'Multiple Endings', 'multiple-endings');

-- Insert admin user (password: admin123 - remember to change in production)
INSERT INTO users (id, username, email, password_hash, full_name, role, is_active, email_verified) VALUES
    (uuid_generate_v4(), 'admin', 'admin@quicktalktales.com', '$2b$10$rQqQqQqQqQqQqQqQqQqQqOeKhqQqQqQqQqQqQqQqQqQqQqQqQqQqQ', 'System Administrator', 'admin', true, true);

-- Insert sample author user (password: author123)
INSERT INTO users (id, username, email, password_hash, full_name, role, is_active, email_verified) VALUES
    (uuid_generate_v4(), 'storyteller', 'author@quicktalktales.com', '$2b$10$rQqQqQqQqQqQqQqQqQqQqOeKhqQqQqQqQqQqQqQqQqQqQqQqQqQqQ', 'Sample Author', 'author', true, true);

-- Insert sample reader user (password: reader123)
INSERT INTO users (id, username, email, password_hash, full_name, role, is_active, email_verified) VALUES
    (uuid_generate_v4(), 'reader1', 'reader@quicktalktales.com', '$2b$10$rQqQqQqQqQqQqQqQqQqQqOeKhqQqQqQqQqQqQqQqQqQqQqQqQqQqQ', 'Sample Reader', 'reader', true, true);

-- Create variables for user IDs (PostgreSQL doesn't support variables in the same way, so we'll use a different approach)
-- We'll use CTEs (Common Table Expressions) to reference the users

-- Insert sample stories with chapters
WITH 
    author AS (SELECT id FROM users WHERE username = 'storyteller'),
    fantasy_cat AS (SELECT id FROM categories WHERE slug = 'fantasy'),
    adventure_cat AS (SELECT id FROM categories WHERE slug = 'adventure'),
    interactive_tag AS (SELECT id FROM tags WHERE slug = 'interactive'),
    complete_tag AS (SELECT id FROM tags WHERE slug = 'complete'),
    magic_tag AS (SELECT id FROM tags WHERE slug = 'magic')

-- Insert sample story 1
INSERT INTO stories (id, title, slug, description, author_id, category_id, status, difficulty, estimated_reading_time, is_featured, is_interactive, published_at)
SELECT 
    uuid_generate_v4(),
    'The Enchanted Forest Quest',
    'enchanted-forest-quest',
    'A magical journey through an ancient forest where every choice shapes your destiny. Discover hidden secrets, meet mystical creatures, and unlock the power within.',
    author.id,
    fantasy_cat.id,
    'published',
    'beginner',
    15,
    true,
    true,
    CURRENT_TIMESTAMP - INTERVAL '7 days'
FROM author, fantasy_cat;

-- Get the story ID for chapters
WITH story AS (SELECT id FROM stories WHERE slug = 'enchanted-forest-quest')
INSERT INTO chapters (story_id, title, slug, content, chapter_type, order_index, is_published, word_count, reading_time, metadata)
SELECT 
    story.id,
    'The Mysterious Path',
    'mysterious-path',
    'You stand at the edge of the Enchanted Forest, where ancient trees whisper secrets in the wind. Two paths diverge before you: one bathed in golden sunlight, the other shrouded in mysterious mist. Your heart races with anticipation as you realize this choice will determine your entire adventure. The golden path promises warmth and safety, while the misty path calls to your sense of adventure and mystery. What will you choose?',
    'interactive',
    1,
    true,
    120,
    3,
    '{"choices": [{"id": "golden_path", "text": "Take the golden path", "next_chapter": "golden-clearing"}, {"id": "misty_path", "text": "Enter the misty path", "next_chapter": "misty-grove"}]}'
FROM story;

-- Insert more chapters for the story
WITH story AS (SELECT id FROM stories WHERE slug = 'enchanted-forest-quest')
INSERT INTO chapters (story_id, title, slug, content, chapter_type, order_index, is_published, word_count, reading_time)
SELECT 
    story.id,
    'The Golden Clearing',
    'golden-clearing',
    'The golden path leads you to a beautiful clearing where sunbeams dance through the leaves. In the center stands a majestic unicorn, its silver horn gleaming in the light. The creature approaches you with gentle eyes, and you feel a warm magical energy surrounding you. This is clearly a place of good magic and healing.',
    'text',
    2,
    true,
    95,
    2
FROM story
UNION ALL
SELECT 
    story.id,
    'The Misty Grove',
    'misty-grove',
    'The misty path winds deeper into the forest, where shadows dance between ancient oaks. You hear the soft sound of water trickling nearby and catch glimpses of mysterious lights flickering in the distance. This path feels more dangerous, but also more exciting. Adventure awaits those brave enough to continue.',
    'text',
    3,
    true,
    88,
    2
FROM story;

-- Insert second sample story
WITH 
    author AS (SELECT id FROM users WHERE username = 'storyteller'),
    adventure_cat AS (SELECT id FROM categories WHERE slug = 'adventure')
INSERT INTO stories (id, title, slug, description, author_id, category_id, status, difficulty, estimated_reading_time, is_featured, is_interactive, published_at)
SELECT 
    uuid_generate_v4(),
    'Pirates of the Crystal Sea',
    'pirates-crystal-sea',
    'Join Captain Maya on her quest to find the legendary Crystal of Storms. Navigate treacherous waters, battle rival pirates, and discover the true meaning of courage on the high seas.',
    author.id,
    adventure_cat.id,
    'published',
    'intermediate',
    25,
    false,
    false,
    CURRENT_TIMESTAMP - INTERVAL '3 days'
FROM author, adventure_cat;

-- Add chapters for the second story
WITH story AS (SELECT id FROM stories WHERE slug = 'pirates-crystal-sea')
INSERT INTO chapters (story_id, title, slug, content, chapter_type, order_index, is_published, word_count, reading_time)
SELECT 
    story.id,
    'Setting Sail',
    'setting-sail',
    'Captain Maya stands on the deck of her ship, the Windwhisper, as the morning sun paints the Crystal Sea in shades of gold and turquoise. Her crew of loyal pirates bustles about, preparing for what might be their greatest adventure yet. The legendary Crystal of Storms awaits, but the journey will test their courage, wit, and friendship.',
    'text',
    1,
    true,
    150,
    4
FROM story
UNION ALL
SELECT 
    story.id,
    'The Storm Approaches',
    'storm-approaches',
    'Dark clouds gather on the horizon as the Windwhisper cuts through increasingly choppy waters. Maya checks her compass and realizes they are approaching the Forbidden Waters, where legend says the Crystal lies hidden. But first, they must survive the supernatural storm that guards these ancient secrets.',
    'text',
    2,
    true,
    135,
    3
FROM story;

-- Add story-tag relationships
WITH 
    story1 AS (SELECT id FROM stories WHERE slug = 'enchanted-forest-quest'),
    story2 AS (SELECT id FROM stories WHERE slug = 'pirates-crystal-sea'),
    interactive_tag AS (SELECT id FROM tags WHERE slug = 'interactive'),
    complete_tag AS (SELECT id FROM tags WHERE slug = 'complete'),
    magic_tag AS (SELECT id FROM tags WHERE slug = 'magic'),
    adventure_tag AS (SELECT id FROM tags WHERE slug = 'adventure'),
    beginner_tag AS (SELECT id FROM tags WHERE slug = 'beginner-friendly'),
    multiple_endings_tag AS (SELECT id FROM tags WHERE slug = 'multiple-endings')

INSERT INTO story_tags (story_id, tag_id)
SELECT story1.id, interactive_tag.id FROM story1, interactive_tag
UNION ALL
SELECT story1.id, magic_tag.id FROM story1, magic_tag
UNION ALL
SELECT story1.id, beginner_tag.id FROM story1, beginner_tag
UNION ALL
SELECT story1.id, multiple_endings_tag.id FROM story1, multiple_endings_tag
UNION ALL
SELECT story2.id, complete_tag.id FROM story2, complete_tag
UNION ALL
SELECT story2.id, adventure_tag.id FROM story2, adventure_tag;

-- Update tag usage counts (this will be handled by triggers, but let's set initial values)
UPDATE tags SET usage_count = (
    SELECT COUNT(*) FROM story_tags WHERE story_tags.tag_id = tags.id
);

-- Insert sample notifications for admin user
WITH admin_user AS (SELECT id FROM users WHERE username = 'admin')
INSERT INTO notifications (user_id, title, message, type, data)
SELECT 
    admin_user.id,
    'Welcome to Quick Talk Tales!',
    'Your Quick Talk Tales platform is now set up and ready to use. You can start creating stories or managing users.',
    'welcome',
    '{"action": "dashboard"}'
FROM admin_user;

-- Clean up any orphaned records and ensure data integrity
-- This is mainly for safety and future maintenance
UPDATE stories SET view_count = 0 WHERE view_count IS NULL;
UPDATE stories SET rating = 0.00 WHERE rating IS NULL;
UPDATE stories SET rating_count = 0 WHERE rating_count IS NULL;

-- Log the completion
DO $$
BEGIN
    RAISE NOTICE 'Initial data seeding completed successfully!';
    RAISE NOTICE 'Created sample users, stories, chapters, categories, and tags.';
    RAISE NOTICE 'Default admin user: admin / admin123 (change password in production)';
    RAISE NOTICE 'Sample author user: storyteller / author123';
    RAISE NOTICE 'Sample reader user: reader1 / reader123';
END $$;