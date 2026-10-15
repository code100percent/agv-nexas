import 'package:flutter_test/flutter_test.dart';
import 'package:agvnexus/features/auth/domain/user_model.dart';

void main() {
  group('Supabase UserModel & RBAC Role Mapping Tests (Phase 2)', () {
    test('Maps owner role to fleetAdmin with all privileges', () {
      final user = UserModel.fromSupabase(
        id: 'usr-owner-uuid',
        email: 'owner@gigafactory.com',
        profileMap: {
          'id': 'usr-owner-uuid',
          'display_name': 'Chief Operations Officer',
          'created_at': '2026-01-01T00:00:00.000Z',
        },
        memberMap: {'organization_id': 'org-alpha-uuid', 'role': 'owner'},
        orgMap: {'id': 'org-alpha-uuid', 'name': 'Nexus Gigafactory Alpha'},
      );

      expect(user.id, 'usr-owner-uuid');
      expect(user.fullName, 'Chief Operations Officer');
      expect(user.role, UserRole.fleetAdmin);
      expect(user.isAdmin, isTrue);
      expect(user.canDispatchMissions, isTrue);
      expect(user.canModifyConfigurations, isTrue);
      expect(user.organizationName, 'Nexus Gigafactory Alpha');
    });

    test(
      'Maps operator role with mission dispatch but not admin privileges',
      () {
        final user = UserModel.fromSupabase(
          id: 'usr-op-uuid',
          email: 'operator@gigafactory.com',
          profileMap: {
            'id': 'usr-op-uuid',
            'display_name': 'Shift 1 Operator',
            'created_at': '2026-01-01T00:00:00.000Z',
          },
          memberMap: {'organization_id': 'org-alpha-uuid', 'role': 'operator'},
          orgMap: {'id': 'org-alpha-uuid', 'name': 'Nexus Gigafactory Alpha'},
        );

        expect(user.role, UserRole.factoryOperator);
        expect(user.isAdmin, isFalse);
        expect(user.canDispatchMissions, isTrue);
        expect(user.canModifyConfigurations, isFalse);
      },
    );

    test('Maps engineer role with configuration capabilities', () {
      final user = UserModel.fromSupabase(
        id: 'usr-eng-uuid',
        email: 'eng@gigafactory.com',
        profileMap: {
          'id': 'usr-eng-uuid',
          'display_name': 'Robotics Systems Lead',
          'created_at': '2026-01-01T00:00:00.000Z',
        },
        memberMap: {'organization_id': 'org-alpha-uuid', 'role': 'engineer'},
        orgMap: {'id': 'org-alpha-uuid', 'name': 'Nexus Gigafactory Alpha'},
      );

      expect(user.role, UserRole.roboticsEngineer);
      expect(user.isAdmin, isFalse);
      expect(user.canModifyConfigurations, isTrue);
    });

    test('Serializes toMap and parses back fromMap correctly', () {
      final original = UserModel(
        id: 'usr-test',
        email: 'test@agvnexus.local',
        fullName: 'Jane Doe',
        role: UserRole.factoryOperator,
        organizationId: 'org-01',
        organizationName: 'Nexus Plant 1',
        createdAt: DateTime(2026, 2, 10),
      );

      final map = original.toMap();
      final parsed = UserModel.fromMap(map);

      expect(parsed.id, original.id);
      expect(parsed.email, original.email);
      expect(parsed.fullName, original.fullName);
      expect(parsed.role, original.role);
      expect(parsed.organizationId, original.organizationId);
      expect(parsed.organizationName, original.organizationName);
    });
  });
}
