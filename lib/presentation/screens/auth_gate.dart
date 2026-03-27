import 'package:flutter/material.dart';
import 'package:kidpedia/data/services/auth_service.dart';
import 'package:kidpedia/presentation/screens/auth_screen.dart';
import 'package:kidpedia/presentation/screens/splash_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<bool> _authCheck;

  @override
  void initState() {
    super.initState();
    _authCheck = AuthService.isAuthenticated();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _authCheck,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        final isAuthenticated = snapshot.data ?? false;

        if (isAuthenticated) {
          return const SplashScreen();
        } else {
          return const AuthScreen();
        }
      },
    );
  }
}
