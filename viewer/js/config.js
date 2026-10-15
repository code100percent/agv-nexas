/**
 * AGV Nexus - 3D Digital Twin Viewer Configuration Tokens
 */

export const CONFIG = {
  // Connection and API Endpoints
  DEFAULT_ROBOT_ID: 'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b01',
  DEFAULT_MAP_ID: 'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380c01',
  DEFAULT_ORG_ID: 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
  API_BASE_URL: '/api/v1',
  WS_URL: `${window.location.protocol === 'https:' ? 'wss:' : 'ws:'}//${window.location.host}/ws/telemetry`,

  // Factory Arena Dimensions (Derived from factory_arenas2.sdf)
  ARENA: {
    FLOOR_WIDTH: 38.0,   // meters (X in Gazebo / ROS)
    FLOOR_HEIGHT: 24.0,  // meters (Y in Gazebo / ROS)
    WALL_HEIGHT: 4.5,    // meters (Z in Gazebo / ROS)
    WALL_THICKNESS: 0.25,
    GRID_MAJOR: 5.0,     // 5 meter major division lines
    GRID_MINOR: 1.0,     // 1 meter minor grid lines
  },

  // Physical Robot Dimensions (Derived from mobile_robot.urdf)
  ROBOT: {
    BASE_LENGTH: 0.395,  // meters
    BASE_WIDTH: 0.279,   // meters
    BASE_THICKNESS: 0.015,
    BASE_ELEVATION: 0.050, // Wheel radius
    WHEEL_RADIUS: 0.050,
    WHEEL_WIDTH: 0.040,
    WHEEL_TRACK: 0.350,
    MIDDLE_PLATE_ELEVATION: 0.145,
    TOP_PLATE_LENGTH: 0.330,
    TOP_PLATE_WIDTH: 0.228,
    TOP_PLATE_ELEVATION: 0.5075,
    LIDAR_RADIUS: 0.035,
    LIDAR_HEIGHT: 0.040,
    LIDAR_ELEVATION: 0.5425, // Height of scanner above ground
  },

  // Telemetry Stream Parameters
  TELEMETRY: {
    INTERPOLATION_TIME_MS: 150, // LERP smoothing duration
    STALENESS_THRESHOLD_MS: 3000, // >3s without update flags as stale
    DISCONNECT_THRESHOLD_MS: 10000, // >10s flags as disconnected
  },

  // Color Tokens matching AGV Nexus Industrial Theme
  COLORS: {
    BACKGROUND: 0x0A0E17,
    FLOOR: 0x0D131F,
    FLOOR_GRID_MAJOR: 0x1E293B,
    FLOOR_GRID_MINOR: 0x141C2E,
    WALL: 0x1F2937,
    WALL_TRIM: 0x374151,
    RACK_STEEL: 0x1E3A8A, // Industrial blue racking
    RACK_BEAM: 0xF59E0B,  // Caution amber beam
    PALLET_WOOD: 0x854D0E,
    CRATE: 0xA16207,
    ROBOT_BASE: 0xE2E8F0,
    ROBOT_ACCENT: 0x00F0FF, // Cyan status
    ROBOT_BURGUNDY: 0x8B0000,
    WHEEL: 0x111827,
    LIDAR_BEAM: 0x00F0FF,
    LIDAR_SCAN: 0x00F0FF,
    STATION_PICKUP: 0x10B981,
    STATION_DROPOFF: 0x6366F1,
    STATION_CHARGING: 0xF59E0B,
    STATION_STAGING: 0x06B6D4,
    ROUTE_ACTIVE: 0x00F0FF,
    ROUTE_PLANNED: 0x475569,
    ROUTE_COMPLETED: 0x10B981,
  },

  // Default Layer Visibility
  LAYERS: {
    ground: true,
    occupancy: true,
    walls: true,
    stations: true,
    robot: true,
    lidar: true,
    routes: true,
  }
};
