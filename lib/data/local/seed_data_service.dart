import 'package:flutter/foundation.dart';
import 'package:kidpedia/data/models/badge_model.dart';
import 'package:kidpedia/data/models/user_profile_model.dart';
import 'package:kidpedia/data/models/leaderboard_entry_model.dart';
import 'package:kidpedia/data/repositories/topic_repository.dart';
import 'package:kidpedia/data/repositories/game_repository.dart';
import 'package:kidpedia/data/repositories/badge_repository.dart';
import 'package:kidpedia/data/repositories/user_profile_repository.dart';
import 'package:kidpedia/data/repositories/leaderboard_repository.dart';
import 'package:kidpedia/data/local/bot_players_service.dart';
import 'package:kidpedia/core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';

class SeedDataService {
  static const _uuid = Uuid();

  static Future<void> seedAll() async {
    final badgeRepo = BadgeRepository();
    final userRepo = UserProfileRepository();
    final leaderboardRepo = LeaderboardRepository();

    // Initialize user profile if doesn't exist
    var currentUser = userRepo.getCurrentUser();
    if (currentUser == null) {
      final userId = _uuid.v4();
      currentUser = UserProfileModel(
        id: userId,
        username: 'Young Explorer',
        avatarId: 'avatar_cat',
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      await userRepo.saveCurrentUser(currentUser);
    }

    // Add current user to leaderboard if not exists
    final userLeaderboardEntry = leaderboardRepo.getUserEntry(currentUser.id);
    if (userLeaderboardEntry == null) {
      final userEntry = LeaderboardEntryModel(
        id: currentUser.id,
        playerName: currentUser.username,
        totalScore: 0,
        gamesWon: 0,
        topicsRead: 0,
        avatarId: currentUser.avatarId,
        isCurrentUser: true,
        lastUpdated: DateTime.now(),
      );
      await leaderboardRepo.addBotPlayer(userEntry);
    }

    // NOTE: Topics and Games are now fetched from the backend server
    // Fetch initial data from API on first launch
    final topicRepo = TopicRepository();
    final gameRepo = GameRepository();
    
    try {
      // Fetch topics and games from backend API
      await topicRepo.getAllTopics();
      await gameRepo.getAllGames();
      debugPrint('✅ Successfully loaded data from backend API');
    } catch (e) {
      debugPrint('❌ Error loading data from backend: $e');
      debugPrint('⚠️  Make sure backend server is running at http://localhost:8080');
    }
    
    // Seed Badges (these are small and don't require media)
    await _seedBadges(badgeRepo);

    // Generate bot players for leaderboard
    await BotPlayersService.generateBotPlayers();
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
