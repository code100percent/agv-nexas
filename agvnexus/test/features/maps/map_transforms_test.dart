import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:agvnexus/features/maps/domain/map_transforms.dart';

void main() {
  group('MapCoordinateTransforms Tests (Phase 3 REP-103)', () {
    const transforms = MapCoordinateTransforms(
      resolution: 0.05, // 5 cm per cell
      originX: 0.0,
      originY: 0.0,
      originYaw: 0.0,
      gridWidth: 120, // 6.0m
      gridHeight: 80, // 4.0m
    );

    test('World origin (0.0, 0.0) transforms to grid cell (0, 0)', () {
      final (col, row) = transforms.worldToGrid(0.0, 0.0);
      expect(col, equals(0));
      expect(row, equals(0));
    });

    test('Grid cell (0, 0) center transforms back to (0.025, 0.025)', () {
      final (wx, wy) = transforms.gridToWorld(0, 0);
      expect(wx, closeTo(0.025, 1e-4));
      expect(wy, closeTo(0.025, 1e-4));
    });

    test('World point (2.5m, 3.0m) maps to cell (50, 60)', () {
      final (col, row) = transforms.worldToGrid(2.5, 3.0);
      expect(col, equals(50));
      expect(row, equals(60));
    });

    test('Canvas offset conversion scales accurately with zoom and pan', () {
      // 1 meter at 30 px/m with 2.0x zoom and (10, 20) pan
      final offset = transforms.worldToCanvas(
        1.0,
        2.0,
        scale: 30.0,
        zoom: 2.0,
        panOffset: const Offset(10, 20),
      );

      // px = 1.0 * 30.0 * 2.0 + 10 = 70
      // py = 2.0 * 30.0 * 2.0 + 20 = 140
      expect(offset.dx, equals(70.0));
      expect(offset.dy, equals(140.0));
    });

    test('Canvas to world reverses canvas coordinate back to world meters', () {
      final (wx, wy) = transforms.canvasToWorld(
        const Offset(70.0, 140.0),
        scale: 30.0,
        zoom: 2.0,
        panOffset: const Offset(10, 20),
      );
      expect(wx, closeTo(1.0, 1e-4));
      expect(wy, closeTo(2.0, 1e-4));
    });

    test('isWithinBounds accurately detects inside vs outside points', () {
      expect(transforms.isWithinBounds(2.5, 3.0), isTrue);
      expect(transforms.isWithinBounds(0.0, 0.0), isTrue);
      expect(transforms.isWithinBounds(-0.1, 1.0), isFalse); // Negative world X
      expect(
        transforms.isWithinBounds(7.0, 2.0),
        isFalse,
      ); // Exceeds 6.0m width
    });

    test('Rotated map origin transforms correctly', () {
      final rotatedTransforms = MapCoordinateTransforms(
        resolution: 0.1,
        originX: 1.0,
        originY: 1.0,
        originYaw: pi / 2, // 90 degree rotation
        gridWidth: 50,
        gridHeight: 50,
      );

      final (col, row) = rotatedTransforms.worldToGrid(1.0, 1.0);
      expect(col, equals(0));
      expect(row, equals(0));
    });
  });
}
