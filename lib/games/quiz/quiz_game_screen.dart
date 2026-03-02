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
import 'package:kidpedia/presentation/providers/app_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

class QuizGameScreen extends ConsumerStatefulWidget {
  final GameModel game;

  const QuizGameScreen({super.key, required this.game});

  @override
  ConsumerState<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends ConsumerState<QuizGameScreen> {
  late List<QuizQuestion> questions;
  int currentQuestionIndex = 0;
  int score = 0;
  int? selectedOptionIndex;
  bool showResult = false;
  Timer? questionTimer;
  int remainingSeconds = 30;
  late DateTime startTime;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    startTime = DateTime.now();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _initializeQuiz();
    _startTimer();
  }

  @override
  void dispose() {
    questionTimer?.cancel();
    _confettiController.dispose();
    super.dispose();
  }

  void _initializeQuiz() {
    // Get questions from game configuration
    final config = widget.game.configurationData;
    final questionsData = config['questions'] as List<dynamic>? ?? [];
    
    if (questionsData.isEmpty) {
      // Fallback to mock questions if no configuration
      questions = [
        QuizQuestion(
          question: 'What is the largest planet in our solar system?',
          options: ['Earth', 'Jupiter', 'Saturn', 'Mars'],
          correctIndex: 1,
          explanation: 'Jupiter is the largest planet in our solar system!',
        ),
      ];
    } else {
      questions = questionsData.map((q) {
        return QuizQuestion(
          question: q['question'] as String? ?? '',
          options: (q['options'] as List<dynamic>?)?.cast<String>() ?? [],
          correctIndex: q['correctIndex'] as int? ?? 0,
          explanation: q['explanation'] as String? ?? '',
        );
      }).toList();
    }

    // Shuffle for variety
    questions.shuffle();
  }

  void _startTimer() {
    remainingSeconds = 30;
    questionTimer?.cancel();
    questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (remainingSeconds > 0) {
          remainingSeconds--;
        } else {
          _timeOut();
        }
      });
    });
  }

  void _timeOut() {
    questionTimer?.cancel();
    setState(() {
      showResult = true;
    });
    
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  void _onOptionSelected(int index) {
    if (showResult) return;

    questionTimer?.cancel();
    
    setState(() {
      selectedOptionIndex = index;
      showResult = true;
    });

    final isCorrect = index == questions[currentQuestionIndex].correctIndex;
    
    if (isCorrect) {
      setState(() {
        score += 100;
      });
      _confettiController.play();
    }

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  void _nextQuestion() {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        selectedOptionIndex = null;
        showResult = false;
      });
      _startTimer();
    } else {
      _quizCompleted();
    }
  }

  Future<void> _quizCompleted() async {
    questionTimer?.cancel();
    
    final duration = DateTime.now().difference(startTime);
    
    final gameScore = GameScoreModel(
      id: const Uuid().v4(),
      gameId: widget.game.id,
      gameType: widget.game.type,
      score: score,
      maxScore: questions.length * 100,
      completedAt: DateTime.now(),
      timeSpentSeconds: duration.inSeconds,
      difficulty: widget.game.difficulty,
      isWon: score >= (questions.length * 100 * 0.6),
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

    // Show badge notifications
    if (newlyUnlocked.isNotEmpty) {
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Quiz Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your Score: $score / ${questions.length * 100}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${(score / (questions.length * 100) * 100).toStringAsFixed(0)}% Correct',
            ),
            const SizedBox(height: 8),
            Text('Time: ${duration.inSeconds}s'),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: score / (questions.length * 100),
              minHeight: 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(
                score >= (questions.length * 100 * 0.6) ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                currentQuestionIndex = 0;
                score = 0;
                selectedOptionIndex = null;
                showResult = false;
                startTime = DateTime.now();
                _initializeQuiz();
                _startTimer();
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
    final question = questions[currentQuestionIndex];
    final progress = (currentQuestionIndex + 1) / questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.game.title),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Progress Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Question ${currentQuestionIndex + 1}/${questions.length}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Score: $score',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[300],
                      ),
                    ].map((e) => e.animate().fadeIn()).toList(),
                  ),
                ),

                // Timer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.timer,
                        color: remainingSeconds < 10 ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${remainingSeconds}s',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: remainingSeconds < 10 ? Colors.red : Colors.grey[700],
                        ),
                      ),
                    ],
                  ).animate().fadeIn(),
                ),

                const SizedBox(height: 24),

                // Question
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        question.question,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ).animate().fadeIn().scale(),
                ),

                const SizedBox(height: 16),

                // Options
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: question.options.length,
                    itemBuilder: (context, index) {
                      final isSelected = selectedOptionIndex == index;
                      final isCorrect = index == question.correctIndex;
                      
                      Color? backgroundColor;
                      Color? borderColor;
                      
                      if (showResult) {
                        if (isCorrect) {
                          backgroundColor = Colors.green[100];
                          borderColor = Colors.green;
                        } else if (isSelected) {
                          backgroundColor = Colors.red[100];
                          borderColor = Colors.red;
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: InkWell(
                          onTap: () => _onOptionSelected(index),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: backgroundColor ?? Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: borderColor ?? Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: borderColor?.withOpacity(0.2) ?? Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + index), // A, B, C, D
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: borderColor,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    question.options[index],
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                if (showResult && isCorrect)
                                  const Icon(Icons.check_circle, color: Colors.green),
                                if (showResult && isSelected && !isCorrect)
                                  const Icon(Icons.cancel, color: Colors.red),
                              ],
                            ),
                          ),
                        ).animate(delay: (index * 100).ms).fadeIn().slideX(),
                      );
                    },
                  ),
                ),

                // Explanation
                if (showResult)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            question.explanation,
                            style: Theme.of(context).textTheme.bodyMedium,
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
        ],
      ),
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });
}
