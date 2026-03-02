import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidpedia/presentation/providers/app_providers.dart';
import 'package:kidpedia/core/theme/app_theme.dart';
import 'package:kidpedia/presentation/widgets/topic_card.dart';
import 'package:kidpedia/games/puzzle/puzzle_game_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kidpedia/data/repositories/badge_repository.dart';
import 'package:kidpedia/data/repositories/game_repository.dart';
import 'package:kidpedia/data/repositories/leaderboard_repository.dart';
import 'package:kidpedia/data/repositories/user_profile_repository.dart';
import 'package:kidpedia/data/services/badge_service.dart';
import 'package:kidpedia/data/services/api_service.dart';

class TopicDetailScreen extends ConsumerStatefulWidget {
  final String topicId;

  const TopicDetailScreen({super.key, required this.topicId});

  @override
  ConsumerState<TopicDetailScreen> createState() => _TopicDetailScreenState();
}

class _TopicDetailScreenState extends ConsumerState<TopicDetailScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _markAsViewed();
  }

  void _markAsViewed() async {
    final progressRepo = ref.read(progressRepositoryProvider);
    final topicRepo = ref.read(topicRepositoryProvider);
    progressRepo.markTopicAsViewed(widget.topicId);
    topicRepo.incrementReadCount(widget.topicId);
    
    // Update leaderboard score
    final userProfile = UserProfileRepository().getCurrentUser();
    if (userProfile != null) {
      await LeaderboardRepository().updateUserStats(userProfile.id);
      // Refresh leaderboard provider to show updated data immediately
      if (mounted) {
        ref.read(leaderboardProvider.notifier).refresh();
      }
    }
    
    // Check badges after reading topic
    final badgeService = BadgeService(
      badgeRepository: BadgeRepository(),
      gameRepository: GameRepository(),
      progressRepository: progressRepo,
      leaderboardRepository: LeaderboardRepository(),
    );
    
    final newlyUnlocked = await badgeService.checkBadgesAfterTopicRead();
    
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
                  Expanded(
                    child: Text(
                      '🎉 Badge Unlocked: ${badge.title}!',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo(String videoPath) async {
    try {
      final mediaUrl = ApiService.getMediaUrl(videoPath);
      
      // Use network controller if path starts with /uploads, otherwise use asset
      if (videoPath.startsWith('/uploads')) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(mediaUrl));
      } else {
        _videoController = VideoPlayerController.asset(videoPath);
      }
      
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoController!.value.aspectRatio,
        // No duration limit - video plays to completion
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppTheme.getCategoryColor(
            ref.read(topicDetailProvider(widget.topicId))?.category ?? '',
          ),
          handleColor: AppTheme.getCategoryColor(
            ref.read(topicDetailProvider(widget.topicId))?.category ?? '',
          ),
          backgroundColor: Colors.grey[300]!,
          bufferedColor: Colors.grey[200]!,
        ),
      );
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video not available yet. Please add video files to assets/videos/'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _toggleAudio(String audioPath) async {
    try {
      if (_isPlayingAudio) {
        await _audioPlayer.pause();
        setState(() {
          _isPlayingAudio = false;
        });
      } else {
        // Check if audio is from network or local asset
        final mediaUrl = ApiService.getMediaUrl(audioPath);
        
        if (audioPath.startsWith('/uploads')) {
          // Network audio from backend
          await _audioPlayer.play(UrlSource(mediaUrl));
        } else {
          // Local asset
          await _audioPlayer.play(AssetSource(audioPath));
        }
        
        setState(() {
          _isPlayingAudio = true;
        });
        
        // Listen for completion
        _audioPlayer.onPlayerComplete.listen((event) {
          if (mounted) {
            setState(() {
              _isPlayingAudio = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio not available: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
        setState(() {
          _isPlayingAudio = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final topic = ref.watch(topicDetailProvider(widget.topicId));
    final relatedTopics = ref.watch(relatedTopicsProvider(widget.topicId));
    final isBookmarked = ref.watch(isBookmarkedProvider(widget.topicId));
    final games = ref.watch(gamesByTopicProvider(widget.topicId));

    if (topic == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('Topic not found'),
        ),
      );
    }

    final categoryColor = AppTheme.getCategoryColor(topic.category);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Image App Bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                topic.title,
                style: const TextStyle(
                  shadows: [
                    Shadow(
                      offset: Offset(0, 1),
                      blurRadius: 3.0,
                      color: Colors.black54,
                    ),
                  ],
                ),
              ),
              background: Hero(
                tag: 'topic_${topic.id}',
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        categoryColor.withOpacity(0.8),
                        categoryColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: topic.imagePaths.isNotEmpty
                      ? _buildImage(
                          topic.imagePaths.first,
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                ),
                onPressed: () {
                  ref.read(bookmarkRepositoryProvider).toggleBookmark(widget.topicId);
                  ref.invalidate(bookmarkedTopicsProvider);
                  ref.invalidate(isBookmarkedProvider(widget.topicId));
                },
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: categoryColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      topic.category,
                      style: TextStyle(
                        color: categoryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ).animate().fadeIn().slideX(),

                  const SizedBox(height: 16),

                  // Summary
                  Text(
                    topic.summary,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ).animate(delay: 100.ms).fadeIn().slideY(),

                  const SizedBox(height: 24),

                  // Audio Player
                  if (topic.audioPath != null)
                    Card(
                      child: ListTile(
                        leading: Icon(
                          _isPlayingAudio ? Icons.pause_circle : Icons.play_circle,
                          color: categoryColor,
                          size: 40,
                        ),
                        title: const Text('Listen to narration'),
                        onTap: () => _toggleAudio(topic.audioPath!),
                      ),
                    ).animate(delay: 200.ms).fadeIn().slideX(),

                  const SizedBox(height: 16),

                  // Video Player
                  if (topic.videoPath != null)
                    Card(
                      child: Column(
                        children: [
                          if (_chewieController != null)
                            AspectRatio(
                              aspectRatio: _chewieController!.aspectRatio!,
                              child: Chewie(controller: _chewieController!),
                            )
                          else
                            ElevatedButton.icon(
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Watch Video'),
                              onPressed: () => _initializeVideo(topic.videoPath!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: categoryColor,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                        ],
                      ),
                    ).animate(delay: 300.ms).fadeIn().scale(),

                  const SizedBox(height: 24),

                  // Main Content
                  Text(
                    'Learn More',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ).animate(delay: 400.ms).fadeIn(),

                  const SizedBox(height: 12),

                  Text(
                    topic.content,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ).animate(delay: 500.ms).fadeIn(),

                  const SizedBox(height: 24),

                  // Image Gallery
                  if (topic.imagePaths.length > 1) ...[
                    Text(
                      'Gallery',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ).animate(delay: 600.ms).fadeIn(),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: topic.imagePaths.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: _buildImage(
                                topic.imagePaths[index],
                                width: 200,
                                fit: BoxFit.cover,
                              ),
                            ).animate(delay: (700 + index * 50).ms).fadeIn().slideX(),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Fun Facts
                  if (topic.funFacts.isNotEmpty) ...[
                    Text(
                      'Fun Facts! 🎉',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ).animate(delay: 800.ms).fadeIn(),
                    const SizedBox(height: 12),
                    ...topic.funFacts.asMap().entries.map((entry) {
                      return Card(
                        color: categoryColor.withOpacity(0.1),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: categoryColor,
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(entry.value),
                        ),
                      ).animate(delay: (900 + entry.key * 100).ms).fadeIn().slideX();
                    }),
                    const SizedBox(height: 24),
                  ],

                  // Games Section
                  if (games.isNotEmpty) ...[
                    Text(
                      'Play & Learn! 🎮',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ).animate(delay: 1000.ms).fadeIn(),
                    const SizedBox(height: 12),
                    ...games.map((game) {
                      return Card(
                        child: ListTile(
                          leading: Icon(
                            Icons.games,
                            color: categoryColor,
                            size: 40,
                          ),
                          title: Text(game.title),
                          subtitle: Text(game.description),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            if (game.type == 'puzzle') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PuzzleGameScreen(game: game),
                                ),
                              );
                            }
                          },
                        ),
                      ).animate(delay: 1100.ms).fadeIn().slideY();
                    }),
                    const SizedBox(height: 24),
                  ],

                  // Related Topics
                  if (relatedTopics.isNotEmpty) ...[
                    Text(
                      'Related Topics',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ).animate(delay: 1200.ms).fadeIn(),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: relatedTopics.length,
                        itemBuilder: (context, index) {
                          final relatedTopic = relatedTopics[index];
                          return SizedBox(
                            width: 160,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: TopicCard(
                                topic: relatedTopic,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => TopicDetailScreen(
                                        topicId: relatedTopic.id,
                                      ),
                                    ),
                                  );
                                },
                              ).animate(delay: (1300 + index * 100).ms).fadeIn().scale(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Helper method to build image widget (network or asset)
  Widget _buildImage(String path, {BoxFit fit = BoxFit.cover, double? width}) {
    final mediaUrl = ApiService.getMediaUrl(path);
    
    if (path.startsWith('/uploads')) {
      return Image.network(
        mediaUrl,
        fit: fit,
        width: width,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            color: Colors.grey[300],
            child: const Icon(Icons.image),
          );
        },
      );
    }
    
    return Image.asset(
      path,
      fit: fit,
      width: width,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          color: Colors.grey[300],
          child: const Icon(Icons.image),
        );
      },
    );
  }
}
