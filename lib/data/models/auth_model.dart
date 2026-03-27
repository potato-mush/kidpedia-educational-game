class AuthUser {
  final String id;
  final String username;
  final String avatarId;

  AuthUser({
    required this.id,
    required this.username,
    required this.avatarId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'avatarId': avatarId,
  };

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id'] as String,
    username: json['username'] as String,
    avatarId: json['avatarId'] as String,
  );

  AuthUser copyWith({
    String? id,
    String? username,
    String? avatarId,
  }) => AuthUser(
    id: id ?? this.id,
    username: username ?? this.username,
    avatarId: avatarId ?? this.avatarId,
  );
}
