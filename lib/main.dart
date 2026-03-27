import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidpedia/core/theme/app_theme.dart';
import 'package:kidpedia/data/local/hive_service.dart';
import 'package:kidpedia/data/local/seed_data_service.dart';
import 'package:kidpedia/data/models/user_profile_model.dart';
import 'package:kidpedia/data/repositories/user_profile_repository.dart';
import 'package:kidpedia/data/services/auth_service.dart';
import 'package:kidpedia/presentation/providers/app_providers.dart';
import 'package:kidpedia/presentation/screens/auth_gate.dart';
import 'package:kidpedia/presentation/screens/auth_screen.dart';
import 'package:kidpedia/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Hive
  await HiveService.init();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Rehydrate current user profile from persisted auth before seed routines run.
  final authUser = await AuthService.getStoredUser();
  if (authUser != null) {
    final userRepo = UserProfileRepository();
    await userRepo.saveCurrentUser(
      UserProfileModel(
        id: authUser.id,
        username: authUser.username,
        avatarId: authUser.avatarId,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),
    );
  }

  // Seed initial data
  await SeedDataService.seedAll();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const KidpediaApp(),
    ),
  );
}

class KidpediaApp extends ConsumerWidget {
  const KidpediaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Kidpedia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const AuthGate(),
      routes: {
        '/home': (_) => const HomeScreen(),
        '/auth': (_) => const AuthScreen(),
      },
    );
  }
}
