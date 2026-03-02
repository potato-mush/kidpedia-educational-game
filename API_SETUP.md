# API Configuration

## Backend Server Setup

The Kidpedia mobile app now fetches data from the backend admin panel server. Follow these instructions to configure the API connection.

## Backend Server URL

The API service is configured in `lib/data/services/api_service.dart`

### Device-Specific URLs:

1. **Android Emulator**: 
   ```dart
   static const String baseUrl = 'http://10.0.2.2:8080/api/public';
   ```
   - `10.0.2.2` is the special IP that Android emulator uses to access localhost on the host machine

2. **iOS Simulator**:
   ```dart
   static const String baseUrl = 'http://localhost:8080/api/public';
   ```

3. **Physical Device** (phone/tablet on same WiFi):
   ```dart
   static const String baseUrl = 'http://YOUR_COMPUTER_IP:8080/api/public';
   ```
   - Replace `YOUR_COMPUTER_IP` with your actual local IP address
   - Find your IP:
     - Windows: Run `ipconfig` in PowerShell, look for "IPv4 Address"
     - Mac: Run `ifconfig` in Terminal, look for "inet" under active network
   - Example: `http://192.168.1.100:8080/api/public`

## How to Configure

1. Open `lib/data/services/api_service.dart`
2. Update the `baseUrl` constant based on your device type (see above)
3. Also update the `getMediaUrl()` method with the same base URL

## Starting the Backend Server

Before running the mobile app, ensure the backend server is running:

```bash
cd backend
npm run dev
```

Server should start on http://localhost:8080

## Testing the Connection

1. Make sure backend server is running (check http://localhost:8080/health)
2. Run the Flutter app
3. Check the console for any API fetch errors
4. If connection fails, app will automatically fall back to local cached data

## Data Flow

1. **First Launch**: App tries to fetch from API, falls back to local seed data if API unavailable
2. **Subsequent Launches**: App fetches fresh data from API and caches it locally
3. **Offline Mode**: App uses cached Hive data from last successful API fetch
4. **Admin Panel Updates**: Create/update data in admin panel (http://localhost:3000), mobile app will fetch updated data on next refresh

## Troubleshooting

### "API fetch failed" error:
- Check if backend server is running
- Verify the IP address/URL is correct for your device type
- Check firewall settings (Windows Firewall may block connections)
- For physical devices, ensure device and computer are on same WiFi network

### Images not loading:
- Backend serves images from `/uploads` directory
- Check that `getMediaUrl()` in `api_service.dart` returns correct URL
- Verify images were uploaded successfully in admin panel

### Data not syncing:
- Clear app data and restart to force API fetch
- Check backend logs for errors
- Verify database has data (run admin panel and check topics/games)

## API Endpoints

The mobile app uses these public endpoints (no authentication required):

- `GET /api/public/topics` - Get all topics
- `GET /api/public/topics/:id` - Get specific topic
- `GET /api/public/topics/category/:category` - Get topics by category
- `GET /api/public/categories` - Get all categories
- `GET /api/public/games` - Get all games
- `GET /api/public/games/:id` - Get specific game
- `GET /api/public/games/type/:type` - Get games by type
- `GET /api/public/badges` - Get all badges

## Media Files

Uploaded media files (images, videos, audio) are served from:
- `http://10.0.2.2:8080/uploads/FILENAME` (Android emulator)
- `http://YOUR_IP:8080/uploads/FILENAME` (Physical device)

The app automatically constructs these URLs using `ApiService.getMediaUrl(path)`
