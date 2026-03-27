import 'package:flutter/foundation.dart';
import 'package:kidpedia/data/local/hive_service.dart';
import 'package:kidpedia/data/models/game_model.dart';
import 'package:kidpedia/data/models/game_score_model.dart';
import 'package:kidpedia/data/services/api_service.dart';

class GameRepository {
  final _gamesBox = HiveService.gamesBox;
  final _scoresBox = HiveService.gameScoresBox;

  String _readString(Map<String, dynamic> json, String key, {String fallback = ''}) {
    final value = json[key];
    if (value is String) return value;
    if (value == null) return fallback;
    return value.toString();
  }

  DateTime _readDateTime(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  Map<String, dynamic> _readConfig(Map<String, dynamic> json) {
    final config = json['configurationData'];
    if (config is Map<String, dynamic>) {
      return config;
    }
    return {};
  }

  GameModel _gameFromJson(Map<String, dynamic> json) {
    return GameModel(
      id: _readString(json, 'id'),
      topicId: _readString(json, 'topicId'),
      type: _readString(json, 'type'),
      title: _readString(json, 'title', fallback: 'Untitled Game'),
      description: _readString(json, 'description'),
      difficulty: _readString(json, 'difficulty', fallback: 'easy'),
      configurationData: _readConfig(json),
      createdAt: _readDateTime(json, 'createdAt'),
    );
  }

  // Helper method to check if a game is valid
  bool _isValidGame(GameModel game) {
    if (game.type == 'sound_match') {
      final config = game.configurationData;
      final pairs = config['pairs'] as List<dynamic>? ?? 
                    config['sounds'] as List<dynamic>? ?? [];
      return pairs.isNotEmpty;
    }
    return true; // Other game types are valid
  }

  // Async methods - fetch from API and wait for response
  Future<List<GameModel>> getAllGames() async {
    try {
      final data = await ApiService.getGames();
      final games = data
          .whereType<Map>()
          .map((json) => _gameFromJson(Map<String, dynamic>.from(json)))
          .toList();
      await saveGames(games);
      return games.where(_isValidGame).toList();
    } catch (e) {
      debugPrint('❌ Error fetching games: $e');
      // Return cached data if API fails
      return _gamesBox.values.where(_isValidGame).toList();
    }
  }

  // Sync methods - return cached data immediately
  List<GameModel> getAllGamesSync() {
    // Trigger background update if cache is empty
    if (_gamesBox.isEmpty) {
      _updateGamesFromApi();
    }
    return _gamesBox.values.where(_isValidGame).toList();
  }

  GameModel? getGameByIdSync(String id) {
    // Trigger background update
    _updateGameFromApi(id);
    try {
      return _gamesBox.values.firstWhere((game) => game.id == id);
    } catch (e) {
      return null;
    }
  }

  List<GameModel> getGamesByTypeSync(String type) {
    // Trigger background update
    _updateGamesByTypeFromApi(type);
    return _gamesBox.values
        .where((game) => game.type == type && _isValidGame(game))
        .toList();
  }

  // Background update methods
  void _updateGamesFromApi() async {
    try {
      final data = await ApiService.getGames();
      final games = data
          .whereType<Map>()
          .map((json) => _gameFromJson(Map<String, dynamic>.from(json)))
          .toList();
      await saveGames(games);
    } catch (e) {
      debugPrint('Background API fetch failed: $e');
    }
  }

  void _updateGameFromApi(String id) async {
    try {
      final json = await ApiService.getGameById(id);
      final game = _gameFromJson(json);
      await saveGame(game);
    } catch (e) {
      debugPrint('Background API fetch failed: $e');
    }
  }

  void _updateGamesByTypeFromApi(String type) async {
    try {
      final data = await ApiService.getGamesByType(type);
      final games = data
          .whereType<Map>()
          .map((json) => _gameFromJson(Map<String, dynamic>.from(json)))
          .toList();
      await saveGames(games);
    } catch (e) {
      debugPrint('Background API fetch failed: $e');
    }
  }

  // Get games by topic
  List<GameModel> getGamesByTopic(String topicId) {
    return _gamesBox.values
        .where((game) => game.topicId == topicId)
        .toList();
  }

  // Get games by difficulty
  List<GameModel> getGamesByDifficulty(String difficulty) {
    return _gamesBox.values
        .where((game) => game.difficulty == difficulty)
        .toList();
  }

  // Save game
  Future<void> saveGame(GameModel game) async {
    await _gamesBox.put(game.id, game);
  }

  // Save multiple games
  Future<void> saveGames(List<GameModel> games) async {
    final Map<String, GameModel> gamesMap = {
      for (var game in games) game.id: game
    };
    await _gamesBox.putAll(gamesMap);
  }

  // Update game
  Future<void> updateGame(GameModel game) async {
    await _gamesBox.put(game.id, game);
  }

  // Delete game
  Future<void> deleteGame(String id) async {
    await _gamesBox.delete(id);
  }

  // Save game score
  Future<void> saveGameScore(GameScoreModel score) async {
    await _scoresBox.put(score.id, score);

    final currentUser = HiveService.userProfileBox.get('current_user');
    if (currentUser == null) {
      return;
    }

    try {
      // Keep the backend user profile in sync before score submission.
      await ApiService.upsertUserProfile(
        id: currentUser.id,
        username: currentUser.username,
        avatarId: currentUser.avatarId,
      );

      await ApiService.submitGameScore(
        userId: currentUser.id,
        gameId: score.gameId,
        score: score.score,
        timeTaken: score.timeSpentSeconds,
        completedAt: score.completedAt,
      );
    } on ApiException catch (e) {
      if (e.statusCode == 404 && e.message.contains('Game not found')) {
        debugPrint(
          '⚠️ Score saved locally; remote game not found for gameId=${score.gameId}.',
        );
        return;
      }

      debugPrint('⚠️ Score saved locally but sync failed: $e');
    } catch (e) {
      debugPrint('⚠️ Score saved locally but sync failed: $e');
    }
  }

  // Get scores for a game
  List<GameScoreModel> getScoresForGame(String gameId) {
    return _scoresBox.values
        .where((score) => score.gameId == gameId)
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  // Get all scores
  List<GameScoreModel> getAllScores() {
    return _scoresBox.values.toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  // Get high score for game
  GameScoreModel? getHighScoreForGame(String gameId) {
    final scores = getScoresForGame(gameId);
    if (scores.isEmpty) return null;
    
    scores.sort((a, b) => b.score.compareTo(a.score));
    return scores.first;
  }

  // Get total games won
  int getTotalGamesWon() {
    return _scoresBox.values.where((score) => score.isWon).length;
  }

  // Get total games played
  int getTotalGamesPlayed() {
    return _scoresBox.values.length;
  }

  // Get average score
  double getAverageScore() {
    final scores = _scoresBox.values.toList();
    if (scores.isEmpty) return 0.0;
    
    final totalPercentage = scores.fold<double>(
      0.0,
      (sum, score) => sum + score.percentage,
    );
    return totalPercentage / scores.length;
  }

  // Get scores by game type
  List<GameScoreModel> getScoresByGameType(String gameType) {
    return _scoresBox.values
        .where((score) => score.gameType == gameType)
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  // Calculate win rate
  double getWinRate() {
    final totalGames = getTotalGamesPlayed();
    if (totalGames == 0) return 0.0;
    
    final gamesWon = getTotalGamesWon();
    return (gamesWon / totalGames) * 100;
  }
}
