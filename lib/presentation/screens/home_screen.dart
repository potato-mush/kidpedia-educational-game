import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidpedia/presentation/providers/app_providers.dart';
import 'package:kidpedia/presentation/widgets/topic_card.dart';
import 'package:kidpedia/presentation/widgets/category_chip.dart';
import 'package:kidpedia/presentation/screens/topic_detail_screen.dart';
import 'package:kidpedia/presentation/screens/category_screen.dart';
import 'package:kidpedia/presentation/screens/games_screen.dart';
import 'package:kidpedia/presentation/screens/profile_screen.dart';
import 'package:kidpedia/core/constants/app_constants.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final featuredTopics = ref.watch(featuredTopicsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      body: Stack(
        children: [
          const _PlayfulBackground(),
          SafeArea(
            child: _currentIndex == 0
                ? _buildHomeContent(featuredTopics, searchQuery, searchResults)
                : _currentIndex == 1
                    ? const GamesScreen()
                    : _currentIndex == 2
                        ? _buildBookmarksContent()
                        : const ProfileScreen(),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.games_outlined),
            selectedIcon: Icon(Icons.games),
            label: 'Games',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Bookmarks',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(featuredTopics, searchQuery, searchResults) {
    return CustomScrollView(
      slivers: [
        // App Bar
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
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.displaySmall,
                  ).animate().fadeIn(duration: 600.ms).slideX(),
                  Text(
                    AppConstants.appTagline,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF6A5F45),
                          fontWeight: FontWeight.w600,
                        ),
                  ).animate(delay: 200.ms).fadeIn(duration: 600.ms).slideX(),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                ref.watch(themeModeProvider) == ThemeMode.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: () {
                ref.read(themeModeProvider.notifier).toggleTheme();
              },
            ),
          ],
        ),

        // Search Bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search topics...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ).animate().fadeIn(duration: 600.ms).slideY(),
          ),
        ),

        // Search Results or Main Content
        if (searchQuery.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final topic = searchResults[index];
                  return TopicCard(
                    topic: topic,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TopicDetailScreen(topicId: topic.id),
                        ),
                      );
                    },
                  ).animate().fadeIn(delay: (index * 50).ms);
                },
                childCount: searchResults.length,
              ),
            ),
          )
        else ...[
          // Categories Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Categories',
                style: Theme.of(context).textTheme.headlineMedium,
              ).animate().fadeIn(duration: 600.ms),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: AppConstants.categories.length,
                itemBuilder: (context, index) {
                  final category = AppConstants.categories[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: CategoryChip(
                      category: category,
                      isSelected: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryScreen(category: category),
                          ),
                        );
                      },
                    ).animate(delay: (index * 100).ms).fadeIn().slideX(),
                  );
                },
              ),
            ),
          ),

          // Featured Topics
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Featured Topics',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('See All'),
                  ),
                ],
              ).animate().fadeIn(duration: 600.ms),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index >= featuredTopics.length) return null;
                  final topic = featuredTopics[index];
                  return TopicCard(
                    topic: topic,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TopicDetailScreen(topicId: topic.id),
                        ),
                      );
                    },
                  ).animate(delay: (index * 100).ms).fadeIn().scale();
                },
                childCount: featuredTopics.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ],
    );
  }

  Widget _buildBookmarksContent() {
    final bookmarkedTopics = ref.watch(bookmarkedTopicsProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: const Text('Bookmarks'),
        ),
        if (bookmarkedTopics.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No bookmarks yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start exploring and bookmark your favorite topics!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final topic = bookmarkedTopics[index];
                  return TopicCard(
                    topic: topic,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TopicDetailScreen(topicId: topic.id),
                        ),
                      );
                    },
                  );
                },
                childCount: bookmarkedTopics.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _PlayfulBackground extends StatelessWidget {
  const _PlayfulBackground();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradientColors = isDark
        ? const [
            Color(0xFF101828),
            Color(0xFF1A2242),
            Color(0xFF132F3F),
          ]
        : const [
            Color(0xFFFFF3C2),
            Color(0xFFFFE0DA),
            Color(0xFFDFF4FF),
          ];

    final orbColors = isDark
        ? const [
            Color(0x3368E7FF),
            Color(0x33FF8A65),
            Color(0x334ED8A8),
            Color(0x339D7DFF),
          ]
        : const [
            Color(0x55FFB347),
            Color(0x5560A5FA),
            Color(0x554DD9A6),
            Color(0x55FF7A59),
          ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: Stack(
        children: [
          _BubbleOrb(top: -40, left: -30, size: 170, color: orbColors[0]),
          _BubbleOrb(top: 80, right: -35, size: 130, color: orbColors[1]),
          _BubbleOrb(bottom: 120, left: -20, size: 120, color: orbColors[2]),
          _BubbleOrb(bottom: -30, right: 40, size: 150, color: orbColors[3]),
        ],
      ),
    );
  }
}

class _BubbleOrb extends StatelessWidget {
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;
  final double size;
  final Color color;

  const _BubbleOrb({
    this.top,
    this.right,
    this.bottom,
    this.left,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
      ),
    );
  }
}
