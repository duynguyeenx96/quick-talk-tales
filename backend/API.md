# Quick Talk Tales - API Documentation

## Overview
This document provides comprehensive documentation for the Quick Talk Tales API endpoints. The API follows RESTful principles and returns JSON responses.

**Base URL:** `http://localhost:3000/api/v1`

**Authentication:** JWT Bearer Token (where required)

## Authentication Endpoints

### POST /auth/register
Register a new user account.

**Request Body:**
```json
{
  "username": "string (3-50 chars, required)",
  "email": "string (valid email, required)",
  "password": "string (min 6 chars, required)",
  "fullName": "string (max 100 chars, optional)"
}
```

**Response:**
```json
{
  "user": {
    "id": "uuid",
    "username": "string",
    "email": "string",
    "fullName": "string",
    "role": "reader|author|admin",
    "isActive": true,
    "createdAt": "timestamp"
  },
  "accessToken": "jwt_token",
  "refreshToken": "jwt_token"
}
```

### POST /auth/login
Authenticate user and receive tokens.

**Request Body:**
```json
{
  "email": "string (required)",
  "password": "string (required)"
}
```

**Response:**
```json
{
  "user": {
    "id": "uuid",
    "username": "string",
    "email": "string",
    "fullName": "string",
    "role": "reader|author|admin"
  },
  "accessToken": "jwt_token",
  "refreshToken": "jwt_token"
}
```

### POST /auth/refresh
Refresh access token using refresh token.

**Request Body:**
```json
{
  "refreshToken": "string (required)"
}
```

**Response:**
```json
{
  "accessToken": "jwt_token",
  "refreshToken": "jwt_token"
}
```

### POST /auth/logout
**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "refreshToken": "string (optional)"
}
```

**Response:**
```json
{
  "message": "Logged out successfully"
}
```

### POST /auth/profile
Get current user profile.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "id": "uuid",
  "username": "string",
  "email": "string",
  "fullName": "string",
  "role": "reader|author|admin",
  "avatarUrl": "string",
  "preferences": {},
  "createdAt": "timestamp"
}
```

## User Management Endpoints

### GET /users
Get all users (Admin only).

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:**
- `page`: number (default: 1)
- `limit`: number (default: 10, max: 100)
- `search`: string (search in username, email, fullName)
- `sortBy`: string (field to sort by)
- `sortOrder`: "ASC"|"DESC" (default: "DESC")

**Response:**
```json
{
  "data": [
    {
      "id": "uuid",
      "username": "string",
      "email": "string",
      "fullName": "string",
      "role": "reader|author|admin",
      "isActive": boolean,
      "createdAt": "timestamp"
    }
  ],
  "total": number,
  "page": number,
  "limit": number,
  "totalPages": number
}
```

### GET /users/profile
Get current user profile.

**Headers:** `Authorization: Bearer <token>`

### PUT /users/profile
Update current user profile.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "fullName": "string (optional)",
  "avatarUrl": "string (optional)",
  "preferences": {} // optional
}
```

### GET /users/:id
Get user by ID (Admin only).

**Headers:** `Authorization: Bearer <token>`

### PUT /users/:id/deactivate
Deactivate user (Admin only).

**Headers:** `Authorization: Bearer <token>`

### PUT /users/:id/activate
Activate user (Admin only).

**Headers:** `Authorization: Bearer <token>`

## Stories Endpoints

### POST /stories
Create a new story (Author/Admin only).

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "title": "string (1-200 chars, required)",
  "description": "string (max 2000 chars, optional)",
  "coverImageUrl": "string (max 500 chars, optional)",
  "categoryId": "uuid (optional)",
  "difficulty": "beginner|intermediate|advanced (optional)",
  "estimatedReadingTime": number, // minutes
  "isInteractive": boolean,
  "tagIds": ["uuid"], // array of tag IDs
  "status": "draft|published|archived"
}
```

