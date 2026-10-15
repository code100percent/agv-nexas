import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/supabase_config.dart';
import '../data/mock_auth_repository.dart';
import '../data/supabase_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/user_model.dart';

/// Provider for AuthRepository (dynamically selects Supabase or Mock repository).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = SupabaseConfig.client;
  if (client != null) {
    return SupabaseAuthRepository(client);
  }
  final repo = MockAuthRepository(startAuthenticated: false);
  ref.onDispose(repo.dispose);
  return repo;
});

/// Stream provider for auth state changes.
final authStateProvider = StreamProvider<UserModel?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});

/// AsyncNotifier for user authentication actions conforming to Riverpod 3.
class AuthController extends AsyncNotifier<UserModel?> {
  @override
  FutureOr<UserModel?> build() {
    return ref.watch(authRepositoryProvider).getCurrentUser();
  }

  Future<bool> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserModel?>(AuthController.new);
