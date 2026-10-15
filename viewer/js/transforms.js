/**
 * AGV Nexus - Coordinate Transformations Module
 * Bridges ROS 2 (REP-103) with Three.js WebGL coordinate systems.
 */

export class CoordinateTransforms {
  /**
   * Convert continuous ROS 2 world coordinates (meters) to Three.js world coordinates.
   * ROS 2 standard (REP-103):
   *   +X : Forward / East
   *   +Y : Left / North
   *   +Z : Up
   * Three.js standard:
   *   +X : Right
   *   +Y : Up
   *   -Z : Forward (Camera looking down -Z by default)
   */
  static ros2ToThreePos(x, y, z = 0.0) {
    return {
      x: Number(x),
      y: Number(z),
      z: -Number(y)
    };
  }

  /**
   * Inverse transformation from Three.js scene coordinates back to ROS 2 REP-103.
   */
  static threeToRos2Pos(x, y, z) {
    return {
      x: Number(x),
      y: -Number(z),
      z: Number(y)
    };
  }

  /**
   * Convert ROS 2 planar yaw heading (radians, CCW about +Z)
   * to Three.js Y-axis rotation (radians).
   */
  static ros2YawToThreeRot(yawRad) {
    // Both systems measure CCW around the vertical axis;
    // With Z_three = -y_ros, rotation about +Y aligns directly.
    return Number(yawRad);
  }

  /**
   * Compute normalized quaternion (qx, qy, qz, qw) from planar yaw angle.
   */
  static yawToQuaternion(yawRad) {
    const half = yawRad / 2.0;
    return {
      qx: 0.0,
      qy: 0.0,
      qz: Math.sin(half),
      qw: Math.cos(half)
    };
  }

  /**
   * Extract planar yaw angle (radians) from quaternion components.
   */
  static quaternionToYaw(qx, qy, qz, qw) {
    const siny_cosp = 2.0 * (qw * qz + qx * qy);
    const cosy_cosp = 1.0 - 2.0 * (qy * qy + qz * qz);
    return Math.atan2(siny_cosp, cosy_cosp);
  }

  /**
   * Convert continuous world coordinates to discrete occupancy grid indices.
   */
  static worldToGrid(worldX, worldY, resolution = 0.05, originX = 0.0, originY = 0.0) {
    const col = Math.floor((worldX - originX) / resolution);
    const row = Math.floor((worldY - originY) / resolution);
    return { col, row };
  }

  /**
   * Convert discrete occupancy grid indices to world coordinates at cell center.
   */
  static gridToWorld(col, row, resolution = 0.05, originX = 0.0, originY = 0.0) {
    const worldX = (col + 0.5) * resolution + originX;
    const worldY = (row + 0.5) * resolution + originY;
    return { worldX, worldY };
  }

  /**
   * Check whether coordinates are finite numbers within physical sanity bounds.
   */
  static isValidCoordinate(x, y, z = 0.0) {
    return (
      x !== null && x !== undefined && !isNaN(x) && isFinite(x) &&
      y !== null && y !== undefined && !isNaN(y) && isFinite(y) &&
      z !== null && z !== undefined && !isNaN(z) && isFinite(z) &&
      Math.abs(x) < 500 && Math.abs(y) < 500
    );
  }
}
