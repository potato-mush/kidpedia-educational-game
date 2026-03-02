class AppConstants {
  // App Info
  static const String appName = 'Kidpedia';
  static const String appTagline = 'Learn, Play, Explore!';
  
  // Categories
  static const String categoryAnimals = 'Animals';
  static const String categorySpace = 'Space';
  static const String categoryScience = 'Science';
  static const String categoryHistory = 'History';
  static const String categoryGeography = 'Geography';
  
  static const List<String> categories = [
    categoryAnimals,
    categorySpace,
    categoryScience,
    categoryHistory,
    categoryGeography,
  ];
  
  // Storage Keys
  static const String hiveBoxTopics = 'topics';
  static const String hiveBoxGames = 'games';
  static const String hiveBoxProgress = 'progress';
  static const String hiveBoxBookmarks = 'bookmarks';
  static const String hiveBoxBadges = 'badges';
  
  // Shared Preferences Keys
  static const String prefThemeMode = 'theme_mode';
  static const String prefLargeText = 'large_text_mode';
  static const String prefOnboardingComplete = 'onboarding_complete';
  
  // Game Types
  static const String gameTypePuzzle = 'puzzle';
  static const String gameTypeSoundMatch = 'sound_match';
  static const String gameTypeQuiz = 'quiz';
  
  // Difficulty Levels
  static const String difficultyEasy = 'easy';
  static const String difficultyMedium = 'medium';
  static const String difficultyHard = 'hard';
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  
  // Badge Thresholds
  static const int badgeTopicsRead5 = 5;
  static const int badgeTopicsRead10 = 10;
  static const int badgeTopicsRead25 = 25;
  static const int badgeGamesWon5 = 5;
  static const int badgeGamesWon10 = 10;
  static const int badgeGamesWon25 = 25;
  
  // Grid Sizes
  static const int puzzleGridEasy = 3; // 3x3
  static const int puzzleGridMedium = 4; // 4x4
  static const int puzzleGridHard = 5; // 5x5
  
  // Quiz Settings
  static const int quizQuestionsPerGame = 5;
  static const int quizOptionsCount = 4;
  static const int quizTimePerQuestionSeconds = 30;
  
  // Sound Match Settings
  static const int soundMatchOptionsCount = 4;
  static const int soundMatchRoundsPerGame = 5;
}
