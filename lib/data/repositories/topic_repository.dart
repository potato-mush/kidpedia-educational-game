import 'package:flutter/foundation.dart';
import 'package:kidpedia/data/local/hive_service.dart';
import 'package:kidpedia/data/models/topic_model.dart';
import 'package:kidpedia/data/services/api_service.dart';

class TopicRepository {
  final _box = HiveService.topicsBox;

  // Async methods - fetch from API and wait for response
  Future<List<TopicModel>> getAllTopics() async {
    try {
      final data = await ApiService.getTopics();
      final topics = data.map((json) {
        return TopicModel(
          id: json['id'] as String,
          title: json['title'] as String,
          category: json['category'] as String,
          summary: json['summary'] as String,
          content: json['content'] as String,
          thumbnailPath: json['thumbnailPath'] as String? ?? '',
          imagePaths: (json['imagePaths'] as List?)?.cast<String>() ?? [],
          videoPath: json['videoPath'] as String?,
          audioPath: json['audioPath'] as String?,
          funFacts: (json['funFacts'] as List?)?.cast<String>() ?? [],
          relatedTopicIds: (json['relatedTopicIds'] as List?)?.cast<String>() ?? [],
          readCount: json['readCount'] as int? ?? 0,
          createdAt: json['createdAt'] != null 
              ? DateTime.parse(json['createdAt'] as String) 
              : DateTime.now(),
        );
      }).toList();
      await saveTopics(topics);
      return topics;
    } catch (e) {
      debugPrint('❌ Error fetching topics: $e');
      // Return cached data if API fails
      return _box.values.toList();
    }
  }

  // Sync methods - return cached data immediately
  List<TopicModel> getAllTopicsSync() {
    // Trigger background update if cache is empty
    if (_box.isEmpty) {
      _updateTopicsFromApi();
    }
    return _box.values.toList();
  }

  TopicModel? getTopicByIdSync(String id) {
    // Trigger background update
    _updateTopicFromApi(id);
    try {
      return _box.values.firstWhere((topic) => topic.id == id);
    } catch (e) {
      return null;
    }
  }

