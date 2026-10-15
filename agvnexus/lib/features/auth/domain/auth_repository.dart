import 'user_model.dart';

/// Abstract contract for authentication operations.
/// Supports both Supabase Auth (Phase 2) and deterministic mock (Phase 1).
abstract class AuthRepository {
  Future<UserModel?> getCurrentUser();
  Stream<UserModel?> authStateChanges();
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? fullName,
  });
  Future<void> resetPasswordForEmail(String email);
  Future<void> signOut();
}
