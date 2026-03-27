import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:kidpedia/data/models/auth_model.dart';
import 'package:kidpedia/data/services/api_service.dart';

class AuthService {
  static const String _authUserKey = 'auth_user';
  static const String _isAuthenticatedKey = 'is_authenticated';
  static const String _childCredentialsKey = 'child_credentials';
  static const _uuid = Uuid();

  static Future<AuthUser?> getStoredUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString(_authUserKey);
      if (userString == null) return null;

      final parts = userString.split('|');
      if (parts.length != 3) return null;

      return AuthUser(
        id: parts[0],
        username: parts[1],
        avatarId: parts[2],
      );
    } catch (e) {
      debugPrint('Error retrieving stored user: $e');
      return null;
    }
  }

  static Future<bool> isAuthenticated() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isAuthenticatedKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<AuthUser?> signUp({
    required String username,
    required String password,
    required String avatarId,
  }) async {
    try {
      final normalizedUsername = username.trim();
      if (normalizedUsername.isEmpty) {
        throw Exception('Username cannot be empty');
      }
      if (password.isEmpty) {
        throw Exception('Password cannot be empty');
      }
      if (avatarId.isEmpty) {
        throw Exception('Please select an avatar');
      }

      final credentials = await _loadCredentials();
      final usernameKey = normalizedUsername.toLowerCase();
      if (credentials.containsKey(usernameKey)) {
        throw Exception('Username already exists');
      }

      final userId = _uuid.v4();
      final user = AuthUser(
        id: userId,
        username: normalizedUsername,
        avatarId: avatarId,
      );

      credentials[usernameKey] = {
        'id': user.id,
        'username': user.username,
        'password': password,
        'avatarId': user.avatarId,
      };
      await _saveCredentials(credentials);

      // Sync with backend
      await ApiService.upsertUserProfile(
        id: user.id,
        username: user.username,
        avatarId: user.avatarId,
      );

      // Store locally
      await _saveUser(user);
      return user;
    } catch (e) {
      debugPrint('❌ Sign up error: $e');
      rethrow;
    }
  }

  static Future<AuthUser?> signIn({
    required String username,
    required String password,
  }) async {
    try {
      final normalizedUsername = username.trim();
      if (normalizedUsername.isEmpty) {
        throw Exception('Username cannot be empty');
      }
      if (password.isEmpty) {
        throw Exception('Password cannot be empty');
      }

      final credentials = await _loadCredentials();
      final usernameKey = normalizedUsername.toLowerCase();
      var savedCredential = credentials[usernameKey] as Map<String, dynamic>?;

      // Recovery path: local credentials missing but account exists on backend.
      if (savedCredential == null) {
        final backendUser = await ApiService.getUserByUsername(normalizedUsername);
        if (backendUser == null) {
          throw Exception('Account not found. Please create a profile first.');
        }

        savedCredential = {
          'id': (backendUser['id'] ?? '').toString(),
          'username': (backendUser['username'] ?? normalizedUsername).toString(),
          'password': password,
          'avatarId': (backendUser['avatarId'] ?? 'avatar_default').toString(),
        };

        credentials[usernameKey] = savedCredential;
        await _saveCredentials(credentials);
      }

      final savedPassword = (savedCredential['password'] ?? '').toString();
      if (savedPassword != password) {
        throw Exception('Invalid username or password');
      }

      final user = AuthUser(
        id: (savedCredential['id'] ?? '').toString(),
        username: (savedCredential['username'] ?? normalizedUsername).toString(),
        avatarId: (savedCredential['avatarId'] ?? 'avatar_default').toString(),
      );

      // Sync with backend
      await ApiService.upsertUserProfile(
        id: user.id,
        username: user.username,
        avatarId: user.avatarId,
      );

      await _saveUser(user);
      return user;
    } catch (e) {
      debugPrint('❌ Sign in error: $e');
      rethrow;
    }
  }

  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authUserKey);
      await prefs.remove(_isAuthenticatedKey);
      debugPrint('✅ User logged out');
    } catch (e) {
      debugPrint('❌ Logout error: $e');
    }
  }

  static Future<void> _saveUser(AuthUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Store as simple pipe-delimited string to avoid JSON complexity
      final userString = '${user.id}|${user.username}|${user.avatarId}';
      await prefs.setString(_authUserKey, userString);
      await prefs.setBool(_isAuthenticatedKey, true);
      debugPrint('✅ User saved locally: ${user.username}');
    } catch (e) {
      debugPrint('❌ Error saving user: $e');
    }
  }

  static Future<Map<String, dynamic>> _loadCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_childCredentialsKey);
    if (raw == null || raw.isEmpty) return <String, dynamic>{};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Ignore malformed legacy data and reset to an empty map.
    }

    return <String, dynamic>{};
  }

  static Future<void> _saveCredentials(Map<String, dynamic> credentials) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_childCredentialsKey, jsonEncode(credentials));
  }
}
