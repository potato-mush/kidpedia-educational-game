import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidpedia/core/theme/app_theme.dart';
import 'package:kidpedia/data/models/user_profile_model.dart';
import 'package:kidpedia/data/repositories/leaderboard_repository.dart';
import 'package:kidpedia/data/services/auth_service.dart';
import 'package:kidpedia/presentation/providers/app_providers.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _avatarController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _isSigningUp = false;

  final _avatarOptions = [
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  void _toggleAuthMode() {
    setState(() {
      _isSigningUp = !_isSigningUp;
      _error = null;
      _usernameController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _avatarController.clear();
    });
  }

  Future<void> _handleAuth() async {
    if (_usernameController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a username');
      return;
    }
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Please enter a password');
      return;
    }
    if (_isSigningUp && _confirmPasswordController.text != _passwordController.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    if (_isSigningUp && _avatarController.text.isEmpty) {
      setState(() => _error = 'Please select an avatar');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = _isSigningUp
          ? await AuthService.signUp(
              username: _usernameController.text,
              password: _passwordController.text,
              avatarId: _avatarController.text,
            )
          : await AuthService.signIn(
              username: _usernameController.text,
              password: _passwordController.text,
            );

      if (user != null && mounted) {
        await ref.read(userProfileProvider.notifier).setCurrentUser(
              UserProfileModel(
                id: user.id,
                username: user.username,
                avatarId: user.avatarId,
                createdAt: DateTime.now(),
                lastUpdated: DateTime.now(),
              ),
            );
        await LeaderboardRepository().updateUserStats(user.id);
        ref.read(leaderboardProvider.notifier).refresh();
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFF3C2),
                Color(0xFFFFE0DA),
                Color(0xFFDFF4FF),
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  height: constraints.maxHeight,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Kidpedia',
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _isSigningUp
                                  ? 'Create Your Profile'
                                  : 'Sign In To Continue',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                hintText: 'Username',
                                prefixIcon: const Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              maxLength: 20,
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                prefixIcon: const Icon(Icons.lock),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                            if (_isSigningUp) ...[
                              const SizedBox(height: 8),
                              TextField(
                                controller: _confirmPasswordController,
                                obscureText: true,
                                decoration: InputDecoration(
                                  hintText: 'Confirm password',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Pick Your Avatar',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _avatarOptions.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 5,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 0.8,
                                  ),
                                  itemBuilder: (context, index) {
                                    final avatar = _avatarOptions[index];
                                    final avatarId = avatar['id']!;
                                    final avatarName = avatar['name']!;
                                    final isSelected = _avatarController.text == avatarId;

                                    return GestureDetector(
                                      onTap: () => setState(
                                        () => _avatarController.text = avatarId,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppTheme.primaryColor.withOpacity(0.18)
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppTheme.primaryColor
                                                : Colors.grey.shade300,
                                            width: isSelected ? 2.5 : 1.2,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/images/avatars/$avatarId.png',
                                              width: 36,
                                              height: 36,
                                              fit: BoxFit.contain,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.pets,
                                                  size: 22,
                                                  color: isSelected
                                                      ? AppTheme.primaryColor
                                                      : Colors.grey[700],
                                                );
                                              },
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              avatarName,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: isSelected
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                color: isSelected
                                                    ? AppTheme.primaryColor
                                                    : Colors.grey[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                            if (_error != null)
                              Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _error!,
                                  style: TextStyle(color: Colors.red[800]),
                                ),
                              ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _isLoading ? null : _handleAuth,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: AppTheme.primaryColor,
                              ),
                              child: Text(
                                _isLoading
                                    ? 'Loading...'
                                    : (_isSigningUp ? 'Create Profile' : 'Continue'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Center(
                              child: TextButton(
                                onPressed: _isLoading ? null : _toggleAuthMode,
                                child: Text(
                                  _isSigningUp
                                      ? 'Already have a profile? Sign In'
                                      : 'First time? Create a new profile',
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
