import 'package:hive/hive.dart';

part 'topic_model.g.dart';

@HiveType(typeId: 0)
class TopicModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String category;

  @HiveField(3)
  final String summary;

  @HiveField(4)
  final String content;

  @HiveField(5)
  final List<String> imagePaths;

  @HiveField(6)
  final String? videoPath;

  @HiveField(7)
  final String? audioPath;

  @HiveField(8)
  final List<String> funFacts;

  @HiveField(9)
  final List<String> relatedTopicIds;

  @HiveField(10)
  final String thumbnailPath;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final int readCount;

  TopicModel({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.content,
    required this.imagePaths,
    this.videoPath,
    this.audioPath,
    required this.funFacts,
    required this.relatedTopicIds,
    required this.thumbnailPath,
    required this.createdAt,
    this.readCount = 0,
  });

  TopicModel copyWith({
    String? id,
    String? title,
    String? category,
    String? summary,
    String? content,
    List<String>? imagePaths,
    String? videoPath,
    String? audioPath,
    List<String>? funFacts,
    List<String>? relatedTopicIds,
    String? thumbnailPath,
    DateTime? createdAt,
    int? readCount,
  }) {
    return TopicModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      summary: summary ?? this.summary,
      content: content ?? this.content,
      imagePaths: imagePaths ?? this.imagePaths,
      videoPath: videoPath ?? this.videoPath,
      audioPath: audioPath ?? this.audioPath,
      funFacts: funFacts ?? this.funFacts,
      relatedTopicIds: relatedTopicIds ?? this.relatedTopicIds,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      readCount: readCount ?? this.readCount,
    );
  }
}
