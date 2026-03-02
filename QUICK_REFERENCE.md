# Quick Reference Guide

Common tasks and commands for Kidpedia development.

## 🚀 Quick Start

```bash
# Get dependencies
flutter pub get

# Generate code
flutter pub run build_runner build --delete-conflicting-outputs

# Run app
flutter run

# Run on specific device
flutter run -d <device-id>
```

## 📦 Build Commands

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Release with split ABIs (smaller files)
flutter build apk --release --split-per-abi

# App Bundle for Play Store
flutter build appbundle --release

# With obfuscation
flutter build apk --release --obfuscate --split-debug-info=./symbols
```

## 🔧 Development

```bash
# Run with hot reload
flutter run

# Analyze code
flutter analyze

# Format code
flutter format lib/

# Run tests
flutter test

# Check outdated packages
flutter pub outdated

# Update packages
flutter pub upgrade
```

## 🏗️ Code Generation

```bash
# Generate once
flutter pub run build_runner build --delete-conflicting-outputs

# Watch for changes (auto-regenerate)
flutter pub run build_runner watch --delete-conflicting-outputs

# Clean before generate
flutter pub run build_runner clean
```

## 📱 Device Management

```bash
# List devices
flutter devices

# List emulators
flutter emulators

# Launch emulator
flutter emulators --launch <emulator-id>
```

## 🐛 Debugging

```bash
# Enable verbose logging
flutter run -v

# Show performance overlay
flutter run --enable-software-rendering

# Profile mode
flutter run --profile

# Observatory (debugger)
# Opens automatically on flutter run
```

## 📊 Performance

```bash
# Analyze app size
flutter build apk --analyze-size

# Profile performance
flutter run --profile

# Check for unnecessary imports
flutter analyze
```

## 🧹 Cleanup

```bash
# Clean build files
flutter clean

# Remove generated files
find . -name "*.g.dart" -delete
find . -name "*.freezed.dart" -delete

# Full cleanup
flutter clean
flutter pub get
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

## 🎨 Assets

```bash
# Verify asset paths
flutter pub run flutter_asset_validator

# List all assets
grep -r "assets/" pubspec.yaml
```

## 📝 Common File Locations

| Purpose | Path |
|---------|------|
| Main entry | `lib/main.dart` |
| Constants | `lib/core/constants/app_constants.dart` |
| Theme | `lib/core/theme/app_theme.dart` |
| Models | `lib/data/models/` |
| Repositories | `lib/data/repositories/` |
| Providers | `lib/presentation/providers/app_providers.dart` |
| Screens | `lib/presentation/screens/` |
| Widgets | `lib/presentation/widgets/` |
| Games | `lib/games/` |
| Seed Data | `lib/data/local/seed_data_service.dart` |

## 🔑 Key Files to Edit

### Adding Topics
- `lib/data/local/seed_data_service.dart`

### Adding Categories
- `lib/core/constants/app_constants.dart`
- `lib/core/theme/app_theme.dart`

### Modifying Themes
- `lib/core/theme/app_theme.dart`

### Adding Providers
- `lib/presentation/providers/app_providers.dart`

### Configuring Games
- `lib/core/constants/app_constants.dart`
- Game-specific screens in `lib/games/`

## 🎯 Common Tasks

### Add a New Topic

1. Edit `seed_data_service.dart`
2. Add `TopicModel` to topics list
3. Add assets to appropriate folders
4. Hot restart app

### Add a New Game

1. Create game screen in `lib/games/new_game/`
2. Add game type constant to `app_constants.dart`
3. Update `seed_data_service.dart` to create game instances
4. Add navigation in `games_screen.dart`

### Change App Theme

1. Edit `lib/core/theme/app_theme.dart`
2. Modify color schemes
3. Hot reload to see changes

### Add a New Screen

1. Create screen file in `lib/presentation/screens/`
2. Add route if needed
3. Import in navigation logic

### Reset All Data

```dart
// In app
await HiveService.clearAllData();
await SeedDataService.seedAll();
```

## 🚨 Troubleshooting

| Issue | Solution |
|-------|----------|
| Missing .g.dart files | Run `flutter pub run build_runner build --delete-conflicting-outputs` |
| Assets not loading | Check `pubspec.yaml` paths and run `flutter clean` |
| Hive errors | Verify adapters registered in `hive_service.dart` |
| State not updating | Check provider usage and use `ref.invalidate()` |
| Build fails | Run `flutter clean` then `flutter pub get` |

## 📚 Documentation

- Main README: `README.md`
- Developer Guide: `DEVELOPER_GUIDE.md`
- Build Instructions: `BUILD.md`
- Changelog: `CHANGELOG.md`

## 🔗 Useful Commands

```bash
# Check Flutter doctor
flutter doctor -v

# Check Flutter version
flutter --version

# Upgrade Flutter
flutter upgrade

# Switch Flutter channel
flutter channel stable
flutter channel beta

# Clear cache
flutter pub cache repair
```

---

**Pro Tip**: Save commonly used commands as scripts in your IDE or terminal aliases!
