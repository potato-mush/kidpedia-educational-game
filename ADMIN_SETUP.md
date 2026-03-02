# Kidpedia Educational Game - Admin System

This directory contains the web-based admin panel and backend API for managing the Kidpedia Educational Game.

## Components

### 1. Admin Panel (`/admin-panel`)
- Modern React + TypeScript web application
- Manage users, topics, games, and media
- Built with Vite, Tailwind CSS, and React Query

[View Admin Panel Documentation](./admin-panel/README.md)

### 2. Backend API (`/backend`)
- Node.js + Express + TypeScript REST API
- JWT authentication
- File upload support
- Mock data (ready for database integration)

[View Backend Documentation](./backend/README.md)

## Quick Start

### 1. Start the Backend API

```bash
cd backend
npm install
cp .env.example .env
npm run dev
```

Backend runs at: `http://localhost:8080`

### 2. Start the Admin Panel

```bash
cd admin-panel
npm install
npm run dev
```

Admin panel runs at: `http://localhost:3000`

### 3. Login

Open `http://localhost:3000` and login with:
- **Username**: admin
- **Password**: admin

## Architecture

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│  Admin Panel    │─────→│  Backend API    │─────→│  Flutter App    │
│  (React/TS)     │ REST │  (Node.js/TS)   │      │  (Hive/Local)   │
│  Port: 3000     │      │  Port: 8080     │      │                 │
└─────────────────┘      └─────────────────┘      └─────────────────┘
```

### Current State
- ✅ Admin Panel UI complete
- ✅ Backend API with mock data
- ⚠️ Database integration needed
- ⚠️ Connect to Flutter app's Hive data

### Integration Options

#### Option A: Shared Database
1. Set up PostgreSQL/MongoDB
2. Migrate Flutter app to use cloud database
3. Connect backend to same database
4. Both apps work with same data

#### Option B: Firebase/Supabase
1. Use Firebase as backend
2. Connect Flutter app to Firebase
3. Connect admin panel to Firebase
4. Real-time sync between apps

#### Option C: Direct Hive Access (Mobile Only)
1. Backend reads/writes to Hive files
2. Only works for desktop/server deployment
3. Not recommended for web admin

## Features

### ✅ Implemented

#### Admin Panel
- User management (view, delete)
- Topic/Wiki CRUD with categories
- Game CRUD with configuration
- Media library with drag-drop upload
- Dashboard with statistics
- Responsive design

#### Backend
- JWT authentication
- RESTful API endpoints
- File upload handling
- Security middleware
- Rate limiting

### 🚧 TODO

- [ ] Database integration (PostgreSQL/MongoDB)
- [ ] Connect to Flutter app's data
- [ ] Real authentication system
- [ ] User role management
- [ ] Audit logs
- [ ] Analytics dashboard
- [ ] Batch operations
- [ ] Export/import data
- [ ] Email notifications
- [ ] Advanced search & filters

## Technology Stack

### Admin Panel
- React 18
- TypeScript
- Vite
- Tailwind CSS
- React Query
- React Router v6
- React Hook Form
- React Dropzone
- Lucide Icons

### Backend
- Node.js 18+
- Express.js
- TypeScript
- JWT (jsonwebtoken)
- Multer (file uploads)
- Helmet (security)
- Morgan (logging)
- CORS

## Development

### Project Structure
```
kidpedia-educational-game/
├── admin-panel/              # React admin dashboard
│   ├── src/
│   │   ├── components/       # React components
│   │   ├── pages/            # Page components
│   │   ├── services/         # API services
│   │   ├── types/            # TypeScript types
│   │   └── lib/              # Utilities
│   └── package.json
├── backend/                  # Node.js API server
│   ├── src/
│   │   ├── routes/           # API routes
│   │   ├── middleware/       # Express middleware
│   │   └── index.ts          # Entry point
│   └── package.json
└── lib/                      # Flutter app source
```

### Environment Variables

**Backend** (`.env`):
```env
PORT=8080
JWT_SECRET=your-secret
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin
```

**Admin Panel** (`.env`):
```env
VITE_API_URL=http://localhost:8080/api
```

## Deployment

### Backend Deployment

**Docker:**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY dist ./dist
EXPOSE 8080
CMD ["node", "dist/index.js"]
```

**PM2:**
```bash
npm run build
pm2 start dist/index.js --name kidpedia-api
```

### Admin Panel Deployment

**Build:**
```bash
npm run build
```

**Deploy to:**
- Vercel
- Netlify
- AWS S3 + CloudFront
- Nginx static hosting

## Security Checklist

- [ ] Change default admin credentials
- [ ] Use strong JWT secret
- [ ] Enable HTTPS in production
- [ ] Configure CORS properly
- [ ] Add rate limiting
- [ ] Implement CSRF protection
- [ ] Validate all inputs
- [ ] Sanitize user data
- [ ] Add security headers
- [ ] Enable audit logging
- [ ] Regular security updates
- [ ] Database backups

## Support & Documentation

- [Admin Panel README](./admin-panel/README.md)
- [Backend API README](./backend/README.md)
- [Flutter App README](./README.md)

## License

Part of the Kidpedia Educational Game project.
