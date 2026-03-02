# Kidpedia Backend API

REST API server for the Kidpedia Admin Panel built with Node.js, Express, and TypeScript.

## Features

- **Authentication**: JWT-based authentication for admin access
- **User Management API**: CRUD operations for user profiles
- **Topic/Wiki API**: Manage educational content
- **Game Management API**: Configure and manage games
- **Media Upload API**: Handle image, video, and audio uploads
- **Security**: Helmet, CORS, rate limiting
- **File Upload**: Multer for handling media files

## Tech Stack

- **Runtime**: Node.js 18+
- **Framework**: Express.js
- **Language**: TypeScript
- **Authentication**: JWT (jsonwebtoken)
- **File Upload**: Multer
- **Security**: Helmet, CORS, express-rate-limit
- **Logging**: Morgan

## Getting Started

### Prerequisites

- Node.js 18+ and npm/yarn
- Port 8080 available (or configure a different port)

### Installation

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create environment file:
```bash
cp .env.example .env
```

4. Edit `.env` and configure your settings:
```env
PORT=8080
JWT_SECRET=your-secret-key
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin
```

5. Start the development server:
```bash
npm run dev
```

The API will be available at `http://localhost:8080`

## API Endpoints

### Authentication

#### POST `/api/auth/login`
Login to admin panel

**Request Body:**
```json
{
  "username": "admin",
  "password": "admin"
}
```

**Response:**
```json
{
  "token": "jwt-token-here",
  "user": {
    "id": "1",
    "username": "admin"
  }
}
```

### Users

All user endpoints require authentication (Bearer token in Authorization header).

- `GET /api/users` - Get all users
- `GET /api/users/:id` - Get user by ID
- `GET /api/users/statistics` - Get user statistics
- `GET /api/users/:id/stats` - Get user-specific stats
- `GET /api/users/:id/scores` - Get user game scores
- `GET /api/users/:id/progress` - Get user progress
- `PUT /api/users/:id` - Update user
- `DELETE /api/users/:id` - Delete user

### Topics

- `GET /api/topics` - Get all topics
- `GET /api/topics/:id` - Get topic by ID
- `GET /api/topics/categories` - Get all categories
- `GET /api/topics/category/:category` - Get topics by category
- `GET /api/topics/statistics` - Get topic statistics
- `POST /api/topics` - Create new topic
- `PUT /api/topics/:id` - Update topic
- `DELETE /api/topics/:id` - Delete topic

### Games

- `GET /api/games` - Get all games
- `GET /api/games/:id` - Get game by ID
- `GET /api/games/topic/:topicId` - Get games by topic
- `GET /api/games/type/:type` - Get games by type
- `GET /api/games/statistics` - Get game statistics
- `POST /api/games` - Create new game
- `PUT /api/games/:id` - Update game
- `DELETE /api/games/:id` - Delete game

### Media

- `GET /api/media` - Get all media files
- `GET /api/media/type/:type` - Get media by type (image/video/audio)
- `GET /api/media/category/:category` - Get media by category
- `GET /api/media/statistics` - Get media statistics
- `POST /api/media/upload` - Upload single file (multipart/form-data)
- `POST /api/media/upload-multiple` - Upload multiple files
- `DELETE /api/media/:id` - Delete media file

## Project Structure

```
backend/
├── src/
│   ├── routes/
│   │   ├── auth.ts          # Authentication routes
│   │   ├── users.ts         # User management routes
│   │   ├── topics.ts        # Topic/wiki routes
│   │   ├── games.ts         # Game management routes
│   │   └── media.ts         # Media upload routes
│   ├── middleware/
│   │   └── auth.ts          # JWT authentication middleware
│   └── index.ts             # Main application entry
├── uploads/                 # Uploaded media files
├── .env.example             # Environment variables template
├── package.json
├── tsconfig.json
└── README.md
```

## Development

### Running in Development Mode

```bash
npm run dev
```

Uses nodemon for hot-reloading on file changes.

### Building for Production

```bash
npm run build
```

Compiles TypeScript to JavaScript in the `dist` directory.

### Running in Production

```bash
npm start
```

## Authentication

All endpoints except `/api/auth/login` and `/health` require a valid JWT token.

Include the token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

## File Uploads

Media files are uploaded to the `uploads/` directory by default.

**Upload single file:**
```bash
curl -X POST http://localhost:8080/api/media/upload \
  -H "Authorization: Bearer <token>" \
  -F "file=@image.jpg" \
  -F "type=image" \
  -F "category=animals"
```

**Upload multiple files:**
```bash
curl -X POST http://localhost:8080/api/media/upload-multiple \
  -H "Authorization: Bearer <token>" \
  -F "files=@image1.jpg" \
  -F "files=@image2.jpg" \
  -F "type=image" \
  -F "category=animals"
```

## Security Features

- **Helmet**: Sets security-related HTTP headers
- **CORS**: Configured to accept requests from admin panel origin
- **Rate Limiting**: Limits requests to prevent abuse
- **JWT**: Secure token-based authentication
- **File Validation**: Only allows specific file types

## Integration with Flutter App

The current implementation uses mock data. To integrate with your Flutter app:

### Option 1: Direct Hive Access (Not Recommended for Web)
Read/write directly to Hive database files used by the Flutter app.

### Option 2: Shared Database (Recommended)
1. Set up a database (PostgreSQL, MongoDB, etc.)
2. Migrate Flutter app to use the database
3. Connect backend to the same database

### Option 3: Firebase/Supabase
1. Use Firebase or Supabase as backend
2. Connect both Flutter app and admin panel to the same backend

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | 8080 |
| `NODE_ENV` | Environment (development/production) | development |
| `JWT_SECRET` | Secret key for JWT tokens | (required) |
| `ADMIN_USERNAME` | Admin username | admin |
| `ADMIN_PASSWORD` | Admin password | admin |
| `UPLOAD_DIR` | Upload directory path | ./uploads |
| `MAX_FILE_SIZE` | Max file size in bytes | 10485760 (10MB) |
| `CORS_ORIGIN` | Allowed CORS origin | http://localhost:3000 |

## TODO for Production

- [ ] Replace mock data with actual database
- [ ] Implement proper user authentication with password hashing
- [ ] Add input validation and sanitization
- [ ] Set up database migrations
- [ ] Add comprehensive error handling
- [ ] Implement logging to files
- [ ] Add API documentation (Swagger/OpenAPI)
- [ ] Set up automated tests
- [ ] Configure for deployment (Docker, PM2, etc.)
- [ ] Add database backups
- [ ] Implement role-based access control

## License

This project is part of the Kidpedia Educational Game.
