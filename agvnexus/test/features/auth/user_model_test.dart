import 'package:flutter_test/flutter_test.dart';
import 'package:agvnexus/features/auth/domain/user_model.dart';

void main() {
  group('UserModel Role & Permissions Tests', () {
    test('FleetAdmin has admin and dispatch privileges', () {
      final admin = UserModel(
        id: 'usr-admin',
        email: 'admin@agvnexus.local',
        fullName: 'Admin User',
        role: UserRole.fleetAdmin,
        organizationId: 'org-01',
        organizationName: 'Nexus Plant 1',
        createdAt: DateTime(2025, 1, 1),
      );

      expect(admin.isAdmin, isTrue);
      expect(admin.canDispatchMissions, isTrue);
      expect(admin.canModifyConfigurations, isTrue);
    });

    test(
      'FactoryOperator has mission dispatch but not configuration privileges',
      () {
        final operator = UserModel(
          id: 'usr-op',
          email: 'operator@agvnexus.local',
          fullName: 'Operator User',
          role: UserRole.factoryOperator,
          organizationId: 'org-01',
          organizationName: 'Nexus Plant 1',
          createdAt: DateTime(2025, 1, 1),
        );

        expect(operator.isAdmin, isFalse);
        expect(operator.canDispatchMissions, isTrue);
        expect(operator.canModifyConfigurations, isFalse);
      },
    );

    test(
      'MaintenanceEngineer can configure but cannot dispatch routine production missions',
      () {
        final engineer = UserModel(
          id: 'usr-eng',
          email: 'engineer@agvnexus.local',
          fullName: 'Maintenance Tech',
          role: UserRole.maintenanceEngineer,
          organizationId: 'org-01',
          organizationName: 'Nexus Plant 1',
          createdAt: DateTime(2025, 1, 1),
        );

        expect(engineer.isAdmin, isFalse);
        expect(engineer.canDispatchMissions, isFalse);
      },
    );
  });
}
