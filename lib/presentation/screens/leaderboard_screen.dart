import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidpedia/presentation/providers/app_providers.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardProvider);
    final userProfile = ref.watch(userProfileProvider);
    final userRank = ref.watch(userRankProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Leaderboard'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // User's Rank Card
          if (userProfile != null)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: _getAvatarWidget(userProfile.avatarId, 60),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProfile.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Your Rank: #$userRank',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '#$userRank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(),

          // Leaderboard List
          Expanded(
            child: leaderboard.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: leaderboard.length,
                    itemBuilder: (context, index) {
                      final entry = leaderboard[index];
                      final rank = index + 1;
                      final isCurrentUser = entry.isCurrentUser;

                      Color? rankColor;
                      IconData? medalIcon;

                      if (rank == 1) {
                        rankColor = Colors.amber;
                        medalIcon = Icons.emoji_events;
                      } else if (rank == 2) {
                        rankColor = Colors.grey[400];
                        medalIcon = Icons.emoji_events;
                      } else if (rank == 3) {
                        rankColor = Colors.brown[300];
                        medalIcon = Icons.emoji_events;
                      }

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: isCurrentUser
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                            : null,
                        child: ListTile(
                          leading: SizedBox(
                            width: 50,
                            child: Row(
                              children: [
                                if (medalIcon != null)
                                  Icon(medalIcon, color: rankColor, size: 24)
                                else
                                  SizedBox(
                                    width: 30,
                                    child: Text(
                                      '#$rank',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          ),
                          title: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: rankColor ?? Colors.grey[300],
                                child: _getAvatarWidget(entry.avatarId, 40),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          entry.playerName,
                                          style: TextStyle(
                                            fontWeight: isCurrentUser
                                                ? FontWeight.bold
                                                : FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (isCurrentUser) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'YOU',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      '${entry.gamesWon} wins • ${entry.topicsRead} topics',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${entry.totalScore}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: rankColor ?? Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Text(
                                'points',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate(delay: (index * 50).ms).fadeIn().slideX();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _getAvatarWidget(String avatarId, double size) {
    // Load actual avatar images
    try {
      return ClipOval(
        child: Image.asset(
          'assets/images/avatars/$avatarId.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to icon if image fails to load
            final avatarIcons = {
              'avatar_cat': Icons.pets,
              'avatar_dog': Icons.pets,
              'avatar_bear': Icons.cruelty_free,
              'avatar_fox': Icons.pest_control,
              'avatar_rabbit': Icons.cruelty_free,
              'avatar_panda': Icons.nature,
              'avatar_lion': Icons.pets,
              'avatar_tiger': Icons.pets,
              'avatar_elephant': Icons.nature,
              'avatar_giraffe': Icons.nature,
              'avatar_default': Icons.person,
            };
            return Icon(
              avatarIcons[avatarId] ?? Icons.person,
              size: size * 0.6,
              color: Colors.white,
            );
          },
        ),
      );
    } catch (e) {
      // Fallback if something goes wrong
      return Icon(
        Icons.person,
        size: size * 0.6,
        color: Colors.white,
      );
    }
  }
}
