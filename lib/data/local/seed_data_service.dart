import 'package:flutter/foundation.dart';
import 'package:kidpedia/data/models/badge_model.dart';
import 'package:kidpedia/data/models/game_score_model.dart';
import 'package:kidpedia/data/models/progress_model.dart';
import 'package:kidpedia/data/repositories/topic_repository.dart';
import 'package:kidpedia/data/repositories/game_repository.dart';
import 'package:kidpedia/data/repositories/badge_repository.dart';
import 'package:kidpedia/data/repositories/progress_repository.dart';
import 'package:kidpedia/data/repositories/user_profile_repository.dart';
import 'package:kidpedia/data/repositories/leaderboard_repository.dart';
import 'package:kidpedia/data/local/bot_players_service.dart';
import 'package:kidpedia/data/local/hive_service.dart';
import 'package:kidpedia/core/constants/app_constants.dart';
import 'package:kidpedia/data/services/api_service.dart';
import 'package:kidpedia/data/services/badge_service.dart';

class SeedDataService {
  static Future<void> seedAll() async {
    final badgeRepo = BadgeRepository();
    final userRepo = UserProfileRepository();
    final leaderboardRepo = LeaderboardRepository();
    final gameRepo = GameRepository();

    // Seed badge definitions first, then restore and re-evaluate unlock state.
    await _seedBadges(badgeRepo);

    // Add authenticated current user to leaderboard if available.
    final currentUser = userRepo.getCurrentUser();
    if (currentUser != null) {
      await _syncUserStateFromBackend(currentUser.id);

      final badgeService = BadgeService(
        badgeRepository: badgeRepo,
        gameRepository: gameRepo,
        progressRepository: ProgressRepository(),
        leaderboardRepository: leaderboardRepo,
      );
      await badgeService.checkAndUpdateAllBadges();

      await leaderboardRepo.updateUserStats(currentUser.id);
    }

    // NOTE: Topics and Games are now fetched from the backend server
    // Fetch initial data from API on first launch
    final topicRepo = TopicRepository();
    
    try {
      // Fetch topics and games from backend API
      await topicRepo.getAllTopics();
      await gameRepo.getAllGames();
      debugPrint('✅ Successfully loaded data from backend API');
    } catch (e) {
      debugPrint('❌ Error loading data from backend: $e');
      debugPrint('⚠️  Make sure backend server is running at http://localhost:8080');
    }
    
    // Generate bot players for leaderboard
    await BotPlayersService.generateBotPlayers();
  }

  static Future<void> _syncUserStateFromBackend(String userId) async {
    try {
      final snapshot = await ApiService.getUserSnapshot(userId);
      if (snapshot == null) {
        return;
      }

      final rawScores = (snapshot['gameScores'] as List<dynamic>? ?? const []);
      final rawProgress = (snapshot['progress'] as List<dynamic>? ?? const []);
      final rawBookmarks = (snapshot['bookmarks'] as List<dynamic>? ?? const []);

      final scores = rawScores
          .whereType<Map>()
          .map((item) {
            final json = Map<String, dynamic>.from(item);
            final scoreValue = (json['score'] as num?)?.toInt() ?? 0;
            final completedAt = DateTime.tryParse((json['completedAt'] ?? '').toString()) ??
                DateTime.now();
            return GameScoreModel(
              id: (json['id'] ?? '').toString(),
              gameId: (json['gameId'] ?? '').toString(),
              gameType: (json['gameType'] ?? '').toString(),
              score: scoreValue,
              maxScore: scoreValue > 0 ? scoreValue : 100,
              completedAt: completedAt,
              timeSpentSeconds: (json['timeTaken'] as num?)?.toInt() ?? 0,
              difficulty: (json['difficulty'] ?? 'easy').toString(),
              isWon: scoreValue > 0,
            );
          })
          .toList();

      final progressEntries = rawProgress
          .whereType<Map>()
          .map((item) {
            final json = Map<String, dynamic>.from(item);
            final lastViewed = DateTime.tryParse((json['lastAccessedAt'] ?? '').toString()) ??
                DateTime.now();
            return ProgressModel(
              topicId: (json['topicId'] ?? '').toString(),
              lastViewed: lastViewed,
              viewCount: 1,
              isCompleted: true,
              progressPercentage: 100.0,
            );
          })
          .where((p) => p.topicId.isNotEmpty)
          .toList();

      final bookmarkIds = rawBookmarks
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item)['topicId'])
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      if (scores.isNotEmpty) {
        await HiveService.gameScoresBox.clear();
        await HiveService.gameScoresBox.putAll({
          for (final score in scores) score.id: score,
        });
      }

      if (progressEntries.isNotEmpty) {
        await HiveService.progressBox.clear();
        await HiveService.progressBox.putAll({
          for (final progress in progressEntries) progress.topicId: progress,
        });
      }

      if (bookmarkIds.isNotEmpty) {
        await HiveService.bookmarksBox.clear();
        for (final topicId in bookmarkIds) {
          await HiveService.bookmarksBox.add(topicId);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Could not sync user state from backend: $e');
    }
  }

  static Future<void> _seedBadges(BadgeRepository repo) async {
    final badges = <BadgeModel>[
      // Reading badges
      BadgeModel(
        id: 'badge_read_5',
        title: 'Curious Reader',
        description: 'Read 5 topics',
        iconPath: 'images/badges/first_reader.png',
        category: 'reading',
        requiredCount: AppConstants.badgeTopicsRead5,
      ),
      BadgeModel(
        id: 'badge_read_10',
        title: 'Knowledge Seeker',
        description: 'Read 10 topics',
        iconPath: 'images/badges/knowledge_king.png',
        category: 'reading',
        requiredCount: AppConstants.badgeTopicsRead10,
      ),
      BadgeModel(
        id: 'badge_read_25',
        title: 'Encyclopedia Master',
        description: 'Read 25 topics',
        iconPath: 'images/badges/explorer.png',
        category: 'reading',
        requiredCount: AppConstants.badgeTopicsRead25,
      ),

      // Gaming badges
      BadgeModel(
        id: 'badge_games_5',
        title: 'Game Starter',
        description: 'Win 5 games',
        iconPath: 'images/badges/quick_learner.png',
        category: 'gaming',
        requiredCount: AppConstants.badgeGamesWon5,
      ),
      BadgeModel(
        id: 'badge_games_10',
        title: 'Game Champion',
        description: 'Win 10 games',
        iconPath: 'images/badges/game_master.png',
        category: 'gaming',
        requiredCount: AppConstants.badgeGamesWon10,
      ),
      BadgeModel(
        id: 'badge_games_25',
        title: 'Game Legend',
        description: 'Win 25 games',
        iconPath: 'images/badges/perfect_score.png',
        category: 'gaming',
        requiredCount: AppConstants.badgeGamesWon25,
      ),
    ];

    await repo.saveBadges(badges);
  }
}
