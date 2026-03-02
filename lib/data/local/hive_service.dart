import 'package:hive_flutter/hive_flutter.dart';
import 'package:kidpedia/core/constants/app_constants.dart';
import 'package:kidpedia/data/models/topic_model.dart';
import 'package:kidpedia/data/models/game_model.dart';
import 'package:kidpedia/data/models/progress_model.dart';
import 'package:kidpedia/data/models/badge_model.dart';
import 'package:kidpedia/data/models/game_score_model.dart';
import 'package:kidpedia/data/models/leaderboard_entry_model.dart';
import 'package:kidpedia/data/models/user_profile_model.dart';

class HiveService {
  static Future<void> init() async {
    await Hive.initFlutter();

    // Register Adapters
    Hive.registerAdapter(TopicModelAdapter());
    Hive.registerAdapter(GameModelAdapter());
    Hive.registerAdapter(ProgressModelAdapter());
    Hive.registerAdapter(BadgeModelAdapter());
    Hive.registerAdapter(GameScoreModelAdapter());
    Hive.registerAdapter(LeaderboardEntryModelAdapter());
    Hive.registerAdapter(UserProfileModelAdapter());

    // Open Boxes
    await Future.wait([
      Hive.openBox<TopicModel>(AppConstants.hiveBoxTopics),
      Hive.openBox<GameModel>(AppConstants.hiveBoxGames),
      Hive.openBox<ProgressModel>(AppConstants.hiveBoxProgress),
      Hive.openBox<BadgeModel>(AppConstants.hiveBoxBadges),
      Hive.openBox<GameScoreModel>('game_scores'),
      Hive.openBox<String>(AppConstants.hiveBoxBookmarks),
      Hive.openBox<LeaderboardEntryModel>('leaderboard'),
      Hive.openBox<UserProfileModel>('user_profile'),
    ]);
  }

  static Box<TopicModel> get topicsBox =>
      Hive.box<TopicModel>(AppConstants.hiveBoxTopics);

  static Box<GameModel> get gamesBox =>
      Hive.box<GameModel>(AppConstants.hiveBoxGames);

  static Box<ProgressModel> get progressBox =>
      Hive.box<ProgressModel>(AppConstants.hiveBoxProgress);

  static Box<BadgeModel> get badgesBox =>
      Hive.box<BadgeModel>(AppConstants.hiveBoxBadges);

  static Box<GameScoreModel> get gameScoresBox =>
      Hive.box<GameScoreModel>('game_scores');

  static Box<String> get bookmarksBox =>
      Hive.box<String>(AppConstants.hiveBoxBookmarks);

  static Box<LeaderboardEntryModel> get leaderboardBox =>
      Hive.box<LeaderboardEntryModel>('leaderboard');

  static Box<UserProfileModel> get userProfileBox =>
      Hive.box<UserProfileModel>('user_profile');

  static Future<void> clearAllData() async {
    await Future.wait([
      topicsBox.clear(),
      gamesBox.clear(),
      progressBox.clear(),
      badgesBox.clear(),
      gameScoresBox.clear(),
      bookmarksBox.clear(),
    ]);
  }
}
