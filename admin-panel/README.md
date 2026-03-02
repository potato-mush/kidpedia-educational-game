# Kidpedia Admin Panel

Web-based administration panel for managing the Kidpedia Educational Game.

## Features

- **Dashboard**: Overview of users, topics, games, and activity statistics
- **User Management**: View and manage user profiles, track user progress and scores
- **Wiki/Topic Management**: Create, edit, and delete educational topics with rich content
- **Game Management**: Configure puzzle, quiz, and sound match games
- **Media Library**: Upload and manage images, videos, and audio files

## Tech Stack

- **Framework**: React 18 with TypeScript
- **Build Tool**: Vite
- **Styling**: Tailwind CSS
- **State Management**: Zustand + React Query (TanStack Query)
- **Routing**: React Router v6
- **Forms**: React Hook Form with Zod validation
- **File Upload**: React Dropzone
- **Icons**: Lucide React

## Getting Started

### Prerequisites

- Node.js 18+ and npm/yarn
- Backend API server running (see Backend Setup below)

### Installation

1. Navigate to the admin panel directory:
```bash
cd admin-panel
```

2. Install dependencies:
```bash
npm install
```

3. Start the development server:
```bash
npm run dev
```

The admin panel will be available at `http://localhost:3000`

### Default Login Credentials

- Username: `admin`
- Password: `admin`

**Note**: These are temporary credentials. Implement proper authentication before production use.

## Building for Production

```bash
npm run build
```

The production-ready files will be in the `dist` directory.

## API Integration

The admin panel expects a REST API at `/api` with the following endpoints:

### Authentication
- POST `/api/auth/login` - Admin login

### Users
- GET `/api/users` - Get all users
- GET `/api/users/:id` - Get user by ID
- PUT `/api/users/:id` - Update user
- DELETE `/api/users/:id` - Delete user
- GET `/api/users/statistics` - Get user statistics
- GET `/api/users/:id/stats` - Get user-specific stats
- GET `/api/users/:id/scores` - Get user game scores
- GET `/api/users/:id/progress` - Get user progress

### Topics
- GET `/api/topics` - Get all topics
- GET `/api/topics/:id` - Get topic by ID
- POST `/api/topics` - Create topic
- PUT `/api/topics/:id` - Update topic
- DELETE `/api/topics/:id` - Delete topic
- GET `/api/topics/categories` - Get all categories
- GET `/api/topics/category/:category` - Get topics by category
- GET `/api/topics/statistics` - Get topic statistics

### Games
- GET `/api/games` - Get all games
- GET `/api/games/:id` - Get game by ID
- POST `/api/games` - Create game
- PUT `/api/games/:id` - Update game
- DELETE `/api/games/:id` - Delete game
- GET `/api/games/topic/:topicId` - Get games by topic
- GET `/api/games/type/:type` - Get games by type
- GET `/api/games/statistics` - Get game statistics

### Media
- GET `/api/media` - Get all media files
- GET `/api/media/type/:type` - Get media by type
- GET `/api/media/category/:category` - Get media by category
- POST `/api/media/upload` - Upload single file
- POST `/api/media/upload-multiple` - Upload multiple files
- DELETE `/api/media/:id` - Delete media file
- GET `/api/media/statistics` - Get media statistics

## Project Structure

```
admin-panel/
├── src/
│   ├── components/          # Reusable components
│   │   └── Layout.tsx       # Main layout with sidebar
│   ├── pages/               # Page components
│   │   ├── Dashboard.tsx    # Dashboard with stats
│   │   ├── Users.tsx        # User management
│   │   ├── Topics.tsx       # Topic listing
│   │   ├── TopicEditor.tsx  # Topic create/edit
│   │   ├── Games.tsx        # Game listing
│   │   ├── GameEditor.tsx   # Game create/edit
│   │   ├── Media.tsx        # Media library
│   │   └── Login.tsx        # Login page
│   ├── services/            # API service functions
│   │   ├── userService.ts
│   │   ├── topicService.ts
│   │   ├── gameService.ts
│   │   └── mediaService.ts
│   ├── types/               # TypeScript types
│   │   └── index.ts
│   ├── lib/                 # Utilities
│   │   └── api.ts           # Axios configuration
│   ├── App.tsx              # Main app component
│   ├── main.tsx             # Entry point
│   └── index.css            # Global styles
├── public/                  # Static assets
├── index.html
├── package.json
├── tsconfig.json
├── vite.config.ts
└── tailwind.config.js
```

## Development Notes

### Adding New Features

1. Create type definitions in `src/types/index.ts`
2. Add API service methods in `src/services/`
3. Create page components in `src/pages/`
4. Add routes in `src/App.tsx`
5. Update navigation in `src/components/Layout.tsx`

### Styling

The project uses Tailwind CSS. Customize colors and theme in `tailwind.config.js`.

### State Management

- Use React Query for server state (API data)
- Use Zustand for client state (if needed)
- Forms use React Hook Form with Zod validation

## Backend Setup

See `backend/README.md` for setting up the API server that connects to the Flutter app's Hive database.

## Security Considerations

⚠️ **Important**: Before deploying to production:

1. Implement proper authentication with JWT tokens
2. Add role-based access control
3. Validate all API inputs
4. Use HTTPS for all communication
5. Implement rate limiting
6. Add CSRF protection
7. Sanitize user inputs to prevent XSS
8. Use environment variables for sensitive data

## License

This project is part of the Kidpedia Educational Game.
