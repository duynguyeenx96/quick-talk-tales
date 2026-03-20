-- Quick Talk Tales Database Schema
-- PostgreSQL Database Schema for Story Management System

-- Create database
CREATE DATABASE quick_talk_tales;

-- Use the database
\c quick_talk_tales;

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create custom types
CREATE TYPE user_role AS ENUM ('admin', 'author', 'reader');
CREATE TYPE story_status AS ENUM ('draft', 'published', 'archived');
CREATE TYPE chapter_type AS ENUM ('text', 'interactive', 'multimedia');
CREATE TYPE difficulty_level AS ENUM ('beginner', 'intermediate', 'advanced');

-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100),
    avatar_url VARCHAR(500),
    role user_role DEFAULT 'reader',
    is_active BOOLEAN DEFAULT true,
    email_verified BOOLEAN DEFAULT false,
    preferences JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Categories table
CREATE TABLE categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    slug VARCHAR(100) UNIQUE NOT NULL,
    color VARCHAR(7) DEFAULT '#007bff',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Tags table
CREATE TABLE tags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(50) UNIQUE NOT NULL,
    slug VARCHAR(50) UNIQUE NOT NULL,
    usage_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Stories table
CREATE TABLE stories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(200) UNIQUE NOT NULL,
    description TEXT,
    cover_image_url VARCHAR(500),
    author_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    status story_status DEFAULT 'draft',
    difficulty difficulty_level DEFAULT 'beginner',
    estimated_reading_time INTEGER, -- in minutes
    is_featured BOOLEAN DEFAULT false,
    is_interactive BOOLEAN DEFAULT false,
    view_count INTEGER DEFAULT 0,
    rating DECIMAL(3,2) DEFAULT 0.00,
    rating_count INTEGER DEFAULT 0,
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Story tags junction table
CREATE TABLE story_tags (
    story_id UUID REFERENCES stories(id) ON DELETE CASCADE,
    tag_id UUID REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (story_id, tag_id)
);

-- Chapters table
CREATE TABLE chapters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    story_id UUID NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    slug VARCHAR(200) NOT NULL,
    content TEXT NOT NULL,
    chapter_type chapter_type DEFAULT 'text',
    order_index INTEGER NOT NULL,
    is_published BOOLEAN DEFAULT false,
    word_count INTEGER DEFAULT 0,
    reading_time INTEGER DEFAULT 0, -- in minutes
    metadata JSONB DEFAULT '{}', -- For interactive choices, media urls, etc.
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(story_id, slug),
    UNIQUE(story_id, order_index)
);

-- User story progress table
CREATE TABLE user_story_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    story_id UUID NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
    current_chapter_id UUID REFERENCES chapters(id) ON DELETE SET NULL,
    progress_percentage DECIMAL(5,2) DEFAULT 0.00,
    reading_time INTEGER DEFAULT 0, -- total reading time in minutes
    bookmarked BOOLEAN DEFAULT false,
    favorite BOOLEAN DEFAULT false,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_read_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, story_id)
);

-- User chapter progress table (for detailed tracking)
CREATE TABLE user_chapter_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    chapter_id UUID NOT NULL REFERENCES chapters(id) ON DELETE CASCADE,
    story_id UUID NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
    is_completed BOOLEAN DEFAULT false,
    reading_time INTEGER DEFAULT 0, -- time spent reading this chapter in seconds
    choices_made JSONB DEFAULT '[]', -- for interactive chapters
    last_position INTEGER DEFAULT 0, -- last reading position in the chapter
    read_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(user_id, chapter_id)
);

-- User ratings table
CREATE TABLE user_ratings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    story_id UUID NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    review TEXT,
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(user_id, story_id)
);

-- Comments table
CREATE TABLE comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    story_id UUID REFERENCES stories(id) ON DELETE CASCADE,
    chapter_id UUID REFERENCES chapters(id) ON DELETE CASCADE,
    parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_approved BOOLEAN DEFAULT true,
    like_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CHECK (story_id IS NOT NULL OR chapter_id IS NOT NULL)
);

