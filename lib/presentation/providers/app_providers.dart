import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidpedia/data/repositories/topic_repository.dart';
import 'package:kidpedia/data/repositories/game_repository.dart';
import 'package:kidpedia/data/repositories/progress_repository.dart';
import 'package:kidpedia/data/repositories/badge_repository.dart';
import 'package:kidpedia/data/repositories/bookmark_repository.dart';
import 'package:kidpedia/data/repositories/leaderboard_repository.dart';
import 'package:kidpedia/data/repositories/user_profile_repository.dart';
import 'package:kidpedia/data/services/badge_service.dart';
import 'package:kidpedia/data/models/topic_model.dart';
import 'package:kidpedia/data/models/game_model.dart';
import 'package:kidpedia/data/models/badge_model.dart';
import 'package:kidpedia/data/models/progress_model.dart';
import 'package:kidpedia/data/models/leaderboard_entry_model.dart';
import 'package:kidpedia/data/models/user_profile_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:kidpedia/core/constants/app_constants.dart';

// Repository Providers
final topicRepositoryProvider = Provider<TopicRepository>((ref) {
  return TopicRepository();
});

final gameRepositoryProvider = Provider<GameRepository>((ref) {
  return GameRepository();
});

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository();
});

final badgeRepositoryProvider = Provider<BadgeRepository>((ref) {
  return BadgeRepository();
});

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  return BookmarkRepository();
});

final leaderboardRepositoryProvider = Provider<LeaderboardRepository>((ref) {
  return LeaderboardRepository();
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository();
});

// Badge Service Provider
final badgeServiceProvider = Provider<BadgeService>((ref) {
  return BadgeService(
    badgeRepository: ref.watch(badgeRepositoryProvider),
    gameRepository: ref.watch(gameRepositoryProvider),
    progressRepository: ref.watch(progressRepositoryProvider),
    leaderboardRepository: ref.watch(leaderboardRepositoryProvider),
  );
});

// Shared Preferences Provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

// Theme Mode Provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(ThemeMode.light) {
    _loadThemeMode();
  }

  void _loadThemeMode() {
    final themeModeString = _prefs.getString(AppConstants.prefThemeMode);
    if (themeModeString != null) {
      state = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == themeModeString,
        orElse: () => ThemeMode.light,
      );
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(AppConstants.prefThemeMode, mode.toString());
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }
}

// Large Text Mode Provider
final largeTextModeProvider = StateNotifierProvider<LargeTextModeNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LargeTextModeNotifier(prefs);
});

class LargeTextModeNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  LargeTextModeNotifier(this._prefs) : super(false) {
    _loadLargeTextMode();
  }

  void _loadLargeTextMode() {
    state = _prefs.getBool(AppConstants.prefLargeText) ?? false;
  }

  Future<void> toggle() async {
    state = !state;
    await _prefs.setBool(AppConstants.prefLargeText, state);
  }
}

// Topics Provider - Async to fetch from API
final allTopicsProvider = FutureProvider<List<TopicModel>>((ref) async {
  final repository = ref.watch(topicRepositoryProvider);
  return await repository.getAllTopics();
});

