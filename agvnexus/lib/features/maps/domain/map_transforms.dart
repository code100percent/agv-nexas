import 'dart:math';
import 'dart:ui';

/// High-precision coordinate transformation utility between:
/// 1. ROS 2 / World frame (REP-103: X forward/east, Y left/north, metric in meters)
/// 2. Discrete Grid cells (column index, row index in row-major occupancy array)
/// 3. Flutter Canvas viewport (pixels, screen top-left origin, pan and zoom)
class MapCoordinateTransforms {
  final double resolution; // meters per grid cell
  final double originX; // world X in meters
  final double originY; // world Y in meters
  final double originYaw; // radians rotation of map origin
  final int gridWidth; // number of cell columns
  final int gridHeight; // number of cell rows

  const MapCoordinateTransforms({
    required this.resolution,
    this.originX = 0.0,
    this.originY = 0.0,
    this.originYaw = 0.0,
    required this.gridWidth,
    required this.gridHeight,
  });

  /// Convert continuous world position (meters) to discrete grid indices (col, row).
  (int col, int row) worldToGrid(double worldX, double worldY) {
    final dx = worldX - originX;
    final dy = worldY - originY;
    final cosTheta = cos(-originYaw);
    final sinTheta = sin(-originYaw);

    final rx = dx * cosTheta - dy * sinTheta;
    final ry = dx * sinTheta + dy * cosTheta;

    final col = (rx / resolution).floor();
    final row = (ry / resolution).floor();
    return (col, row);
  }

  /// Convert discrete grid indices (col, row) to world coordinates at cell center (meters).
  (double worldX, double worldY) gridToWorld(int col, int row) {
    final rx = (col + 0.5) * resolution;
    final ry = (row + 0.5) * resolution;
    final cosTheta = cos(originYaw);
    final sinTheta = sin(originYaw);

    final worldX = rx * cosTheta - ry * sinTheta + originX;
    final worldY = rx * sinTheta + ry * cosTheta + originY;
    return (worldX, worldY);
  }

  /// Convert world position (meters) to Flutter Canvas Offset (pixels).
  /// [scale] is pixels per meter (default 30.0 px/m).
  /// [panOffset] accounts for operator drag/pan translation.
  /// [zoom] accounts for pinch-to-zoom magnification.
  Offset worldToCanvas(
    double worldX,
    double worldY, {
    double scale = 30.0,
    Offset panOffset = Offset.zero,
    double zoom = 1.0,
  }) {
    // Canvas X is positive rightwards, Canvas Y is positive downwards
    final px = (worldX * scale * zoom) + panOffset.dx;
    final py = (worldY * scale * zoom) + panOffset.dy;
    return Offset(px, py);
  }

  /// Convert screen canvas pixel offset back to world coordinates (meters).
  (double worldX, double worldY) canvasToWorld(
    Offset canvasPoint, {
    double scale = 30.0,
    Offset panOffset = Offset.zero,
    double zoom = 1.0,
  }) {
    final worldX = (canvasPoint.dx - panOffset.dx) / (scale * zoom);
    final worldY = (canvasPoint.dy - panOffset.dy) / (scale * zoom);
    return (worldX, worldY);
  }

  /// Check whether given world coordinate lies within the valid map boundaries.
  bool isWithinBounds(double worldX, double worldY) {
    final (col, row) = worldToGrid(worldX, worldY);
    return col >= 0 && col < gridWidth && row >= 0 && row < gridHeight;
  }
}