  List<TopicModel> getTopicsByCategorySync(String category) {
    // Trigger background update
    _updateTopicsByCategoryFromApi(category);
    return _box.values
        .where((topic) => topic.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  // Background update methods (fire and forget)
  void _updateTopicsFromApi() async {
    try {
      final data = await ApiService.getTopics();
      final topics = data.map((json) {
        return TopicModel(
          id: json['id'] as String,
          title: json['title'] as String,
          category: json['category'] as String,
          summary: json['summary'] as String,
          content: json['content'] as String,
          thumbnailPath: json['thumbnailPath'] as String? ?? '',
          imagePaths: (json['imagePaths'] as List?)?.cast<String>() ?? [],
          videoPath: json['videoPath'] as String?,
          audioPath: json['audioPath'] as String?,
          funFacts: (json['funFacts'] as List?)?.cast<String>() ?? [],
          relatedTopicIds: (json['relatedTopicIds'] as List?)?.cast<String>() ?? [],
          readCount: json['readCount'] as int? ?? 0,
          createdAt: json['createdAt'] != null 
              ? DateTime.parse(json['createdAt'] as String) 
              : DateTime.now(),
        );
      }).toList();
      await saveTopics(topics);
    } catch (e) {
      debugPrint('Background API fetch failed: $e');
    }
  }

  void _updateTopicFromApi(String id) async {
    try {
      final json = await ApiService.getTopicById(id);
      final topic = TopicModel(
        id: json['id'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        summary: json['summary'] as String,
        content: json['content'] as String,
        thumbnailPath: json['thumbnailPath'] as String? ?? '',
        imagePaths: (json['imagePaths'] as List?)?.cast<String>() ?? [],
        videoPath: json['videoPath'] as String?,
        audioPath: json['audioPath'] as String?,
        funFacts: (json['funFacts'] as List?)?.cast<String>() ?? [],
        relatedTopicIds: (json['relatedTopicIds'] as List?)?.cast<String>() ?? [],
        readCount: json['readCount'] as int? ?? 0,
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt'] as String) 
            : DateTime.now(),
      );
      await saveTopic(topic);
    } catch (e) {
      debugPrint('Background API fetch failed: $e');
    }
  }

  void _updateTopicsByCategoryFromApi(String category) async {
    try {
      final data = await ApiService.getTopicsByCategory(category);
      final topics = data.map((json) {
        return TopicModel(
          id: json['id'] as String,
          title: json['title'] as String,
          category: json['category'] as String,
          summary: json['summary'] as String,
          content: json['content'] as String,
          thumbnailPath: json['thumbnailPath'] as String? ?? '',
          imagePaths: (json['imagePaths'] as List?)?.cast<String>() ?? [],
          videoPath: json['videoPath'] as String?,
          audioPath: json['audioPath'] as String?,
          funFacts: (json['funFacts'] as List?)?.cast<String>() ?? [],
          relatedTopicIds: (json['relatedTopicIds'] as List?)?.cast<String>() ?? [],
          readCount: json['readCount'] as int? ?? 0,
          createdAt: json['createdAt'] != null 
              ? DateTime.parse(json['createdAt'] as String) 
              : DateTime.now(),
        );
      }).toList();
      await saveTopics(topics);
    } catch (e) {
      debugPrint('Background API fetch failed: $e');
    }
  }

  // Save topic
  Future<void> saveTopic(TopicModel topic) async {
    await _box.put(topic.id, topic);
  }

  // Save multiple topics
  Future<void> saveTopics(List<TopicModel> topics) async {
    final Map<String, TopicModel> topicsMap = {
      for (var topic in topics) topic.id: topic
    };
    await _box.putAll(topicsMap);
  }

  // Update topic
  Future<void> updateTopic(TopicModel topic) async {
    await _box.put(topic.id, topic);
  }

  // Delete topic
  Future<void> deleteTopic(String id) async {
    await _box.delete(id);
  }

  // Search topics
  List<TopicModel> searchTopics(String query) {
    final lowerQuery = query.toLowerCase();
    return _box.values.where((topic) {
      return topic.title.toLowerCase().contains(lowerQuery) ||
          topic.summary.toLowerCase().contains(lowerQuery) ||
          topic.content.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Get featured topics (most read)
  List<TopicModel> getFeaturedTopics({int limit = 5}) {
    final topics = _box.values.toList();
    topics.sort((a, b) => b.readCount.compareTo(a.readCount));
    return topics.take(limit).toList();
  }

  // Increment read count
  Future<void> incrementReadCount(String topicId) async {
    // Update backend first
    try {
      await ApiService.incrementTopicReadCount(topicId);
    } catch (e) {
      debugPrint('Failed to increment read count on backend: $e');
    }
    
    // Update local cache
    final topic = getTopicByIdSync(topicId);
    if (topic != null) {
      final updatedTopic = topic.copyWith(
        readCount: topic.readCount + 1,
      );
      await updateTopic(updatedTopic);
    }
  }

  // Get related topics
  List<TopicModel> getRelatedTopics(String topicId) {
    final topic = getTopicByIdSync(topicId);
    if (topic == null) return [];

    return topic.relatedTopicIds
        .map((id) {
          try {
            return getTopicByIdSync(id);
          } catch (e) {
            return null;
          }
        })
        .whereType<TopicModel>()
        .toList();
  }

  // Get all categories
  List<String> getAllCategories() {
    return _box.values.map((topic) => topic.category).toSet().toList();
  }

  // Get topic count by category
  Map<String, int> getTopicCountByCategory() {
    final Map<String, int> counts = {};
    for (final topic in _box.values) {
      counts[topic.category] = (counts[topic.category] ?? 0) + 1;
    }
    return counts;
  }
}
