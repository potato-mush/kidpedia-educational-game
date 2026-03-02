import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Auto-detect platform and use appropriate URL
  static String get baseUrl {
    if (kIsWeb) {
      // For web (Chrome, Firefox, etc.)
      return 'http://localhost:8080/api/public';
    } else {
      // For Android emulator
      return 'http://192.168.100.104:8080/api/public';
      // For iOS simulator, use: http://localhost:8080/api/public
      // For physical device, use: http://192.168.100.104:8080/api/public
    }
  }

  // Get full media URL for uploaded files
  static String getMediaUrl(String path) {
    if (path.isEmpty) return '';
    
    // If path already includes http, return as is
    if (path.startsWith('http')) return path;
    
    // If path starts with /uploads, append to server URL
    if (path.startsWith('/uploads')) {
      final serverUrl = kIsWeb ? 'http://localhost:8080' : 'http://192.168.100.104:8080';
      return '$serverUrl$path';
    }
    
    // Otherwise return the path as is (for assets)
    return path;
  }

  static Future<List<dynamic>> getTopics() async {
    try {
      debugPrint('📚 Fetching topics from: $baseUrl/topics');
      final response = await http.get(Uri.parse('$baseUrl/topics'));
      
      if (response.statusCode == 200) {
        final topics = json.decode(response.body) as List<dynamic>;
        debugPrint('📦 Received ${topics.length} topics from API');
        
        // Debug: Print each topic
        for (var topic in topics) {
          debugPrint('  - ${topic['title']} (${topic['category']})');
        }
        
        return topics;
      } else {
        throw Exception('Failed to load topics: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching topics: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getTopicById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/topics/$id'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load topic: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching topic: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getTopicsByCategory(String category) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/topics/category/$category'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to load topics: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching topics by category: $e');
      rethrow;
    }
  }

  static Future<List<String>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categories'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<String>();
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getGames() async {
    try {
      debugPrint('🎮 Fetching games from: $baseUrl/games');
      final response = await http.get(Uri.parse('$baseUrl/games'));
      
      if (response.statusCode == 200) {
        final games = json.decode(response.body) as List<dynamic>;
        debugPrint('📦 Received ${games.length} games from API');
        
        // Debug: Print each game's configuration
        for (var game in games) {
          debugPrint('  - ${game['title']} (${game['type']})');
          debugPrint('    Config: ${game['configurationData']}');
        }
        
        return games;
      } else {
        throw Exception('Failed to load games: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching games: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getGameById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/games/$id'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load game: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching game: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getGamesByType(String type) async {
    try {
      debugPrint('🎮 Fetching games by type: $type from $baseUrl/games/type/$type');
      final response = await http.get(Uri.parse('$baseUrl/games/type/$type'));
      
      if (response.statusCode == 200) {
        final games = json.decode(response.body) as List<dynamic>;
        debugPrint('📦 Received ${games.length} $type games');
        
        // Debug each game
        for (var game in games) {
          debugPrint('  - ${game['title']}');
          debugPrint('    Config: ${game['configurationData']}');
        }
        
        return games;
      } else {
        throw Exception('Failed to load games: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching games by type: $e');
      rethrow;
    }
  }

  static Future<List<dynamic>> getBadges() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/badges'));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to load badges: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching badges: $e');
      rethrow;
    }
  }

  static Future<void> incrementTopicReadCount(String topicId) async {
    try {
      debugPrint('📖 Incrementing read count for topic: $topicId');
      final response = await http.post(
        Uri.parse('$baseUrl/topics/$topicId/read'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('✅ Read count updated: ${data['readCount']}');
      } else {
        debugPrint('⚠️ Failed to increment read count: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error incrementing read count: $e');
      // Don't rethrow - this is a non-critical operation
    }
  }
}
