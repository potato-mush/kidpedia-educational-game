import 'package:hive/hive.dart';

part 'progress_model.g.dart';

@HiveType(typeId: 2)
class ProgressModel extends HiveObject {
  @HiveField(0)
  final String topicId;

  @HiveField(1)
  final DateTime lastViewed;

  @HiveField(2)
  final int viewCount;

  @HiveField(3)
  final bool isCompleted;

  @HiveField(4)
  final double progressPercentage;

  ProgressModel({
    required this.topicId,
    required this.lastViewed,
    required this.viewCount,
    this.isCompleted = false,
    this.progressPercentage = 0.0,
  });

  ProgressModel copyWith({
    String? topicId,
    DateTime? lastViewed,
    int? viewCount,
    bool? isCompleted,
    double? progressPercentage,
  }) {
    return ProgressModel(
      topicId: topicId ?? this.topicId,
      lastViewed: lastViewed ?? this.lastViewed,
      viewCount: viewCount ?? this.viewCount,
      isCompleted: isCompleted ?? this.isCompleted,
      progressPercentage: progressPercentage ?? this.progressPercentage,
    );
  }
}
