# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-19

### Added
- **Core Features**
  - Wiki-style educational articles across 5 categories (Animals, Space, Science, History, Geography)
  - Interactive home screen with category navigation
  - Full-text search functionality
  - Topic detail screen with multimedia content
  - Image galleries for topics
  - Video player integration with Chewie
  - Audio narration playback
  - Bookmark system for saving favorite topics
  - Recently viewed topics tracking

- **Mini-Games**
  - Puzzle game with drag-and-drop mechanics
    - Three difficulty levels (3x3, 4x4, 5x5 grids)
    - Move counter and timer
    - Score calculation system
    - Confetti celebration on completion
  - Sound Match game
    - Audio playback of animal sounds
    - Multiple choice image selection
    - Round-based gameplay (5 rounds per game)
    - Immediate feedback system
  - Quiz game
    - Multiple choice questions
    - Timed questions (30 seconds each)
    - Visual feedback and explanations
    - Progress tracking

- **Progress & Achievements**
  - Reading progress tracking
  - Game score history
  - Badge/achievement system with 6 unlockable badges
  - Statistics dashboard

- **UI/UX**
  - Material 3 design system
  - Light and dark theme support
  - Large text mode for accessibility
  - Smooth animations using flutter_animate
  - Confetti effects for celebrations
  - Hero animations for transitions
  - Category-based color coding
  - Kid-friendly interface design

- **Data Management**
  - Hive local database integration
  - Offline-first architecture
  - Sample seed data with 6 topics
  - Multiple games per topic
  - State management with Riverpod

- **Architecture**
  - Clean architecture implementation
  - Repository pattern
  - Separation of concerns
  - Proper code organization
  - Type safety with null safety

### Technical
- Flutter with null safety
- Riverpod for state management
- Hive for local storage
- Video and audio playback support
- Confetti animations
- Flutter Animate for UI animations
- SharedPreferences for settings

### Documentation
- Comprehensive README.md
- Developer guide (DEVELOPER_GUIDE.md)
- Build instructions (BUILD.md)
- Code comments and documentation
- Asset organization guidelines

### Assets Structure
- Placeholder structure for images, videos, and audio
- Category-based asset organization
- Font configuration (Poppins family)
- Lottie animation support

## [Unreleased]

### Planned Features
- More educational topics
- Additional game types
- User profiles with avatars
- Parent dashboard
- Offline speech synthesis
- Drawing/coloring activities
- More categories (Math, Arts, Music)
- Multi-language support
- Parental controls

### Known Issues
- Assets need to be added manually (placeholders in place)
- Font files need separate download
- Video/audio require valid asset paths

---

## Version History

- **1.0.0** (2026-02-19) - Initial release with core features