**Response:**
```json
{
  "id": "uuid",
  "title": "string",
  "slug": "string",
  "description": "string",
  "coverImageUrl": "string",
  "author": {
    "id": "uuid",
    "username": "string",
    "fullName": "string"
  },
  "category": {
    "id": "uuid",
    "name": "string",
    "slug": "string",
    "color": "string"
  },
  "status": "draft|published|archived",
  "difficulty": "beginner|intermediate|advanced",
  "estimatedReadingTime": number,
  "isFeatured": boolean,
  "isInteractive": boolean,
  "viewCount": number,
  "rating": number,
  "ratingCount": number,
  "tags": [
    {
      "id": "uuid",
      "name": "string",
      "slug": "string"
    }
  ],
  "publishedAt": "timestamp",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### GET /stories
Get all published stories.

**Query Parameters:**
- `page`: number (default: 1)
- `limit`: number (default: 10, max: 100)
- `search`: string (search in title, description, author)
- `sortBy`: string (field to sort by)
- `sortOrder`: "ASC"|"DESC" (default: "DESC")
- `status`: "draft|published|archived" (default: published)
- `categoryId`: uuid (filter by category)
- `difficulty`: "beginner|intermediate|advanced"
- `isFeatured`: boolean
- `isInteractive`: boolean
- `authorId`: uuid

**Response:**
```json
{
  "data": [/* array of stories */],
  "total": number,
  "page": number,
  "limit": number,
  "totalPages": number
}
```

### GET /stories/featured
Get featured stories.

**Response:**
```json
[/* array of featured stories */]
```

### GET /stories/popular
Get popular stories (sorted by views and ratings).

**Response:**
```json
[/* array of popular stories */]
```

### GET /stories/recent
Get recently published stories.

**Response:**
```json
[/* array of recent stories */]
```

### GET /stories/my-stories
Get current user's stories (Author/Admin only).

**Headers:** `Authorization: Bearer <token>`

**Query Parameters:** Same as GET /stories

### GET /stories/:id
Get story by ID.

**Response:** Story object with chapters

### GET /stories/slug/:slug
Get story by slug.

**Response:** Story object with chapters

### PATCH /stories/:id
Update story (Author/Admin only).

**Headers:** `Authorization: Bearer <token>`

**Request Body:** Same as POST /stories (all fields optional)

### DELETE /stories/:id
Delete story (Author/Admin only).

**Headers:** `Authorization: Bearer <token>`

### POST /stories/:id/rate
Rate a story.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "rating": number, // 1-5
  "review": "string (max 1000 chars, optional)"
}
```

### GET /stories/:id/ratings
Get story ratings.

**Query Parameters:**
- `page`: number (default: 1)
- `limit`: number (default: 10)

**Response:**
```json
{
  "data": [
    {
      "id": "uuid",
      "rating": number,
      "review": "string",
      "user": {
        "username": "string",
        "avatarUrl": "string"
      },
      "createdAt": "timestamp"
    }
  ],
  "total": number,
  "page": number,
  "limit": number,
  "totalPages": number
}
```

### GET /stories/:id/progress
Get user's reading progress for a story.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "id": "uuid",
  "progressPercentage": number,
  "readingTime": number,
  "bookmarked": boolean,
  "favorite": boolean,
  "currentChapter": {
    "id": "uuid",
    "title": "string",
    "orderIndex": number
  },
  "startedAt": "timestamp",
  "lastReadAt": "timestamp",
  "completedAt": "timestamp"
}
```

### POST /stories/:id/progress
Update user's reading progress for a story.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "currentChapterId": "uuid (optional)",
  "progressPercentage": number,
  "bookmarked": boolean,
  "favorite": boolean
}
```

## Chapters Endpoints

