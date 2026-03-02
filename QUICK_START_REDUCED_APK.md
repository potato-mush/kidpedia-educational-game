# Quick Start: Build Reduced APK

## 🎯 Goal
Reduce your APK size from 100-500 MB to 10-20 MB by serving all media from your local backend.

## ⚡ Quick Steps

### 1. Migrate Assets to Backend (One-time)
```powershell
# Run the migration script
.\migrate-assets.ps1
```

This copies all media files from `assets/` to `backend/uploads/`

### 2. Start Backend Server
```powershell
cd backend
npm install  # First time only
npm run dev
```

Keep this running. Backend serves at: `http://localhost:8080`

### 3. Clean and Rebuild APK
```powershell
# Clean previous build
flutter clean

# Get dependencies
flutter pub get

# Build smallest possible APK (split per CPU architecture)
flutter build apk --release --split-per-abi
```

**Result**: Find your APKs in `build/app/outputs/flutter-apk/`:
- `app-armeabi-v7a-release.apk` (32-bit ARM - ~10-15 MB)
- `app-arm64-v8a-release.apk` (64-bit ARM - ~12-18 MB)
- `app-x86_64-release.apk` (64-bit x86 - ~15-20 MB)

### 4. Install and Test
```powershell
# Install on connected device/emulator
flutter install

# Or manually install specific APK
adb install build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

**Important**: Make sure backend is running and accessible!

## 📱 Testing Checklist

- [ ] Backend server is running (`http://localhost:8080`)
- [ ] App launches successfully
- [ ] Topics load from API
- [ ] Images display correctly
- [ ] Videos play properly
- [ ] Audio works
- [ ] Games load with correct assets

## 🔧 Troubleshooting

### "No internet connection" or blank screens?
- Ensure backend is running: `cd backend; npm run dev`
- Check backend is accessible at `http://localhost:8080/health`

### Images/videos not loading?
- Verify assets were copied: Check `backend/uploads/` folder
- Look at app logs: `flutter run` to see debug output
- Backend should serve files at `http://localhost:8080/uploads/...`

### APK still large?
- Make sure you ran `flutter clean` before building
- Check `pubspec.yaml` - should only have Lottie, badges, avatars
- Use `--split-per-abi` flag for separate architecture APKs

### App crashes on launch?
- Check if backend API is reachable
- App needs network permission (already in AndroidManifest.xml)
- Clear app data and reinstall

## 🎨 Creating Content

Use the admin panel to add topics and games:

```powershell
cd admin-panel
npm install  # First time only
npm run dev
```

Access at: `http://localhost:3000`

1. **Upload Media**: Use Media Manager to upload images, videos, audio
2. **Create Topics**: Reference uploaded media by path
3. **Create Games**: Upload game-specific assets
4. **App Auto-Updates**: Repositories fetch new content automatically

## 📊 Size Comparison

| Build Type | Before | After | Reduction |
|------------|--------|-------|-----------|
| Single APK | 300 MB | 15 MB | 95% |
| Split APKs | N/A | 10-18 MB | Per architecture |

## 🚀 Distribution

**For local testing:**
- Share APK file
- Users need access to your local network
- Backend must be running at known IP address

**For production:**
- Deploy backend to cloud server (AWS, DigitalOcean, etc.)
- Update API URL in `lib/data/services/api_service.dart`
- Rebuild APK with production URL

## 💡 What Changed?

### Removed from APK:
- ❌ All topic images (animals, space, science, etc.)
- ❌ All videos
- ❌ All audio files
- ❌ Large media assets

### Kept in APK:
- ✅ Lottie animations (tiny files)
- ✅ Badge images (small UI elements)
- ✅ Avatar images (small UI elements)
- ✅ Onboarding images (small UI elements)

### How It Works:
1. App launches with local cache
2. Fetches topics/games from backend API
3. Downloads images/videos on-demand
4. Caches media for offline viewing
5. Updates content from backend automatically

---

**Need detailed information?** See [ASSET_MIGRATION_GUIDE.md](ASSET_MIGRATION_GUIDE.md)