-- User sessions table (for JWT refresh tokens)
CREATE TABLE user_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    refresh_token_hash VARCHAR(255) NOT NULL,
    device_info JSONB DEFAULT '{}',
    ip_address INET,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    last_used_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Notifications table
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'new_chapter', 'story_update', 'comment', etc.
    data JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_role ON users(role);

CREATE INDEX idx_stories_author_id ON stories(author_id);
CREATE INDEX idx_stories_category_id ON stories(category_id);
CREATE INDEX idx_stories_status ON stories(status);
CREATE INDEX idx_stories_published_at ON stories(published_at);
CREATE INDEX idx_stories_is_featured ON stories(is_featured);
CREATE INDEX idx_stories_slug ON stories(slug);

CREATE INDEX idx_chapters_story_id ON chapters(story_id);
CREATE INDEX idx_chapters_order_index ON chapters(story_id, order_index);
CREATE INDEX idx_chapters_slug ON chapters(story_id, slug);

CREATE INDEX idx_user_story_progress_user_id ON user_story_progress(user_id);
CREATE INDEX idx_user_story_progress_story_id ON user_story_progress(story_id);
CREATE INDEX idx_user_story_progress_bookmarked ON user_story_progress(user_id, bookmarked);
CREATE INDEX idx_user_story_progress_favorite ON user_story_progress(user_id, favorite);

CREATE INDEX idx_user_chapter_progress_user_id ON user_chapter_progress(user_id);
CREATE INDEX idx_user_chapter_progress_chapter_id ON user_chapter_progress(chapter_id);
CREATE INDEX idx_user_chapter_progress_story_id ON user_chapter_progress(story_id);

CREATE INDEX idx_user_ratings_user_id ON user_ratings(user_id);
CREATE INDEX idx_user_ratings_story_id ON user_ratings(story_id);

CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_comments_story_id ON comments(story_id);
CREATE INDEX idx_comments_chapter_id ON comments(chapter_id);
CREATE INDEX idx_comments_parent_id ON comments(parent_comment_id);

CREATE INDEX idx_user_sessions_user_id ON user_sessions(user_id);
CREATE INDEX idx_user_sessions_expires_at ON user_sessions(expires_at);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_is_read ON notifications(user_id, is_read);

-- Create triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_categories_updated_at BEFORE UPDATE ON categories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_stories_updated_at BEFORE UPDATE ON stories FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_chapters_updated_at BEFORE UPDATE ON chapters FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_ratings_updated_at BEFORE UPDATE ON user_ratings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON comments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Create function to update story rating
CREATE OR REPLACE FUNCTION update_story_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE stories 
    SET rating = (
        SELECT COALESCE(AVG(rating::decimal), 0)
        FROM user_ratings 
        WHERE story_id = COALESCE(NEW.story_id, OLD.story_id)
    ),
    rating_count = (
        SELECT COUNT(*)
        FROM user_ratings 
        WHERE story_id = COALESCE(NEW.story_id, OLD.story_id)
    )
    WHERE id = COALESCE(NEW.story_id, OLD.story_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_update_story_rating 
    AFTER INSERT OR UPDATE OR DELETE ON user_ratings 
    FOR EACH ROW EXECUTE FUNCTION update_story_rating();

-- Create function to update tag usage count
CREATE OR REPLACE FUNCTION update_tag_usage_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE tags SET usage_count = usage_count + 1 WHERE id = NEW.tag_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE tags SET usage_count = usage_count - 1 WHERE id = OLD.tag_id;
        RETURN OLD;
    END IF;
    RETURN NULL;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_update_tag_usage_count 
    AFTER INSERT OR DELETE ON story_tags 
    FOR EACH ROW EXECUTE FUNCTION update_tag_usage_count();