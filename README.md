# Kidpedia - Educational Game for Kids

A production-ready Flutter Android educational application inspired by Microsoft Encarta Kids Edition. An interactive offline encyclopedia for children featuring wiki-style articles, images, videos, audio clips, and mini-games.

## 🎯 Features

### Core Features
- **Wiki-Style Articles**: Rich educational content across multiple categories
- **Multimedia Content**: Images, videos, and audio narrations
- **Interactive Mini-Games**: 
  - Puzzle Game (drag-and-drop with multiple difficulty levels)
  - Sound Matching Game (match animal sounds with images)
  - Quiz Game (multiple choice with instant feedback)
- **Fully Offline**: No internet required, all content stored locally
- **Progress Tracking**: Track reading progress and game scores
- **Badge System**: Unlock achievements for learning milestones
- **Bookmarks**: Save favorite topics for quick access

### Categories
- 🦁 Animals
- 🚀 Space
- 🔬 Science
- 📜 History
- 🌍 Geography

### UI/UX Features
- Kid-friendly colorful design
- Material 3 design system
- Light/Dark mode toggle
- Large text mode for accessibility
- Smooth animations with flutter_animate
- Confetti celebrations on game completion
- Recently viewed topics
- Search functionality

## 🛠 Tech Stack

- **Framework**: Flutter (Latest Stable)
- **Language**: Dart with null safety
- **State Management**: Riverpod
- **Local Database**: Hive
- **Architecture**: Clean Architecture
- **Media**: 
  - audioplayers for audio playback
  - video_player & chewie for video playback
- **Animations**: flutter_animate & confetti
- **Platform**: Android only

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── core/
│   ├── theme/
│   │   └── app_theme.dart      # App theming
│   └── constants/
│       └── app_constants.dart   # App-wide constants
├── data/
│   ├── models/                  # Data models with Hive
│   │   ├── topic_model.dart
│   │   ├── game_model.dart
│   │   ├── progress_model.dart
│   │   ├── badge_model.dart
│   │   └── game_score_model.dart
│   ├── repositories/            # Business logic layer
│   │   ├── topic_repository.dart
│   │   ├── game_repository.dart
│   │   ├── progress_repository.dart
│   │   ├── badge_repository.dart
│   │   └── bookmark_repository.dart
│   └── local/                   # Local data management
│       ├── hive_service.dart
│       └── seed_data_service.dart
├── presentation/
│   ├── screens/                 # UI screens
│   │   ├── home_screen.dart
│   │   ├── category_screen.dart
│   │   ├── topic_detail_screen.dart
│   │   ├── games_screen.dart
│   │   └── profile_screen.dart
│   ├── widgets/                 # Reusable widgets
│   │   ├── topic_card.dart
│   │   ├── category_chip.dart
│   │   └── badge_card.dart
│   └── providers/               # Riverpod providers
│       └── app_providers.dart
└── games/                       # Mini-game implementations
    ├── puzzle/
    │   └── puzzle_game_screen.dart
    ├── sound_match/
    │   └── sound_match_game_screen.dart
    └── quiz/
        └── quiz_game_screen.dart
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.3.0 or higher)
- Dart SDK (3.3.0 or higher)
- Android Studio / VS Code
- Android SDK (for Android development)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd kidpedia-educational-game
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code (for Hive adapters)**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Create asset directories** (if not present)
   ```bash
   mkdir -p assets/images/animals
   mkdir -p assets/images/space
   mkdir -p assets/images/science
   mkdir -p assets/images/history
   mkdir -p assets/images/geography
   mkdir -p assets/images/badges
   mkdir -p assets/videos/animals
   mkdir -p assets/videos/space
   mkdir -p assets/videos/science
   mkdir -p assets/audio/narrations
   mkdir -p assets/audio/sounds
   mkdir -p assets/lottie
   mkdir -p assets/fonts
   ```

5. **Add sample assets** (optional but recommended)
   - Add images to respective category folders
   - Add video files for topics
   - Add audio narrations and sound effects
   - Download and add Poppins font family to assets/fonts

6. **Run the app**
   ```bash
   flutter run
   ```

## 📱 Building for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle (for Google Play)
```bash
flutter build appbundle --release
```

The output will be in:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

## 🎮 Games

### 1. Puzzle Game
- Drag-and-drop image puzzle
- Three difficulty levels (3x3, 4x4, 5x5)
- Move counter and timer
- Score calculation based on time and moves
- Confetti animation on completion

### 2. Sound Match Game
- Play animal sounds
- Match sounds with correct images
- Multiple rounds per game
- Immediate feedback
- Score tracking

### 3. Quiz Game
- Multiple choice questions
- Timed questions (30 seconds each)
- Instant feedback with explanations
- Progress indicator
- Score calculation

## 💾 Data Management

### Local Storage
- **Hive** is used for all local data storage
- Data persists across app restarts
- No internet connection required

### Seed Data
- App comes pre-populated with sample educational content
- 5+ topics across different categories
- Multiple games per topic
- Badge system with achievement tracking

### Data Models
- Topics: Educational content with multimedia
- Games: Game configurations and metadata
- Progress: User reading progress
- Badges: Achievement system
- Game Scores: Game performance history

## 🎨 Customization

### Adding New Topics
Edit `lib/data/local/seed_data_service.dart` and add new `TopicModel` instances.

### Adding New Categories
1. Update `AppConstants.categories` in `lib/core/constants/app_constants.dart`
2. Add category color in `AppTheme.getCategoryColor()`
3. Add category icon mapping in widgets

### Theming
Modify `lib/core/theme/app_theme.dart` to customize colors, fonts, and styles.

## 🔧 Configuration

### App Constants
Edit `lib/core/constants/app_constants.dart` for:
- Badge thresholds
- Game settings
- Animation durations
- Grid sizes

### Theme Settings
Edit `lib/core/theme/app_theme.dart` for:
- Color schemes
- Typography
- Component themes

## 📊 Performance Optimizations

- Lazy loading of images
- Efficient state management with Riverpod
- Local caching with Hive
- Optimized animations
- Hero animations for smooth transitions

## 🐛 Known Limitations

- Assets (images, videos, audio) need to be added manually
- Font files need to be downloaded separately
- Some game features use placeholder data
- Video/audio playback requires valid asset paths

## 🔒 Privacy & Safety

- **100% Offline**: No data collection or internet access
- **Kid-Safe**: No ads, in-app purchases, or external links
- **Local Storage Only**: All data stored on device
- **No Tracking**: Zero analytics or user tracking

## 📄 License

This project is created for educational purposes.

## 🤝 Contributing

To add content:
1. Add assets to appropriate folders
2. Update seed data in `seed_data_service.dart`
3. Run code generation if models change
4. Test thoroughly before committing

## 📞 Support

For issues or questions:
- Check the code comments
- Review the architecture documentation
- Examine the sample data structure

## 🎯 Future Enhancements

Potential features to add:
- More game types
- User profiles with avatars
- Parent dashboard
- Content filtering by age
- Offline speech synthesis
- Drawing/coloring activities
- More categories (Math, Arts, Music)

---

**Built with ❤️ for curious young minds**
# kidpedia-educational-game
