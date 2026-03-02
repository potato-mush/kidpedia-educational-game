import 'package:kidpedia/data/local/hive_service.dart';
import 'package:kidpedia/data/models/progress_model.dart';

class ProgressRepository {
  final _box = HiveService.progressBox;

  // Get progress for topic
  ProgressModel? getProgressForTopic(String topicId) {
    try {
      return _box.values.firstWhere((progress) => progress.topicId == topicId);
    } catch (e) {
      return null;
    }
  }

  // Save progress
  Future<void> saveProgress(ProgressModel progress) async {
    await _box.put(progress.topicId, progress);
  }

  // Update progress
  Future<void> updateProgress(String topicId, {
    bool? isCompleted,
    double? progressPercentage,
  }) async {
    var progress = getProgressForTopic(topicId);
    
    if (progress == null) {
      progress = ProgressModel(
        topicId: topicId,
        lastViewed: DateTime.now(),
        viewCount: 1,
        isCompleted: isCompleted ?? false,
        progressPercentage: progressPercentage ?? 0.0,
      );
    } else {
      progress = progress.copyWith(
        lastViewed: DateTime.now(),
        viewCount: progress.viewCount + 1,
        isCompleted: isCompleted ?? progress.isCompleted,
        progressPercentage: progressPercentage ?? progress.progressPercentage,
      );
    }
    
    await saveProgress(progress);
  }

  // Mark topic as viewed
  Future<void> markTopicAsViewed(String topicId) async {
    await updateProgress(topicId);
  }

  // Mark topic as completed
  Future<void> markTopicAsCompleted(String topicId) async {
    await updateProgress(
      topicId,
      isCompleted: true,
      progressPercentage: 100.0,
    );
  }

  // Get all progress
  List<ProgressModel> getAllProgress() {
    return _box.values.toList();
  }

  // Get recently viewed topics
  List<ProgressModel> getRecentlyViewedTopics({int limit = 10}) {
    final progressList = _box.values.toList();
    progressList.sort((a, b) => b.lastViewed.compareTo(a.lastViewed));
    return progressList.take(limit).toList();
  }

  // Get completed topics
  List<ProgressModel> getCompletedTopics() {
    return _box.values.where((progress) => progress.isCompleted).toList();
  }

  // Get completion percentage
  double getOverallCompletionPercentage(int totalTopics) {
    if (totalTopics == 0) return 0.0;
    
    final completedCount = getCompletedTopics().length;
    return (completedCount / totalTopics) * 100;
  }

  // Get total topics viewed
  int getTotalTopicsViewed() {
    return _box.values.length;
  }

  // Clear progress
  Future<void> clearProgress() async {
    await _box.clear();
  }
}
