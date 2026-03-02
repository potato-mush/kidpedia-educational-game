import 'package:kidpedia/data/models/leaderboard_entry_model.dart';
import 'package:kidpedia/data/repositories/leaderboard_repository.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';

class BotPlayersService {
  static const _uuid = Uuid();
  static final _random = Random();

  static final List<String> _botNames = [
    'Alex Explorer',
    'Bella Bookworm',
    'Charlie Curious',
    'Diana Discoverer',
    'Ethan Einstein',
    'Fiona Facts',
    'George Genius',
    'Hannah History',
    'Isaac Inventor',
    'Julia Journey',
    'Kevin Knowledge',
    'Luna Learner',
    'Max Mind',
    'Nina Nature',
    'Oscar Observer',
    'Penny Puzzler',
    'Quinn Quest',
    'Ruby Reader',
    'Sam Science',
    'Tina Thinker',
    'Uma Universe',
    'Victor Voyager',
    'Wendy Wonder',
    'Xavier Xplorer',
    'Yara Young',
    'Zoe Zoologist',
    'Adam Adventure',
    'Brooke Brain',
    'Carter Champion',
    'Daisy Detective',
  ];

  static final List<String> _avatarIds = [
    'avatar_cat',
    'avatar_dog',
    'avatar_bear',
    'avatar_fox',
    'avatar_rabbit',
    'avatar_panda',
    'avatar_lion',
    'avatar_tiger',
    'avatar_elephant',
    'avatar_giraffe',
  ];

  static Future<void> generateBotPlayers() async {
    final repo = LeaderboardRepository();
    final existingEntries = repo.getLeaderboard();

    // Only generate if we have fewer than 30 entries
    if (existingEntries.length >= 30) {
      return;
    }

    // Generate 25 bot players
    for (int i = 0; i < 25; i++) {
      final botId = 'bot_${_uuid.v4()}';
      final name = _botNames[i % _botNames.length];
      final avatarId = _avatarIds[_random.nextInt(_avatarIds.length)];
      
      // Generate realistic scores
      final baseScore = _random.nextInt(5000) + 1000;
      final gamesWon = _random.nextInt(50) + 10;
      final topicsRead = _random.nextInt(20) + 5;
      final totalScore = baseScore + (gamesWon * 100) + (topicsRead * 50);

      final entry = LeaderboardEntryModel(
        id: botId,
        playerName: name,
        totalScore: totalScore,
        gamesWon: gamesWon,
        topicsRead: topicsRead,
        avatarId: avatarId,
        isCurrentUser: false,
        lastUpdated: DateTime.now().subtract(
          Duration(days: _random.nextInt(30)),
        ),
      );

      await repo.addBotPlayer(entry);
    }
  }

  static Future<void> addVariance() async {
    // Occasionally update bot scores slightly to simulate activity
    final repo = LeaderboardRepository();
    final bots = repo.getLeaderboard().where((e) => !e.isCurrentUser).toList();

    if (bots.isNotEmpty && _random.nextDouble() < 0.3) {
      final bot = bots[_random.nextInt(bots.length)];
      final scoreIncrease = _random.nextInt(200);
      
      final updated = bot.copyWith(
        totalScore: bot.totalScore + scoreIncrease,
        gamesWon: bot.gamesWon + (_random.nextBool() ? 1 : 0),
        lastUpdated: DateTime.now(),
      );

      await repo.addBotPlayer(updated);
    }
  }
}
