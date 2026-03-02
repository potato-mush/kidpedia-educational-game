import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidpedia/presentation/providers/app_providers.dart';
import 'package:kidpedia/core/constants/app_constants.dart';
import 'package:kidpedia/games/puzzle/puzzle_game_screen.dart';
import 'package:kidpedia/games/sound_match/sound_match_game_screen.dart';
import 'package:kidpedia/games/quiz/quiz_game_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GamesScreen extends ConsumerWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allGamesAsync = ref.watch(allGamesProvider);
    final gameStats = ref.watch(gameStatsProvider);

    return allGamesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading games: $err'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(allGamesProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (allGames) => CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          expandedHeight: 120,
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Games',
                    style: Theme.of(context).textTheme.displaySmall,
                  ).animate().fadeIn(duration: 600.ms),
                  Text(
                    'Play and learn at the same time!',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ).animate(delay: 200.ms).fadeIn(),
                ],
              ),
            ),
          ),
        ),

        // Stats Cards
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon: Icons.games,
                    label: 'Played',
                    value: '${gameStats['totalPlayed']}',
                    color: Colors.blue,
                  ).animate().fadeIn().slideX(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.emoji_events,
                    label: 'Won',
                    value: '${gameStats['totalWon']}',
                    color: Colors.amber,
                  ).animate(delay: 100.ms).fadeIn().slideX(),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    icon: Icons.trending_up,
                    label: 'Win Rate',
                    value: '${gameStats['winRate'].toStringAsFixed(0)}%',
                    color: Colors.green,
                  ).animate(delay: 200.ms).fadeIn().slideX(),
                ),
              ],
            ),
          ),
        ),

        // Game Types
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Game Types',
              style: Theme.of(context).textTheme.headlineMedium,
            ).animate(delay: 300.ms).fadeIn(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                _GameTypeCard(
                  title: 'Puzzle Game',
                  description: 'Solve image puzzles of different difficulties',
                  icon: Icons.extension,
                  color: Colors.purple,
                  onTap: () {
                    final puzzleGames = allGames
                        .where((g) => g.type == AppConstants.gameTypePuzzle)
                        .toList();
                    
                    debugPrint('\n=== PUZZLE GAMES AVAILABLE ===');
                    debugPrint('Total puzzle games: ${puzzleGames.length}');
                    for (var i = 0; i < puzzleGames.length; i++) {
                      debugPrint('  ${i + 1}. ${puzzleGames[i].title}');
                      debugPrint('     Config: ${puzzleGames[i].configurationData}');
                    }
                    debugPrint('==============================\n');
                    
                    if (puzzleGames.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No puzzle games available')),
                      );
                      return;
                    }
                    
                    // Show game selection dialog
                    _showGameSelectionDialog(context, 'Puzzle Games', puzzleGames);
                  },
                ).animate(delay: 400.ms).fadeIn().slideX(),
                const SizedBox(height: 12),
                _GameTypeCard(
                  title: 'Sound Match',
                  description: 'Match sounds with correct images',
                  icon: Icons.volume_up,
                  color: Colors.orange,
                  onTap: () {
                    final soundGames = allGames
                        .where((g) => g.type == AppConstants.gameTypeSoundMatch)
                        .toList();
                    
                    if (soundGames.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No sound match games available')),
                      );
                      return;
                    }
                    
                    _showGameSelectionDialog(context, 'Sound Match Games', soundGames);
                  },
                ).animate(delay: 500.ms).fadeIn().slideX(),
                const SizedBox(height: 12),
                _GameTypeCard(
                  title: 'Quiz Game',
                  description: 'Test your knowledge with fun quizzes',
                  icon: Icons.quiz,
                  color: Colors.teal,
                  onTap: () {
                    final quizGames = allGames
                        .where((g) => g.type == AppConstants.gameTypeQuiz)
                        .toList();
                    
                    if (quizGames.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No quiz games available')),
                      );
                      return;
                    }
                    
                    _showGameSelectionDialog(context, 'Quiz Games', quizGames);
                  },
                ).animate(delay: 600.ms).fadeIn().slideX(),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    ),
    ); // Close .when()
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _GameTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GameTypeCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}

void _showGameSelectionDialog(BuildContext context, String title, List<dynamic> games) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getDifficultyColor(game.difficulty),
                    child: Text(
                      game.difficulty[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(game.title),
                  subtitle: Text(
                    '${game.difficulty.toUpperCase()} • ${game.description}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.play_arrow),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    
                    debugPrint('\n🎮 Starting ${game.type} game: ${game.title}');
                    debugPrint('   Configuration: ${game.configurationData}');
                    
                    // Navigate to the appropriate game screen
                    if (game.type == 'puzzle') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PuzzleGameScreen(game: game),
                        ),
                      );
                    } else if (game.type == 'sound_match') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SoundMatchGameScreen(game: game),
                        ),
                      );
                    } else if (game.type == 'quiz') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizGameScreen(game: game),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}

Color _getDifficultyColor(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'easy':
      return Colors.green;
    case 'medium':
      return Colors.orange;
    case 'hard':
      return Colors.red;
    default:
      return Colors.grey;
  }
}
