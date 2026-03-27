import 'package:hive/hive.dart';
import 'package:kidpedia/data/models/user_profile_model.dart';
import 'package:kidpedia/data/services/api_service.dart';

class UserProfileRepository {
  static const _boxName = 'user_profile';
  static const _currentUserKey = 'current_user';

  Box<UserProfileModel> get _box => Hive.box<UserProfileModel>(_boxName);

  // Get current user profile
  UserProfileModel? getCurrentUser() {
    return _box.get(_currentUserKey);
  }

  // Save/Update current user
  Future<void> saveCurrentUser(UserProfileModel profile) async {
    await _box.put(_currentUserKey, profile);

    try {
      await ApiService.upsertUserProfile(
        id: profile.id,
        username: profile.username,
        avatarId: profile.avatarId,
      );
    } catch (_) {
      // Keep local profile available even if backend is temporarily offline.
    }
  }

  // Update username
  Future<void> updateUsername(String username) async {
    final user = getCurrentUser();
    if (user != null) {
      final updated = user.copyWith(
        username: username,
        lastUpdated: DateTime.now(),
      );
      await saveCurrentUser(updated);
    }
  }

  // Update avatar
  Future<void> updateAvatar(String avatarId) async {
    final user = getCurrentUser();
    if (user != null) {
      final updated = user.copyWith(
        avatarId: avatarId,
        lastUpdated: DateTime.now(),
      );
      await saveCurrentUser(updated);
    }
  }
}
