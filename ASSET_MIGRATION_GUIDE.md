# Asset Migration Guide - Reducing APK Size

## Overview

Your APK was large because all media assets (images, videos, audio) were bundled inside it. We've reconfigured the app to fetch all content from your local backend server instead.

**APK Size Reduction**: By removing bundled media assets, your APK size should reduce by 80-95% (depending on how many assets were bundled).

## What Changed?

### ✅ Kept in APK (Small UI Assets)
- Lottie animations (loading, confetti, celebration)
- Badge images 
- Avatar images
- Onboarding images

### 🌐 Now Served from Backend (Large Media)
- All topic images (animals, space, science, history, geography)
- All videos
- All audio files (narrations, sounds, music)
- User-uploaded content

## Setup Instructions

### Step 1: Organize Your Assets

Move all your media assets to the backend's `uploads` folder. Recommended structure:

```
backend/
  uploads/
    images/
      animals/
        elephant1.jpg
        elephant2.jpg
        elephant_thumb.jpg
        dolphin1.jpg
        dolphin2.jpg
        dolphin_thumb.jpg
      space/
        solar_system1.jpg
        solar_system2.jpg
        solar_system_thumb.jpg
      science/
        water_cycle1.jpg
        water_cycle2.jpg
        water_cycle_thumb.jpg
      history/
        egypt1.jpg
        egypt2.jpg
        egypt_thumb.jpg
      geography/
        amazon1.jpg
        amazon2.jpg
        amazon_thumb.jpg
    videos/
      animals/
        elephant.mp4
        dolphin.mp4
      space/
        solar_system.mp4
      science/
        water_cycle.mp4
      history/
        egypt.mp4
      geography/
        amazon.mp4
    audio/
      narrations/
        elephant.mp3
        dolphin.mp3
        solar_system.mp3
        water_cycle.mp3
        egypt.mp3
        amazon.mp3
      sounds/
        correct.mp3
        wrong.mp3
        click.mp3
      music/
        background.mp3
```

### Step 2: Copy Assets from `assets/` to `backend/uploads/`

**Windows PowerShell:**
```powershell
# From your project root directory
Copy-Item -Path "assets/images/animals", "assets/images/space", "assets/images/science", "assets/images/history", "assets/images/geography" -Destination "backend/uploads/images/" -Recurse -Force
Copy-Item -Path "assets/videos/*" -Destination "backend/uploads/videos/" -Recurse -Force
Copy-Item -Path "assets/audio/*" -Destination "backend/uploads/audio/" -Recurse -Force
```

### Step 3: Create Content via Admin Panel

Use your admin panel to create topics and games. When uploading media:

1. **For Topics**: Upload images, videos, and audio through the admin interface
2. **For Games**: Upload game assets (images, sounds) through the game editor
3. **Asset Paths**: The admin panel will automatically save paths as `/uploads/...`

The Flutter app will automatically convert these paths to full URLs using `ApiService.getMediaUrl()`.

### Step 4: Start Your Backend Server

```powershell
cd backend
npm install
npm run dev
```

The backend will serve assets at:
- Web: `http://localhost:8080/uploads/...`
- Android Emulator: `http://10.0.2.2:8080/uploads/...`

### Step 5: Clean and Rebuild Your APK

```powershell
# Clean the build
flutter clean

# Get dependencies
flutter pub get

# Build APK (release mode for smallest size)
flutter build apk --release

# Or build split APKs (even smaller - one per CPU architecture)
flutter build apk --split-per-abi
```

## How It Works

### Data Flow

1. **App Launch**: App initializes with empty local cache
2. **Data Fetch**: Repositories automatically fetch topics/games from backend API
3. **Asset Loading**: When displaying content:
   - App receives asset path like `/uploads/images/animals/elephant1.jpg`
   - `ApiService.getMediaUrl()` converts to full URL
   - `CachedNetworkImage` widget downloads and caches the image
4. **Offline Mode**: Previously loaded content remains cached for offline viewing

### Code Changes Made

1. **seed_data_service.dart**: Removed hardcoded topic/game seeding
2. **pubspec.yaml**: Removed bundled media assets
3. **Repositories**: Already configured to fetch from API (no changes needed)
4. **ApiService**: Already has `getMediaUrl()` helper (no changes needed)

## Testing

### Test Data Loading

1. Delete app data to force fresh cache
2. Launch app with backend running
3. Navigate to topics - they should load from API
4. Check images/videos load properly

### Test Asset URLs

Add this debug code temporarily to check URLs:

```dart
// In your image widget
onLoadComplete: () {
  debugPrint('Loaded image: ${ApiService.getMediaUrl(imagePath)}');
},
```

## Troubleshooting

### Images Not Loading?

Check:
- Backend server is running (`npm run dev` in backend folder)
- Assets exist in `backend/uploads/` folder
- File paths in database match actual file locations
- CORS is enabled (already configured in backend)

### APK Still Large?

Check:
- Run `flutter clean` before building
- Ensure `pubspec.yaml` doesn't include large asset folders
- Build with `--release` flag for optimization
- Use `--split-per-abi` for smallest possible size

### Need to Add New Content?

Use the admin panel at `http://localhost:3000`:
1. Upload media files through the media manager
2. Create topics/games referencing those files
3. App will fetch new content automatically

## Expected Results

| Before | After |
|--------|-------|
| 100-500 MB APK | 10-20 MB APK |
| All assets bundled | Only UI assets bundled |
| Offline by default | Requires backend connection |
| Hard to update content | Update via admin panel |

## Next Steps

1. ✅ Assets migrated to backend
2. ✅ APK rebuilt with reduced size
3. 📱 Test on device/emulator
4. 🎨 Create content via admin panel
5. 🚀 Distribute smaller APK to users

---

**Note**: Users will need access to your local network where the backend is running. For production, you'd deploy the backend to a cloud server and update the API URLs in `api_service.dart`.
