import 'package:kidpedia/data/repositories/badge_repository.dart';
import 'package:kidpedia/data/repositories/game_repository.dart';
import 'package:kidpedia/data/repositories/progress_repository.dart';
import 'package:kidpedia/data/repositories/leaderboard_repository.dart';

class BadgeService {
  final BadgeRepository _badgeRepository;
  final GameRepository _gameRepository;
  final ProgressRepository _progressRepository;
  final LeaderboardRepository _leaderboardRepository;

  BadgeService({
    required BadgeRepository badgeRepository,
    required GameRepository gameRepository,
    required ProgressRepository progressRepository,
    required LeaderboardRepository leaderboardRepository,
  })  : _badgeRepository = badgeRepository,
        _gameRepository = gameRepository,
        _progressRepository = progressRepository,
        _leaderboardRepository = leaderboardRepository;

  /// Check and update all badges based on current progress
  Future<List<String>> checkAndUpdateAllBadges() async {
    final newlyUnlocked = <String>[];

    // Get current stats
    final topicsRead = _progressRepository.getTotalTopicsViewed();
    final gamesWon = _gameRepository.getTotalGamesWon();
    final allBadges = _badgeRepository.getAllBadgesSync();

    // Check each badge
    for (final badge in allBadges) {
      if (badge.isUnlocked) continue;

      bool shouldUnlock = false;
      int currentCount = 0;

      switch (badge.category) {
        case 'reading':
          currentCount = topicsRead;
          shouldUnlock = topicsRead >= badge.requiredCount;
          break;
        
        case 'gaming':
          currentCount = gamesWon;
          shouldUnlock = gamesWon >= badge.requiredCount;
          break;
        
        case 'perfect':
          // Check for perfect scores
          final allScores = _gameRepository.getAllScores();
          final perfectScores = allScores.where((score) => 
            score.score == score.maxScore
          ).length;
          currentCount = perfectScores;
          shouldUnlock = perfectScores >= badge.requiredCount;
          break;
        
        case 'explorer':
          // Special exploration badges
          shouldUnlock = badge.requiredCount > 0 && topicsRead >= badge.requiredCount;
          currentCount = topicsRead;
          break;
      }

      // Update progress
      await _badgeRepository.updateBadgeProgress(badge.id, currentCount);

      if (shouldUnlock) {
        await _badgeRepository.unlockBadge(badge.id);
        newlyUnlocked.add(badge.id);
      }
    }

    // Update leaderboard points based on badges
    if (newlyUnlocked.isNotEmpty) {
      await _updateLeaderboardFromBadges();
    }

    return newlyUnlocked;
  }

  /// Update leaderboard score when badges or stats change
  Future<void> _updateLeaderboardFromBadges() async {
    // This will be called to recalculate leaderboard scores
    final user = await _leaderboardRepository.getCurrentUserEntry();
    if (user != null) {
      await _leaderboardRepository.updateUserStats(user.id);
    }
  }

  /// Check badges after a game is completed
  Future<List<String>> checkBadgesAfterGame() async {
    return await checkAndUpdateAllBadges();
  }

  /// Check badges after a topic is read
  Future<List<String>> checkBadgesAfterTopicRead() async {
    return await checkAndUpdateAllBadges();
  }
}
