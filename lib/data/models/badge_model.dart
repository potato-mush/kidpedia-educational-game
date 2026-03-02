import 'package:hive/hive.dart';

part 'badge_model.g.dart';

@HiveType(typeId: 3)
class BadgeModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String iconPath;

  @HiveField(4)
  final bool isUnlocked;

  @HiveField(5)
  final DateTime? unlockedAt;

  @HiveField(6)
  final String category;

  @HiveField(7)
  final int requiredCount;

  @HiveField(8)
  final int currentCount;

  BadgeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    this.isUnlocked = false,
    this.unlockedAt,
    required this.category,
    required this.requiredCount,
    this.currentCount = 0,
  });

  BadgeModel copyWith({
    String? id,
    String? title,
    String? description,
    String? iconPath,
    bool? isUnlocked,
    DateTime? unlockedAt,
    String? category,
    int? requiredCount,
    int? currentCount,
  }) {
    return BadgeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      category: category ?? this.category,
      requiredCount: requiredCount ?? this.requiredCount,
      currentCount: currentCount ?? this.currentCount,
    );
  }

  double get progress => currentCount / requiredCount;
}
