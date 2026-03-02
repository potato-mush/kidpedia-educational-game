import 'package:hive/hive.dart';

part 'game_score_model.g.dart';

@HiveType(typeId: 4)
class GameScoreModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String gameId;

  @HiveField(2)
  final String gameType;

  @HiveField(3)
  final int score;

  @HiveField(4)
  final int maxScore;

  @HiveField(5)
  final DateTime completedAt;

  @HiveField(6)
  final int timeSpentSeconds;

  @HiveField(7)
  final String difficulty;

  @HiveField(8)
  final bool isWon;

  GameScoreModel({
    required this.id,
    required this.gameId,
    required this.gameType,
    required this.score,
    required this.maxScore,
    required this.completedAt,
    required this.timeSpentSeconds,
    required this.difficulty,
    required this.isWon,
  });

  double get percentage => (score / maxScore * 100).clamp(0, 100);

  GameScoreModel copyWith({
    String? id,
    String? gameId,
    String? gameType,
    int? score,
    int? maxScore,
    DateTime? completedAt,
    int? timeSpentSeconds,
    String? difficulty,
    bool? isWon,
  }) {
    return GameScoreModel(
      id: id ?? this.id,
      gameId: gameId ?? this.gameId,
      gameType: gameType ?? this.gameType,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      completedAt: completedAt ?? this.completedAt,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      difficulty: difficulty ?? this.difficulty,
      isWon: isWon ?? this.isWon,
    );
  }
}