### POST /stories/:storyId/chapters
Create a new chapter (Author/Admin only).

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "title": "string (1-200 chars, required)",
  "content": "string (required)",
  "chapterType": "text|interactive|multimedia",
  "orderIndex": number, // chapter order
  "isPublished": boolean,
  "metadata": {} // for interactive choices, media URLs, etc.
}
```

**Response:**
```json
{
  "id": "uuid",
  "title": "string",
  "slug": "string",
  "content": "string",
  "chapterType": "text|interactive|multimedia",
  "orderIndex": number,
  "isPublished": boolean,
  "wordCount": number,
  "readingTime": number, // in minutes
  "metadata": {},
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### GET /stories/:storyId/chapters
Get all chapters for a story.

**Query Parameters:**
- `includeUnpublished`: boolean (default: false, requires author/admin)

**Response:**
```json
[/* array of chapters ordered by orderIndex */]
```

### GET /stories/:storyId/chapters/:id
Get chapter by ID.

**Response:** Chapter object

### GET /stories/:storyId/chapters/slug/:slug
Get chapter by slug.

**Response:** Chapter object

### PATCH /stories/:storyId/chapters/:id
Update chapter (Author/Admin only).

**Headers:** `Authorization: Bearer <token>`

**Request Body:** Same as POST chapters (all fields optional)

### DELETE /stories/:storyId/chapters/:id
Delete chapter (Author/Admin only).

**Headers:** `Authorization: Bearer <token>`

### POST /stories/:storyId/chapters/reorder
Reorder chapters (Author/Admin only).

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "chapterIds": ["uuid1", "uuid2", "uuid3"] // ordered array of chapter IDs
}
```

### POST /stories/:storyId/chapters/:id/mark-read
Mark chapter as read.

**Headers:** `Authorization: Bearer <token>`

**Request Body:**
```json
{
  "choicesMade": [/* array of choices for interactive chapters */]
}
```

### GET /stories/:storyId/chapters/:id/progress
Get user's progress for a specific chapter.

**Headers:** `Authorization: Bearer <token>`

**Response:**
```json
{
  "id": "uuid",
  "isCompleted": boolean,
  "readingTime": number,
  "choicesMade": [],
  "lastPosition": number,
  "readAt": "timestamp",
  "completedAt": "timestamp"
}
```

## Error Responses

All endpoints may return the following error responses:

### 400 Bad Request
```json
{
  "statusCode": 400,
  "message": "Validation error message",
  "error": "Bad Request"
}
```

### 401 Unauthorized
```json
{
  "statusCode": 401,
  "message": "Unauthorized",
  "error": "Unauthorized"
}
```

### 403 Forbidden
```json
{
  "statusCode": 403,
  "message": "Insufficient permissions",
  "error": "Forbidden"
}
```

### 404 Not Found
```json
{
  "statusCode": 404,
  "message": "Resource not found",
  "error": "Not Found"
}
```

### 409 Conflict
```json
{
  "statusCode": 409,
  "message": "Resource already exists",
  "error": "Conflict"
}
```

### 500 Internal Server Error
```json
{
  "statusCode": 500,
  "message": "Internal server error",
  "error": "Internal Server Error"
}
```

## Data Models

### User Roles
- `reader`: Can read stories, rate, comment, track progress
- `author`: Can create and manage stories and chapters
- `admin`: Full access to all features and user management

### Story Status
- `draft`: Story is being written, not visible to readers
- `published`: Story is live and visible to readers
- `archived`: Story is hidden from public view

### Difficulty Levels
- `beginner`: Easy to read, suitable for new readers
- `intermediate`: Moderate difficulty
- `advanced`: Complex stories for experienced readers

### Chapter Types
- `text`: Traditional text-based chapter
- `interactive`: Chapter with choices that affect the story
- `multimedia`: Chapter with images, audio, or other media

## Rate Limits

- Authentication endpoints: 10 requests per minute per IP
- Story creation/updates: 30 requests per hour per user
- General API endpoints: 100 requests per minute per user

## Pagination

All list endpoints support pagination with the following parameters:
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 10, max: 100)

Response includes:
- `data`: Array of items
- `total`: Total number of items
- `page`: Current page
- `limit`: Items per page
- `totalPages`: Total number of pages

## Search and Filtering

Most list endpoints support:
- `search`: Full-text search across relevant fields
- `sortBy`: Field to sort by
- `sortOrder`: "ASC" or "DESC"
- Additional filters specific to each endpoint

## WebSocket Events (Future)

The API is designed to support real-time features via WebSockets:
- New chapter notifications
- Reading progress updates
- Live commenting
- Author notifications