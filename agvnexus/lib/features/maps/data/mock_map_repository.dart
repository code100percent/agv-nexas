import '../domain/map_model.dart';
import '../domain/map_repository.dart';

/// Phase 1 Deterministic Mock Map Repository.
class MockMapRepository implements MapRepository {
  static const FactoryMapModel defaultMap = FactoryMapModel(
    id: 'map-plant-01',
    name: 'Nexus Plant 1 - Main Floor',
    resolution: 0.05, // 5 cm per cell
    originX: 0.0,
    originY: 0.0,
    widthCells: 600, // 30 meters
    heightCells: 400, // 20 meters
    stations: [
      StationModel(
        id: 'STN-DOCK-1',
        name: 'Dock Station 01',
        type: StationType.dock,
        x: 2.0,
        y: 3.5,
        yaw: 0.0,
      ),
      StationModel(
        id: 'STN-DOCK-2',
        name: 'Dock Station 02',
        type: StationType.dock,
        x: 2.0,
        y: 16.5,
        yaw: 0.0,
      ),
      StationModel(
        id: 'STN-WH-A',
        name: 'Warehouse Bay A',
        type: StationType.pickup,
        x: 6.0,
        y: 4.0,
        yaw: 1.57,
      ),
      StationModel(
        id: 'STN-WH-B',
        name: 'Storage Bay B2',
        type: StationType.pickup,
        x: 6.0,
        y: 14.0,
        yaw: 1.57,
      ),
      StationModel(
        id: 'STN-ASSY-1',
        name: 'Assembly Line 1',
        type: StationType.delivery,
        x: 18.0,
        y: 4.0,
        yaw: 3.14,
      ),
      StationModel(
        id: 'STN-ASSY-2',
        name: 'Assembly Line 2',
        type: StationType.delivery,
        x: 18.0,
        y: 10.0,
        yaw: 3.14,
      ),
      StationModel(
        id: 'STN-ASSY-3',
        name: 'Assembly Line 3',
        type: StationType.delivery,
        x: 18.0,
        y: 16.0,
        yaw: 3.14,
      ),
      StationModel(
        id: 'STN-PALLET',
        name: 'Pallet Buffer Area',
        type: StationType.waypoint,
        x: 24.0,
        y: 10.0,
        yaw: 0.0,
      ),
    ],
    obstacleRects: [
      // Factory Outer Perimeter walls
      [0.0, 0.0, 30.0, 0.4],
      [0.0, 0.0, 0.4, 20.0],
      [0.0, 19.6, 30.0, 0.4],
      [29.6, 0.0, 0.4, 20.0],
      // Storage Racks Area
      [4.5, 6.0, 3.0, 6.0],
      // Central Structural Pillars
      [10.0, 5.0, 1.0, 1.0],
      [10.0, 14.0, 1.0, 1.0],
      [15.0, 7.0, 1.2, 5.0],
      // CNC Enclosure Cells
      [21.0, 3.0, 5.0, 4.0],
      [21.0, 13.0, 5.0, 4.0],
    ],
  );

  @override
  Future<FactoryMapModel> getActiveMap() async {
    return defaultMap;
  }

  @override
  Future<List<StationModel>> getStations() async {
    return defaultMap.stations;
  }
}
