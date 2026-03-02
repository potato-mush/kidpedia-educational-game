import 'package:hive/hive.dart';

part 'leaderboard_entry_model.g.dart';

@HiveType(typeId: 5)
class LeaderboardEntryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String playerName;

  @HiveField(2)
  final int totalScore;

  @HiveField(3)
  final int gamesWon;

  @HiveField(4)
  final int topicsRead;

  @HiveField(5)
  final String avatarId;

  @HiveField(6)
  final bool isCurrentUser;

  @HiveField(7)
  final DateTime lastUpdated;

  LeaderboardEntryModel({
    required this.id,
    required this.playerName,
    required this.totalScore,
    required this.gamesWon,
    required this.topicsRead,
    required this.avatarId,
    this.isCurrentUser = false,
    required this.lastUpdated,
  });

  LeaderboardEntryModel copyWith({
    String? id,
    String? playerName,
    int? totalScore,
    int? gamesWon,
    int? topicsRead,
    String? avatarId,
    bool? isCurrentUser,
    DateTime? lastUpdated,
  }) {
    return LeaderboardEntryModel(
      id: id ?? this.id,
      playerName: playerName ?? this.playerName,
      totalScore: totalScore ?? this.totalScore,
      gamesWon: gamesWon ?? this.gamesWon,
      topicsRead: topicsRead ?? this.topicsRead,
      avatarId: avatarId ?? this.avatarId,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
