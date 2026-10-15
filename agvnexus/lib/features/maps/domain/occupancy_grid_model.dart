import 'package:flutter/foundation.dart';

/// Represents a live or cached 2D metric occupancy grid matching ROS 2 nav_msgs/OccupancyGrid.
@immutable
class OccupancyGridModel {
  final String mapId;
  final String robotId;
  final String frameId;
  final int width; // columns
  final int height; // rows
  final double resolution; // meters/cell
  final double originX;
  final double originY;
  final double originYaw;
  final List<int> data; // -1: unknown, 0: free, 100: occupied

  const OccupancyGridModel({
    required this.mapId,
    required this.robotId,
    this.frameId = 'map',
    required this.width,
    required this.height,
    required this.resolution,
    this.originX = 0.0,
    this.originY = 0.0,
    this.originYaw = 0.0,
    required this.data,
  });

  double get widthMeters => width * resolution;
  double get heightMeters => height * resolution;

  factory OccupancyGridModel.fromJson(Map<String, dynamic> json) {
    final origin = json['origin'] as Map<String, dynamic>? ?? {};
    final rawData = json['data'] as List<dynamic>? ?? [];

    return OccupancyGridModel(
      mapId: json['map_id'] as String? ?? 'default-map',
      robotId: json['robot_id'] as String? ?? 'default-robot',
      frameId: json['frame_id'] as String? ?? 'map',
      width: (json['width'] as num?)?.toInt() ?? 100,
      height: (json['height'] as num?)?.toInt() ?? 80,
      resolution: (json['resolution'] as num?)?.toDouble() ?? 0.05,
      originX: (origin['x'] as num?)?.toDouble() ?? 0.0,
      originY: (origin['y'] as num?)?.toDouble() ?? 0.0,
      originYaw: (origin['yaw'] as num?)?.toDouble() ?? 0.0,
      data: rawData.map((e) => (e as num).toInt()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'map_id': mapId,
      'robot_id': robotId,
      'frame_id': frameId,
      'width': width,
      'height': height,
      'resolution': resolution,
      'origin': {'x': originX, 'y': originY, 'yaw': originYaw},
      'data': data,
    };
  }
}
