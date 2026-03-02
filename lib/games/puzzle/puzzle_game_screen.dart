import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidpedia/data/models/game_model.dart';
import 'package:kidpedia/data/models/game_score_model.dart';
import 'package:kidpedia/data/repositories/game_repository.dart';
import 'package:kidpedia/data/repositories/badge_repository.dart';
import 'package:kidpedia/data/repositories/progress_repository.dart';
import 'package:kidpedia/data/repositories/leaderboard_repository.dart';
import 'package:kidpedia/data/repositories/user_profile_repository.dart';
import 'package:kidpedia/data/services/badge_service.dart';
import 'package:kidpedia/data/services/api_service.dart';
import 'package:kidpedia/presentation/providers/app_providers.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'dart:async';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PuzzleGameScreen extends ConsumerStatefulWidget {
  final GameModel game;

  const PuzzleGameScreen({super.key, required this.game});

  @override
  ConsumerState<PuzzleGameScreen> createState() => _PuzzleGameScreenState();
}

class _PuzzleGameScreenState extends ConsumerState<PuzzleGameScreen> {
  late int gridSize; // Dynamic based on difficulty
  late List<PuzzlePiece> pieces;
  late List<PuzzlePiece> board;
  int? selectedIndex;
  int moves = 0;
  late DateTime startTime;
  int elapsedSeconds = 0;
  Timer? _timer;
  bool isCompleted = false;
  late ConfettiController _confettiController;
  late String puzzleImage;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _initializePuzzle();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isCompleted && mounted) {
        setState(() {
          elapsedSeconds++;
        });
      }
    });
  }

  void _initializePuzzle() {
    // Get configuration from game model
    final config = widget.game.configurationData;
    
    // Debug: Print configuration
    debugPrint('=== PUZZLE CONFIGURATION ===');
    debugPrint('Game ID: ${widget.game.id}');
    debugPrint('Game Title: ${widget.game.title}');
    debugPrint('Config: $config');
    debugPrint('Grid Size: ${config['gridSize']}');
    debugPrint('Image Path: ${config['imagePath']}');
    debugPrint('===========================');
    
    gridSize = config['gridSize'] as int? ?? 3;
    puzzleImage = config['imagePath'] as String? ?? 'images/animals/elephant1.jpg';
    
    // Use ApiService to convert to full URL if needed
    puzzleImage = ApiService.getMediaUrl(puzzleImage);
    
    debugPrint('Final puzzle image: $puzzleImage');
    
    // Create puzzle pieces with row and column info
    pieces = [];
    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final index = row * gridSize + col;
        pieces.add(PuzzlePiece(
          id: index,
          correctPosition: index,
          currentPosition: index,
          row: row,
          col: col,
        ));
      }
    }

    // Shuffle pieces
    pieces.shuffle(Random());
    for (int i = 0; i < pieces.length; i++) {
      pieces[i].currentPosition = i;
    }

    // Initialize board
    board = List.from(pieces);
    selectedIndex = null;
    moves = 0;
    isCompleted = false;
    startTime = DateTime.now();
    _startTimer();
  }

  void _onPieceTap(int index) {
    if (isCompleted) return;

    setState(() {
      if (selectedIndex == null) {
        // First piece selected
        selectedIndex = index;
      } else if (selectedIndex == index) {
        // Deselect
        selectedIndex = null;
      } else {
        // Swap pieces
        final temp = board[selectedIndex!];
        board[selectedIndex!] = board[index];
        board[index] = temp;

        // Update positions
        board[selectedIndex!].currentPosition = selectedIndex!;
        board[index].currentPosition = index;

        selectedIndex = null;
        moves++;

        // Check if completed
        _checkCompletion();
      }
    });
  }

  void _checkCompletion() {
    bool completed = true;
    for (int i = 0; i < board.length; i++) {
      if (board[i].correctPosition != i) {
        completed = false;
        break;
      }
    }

    if (completed) {
      setState(() {
        isCompleted = true;
      });
      _timer?.cancel();
      _confettiController.play();
      _saveScore();
      _showCompletionDialog();
    }
  }

  Future<void> _saveScore() async {
    final score = _calculateScore(elapsedSeconds, moves);

    final gameScore = GameScoreModel(
      id: const Uuid().v4(),
      gameId: widget.game.id,
      gameType: widget.game.type,
      score: score,
      maxScore: 1000,
      completedAt: DateTime.now(),
      timeSpentSeconds: elapsedSeconds,
      difficulty: widget.game.difficulty,
      isWon: true,
    );

    final repository = GameRepository();
    await repository.saveGameScore(gameScore);

    // Update leaderboard score
    final userProfile = UserProfileRepository().getCurrentUser();
    if (userProfile != null) {
      await LeaderboardRepository().updateUserStats(userProfile.id);
      // Refresh leaderboard provider to show updated data immediately
      if (mounted) {
        ref.read(leaderboardProvider.notifier).refresh();
      }
    }

    // Check and update badges
    final badgeService = BadgeService(
      badgeRepository: BadgeRepository(),
      gameRepository: repository,
      progressRepository: ProgressRepository(),
      leaderboardRepository: LeaderboardRepository(),
    );
    final newlyUnlocked = await badgeService.checkBadgesAfterGame();

    // Show badge notifications
    if (newlyUnlocked.isNotEmpty && mounted) {
      final badgeRepo = BadgeRepository();
      for (final badgeId in newlyUnlocked) {
        final badge = badgeRepo.getBadgeById(badgeId);
        if (badge != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(child: Text('🎉 Badge Unlocked: ${badge.title}!')),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  int _calculateScore(int seconds, int moves) {
    // Base score
    int score = 1000;

    // Deduct points for time (1 point per second)
    score -= seconds;

    // Deduct points for moves (5 points per move)
    score -= moves * 5;

    // Ensure minimum score
    return max(100, score);
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Congratulations!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You completed the puzzle!'),
            const SizedBox(height: 16),
            Text('Moves: $moves'),
            Text(
              'Time: ${elapsedSeconds}s',
            ),
            Text(
              'Score: ${_calculateScore(elapsedSeconds, moves)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                isCompleted = false;
                _initializePuzzle();
              });
            },
            child: const Text('Play Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.game.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _initializePuzzle();
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Stats
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatChip(
                        icon: Icons.touch_app,
                        label: 'Moves',
                        value: '$moves',
                      ),
                      _StatChip(
                        icon: Icons.timer,
                        label: 'Time',
                        value: '${elapsedSeconds}s',
                      ),
                      _StatChip(
                        icon: Icons.grid_on,
                        label: 'Size',
                        value: '${gridSize}x$gridSize',
                      ),
                    ].map((e) => e.animate().fadeIn().scale()).toList(),
                  ),
                ),

                // Instructions
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      // Preview image
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[400]!, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: puzzleImage.startsWith('http')
                            ? Image.network(
                                puzzleImage,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image),
                                  );
                                },
                              )
                            : Image.asset(
                                puzzleImage,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image),
                                  );
                                },
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Complete the puzzle!',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap pieces to swap them',
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ).animate().fadeIn(),
                ),

                const SizedBox(height: 24),

                // Puzzle Grid
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: gridSize,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                          ),
                          itemCount: gridSize * gridSize,
                          itemBuilder: (context, index) {
                            final piece = board[index];
                            final isSelected = selectedIndex == index;

                            return GestureDetector(
                              onTap: () => _onPieceTap(index),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : piece.isInCorrectPosition()
                                            ? Colors.green
                                            : Colors.grey[600]!,
                                    width: isSelected ? 4 : 2,
                                  ),
                                  boxShadow: [
                                    if (isSelected)
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.5),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                  ],
                                ),
                                child: _PuzzlePieceWidget(
                                  imagePath: puzzleImage,
                                  piece: piece,
                                  gridSize: gridSize,
                                ),
                              ),
                            ).animate().fadeIn().scale();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.05,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PuzzlePiece {
  final int id;
  final int correctPosition;
  int currentPosition;
  final int row;
  final int col;

  PuzzlePiece({
    required this.id,
    required this.correctPosition,
    required this.currentPosition,
    required this.row,
    required this.col,
  });

  bool isInCorrectPosition() => correctPosition == currentPosition;
}

// Widget to display a cropped portion of the puzzle image
class _PuzzlePieceWidget extends StatelessWidget {
  final String imagePath;
  final PuzzlePiece piece;
  final int gridSize;

  const _PuzzlePieceWidget({
    required this.imagePath,
    required this.piece,
    required this.gridSize,
  });

  @override
  Widget build(BuildContext context) {
    // Use a fixed base size for calculations
    const double baseSize = 100.0;
    final double fullSize = baseSize * gridSize;
    
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.fill,
        child: SizedBox(
          width: baseSize,
          height: baseSize,
          child: Stack(
            children: [
              Positioned(
                left: -piece.col * baseSize,
                top: -piece.row * baseSize,
                width: fullSize,
                height: fullSize,
                child: imagePath.startsWith('http')
                  ? Image.network(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[600],
                              size: 30,
                            ),
                          ),
                        );
                      },
                    )
                  : Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[600],
                              size: 30,
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
