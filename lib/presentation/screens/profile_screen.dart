import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidpedia/data/services/auth_service.dart';
import 'package:kidpedia/presentation/providers/app_providers.dart';
import 'package:kidpedia/presentation/widgets/badge_card.dart';
import 'package:kidpedia/presentation/screens/leaderboard_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showAvatarSelector(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _AvatarSelectorDialog(),
    );
  }

  void _showUsernameEditor(BuildContext context, WidgetRef ref, String currentUsername) {
    final controller = TextEditingController(text: currentUsername);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Username'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
          ),
          maxLength: 20,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref.read(userProfileProvider.notifier).updateUsername(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allBadges = ref.watch(allBadgesProvider);
    final badgeStats = ref.watch(badgeStatsProvider);
    final totalTopicsViewed = ref.watch(totalTopicsViewedProvider);
    final gameStats = ref.watch(gameStatsProvider);
    final largeTextMode = ref.watch(largeTextModeProvider);
    final userProfile = ref.watch(userProfileProvider);
    final userRank = ref.watch(userRankProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          expandedHeight: 170,
          flexibleSpace: FlexibleSpaceBar(
            background: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showAvatarSelector(context, ref),
                        child: Stack(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              alignment: Alignment.center,
                              child: _getAvatarWidget(
                                userProfile?.avatarId ?? 'avatar_default',
                                64,
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () => _showUsernameEditor(
                                context,
                                ref,
                                userProfile?.username ?? 'Young Explorer',
                              ),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      userProfile?.username ?? 'Young Explorer',
                                      style: Theme.of(context).textTheme.headlineSmall,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.edit, size: 16),
                                ],
                              ),
                            ).animate().fadeIn().slideX(),
                            Text(
                              'Rank #$userRank • Keep learning!',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ).animate(delay: 100.ms).fadeIn().slideX(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Leaderboard Button
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LeaderboardScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.emoji_events),
              label: const Text('View Leaderboard'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Theme.of(context).colorScheme.secondary,
              ),
            ).animate().fadeIn().slideY(),
          ),
        ),

        // Statistics
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Statistics',
                  style: Theme.of(context).textTheme.headlineMedium,
                ).animate(delay: 200.ms).fadeIn(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.book,
                        label: 'Topics Read',
                        value: '$totalTopicsViewed',
                        color: Colors.blue,
                      ).animate(delay: 300.ms).fadeIn().scale(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.games,
                        label: 'Games Played',
                        value: '${gameStats['totalPlayed']}',
                        color: Colors.green,
                      ).animate(delay: 400.ms).fadeIn().scale(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.emoji_events,
                        label: 'Badges',
                        value: '${badgeStats['unlocked']}/${badgeStats['total']}',
                        color: Colors.amber,
                      ).animate(delay: 500.ms).fadeIn().scale(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.bookmark,
                        label: 'Bookmarks',
                        value: '${ref.watch(bookmarkedTopicsProvider).length}',
                        color: Colors.purple,
                      ).animate(delay: 600.ms).fadeIn().scale(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Badges
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Badges',
                  style: Theme.of(context).textTheme.headlineMedium,
                ).animate(delay: 900.ms).fadeIn(),
                Text(
                  '${badgeStats['percentage'].toStringAsFixed(0)}% Complete',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ).animate(delay: 1000.ms).fadeIn(),
              ],
            ),
          ),
        ),

        // Badge Grid
        if (allBadges.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No badges yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start exploring topics and playing games!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[500],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final badge = allBadges[index];
                  return BadgeCard(badge: badge)
                      .animate(delay: (1100 + index * 50).ms)
                      .fadeIn()
                      .scale();
                },
                childCount: allBadges.length,
              ),
            ),
          ),

        // Settings
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineMedium,
                ).animate(delay: 700.ms).fadeIn(),
                const SizedBox(height: 12),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle: const Text('Switch between light and dark theme'),
                        secondary: Icon(
                          ref.watch(themeModeProvider) == ThemeMode.dark
                              ? Icons.dark_mode
                              : Icons.light_mode,
                        ),
                        value: ref.watch(themeModeProvider) == ThemeMode.dark,
                        onChanged: (value) {
                          ref.read(themeModeProvider.notifier).toggleTheme();
                        },
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Large Text'),
                        subtitle: const Text('Make text easier to read'),
                        secondary: const Icon(Icons.text_fields),
                        value: largeTextMode,
                        onChanged: (value) {
                          ref.read(largeTextModeProvider.notifier).toggle();
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        title: const Text('Logout'),
                        subtitle: const Text('Sign out and return to login'),
                        leading: const Icon(Icons.logout),
                        textColor: Colors.red,
                        iconColor: Colors.red,
                        onTap: () async {
                          await AuthService.logout();
                          if (context.mounted) {
                            Navigator.pushReplacementNamed(context, '/');
                          }
                        },
                      ),
                    ],
                  ),
                ).animate(delay: 800.ms).fadeIn().slideY(),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _getAvatarWidget(String avatarId, double size) {
    // Load actual avatar images
    try {
      return Image.asset(
        'assets/images/avatars/$avatarId.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
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

class _AvatarSelectorDialog extends ConsumerWidget {
  const _AvatarSelectorDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAvatar = ref.watch(userProfileProvider)?.avatarId ?? 'avatar_default';

    final avatars = [
      {'id': 'avatar_cat', 'name': 'Cat'},
      {'id': 'avatar_dog', 'name': 'Dog'},
      {'id': 'avatar_bear', 'name': 'Bear'},
      {'id': 'avatar_fox', 'name': 'Fox'},
      {'id': 'avatar_rabbit', 'name': 'Rabbit'},
      {'id': 'avatar_panda', 'name': 'Panda'},
      {'id': 'avatar_lion', 'name': 'Lion'},
      {'id': 'avatar_tiger', 'name': 'Tiger'},
      {'id': 'avatar_elephant', 'name': 'Elephant'},
      {'id': 'avatar_giraffe', 'name': 'Giraffe'},
    ];

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Choose Your Avatar',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 400,
              width: double.maxFinite,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: avatars.length,
                itemBuilder: (context, index) {
                  final avatar = avatars[index];
                  final isSelected = avatar['id'] == currentAvatar;

                  return GestureDetector(
                    onTap: () {
                      ref
                          .read(userProfileProvider.notifier)
                          .updateAvatar(avatar['id'] as String);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/avatars/${avatar['id']}.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback to icon if image fails
                              return Icon(
                                Icons.pets,
                                size: 40,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[700],
                              );
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            avatar['name'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.grey[700],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              size: 16,
                              color: Colors.green,
                            ),
                        ],
                      ),
                    ).animate(delay: (index * 50).ms).fadeIn().scale(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
