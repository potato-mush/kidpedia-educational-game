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
import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

class SoundMatchGameScreen extends ConsumerStatefulWidget {
  final GameModel game;

  const SoundMatchGameScreen({super.key, required this.game});

  @override
  ConsumerState<SoundMatchGameScreen> createState() => _SoundMatchGameScreenState();
}

class _SoundMatchGameScreenState extends ConsumerState<SoundMatchGameScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  late List<SoundMatchItem> items;
  late List<SoundMatchItem> soundOptions;
  late List<SoundMatchItem> animalOptions;
  SoundMatchItem? selectedSound;
  Set<String> matchedIds = {};
  bool showWrongFeedback = false;
  int score = 0;
  int correctMatches = 0;
  int wrongMatches = 0;
  bool isPlaying = false;
  late DateTime startTime;
  int elapsedSeconds = 0;
  Timer? _timer;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    startTime = DateTime.now();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _startTimer();
    _initializeGame();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _confettiController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          elapsedSeconds = DateTime.now().difference(startTime).inSeconds;
        });
      }
    });
  }

  void _initializeGame() {
    // Get pairs from game configuration
    final config = widget.game.configurationData;
    final pairsData = config['pairs'] as List<dynamic>? ?? [];
    
    // Check if game has valid data
    if (pairsData.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('⚠️ Game Not Ready'),
              content: const Text(
                'This sound match game hasn\'t been configured yet. Please ask an administrator to add the sound pairs!',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Go Back'),
                ),
              ],
            ),
          );
        }
      });
      return;
    }
    
    items = pairsData.map((pair) {
      var imagePath = pair['imagePath'] as String? ?? '';
      var audioPath = pair['audioPath'] as String? ?? '';
      
      // Use ApiService to convert paths to full URLs if needed
      imagePath = ApiService.getMediaUrl(imagePath);
      
      // Check if audio is from network (uploaded files)
      final isNetworkAudio = audioPath.startsWith('/uploads');
      audioPath = ApiService.getMediaUrl(audioPath);
      
      return SoundMatchItem(
        id: pair['id'] as String? ?? '',
        name: pair['name'] as String? ?? '',
        soundPath: audioPath,
        imagePath: imagePath,
        isNetworkAudio: isNetworkAudio,
      );
    }).toList();

    setState(() {
      selectedSound = null;
      matchedIds.clear();
      showWrongFeedback = false;
      correctMatches = 0;
      wrongMatches = 0;
      score = 0;
      
      // Use all items for both sound and animal options
      soundOptions = List.from(items);
      animalOptions = List.from(items);
      soundOptions.shuffle();
      animalOptions.shuffle();
    });
  }



  Future<void> _playSound(SoundMatchItem item) async {
    if (isPlaying || matchedIds.contains(item.id)) return;
    
    setState(() {
      isPlaying = true;
      selectedSound = item;
      showWrongFeedback = false;
    });

    try {
      await _audioPlayer.stop();
      if (item.isNetworkAudio) {
        await _audioPlayer.play(UrlSource(item.soundPath));
      } else {
        await _audioPlayer.play(AssetSource(item.soundPath));
      }
      await _audioPlayer.onPlayerComplete.first;
    } catch (e) {
      debugPrint('Error playing sound: $e');
      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not play ${item.name} sound. Please try another!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        isPlaying = false;
      });
    }
  }

  void _onAnimalSelected(SoundMatchItem animal) {
    if (selectedSound == null) {
      // Show message to select a sound first
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a sound first! 🔊'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    // Check if already matched
    if (matchedIds.contains(animal.id)) {
      return;
    }

    final isCorrect = selectedSound!.id == animal.id;

    if (isCorrect) {
      setState(() {
        score += 100;
        correctMatches++;
        matchedIds.add(animal.id);
      });
      _confettiController.play();
      
      // Check if all matched
      if (matchedIds.length == items.length) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _gameCompleted();
          }
        });
      } else {
        // Clear selection to choose next sound
        setState(() {
          selectedSound = null;
        });
      }
    } else {
      // Show wrong feedback
      setState(() {
        showWrongFeedback = true;
        wrongMatches++;
        score = (score - 10).clamp(0, double.infinity).toInt();
      });
      
      // Hide feedback after 1 second
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            showWrongFeedback = false;
            selectedSound = null;
          });
        }
      });
    }
  }

  Future<void> _gameCompleted() async {
    final duration = DateTime.now().difference(startTime);
    final maxScore = items.length * 100;
    
    final gameScore = GameScoreModel(
      id: const Uuid().v4(),
      gameId: widget.game.id,
      gameType: widget.game.type,
      score: score,
      maxScore: maxScore,
      completedAt: DateTime.now(),
      timeSpentSeconds: duration.inSeconds,
      difficulty: widget.game.difficulty,
      isWon: score >= (maxScore * 0.6),
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

    if (!mounted) return;

    // Show newly unlocked badges
    if (newlyUnlocked.isNotEmpty) {
      final badgeRepo = BadgeRepository();
      for (final badgeId in newlyUnlocked) {
        final badge = badgeRepo.getBadgeById(badgeId);
        if (badge != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('🎉 Badge Unlocked: ${badge.title}!'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Game Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Score: $score / $maxScore',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Correct Matches: $correctMatches'),
            Text('Wrong Attempts: $wrongMatches'),
            const SizedBox(height: 8),
            Text('Time: ${duration.inSeconds}s'),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: score / maxScore,
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(
                score >= (maxScore * 0.6) ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                score = 0;
                correctMatches = 0;
                wrongMatches = 0;
                startTime = DateTime.now();
                elapsedSeconds = 0;
                _initializeGame();
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
      backgroundColor: const Color(0xFF7FDBDA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7FDBDA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Match Animal Sounds',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('How to Play'),
                  content: const Text(
                    '1. Tap a sound card to hear the animal sound.\n2. Then tap the matching animal picture!\n3. Match correctly to earn points! 🎯',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it!'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Stats Bar
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Score
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          const SizedBox(width: 4),
                          Text('$score', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      // Correct matches
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '$correctMatches',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      // Wrong matches
                      Row(
                        children: [
                          const Icon(Icons.cancel, color: Colors.red, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '$wrongMatches',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      // Timer
                      Row(
                        children: [
                          const Icon(Icons.timer, color: Colors.grey, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '${elapsedSeconds ~/ 60}:${(elapsedSeconds % 60).toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(),

                const SizedBox(height: 4),

                // Sounds Label
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(Icons.volume_up, color: Color(0xFFFF6B6B), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Choose a Sound',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn().slideX(),

                const SizedBox(height: 6),

                // Sound Cards Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: soundOptions.length,
                    itemBuilder: (context, index) {
                      final sound = soundOptions[index];
                      final isSelected = selectedSound?.id == sound.id;
                      final isMatched = matchedIds.contains(sound.id);
                      return Opacity(
                        opacity: isMatched ? 0.3 : 1.0,
                        child: GestureDetector(
                          onTap: isMatched ? null : () => _playSound(sound),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFF6B6B) : const Color(0xFFFF8C42),
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                isMatched ? Icons.check : (isPlaying && isSelected ? Icons.pause : Icons.volume_up),
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ).animate(delay: (index * 50).ms).fadeIn().scale(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 10),

                // Animals Label
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(Icons.pets, color: Color(0xFFFF6B6B), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Animals',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn().slideX(),

                const SizedBox(height: 6),

                // Animal Options Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: animalOptions.length,
                    itemBuilder: (context, index) {
                      final animal = animalOptions[index];
                      final isMatched = matchedIds.contains(animal.id);
                      return Opacity(
                        opacity: isMatched ? 0.3 : 1.0,
                        child: GestureDetector(
                          onTap: isMatched ? null : () => _onAnimalSelected(animal),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // Full image background
                                  animal.imagePath.startsWith('http')
                                    ? Image.network(
                                        animal.imagePath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: Icon(
                                              _getAnimalIcon(animal.name),
                                              size: 48,
                                              color: Colors.grey[600],
                                            ),
                                          );
                                        },
                                      )
                                    : Image.asset(
                                        animal.imagePath,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[300],
                                            child: Icon(
                                              _getAnimalIcon(animal.name),
                                              size: 48,
                                              color: Colors.grey[600],
                                            ),
                                          );
                                        },
                                      ),
                                  // Matched overlay
                                  if (isMatched)
                                    Container(
                                      color: Colors.green.withOpacity(0.7),
                                      child: const Center(
                                        child: Icon(
                                          Icons.check_circle,
                                          size: 48,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ).animate(delay: (index * 100).ms).fadeIn().scale(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 6),

                // Instruction at bottom
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app, color: Color(0xFFFF6B6B), size: 18),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Tap a sound to play it, then tap the matching animal! 🐾',
                          style: TextStyle(fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn().slideY(),
              ],
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.05,
              shouldLoop: false,
            ),
          ),

          // Wrong Answer Feedback
          if (showWrongFeedback)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 64,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Wrong!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 200.ms).scale(duration: 200.ms),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getAnimalIcon(String name) {
    switch (name.toLowerCase()) {
      case 'dog':
        return Icons.pets;
      case 'cat':
        return Icons.pets;
      case 'cow':
        return Icons.agriculture;
      case 'lion':
        return Icons.emoji_nature;
      case 'elephant':
        return Icons.nature;
      case 'bird':
        return Icons.flutter_dash;
      default:
        return Icons.pets;
    }
  }
}

class SoundMatchItem {
  final String id;
  final String name;
  final String soundPath;
  final String imagePath;
  final bool isNetworkAudio;

  SoundMatchItem({
    required this.id,
    required this.name,
    required this.soundPath,
    required this.imagePath,
    this.isNetworkAudio = false,
  });
}