// Topics by Category Provider
final topicsByCategoryProvider = Provider.family<List<TopicModel>, String>((ref, category) {
  final allTopicsAsync = ref.watch(allTopicsProvider);
  return allTopicsAsync.when(
    data: (topics) => topics.where((t) => t.category.toLowerCase() == category.toLowerCase()).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Featured Topics Provider
final featuredTopicsProvider = Provider<List<TopicModel>>((ref) {
  final allTopicsAsync = ref.watch(allTopicsProvider);
  return allTopicsAsync.when(
    data: (topics) => topics.take(5).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Search Query Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Search Results Provider
final searchResultsProvider = Provider<List<TopicModel>>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  
  final allTopicsAsync = ref.watch(allTopicsProvider);
  return allTopicsAsync.when(
    data: (topics) {
      final lowerQuery = query.toLowerCase();
      return topics.where((topic) {
        return topic.title.toLowerCase().contains(lowerQuery) ||
            topic.summary.toLowerCase().contains(lowerQuery) ||
            topic.content.toLowerCase().contains(lowerQuery);
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Topic Detail Provider
final topicDetailProvider = Provider.family<TopicModel?, String>((ref, topicId) {
  final allTopicsAsync = ref.watch(allTopicsProvider);
  return allTopicsAsync.when(
    data: (topics) {
      try {
        return topics.firstWhere((t) => t.id == topicId);
      } catch (e) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
});

// Related Topics Provider
final relatedTopicsProvider = Provider.family<List<TopicModel>, String>((ref, topicId) {
  final allTopicsAsync = ref.watch(allTopicsProvider);
  return allTopicsAsync.when(
    data: (topics) {
      final topic = topics.where((t) => t.id == topicId).firstOrNull;
      if (topic == null || topic.relatedTopicIds.isEmpty) return [];
      return topics.where((t) => topic.relatedTopicIds.contains(t.id)).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// All Games Provider - Async to fetch from API
final allGamesProvider = FutureProvider<List<GameModel>>((ref) async {
  final repository = ref.watch(gameRepositoryProvider);
  return await repository.getAllGames();
});

// Games by Topic Provider
final gamesByTopicProvider = Provider.family<List<GameModel>, String>((ref, topicId) {
  final allGamesAsync = ref.watch(allGamesProvider);
  return allGamesAsync.when(
    data: (games) => games.where((g) => g.topicId == topicId).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Games by Type Provider
final gamesByTypeProvider = Provider.family<List<GameModel>, String>((ref, type) {
  final allGamesAsync = ref.watch(allGamesProvider);
  return allGamesAsync.when(
    data: (games) => games.where((g) => g.type == type).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Game Stats Provider - with dependency on leaderboard updates
final gameStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final repository = ref.watch(gameRepositoryProvider);
  // Watch leaderboard to trigger refresh when it updates
  ref.watch(leaderboardProvider);
  
  return {
    'totalPlayed': repository.getTotalGamesPlayed(),
    'totalWon': repository.getTotalGamesWon(),
    'winRate': repository.getWinRate(),
    'averageScore': repository.getAverageScore(),
  };
});

// All Badges Provider - with dependency on leaderboard updates
final allBadgesProvider = Provider<List<BadgeModel>>((ref) {
  final repository = ref.watch(badgeRepositoryProvider);
  // Watch leaderboard to trigger refresh when it updates
  ref.watch(leaderboardProvider);
  
  return repository.getAllBadgesSync();
});

// Unlocked Badges Provider
final unlockedBadgesProvider = Provider<List<BadgeModel>>((ref) {
  final repository = ref.watch(badgeRepositoryProvider);
  // Watch leaderboard to trigger refresh when it updates
  ref.watch(leaderboardProvider);
  
  return repository.getUnlockedBadges();
});

// Badge Stats Provider
final badgeStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final repository = ref.watch(badgeRepositoryProvider);
  // Watch leaderboard to trigger refresh when it updates
  ref.watch(leaderboardProvider);
  
  return {
    'unlocked': repository.getUnlockedCount(),
    'total': repository.getTotalCount(),
    'percentage': repository.getCompletionPercentage(),
  };
});

// Recently Viewed Topics Provider
final recentlyViewedProvider = Provider<List<ProgressModel>>((ref) {
  final repository = ref.watch(progressRepositoryProvider);
  // Watch leaderboard to trigger refresh when topics are read
  ref.watch(leaderboardProvider);
  
  return repository.getRecentlyViewedTopics(limit: 10);
});

// Total Topics Viewed Provider
final totalTopicsViewedProvider = Provider<int>((ref) {
  final repository = ref.watch(progressRepositoryProvider);
  // Watch leaderboard to trigger refresh when topics are read
  ref.watch(leaderboardProvider);
  
  return repository.getTotalTopicsViewed();
});

// Bookmarked Topics Provider
final bookmarkedTopicsProvider = Provider<List<TopicModel>>((ref) {
  final bookmarkRepo = ref.watch(bookmarkRepositoryProvider);
  final bookmarkedIds = bookmarkRepo.getAllBookmarks();
  
  final allTopicsAsync = ref.watch(allTopicsProvider);
  return allTopicsAsync.when(
    data: (topics) => topics.where((topic) => bookmarkedIds.contains(topic.id)).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Is Bookmarked Provider
final isBookmarkedProvider = Provider.family<bool, String>((ref, topicId) {
  final repository = ref.watch(bookmarkRepositoryProvider);
  return repository.isBookmarked(topicId);
});

// Selected Category Provider
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Current Topic Provider
final currentTopicProvider = StateProvider<String?>((ref) => null);

// User Profile Provider
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfileModel?>((ref) {
  final repository = ref.watch(userProfileRepositoryProvider);
  return UserProfileNotifier(repository);
});

class UserProfileNotifier extends StateNotifier<UserProfileModel?> {
  final UserProfileRepository _repository;

  UserProfileNotifier(this._repository) : super(null) {
    _loadProfile();
  }

  void _loadProfile() {
    state = _repository.getCurrentUser();
  }

  Future<void> updateUsername(String username) async {
    await _repository.updateUsername(username);
    _loadProfile();
    
    // Update leaderboard
    if (state != null) {
      // This will be handled by other providers
    }
  }

  Future<void> updateAvatar(String avatarId) async {
    await _repository.updateAvatar(avatarId);
    _loadProfile();
  }
}

// Leaderboard Provider - StateNotifier for reactive updates
final leaderboardProvider = StateNotifierProvider<LeaderboardNotifier, List<LeaderboardEntryModel>>((ref) {
  final repository = ref.watch(leaderboardRepositoryProvider);
  return LeaderboardNotifier(repository);
});

class LeaderboardNotifier extends StateNotifier<List<LeaderboardEntryModel>> {
  final LeaderboardRepository _repository;

  LeaderboardNotifier(this._repository) : super([]) {
    _loadLeaderboard();
  }

  void _loadLeaderboard() {
    state = _repository.getLeaderboard();
  }

  // Method to refresh leaderboard data
  void refresh() {
    _loadLeaderboard();
  }
}

// Top Leaderboard Provider (Top 10)
final topLeaderboardProvider = Provider<List<LeaderboardEntryModel>>((ref) {
  final leaderboard = ref.watch(leaderboardProvider);
  return leaderboard.take(10).toList();
});

// User Rank Provider
final userRankProvider = Provider<int>((ref) {
  final leaderboard = ref.watch(leaderboardProvider);
  final userProfile = ref.watch(userProfileProvider);
  
  if (userProfile == null) return 999;
  
  final index = leaderboard.indexWhere((e) => e.id == userProfile.id);
  return index >= 0 ? index + 1 : 999;
});

// User Leaderboard Entry Provider
final userLeaderboardEntryProvider = Provider<LeaderboardEntryModel?>((ref) {
  final leaderboard = ref.watch(leaderboardProvider);
  final userProfile = ref.watch(userProfileProvider);
  
  if (userProfile == null) return null;
  
  try {
    return leaderboard.firstWhere((e) => e.id == userProfile.id);
  } catch (e) {
    return null;
  }
});
