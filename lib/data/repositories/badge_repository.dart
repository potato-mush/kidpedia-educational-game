import 'package:flutter/foundation.dart';
import 'package:kidpedia/data/local/hive_service.dart';
import 'package:kidpedia/data/models/badge_model.dart';
import 'package:kidpedia/core/constants/app_constants.dart';
import 'package:kidpedia/data/services/api_service.dart';

class BadgeRepository {
  final _box = HiveService.badgesBox;

  String _readString(Map<String, dynamic> json, List<String> keys, {String fallback = ''}) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.isNotEmpty) {
        return value;
      }
    }
    return fallback;
  }

  int _readInt(Map<String, dynamic> json, List<String> keys, {int fallback = 0}) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) return parsed;
      }
    }
    return fallback;
  }

  BadgeModel _badgeFromJson(Map<String, dynamic> json) {
    final id = _readString(json, ['id']);
    final title = _readString(json, ['title', 'name'], fallback: 'Badge');
    final description = _readString(json, ['description', 'requirement']);

    return BadgeModel(
      id: id,
      title: title,
      description: description,
      iconPath: _readString(json, ['iconPath', 'iconName']),
      category: _readString(json, ['category'], fallback: 'general'),
      requiredCount: _readInt(json, ['requiredCount'], fallback: 1),
      currentCount: _readInt(json, ['currentCount']),
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.tryParse(json['unlockedAt'].toString())
          : null,
    );
  }

  // Sync method - return cached data immediately
  List<BadgeModel> getAllBadgesSync() {
    // Trigger background update
    _updateBadgesFromApi();
    return _box.values.toList();
  }

  // Background update method
  void _updateBadgesFromApi() async {
    try {
      final data = await ApiService.getBadges();
      final badges = data.map((json) {
        return _badgeFromJson(Map<String, dynamic>.from(json as Map));
      }).toList();
      await saveBadges(badges);
    } catch (e) {
      debugPrint('Background API fetch failed: $e');
    }
  }

  // Get unlocked badges
  List<BadgeModel> getUnlockedBadges() {
    return _box.values.where((badge) => badge.isUnlocked).toList();
  }

  // Get locked badges
  List<BadgeModel> getLockedBadges() {
    return _box.values.where((badge) => !badge.isUnlocked).toList();
  }

  // Get badge by ID
  BadgeModel? getBadgeById(String id) {
    try {
      return _box.values.firstWhere((badge) => badge.id == id);
    } catch (e) {
      return null;
    }
  }

  // Save badge
  Future<void> saveBadge(BadgeModel badge) async {
    await _box.put(badge.id, badge);
  }

  // Save multiple badges
  Future<void> saveBadges(List<BadgeModel> badges) async {
    final Map<String, BadgeModel> badgesMap = {
      for (var badge in badges)
        badge.id: (() {
          final existing = getBadgeById(badge.id);
          if (existing == null) {
            return badge;
          }

          final mergedCount = existing.currentCount > badge.currentCount
              ? existing.currentCount
              : badge.currentCount;

          return badge.copyWith(
            isUnlocked: existing.isUnlocked,
            unlockedAt: existing.unlockedAt,
            currentCount: mergedCount,
          );
        })()
    };
    await _box.putAll(badgesMap);
  }

  // Unlock badge
  Future<void> unlockBadge(String badgeId) async {
    final badge = getBadgeById(badgeId);
    if (badge != null && !badge.isUnlocked) {
      final updatedBadge = badge.copyWith(
        isUnlocked: true,
        unlockedAt: DateTime.now(),
      );
      await saveBadge(updatedBadge);
    }
  }

  // Update badge progress
  Future<void> updateBadgeProgress(String badgeId, int currentCount) async {
    final badge = getBadgeById(badgeId);
    if (badge != null) {
      final updatedBadge = badge.copyWith(currentCount: currentCount);
      
      // Unlock if requirement met
      if (currentCount >= badge.requiredCount && !badge.isUnlocked) {
        await unlockBadge(badgeId);
      } else {
        await saveBadge(updatedBadge);
      }
    }
  }

  // Check and update all badges
  Future<List<String>> checkAndUpdateBadges({
    required int topicsRead,
    required int gamesWon,
  }) async {
    final List<String> newlyUnlocked = [];

    // Topics read badges
    final readBadges = {
      'badge_read_5': AppConstants.badgeTopicsRead5,
      'badge_read_10': AppConstants.badgeTopicsRead10,
      'badge_read_25': AppConstants.badgeTopicsRead25,
    };

    for (final entry in readBadges.entries) {
      final badge = getBadgeById(entry.key);
      if (badge != null && !badge.isUnlocked && topicsRead >= entry.value) {
        await unlockBadge(entry.key);
        newlyUnlocked.add(entry.key);
      } else if (badge != null) {
        await updateBadgeProgress(entry.key, topicsRead);
      }
    }

    // Games won badges
    final gameBadges = {
      'badge_games_5': AppConstants.badgeGamesWon5,
      'badge_games_10': AppConstants.badgeGamesWon10,
      'badge_games_25': AppConstants.badgeGamesWon25,
    };

    for (final entry in gameBadges.entries) {
      final badge = getBadgeById(entry.key);
      if (badge != null && !badge.isUnlocked && gamesWon >= entry.value) {
        await unlockBadge(entry.key);
        newlyUnlocked.add(entry.key);
      } else if (badge != null) {
        await updateBadgeProgress(entry.key, gamesWon);
      }
    }

    return newlyUnlocked;
  }

  // Get unlocked count
  int getUnlockedCount() {
    return getUnlockedBadges().length;
  }

  // Get total count
  int getTotalCount() {
    return _box.values.length;
  }

  // Get completion percentage
  double getCompletionPercentage() {
    final total = getTotalCount();
    if (total == 0) return 0.0;
    
    final unlocked = getUnlockedCount();
    return (unlocked / total) * 100;
  }
}
