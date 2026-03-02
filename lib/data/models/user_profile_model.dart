import 'package:hive/hive.dart';

part 'user_profile_model.g.dart';

@HiveType(typeId: 6)
class UserProfileModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String username;

  @HiveField(2)
  String avatarId;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  DateTime lastUpdated;

  UserProfileModel({
    required this.id,
    required this.username,
    required this.avatarId,
    required this.createdAt,
    required this.lastUpdated,
  });

  UserProfileModel copyWith({
    String? id,
    String? username,
    String? avatarId,
    DateTime? createdAt,
    DateTime? lastUpdated,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarId: avatarId ?? this.avatarId,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
