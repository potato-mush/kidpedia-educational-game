import 'package:hive/hive.dart';
import 'package:kidpedia/data/models/leaderboard_entry_model.dart';
import 'package:kidpedia/data/models/user_profile_model.dart';
import 'package:kidpedia/data/repositories/game_repository.dart';
import 'package:kidpedia/data/repositories/progress_repository.dart';
import 'package:kidpedia/data/repositories/badge_repository.dart';

class LeaderboardRepository {
  static const _boxName = 'leaderboard';
  static const _userProfileBoxName = 'user_profile';

  Box<LeaderboardEntryModel> get _box => Hive.box<LeaderboardEntryModel>(_boxName);
  Box<UserProfileModel> get _userProfileBox => Hive.box<UserProfileModel>(_userProfileBoxName);

  // Get all leaderboard entries sorted by score
  List<LeaderboardEntryModel> getLeaderboard() {
    final entries = _box.values.toList();
    entries.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return entries;
  }

  // Get top N entries
  List<LeaderboardEntryModel> getTopEntries(int count) {
    final entries = getLeaderboard();
    return entries.take(count).toList();
  }

  // Get user's rank
  int getUserRank(String userId) {
    final entries = getLeaderboard();
    final index = entries.indexWhere((e) => e.id == userId);
    return index + 1; // 1-based ranking
  }

  // Update user's entry
  Future<void> updateUserEntry({
    required String userId,
    required String username,
    required int totalScore,
    required int gamesWon,
    required int topicsRead,
    required String avatarId,
  }) async {
    final existing = _box.values.firstWhere(
      (e) => e.id == userId,
      orElse: () => LeaderboardEntryModel(
        id: userId,
        playerName: username,
        totalScore: 0,
        gamesWon: 0,
        topicsRead: 0,
        avatarId: avatarId,
        isCurrentUser: true,
        lastUpdated: DateTime.now(),
      ),
    );

    final updated = existing.copyWith(
      playerName: username,
      totalScore: totalScore,
      gamesWon: gamesWon,
      topicsRead: topicsRead,
      avatarId: avatarId,
      lastUpdated: DateTime.now(),
    );

    await _box.put(userId, updated);
  }

  // Add bot player
  Future<void> addBotPlayer(LeaderboardEntryModel entry) async {
    await _box.put(entry.id, entry);
  }

  // Clear all entries (for reset)
  Future<void> clearAll() async {
    await _box.clear();
  }

  // Get entries by score range
  List<LeaderboardEntryModel> getEntriesInRange(int minScore, int maxScore) {
    return _box.values
        .where((e) => e.totalScore >= minScore && e.totalScore <= maxScore)
        .toList();
  }

  // Get user's entry
  LeaderboardEntryModel? getUserEntry(String userId) {
    try {
      return _box.values.firstWhere((e) => e.id == userId);
    } catch (e) {
      return null;
    }
  }

  // Get current user's entry
  Future<LeaderboardEntryModel?> getCurrentUserEntry() async {
    try {
      final currentUser = _userProfileBox.get('current_user');
      if (currentUser == null) return null;
      return getUserEntry(currentUser.id);
    } catch (e) {
      return null;
    }
  }

  // Update user stats (called after games or topic reads)
  Future<void> updateUserStats(String userId) async {
    // Calculate total score based on achievements
    final gameRepo = GameRepository();
    final progressRepo = ProgressRepository();
    final badgeRepo = BadgeRepository();
    
    final gamesWon = gameRepo.getTotalGamesWon();
    final topicsRead = progressRepo.getTotalTopicsViewed();
    final unlockedBadges = badgeRepo.getUnlockedBadges().length;
    
    // Calculate total score from all game scores
    final allScores = gameRepo.getAllScores();
    final totalGameScore = allScores.fold<int>(
      0,
      (sum, scoreModel) => sum + scoreModel.score,
    );
    
    // Scoring formula:
    // Base: 100 points
    // Actual game scores: sum of all game scores
    // Topics read: 50 points each
    // Badges unlocked: 200 points each
    final totalScore = 100 + totalGameScore + (topicsRead * 50) + (unlockedBadges * 200);
    
    // Get user profile for username and avatar
    final userProfile = _userProfileBox.get('current_user');
    if (userProfile == null) return;
    
    final existingEntry = getUserEntry(userId);

    // Prevent accidental resets by never writing lower aggregate values
    // than an already stored leaderboard entry.
    final safeTotalScore = existingEntry != null
        ? (totalScore > existingEntry.totalScore ? totalScore : existingEntry.totalScore)
        : totalScore;
    final safeGamesWon = existingEntry != null
        ? (gamesWon > existingEntry.gamesWon ? gamesWon : existingEntry.gamesWon)
        : gamesWon;
    final safeTopicsRead = existingEntry != null
        ? (topicsRead > existingEntry.topicsRead ? topicsRead : existingEntry.topicsRead)
        : topicsRead;

    // Update or create leaderboard entry
    await updateUserEntry(
      userId: userId,
      username: userProfile.username,
      totalScore: safeTotalScore,
      gamesWon: safeGamesWon,
      topicsRead: safeTopicsRead,
      avatarId: userProfile.avatarId,
    );
  }
}
