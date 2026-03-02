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
      body: SafeArea(
        child: _currentIndex == 0
            ? _buildHomeContent(featuredTopics, searchQuery, searchResults)
            : _currentIndex == 1
                ? const GamesScreen()
                : _currentIndex == 2
                    ? _buildBookmarksContent()
                    : const ProfileScreen(),
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
                          color: Colors.grey[600],
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
