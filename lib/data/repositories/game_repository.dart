import 'package:flutter/foundation.dart';
import 'package:kidpedia/data/local/hive_service.dart';
import 'package:kidpedia/data/models/game_model.dart';
import 'package:kidpedia/data/models/game_score_model.dart';
import 'package:kidpedia/data/services/api_service.dart';

class GameRepository {
  final _gamesBox = HiveService.gamesBox;
  final _scoresBox = HiveService.gameScoresBox;

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
      final games = data.map((json) {
        return GameModel(
          id: json['id'] as String,
          topicId: json['topicId'] as String,
          type: json['type'] as String,
          title: json['title'] as String,
          description: json['description'] as String? ?? '',
          difficulty: json['difficulty'] as String,
          configurationData: json['configurationData'] as Map<String, dynamic>? ?? {},
          createdAt: json['createdAt'] != null 
              ? DateTime.parse(json['createdAt'] as String) 
              : DateTime.now(),
        );
      }).toList();
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
      final games = data.map((json) {
        return GameModel(
          id: json['id'] as String,
          topicId: json['topicId'] as String,
          type: json['type'] as String,
          title: json['title'] as String,
          description: json['description'] as String? ?? '',
          difficulty: json['difficulty'] as String,
          configurationData: json['configurationData'] as Map<String, dynamic>? ?? {},
          createdAt: json['createdAt'] != null 
              ? DateTime.parse(json['createdAt'] as String) 
              : DateTime.now(),
        );
      }).toList();
      await saveGames(games);
    } catch (e) {
      debugPrint('Background API fetch failed: $e');
    }
  }

  void _updateGameFromApi(String id) async {
    try {
      final json = await ApiService.getGameById(id);
      final game = GameModel(
        id: json['id'] as String,
        topicId: json['topicId'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        difficulty: json['difficulty'] as String,
        configurationData: json['configurationData'] as Map<String, dynamic>? ?? {},
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt'] as String) 
            : DateTime.now(),
      );
      await saveGame(game);
    } catch (e) {
      debugPrint('Background API fetch failed: $e');
    }
  }

  void _updateGamesByTypeFromApi(String type) async {
    try {
      final data = await ApiService.getGamesByType(type);
      final games = data.map((json) {
        return GameModel(
          id: json['id'] as String,
          topicId: json['topicId'] as String,
          type: json['type'] as String,
          title: json['title'] as String,
          description: json['description'] as String? ?? '',
          difficulty: json['difficulty'] as String,
          configurationData: json['configurationData'] as Map<String, dynamic>? ?? {},
          createdAt: json['createdAt'] != null 
              ? DateTime.parse(json['createdAt'] as String) 
              : DateTime.now(),
        );
      }).toList();
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
