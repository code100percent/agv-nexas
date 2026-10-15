enum StationType {
  dock('Charging Dock'),
  pickup('Pickup Station'),
  delivery('Delivery Bay'),
  waypoint('Navigation Waypoint');

  final String displayName;
  const StationType(this.displayName);
}

class StationModel {
  final String id;
  final String name;
  final StationType type;
  final double x; // meters
  final double y; // meters
  final double yaw; // radians

  const StationModel({
    required this.id,
    required this.name,
    required this.type,
    required this.x,
    required this.y,
    this.yaw = 0.0,
  });

  factory StationModel.fromSupabase(Map<String, dynamic> map) {
    StationType parseType(String? typeStr) {
      switch (typeStr?.toLowerCase()) {
        case 'charging':
        case 'dock':
          return StationType.dock;
        case 'pickup':
          return StationType.pickup;
        case 'dropoff':
        case 'delivery':
          return StationType.delivery;
        case 'staging':
        case 'waypoint':
        default:
          return StationType.waypoint;
      }
    }

    return StationModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Station',
      type: parseType(map['station_type'] as String?),
      x: (map['x'] as num?)?.toDouble() ?? 0.0,
      y: (map['y'] as num?)?.toDouble() ?? 0.0,
      yaw: (map['yaw'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'x': x,
      'y': y,
      'yaw': yaw,
    };
  }
}

class FactoryMapModel {
  final String id;
  final String name;
  final double resolution; // meters/pixel (e.g. 0.05m)
  final double originX; // meters
  final double originY; // meters
  final int widthCells;
  final int heightCells;
  final List<StationModel> stations;
  final List<List<double>> obstacleRects; // [[x, y, w, h], ...] in meters

  const FactoryMapModel({
    required this.id,
    required this.name,
    required this.resolution,
    required this.originX,
    required this.originY,
    required this.widthCells,
    required this.heightCells,
    required this.stations,
    required this.obstacleRects,
  });

  double get widthMeters => widthCells * resolution;
  double get heightMeters => heightCells * resolution;

  factory FactoryMapModel.fromSupabase(
    Map<String, dynamic> map, {
    List<StationModel> stations = const [],
  }) {
    final originMap = map['origin'] is Map<String, dynamic>
        ? map['origin'] as Map<String, dynamic>
        : null;

    return FactoryMapModel(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Factory Map',
      resolution: (map['resolution'] as num?)?.toDouble() ?? 0.05,
      originX: (originMap?['x'] as num?)?.toDouble() ?? 0.0,
      originY: (originMap?['y'] as num?)?.toDouble() ?? 0.0,
      widthCells: (map['width'] as num?)?.toInt() ?? 400,
      heightCells: (map['height'] as num?)?.toInt() ?? 300,
      stations: stations,
      obstacleRects: const [
        [5.0, 2.0, 3.0, 1.0],
        [10.0, 6.0, 2.0, 4.0],
        [3.0, 8.0, 4.0, 0.8],
        [14.0, 3.0, 1.5, 3.0],
      ],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'resolution': resolution,
      'originX': originX,
      'originY': originY,
      'widthCells': widthCells,
      'heightCells': heightCells,
      'stations': stations.map((s) => s.toMap()).toList(),
      'obstacleRects': obstacleRects,
    };
  }
}
