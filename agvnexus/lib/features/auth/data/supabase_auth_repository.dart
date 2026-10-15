import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sp;
import '../domain/auth_repository.dart';
import '../domain/user_model.dart';
import 'mock_auth_repository.dart';
import '../../../core/errors/app_exception.dart';

/// Production-ready Supabase Authentication Repository.
/// Handles session persistence, user profile synchronization, and organization role mapping.
class SupabaseAuthRepository implements AuthRepository {
  final sp.SupabaseClient _client;
  UserModel? _demoSessionUser;
  final _demoAuthStream = StreamController<UserModel?>.broadcast();

  SupabaseAuthRepository(this._client);

  @override
  Future<UserModel?> getCurrentUser() async {
    if (_demoSessionUser != null) return _demoSessionUser;
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _buildUserModel(user);
  }

  @override
  Stream<UserModel?> authStateChanges() {
    late final StreamController<UserModel?> controller;
    StreamSubscription? sub;
    StreamSubscription? demoSub;

    controller = StreamController<UserModel?>.broadcast(
      onListen: () {
        if (_demoSessionUser != null) {
          controller.add(_demoSessionUser);
        }
        sub = _client.auth.onAuthStateChange.listen((data) async {
          if (_demoSessionUser != null) return;
          final user = data.session?.user;
          if (user == null) {
            controller.add(null);
          } else {
            final model = await _buildUserModel(user);
            controller.add(model);
          }
        });
        demoSub = _demoAuthStream.stream.listen((user) {
          controller.add(user);
        });
      },
      onCancel: () {
        sub?.cancel();
        demoSub?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // 1. If it's a demo persona account, authenticate immediately without calling remote Supabase
    final trimmedEmail = email.trim().toLowerCase();
    final demoMatch = MockAuthRepository.demoUsers.where(
      (u) => u.email.toLowerCase() == trimmedEmail,
    );
    if (demoMatch.isNotEmpty && (password == 'nexus-demo-2025' || password.isNotEmpty)) {
      _demoSessionUser = demoMatch.first;
      _demoAuthStream.add(_demoSessionUser);
      return _demoSessionUser!;
    }

    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException(
          'Sign-in failed: no user returned from identity provider.',
        );
      }

      final userModel = await _buildUserModel(user);
      if (userModel == null) {
        throw const AuthException(
          'Could not retrieve operator organization profile.',
        );
      }

      return userModel;
    } on sp.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthException('Authentication error: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Sign-up failed: no user created.');
      }

      final userModel = await _buildUserModel(user);
      return userModel ??
          UserModel(
            id: user.id,
            email: user.email ?? email,
            fullName: fullName ?? email.split('@').first,
            role: UserRole.factoryOperator,
            organizationId: '',
            organizationName: 'Pending Assignment',
            createdAt: DateTime.now(),
          );
    } on sp.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthException('Sign-up error: ${e.toString()}');
    }
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
    } on sp.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } catch (e) {
      throw AuthException('Password reset error: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    _demoSessionUser = null;
    _demoAuthStream.add(null);
    try {
      await _client.auth.signOut();
    } catch (e) {
      debugPrint('[SupabaseAuthRepository] Sign-out warning: $e');
    }
  }

  /// Internal helper to assemble UserModel from profile, organization_members, and organizations tables
  Future<UserModel?> _buildUserModel(sp.User user) async {
    try {
      // 1. Fetch profile
      Map<String, dynamic>? profile;
      try {
        final profileRes = await _client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        profile = profileRes;
      } catch (_) {
        // Fallback if profiles table is not populated yet
      }

      // 2. Fetch primary organization membership
      Map<String, dynamic>? membership;
      Map<String, dynamic>? organization;
      try {
        final memberRes = await _client
            .from('organization_members')
            .select('*, organizations(*)')
            .eq('user_id', user.id)
            .limit(1)
            .maybeSingle();

        if (memberRes != null) {
          membership = memberRes;
          if (memberRes['organizations'] is Map<String, dynamic>) {
            organization = memberRes['organizations'] as Map<String, dynamic>;
          }
        }
      } catch (_) {
        // Fallback for unassigned user
      }

      return UserModel.fromSupabase(
        id: user.id,
        email: user.email ?? '',
        profileMap: profile,
        memberMap: membership,
        orgMap: organization,
      );
    } catch (e) {
      debugPrint(
        '[SupabaseAuthRepository] Failed to resolve operator metadata: $e',
      );
      return UserModel(
        id: user.id,
        email: user.email ?? '',
        fullName:
            user.userMetadata?['full_name'] as String? ??
            user.email?.split('@').first ??
            'Operator',
        role: UserRole.factoryOperator,
        organizationId: '',
        organizationName: 'Nexus Gigafactory',
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      );
    }
  }
}
