import 'dart:async';
import '../domain/auth_repository.dart';
import '../domain/user_model.dart';
import '../../../core/errors/failures.dart';

/// Phase 1 Deterministic Mock Authentication Repository.
class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;
  final _controller = StreamController<UserModel?>.broadcast();

  static final List<UserModel> demoUsers = [
    UserModel(
      id: 'usr-001',
      email: 'operator@agvnexus.local',
      fullName: 'Sarah Chen',
      role: UserRole.factoryOperator,
      organizationId: 'org-01',
      organizationName: 'Nexus Gigafactory 1',
      createdAt: DateTime(2025, 1, 15),
    ),
    UserModel(
      id: 'usr-002',
      email: 'engineer@agvnexus.local',
      fullName: 'Alex Vance',
      role: UserRole.roboticsEngineer,
      organizationId: 'org-01',
      organizationName: 'Nexus Gigafactory 1',
      createdAt: DateTime(2025, 1, 10),
    ),
    UserModel(
      id: 'usr-003',
      email: 'maintenance@agvnexus.local',
      fullName: 'Marcus Miller',
      role: UserRole.maintenanceEngineer,
      organizationId: 'org-01',
      organizationName: 'Nexus Gigafactory 1',
      createdAt: DateTime(2025, 2, 1),
    ),
    UserModel(
      id: 'usr-004',
      email: 'admin@agvnexus.local',
      fullName: 'Elena Rostova',
      role: UserRole.fleetAdmin,
      organizationId: 'org-01',
      organizationName: 'Nexus Gigafactory 1',
      createdAt: DateTime(2024, 11, 20),
    ),
  ];

  MockAuthRepository({bool startAuthenticated = true}) {
    if (startAuthenticated) {
      _currentUser = demoUsers.first; // Default to Factory Operator
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Stream<UserModel?> authStateChanges() async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  @override
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final user = demoUsers.firstWhere(
      (u) => u.email.toLowerCase() == email.toLowerCase().trim(),
      orElse: () => throw const AuthFailure(
        'Invalid credentials or unregistered account in demo directory.',
      ),
    );

    _currentUser = user;
    _controller.add(user);
    return user;
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newUser = UserModel(
      id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
      email: email.trim(),
      fullName: fullName ?? email.split('@').first,
      role: UserRole.factoryOperator,
      organizationId: 'org-01',
      organizationName: 'Nexus Gigafactory 1',
      createdAt: DateTime.now(),
    );
    _currentUser = newUser;
    _controller.add(newUser);
    return newUser;
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Simulated password recovery mail dispatch
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _currentUser = null;
    _controller.add(null);
  }

  void dispose() {
    _controller.close();
  }
}
