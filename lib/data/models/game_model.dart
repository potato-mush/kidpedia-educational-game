import 'package:hive/hive.dart';

part 'game_model.g.dart';

@HiveType(typeId: 1)
class GameModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type; // puzzle, sound_match, quiz

  @HiveField(2)
  final String topicId;

  @HiveField(3)
  final String difficulty; // easy, medium, hard

  @HiveField(4)
  final Map<String, dynamic> configurationData;

  @HiveField(5)
  final String title;

  @HiveField(6)
  final String description;

  @HiveField(7)
  final DateTime createdAt;

  GameModel({
    required this.id,
    required this.type,
    required this.topicId,
    required this.difficulty,
    required this.configurationData,
    required this.title,
    required this.description,
    required this.createdAt,
  });

  GameModel copyWith({
    String? id,
    String? type,
    String? topicId,
    String? difficulty,
    Map<String, dynamic>? configurationData,
    String? title,
    String? description,
    DateTime? createdAt,
  }) {
    return GameModel(
      id: id ?? this.id,
      type: type ?? this.type,
      topicId: topicId ?? this.topicId,
      difficulty: difficulty ?? this.difficulty,
      configurationData: configurationData ?? this.configurationData,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
