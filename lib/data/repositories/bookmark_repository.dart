import 'package:kidpedia/data/local/hive_service.dart';
import 'package:kidpedia/data/services/api_service.dart';

class BookmarkRepository {
  final _box = HiveService.bookmarksBox;

  // Get all bookmarked topic IDs
  List<String> getAllBookmarks() {
    return _box.values.toList();
  }

  // Check if topic is bookmarked
  bool isBookmarked(String topicId) {
    return _box.values.contains(topicId);
  }

  // Toggle bookmark
  Future<bool> toggleBookmark(String topicId) async {
    if (isBookmarked(topicId)) {
      await removeBookmark(topicId);
      return false;
    } else {
      await addBookmark(topicId);
      return true;
    }
  }

  // Add bookmark
  Future<void> addBookmark(String topicId) async {
    if (!isBookmarked(topicId)) {
      await _box.add(topicId);
      final currentUser = HiveService.userProfileBox.get('current_user');
      if (currentUser != null) {
        try {
          await ApiService.addBookmark(
            userId: currentUser.id,
            topicId: topicId,
          );
        } catch (_) {
          // Keep local bookmarks even when backend sync is temporarily unavailable.
        }
      }
    }
  }

  // Remove bookmark
  Future<void> removeBookmark(String topicId) async {
    final key = _box.keys.firstWhere(
      (key) => _box.get(key) == topicId,
      orElse: () => null,
    );
    if (key != null) {
      await _box.delete(key);

      final currentUser = HiveService.userProfileBox.get('current_user');
      if (currentUser != null) {
        try {
          await ApiService.removeBookmark(
            userId: currentUser.id,
            topicId: topicId,
          );
        } catch (_) {
          // Keep local bookmarks even when backend sync is temporarily unavailable.
        }
      }
    }
  }

  // Get bookmark count
  int getBookmarkCount() {
    return _box.values.length;
  }

  // Clear all bookmarks
  Future<void> clearAllBookmarks() async {
    await _box.clear();
  }
}
