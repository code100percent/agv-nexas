import 'package:flutter_test/flutter_test.dart';
import 'package:agvnexus/features/maps/domain/map_model.dart';

void main() {
  group('Supabase Map & Station Model Tests (Phase 2)', () {
    test('Parses StationModel from Supabase with correct StationType enum', () {
      final pickupRow = {
        'id': 'stn-01',
        'name': 'Warehouse Bay A',
        'station_type': 'pickup',
        'x': 2.5,
        'y': 3.0,
        'yaw': 0.0,
      };
      final pickup = StationModel.fromSupabase(pickupRow);
      expect(pickup.type, StationType.pickup);
      expect(pickup.x, 2.5);

      final dockRow = {
        'id': 'stn-02',
        'name': 'Dock Station 1',
        'station_type': 'charging',
        'x': 1.0,
        'y': 1.0,
        'yaw': 3.14,
      };
      final dock = StationModel.fromSupabase(dockRow);
      expect(dock.type, StationType.dock);
      expect(dock.yaw, 3.14);
    });

    test('Parses FactoryMapModel from Supabase with origin and resolution', () {
      final mapRow = {
        'id': 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380c01',
        'name': 'Floor 1',
        'resolution': 0.05,
        'width': 400,
        'height': 300,
        'origin': {'x': 0.0, 'y': 0.0},
      };

      final map = FactoryMapModel.fromSupabase(mapRow);
      expect(map.id, 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380c01');
      expect(map.resolution, 0.05);
      expect(map.widthMeters, 20.0);
      expect(map.heightMeters, 15.0);
    });
  });
}
