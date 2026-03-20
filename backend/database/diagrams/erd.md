# Database Entity Relationship Diagram

## Quick Talk Tales - Database Schema

```mermaid
erDiagram
    USERS {
        uuid id PK
        varchar username UK
        varchar email UK
        varchar password_hash
        varchar full_name
        varchar avatar_url
        user_role role
        boolean is_active
        boolean email_verified
        jsonb preferences
        timestamptz created_at
        timestamptz updated_at
    }

    CATEGORIES {
        uuid id PK
        varchar name UK
        text description
        varchar slug UK
        varchar color
        boolean is_active
        timestamptz created_at
        timestamptz updated_at
    }

    TAGS {
        uuid id PK
        varchar name UK
        varchar slug UK
        integer usage_count
        timestamptz created_at
    }

    STORIES {
        uuid id PK
        varchar title
        varchar slug UK
        text description
        varchar cover_image_url
        uuid author_id FK
        uuid category_id FK
        story_status status
        difficulty_level difficulty
        integer estimated_reading_time
        boolean is_featured
        boolean is_interactive
        integer view_count
        decimal rating
        integer rating_count
        timestamptz published_at
        timestamptz created_at
        timestamptz updated_at
    }

    STORY_TAGS {
        uuid story_id FK
        uuid tag_id FK
    }

    CHAPTERS {
        uuid id PK
        uuid story_id FK
        varchar title
        varchar slug
        text content
        chapter_type chapter_type
        integer order_index
        boolean is_published
        integer word_count
        integer reading_time
        jsonb metadata
        timestamptz created_at
        timestamptz updated_at
    }

    USER_STORY_PROGRESS {
        uuid id PK
        uuid user_id FK
        uuid story_id FK
        uuid current_chapter_id FK
        decimal progress_percentage
        integer reading_time
        boolean bookmarked
        boolean favorite
        timestamptz started_at
        timestamptz last_read_at
        timestamptz completed_at
    }

    USER_CHAPTER_PROGRESS {
        uuid id PK
        uuid user_id FK
        uuid chapter_id FK
        uuid story_id FK
        boolean is_completed
        integer reading_time
        jsonb choices_made
        integer last_position
        timestamptz read_at
        timestamptz completed_at
    }

    USER_RATINGS {
        uuid id PK
        uuid user_id FK
        uuid story_id FK
        integer rating
        text review
        boolean is_public
        timestamptz created_at
        timestamptz updated_at
    }

    COMMENTS {
        uuid id PK
        uuid user_id FK
        uuid story_id FK
        uuid chapter_id FK
        uuid parent_comment_id FK
        text content
        boolean is_approved
        integer like_count
        timestamptz created_at
        timestamptz updated_at
    }

    USER_SESSIONS {
        uuid id PK
        uuid user_id FK
        varchar refresh_token_hash
        jsonb device_info
        inet ip_address
        timestamptz expires_at
        timestamptz created_at
        timestamptz last_used_at
    }

    NOTIFICATIONS {
        uuid id PK
        uuid user_id FK
        varchar title
        text message
        varchar type
        jsonb data
        boolean is_read
        timestamptz created_at
    }

    %% Relationships
    USERS ||--o{ STORIES : "authors"
    USERS ||--o{ USER_STORY_PROGRESS : "tracks"
    USERS ||--o{ USER_CHAPTER_PROGRESS : "tracks"
    USERS ||--o{ USER_RATINGS : "rates"
    USERS ||--o{ COMMENTS : "comments"
    USERS ||--o{ USER_SESSIONS : "has_sessions"
    USERS ||--o{ NOTIFICATIONS : "receives"

    CATEGORIES ||--o{ STORIES : "categorizes"

    STORIES ||--o{ CHAPTERS : "contains"
    STORIES ||--o{ USER_STORY_PROGRESS : "tracked_by"
    STORIES ||--o{ USER_RATINGS : "rated_by"
    STORIES ||--o{ COMMENTS : "commented_on"
    STORIES ||--o{ STORY_TAGS : "tagged_with"

    TAGS ||--o{ STORY_TAGS : "tags"

    CHAPTERS ||--o{ USER_CHAPTER_PROGRESS : "tracked_by"
    CHAPTERS ||--o{ COMMENTS : "commented_on"
    CHAPTERS ||--o{ USER_STORY_PROGRESS : "current_chapter"

    COMMENTS ||--o{ COMMENTS : "parent_child"
```

## Key Relationships

### Core Entities
1. **Users** - Central entity for authentication and user management
2. **Stories** - Main content entity authored by users
3. **Chapters** - Content sections within stories
4. **Categories** - Organization and classification of stories

### Progress Tracking
- **User Story Progress** - High-level progress tracking per user per story
- **User Chapter Progress** - Detailed progress tracking for each chapter
- Both entities work together to provide comprehensive reading analytics

### Content Organization
- **Tags** - Flexible labeling system with many-to-many relationship to stories
- **Categories** - Hierarchical classification system for stories

### User Engagement
- **User Ratings** - 1-5 star rating system with optional reviews
- **Comments** - Nested comment system for stories and chapters
- **Notifications** - System notifications for user engagement

### Authentication & Sessions
- **User Sessions** - Secure session management for JWT refresh tokens
- Supports multiple device sessions per user

## Database Features

### Performance Optimizations
- Comprehensive indexing strategy
- UUID primary keys for distributed systems
- JSONB columns for flexible metadata storage

### Data Integrity
- Foreign key constraints with appropriate cascade rules
- Check constraints for data validation
- Unique constraints for business rules

### Automated Features
- Automatic timestamp updates with triggers
- Automatic rating calculations
- Tag usage count tracking

### Scalability Considerations
- UUID keys support horizontal scaling
- JSONB allows schema flexibility
- Indexes optimized for common query patterns