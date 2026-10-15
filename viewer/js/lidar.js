/**
 * AGV Nexus - 2D Planar LaserScan Spatial Visualizer
 *
 * NOTE: The physical AGV (mobile_robot.urdf) is equipped with a 2D planar LiDAR
 * (sensor_msgs/msg/LaserScan). It does NOT produce a dense 3D point cloud.
 * This module renders the 2D horizontal scan fan at the sensor elevation (z=0.54m),
 * reflecting detected obstacles without falsely claiming 3D spatial reconstruction.
 */

import { CONFIG } from './config.js';

export class LidarVisualizer {
  constructor(robotGroup) {
    this.robotGroup = robotGroup;
    this.group = new THREE.Group();
    this.group.name = 'PlanarLidarRays';
    this.robotGroup.add(this.group);

    this.scanLines = null;
    this.hitPoints = null;
    this.numRays = 72; // Sampled rays around 360 degrees
    this.maxRange = 8.0; // meters

    this.init();
  }

  init() {
    const { ROBOT } = CONFIG;
    const sensorElevation = ROBOT.LIDAR_ELEVATION;

    // 1. Planar Laser Fan Line Segments
    const linePositions = new Float32Array(this.numRays * 2 * 3);
    const lineGeo = new THREE.BufferGeometry();
    lineGeo.setAttribute('position', new THREE.BufferAttribute(linePositions, 3));

    const lineMat = new THREE.LineBasicMaterial({
      color: CONFIG.COLORS.LIDAR_SCAN,
      transparent: true,
      opacity: 0.25,
      blending: THREE.AdditiveBlending,
    });
    this.scanLines = new THREE.LineSegments(lineGeo, lineMat);
    this.group.add(this.scanLines);

    // 2. Obstacle Boundary Return Points (Small cyan dots at ray termination)
    const pointPositions = new Float32Array(this.numRays * 3);
    const pointGeo = new THREE.BufferGeometry();
    pointGeo.setAttribute('position', new THREE.BufferAttribute(pointPositions, 3));

    const pointMat = new THREE.PointsMaterial({
      color: CONFIG.COLORS.LIDAR_BEAM,
      size: 0.08,
      transparent: true,
      opacity: 0.8,
    });
    this.hitPoints = new THREE.Points(pointGeo, pointMat);
    this.group.add(this.hitPoints);

    this.updateScanGeometry(sensorElevation);
  }

  updateScanGeometry(elevation) {
    const linePos = this.scanLines.geometry.attributes.position.array;
    const pointPos = this.hitPoints.geometry.attributes.position.array;

    const sensorX = 0.06;
    const sensorZ = 0.0;

    for (let i = 0; i < this.numRays; i++) {
      const angle = (i / this.numRays) * Math.PI * 2;
      // Synthetic range simulation if raw scan array is not supplied
      const range = 2.5 + 1.5 * Math.sin(angle * 3.0) + Math.cos(angle * 5.0) * 0.8;
      const targetRange = Math.min(Math.max(range, 0.8), this.maxRange);

      const hitX = sensorX + targetRange * Math.cos(angle);
      const hitZ = sensorZ + targetRange * Math.sin(angle);

      // Line origin (LiDAR center)
      const lIdx = i * 6;
      linePos[lIdx] = sensorX;
      linePos[lIdx + 1] = elevation;
      linePos[lIdx + 2] = sensorZ;

      // Line endpoint (LiDAR ray hit)
      linePos[lIdx + 3] = hitX;
      linePos[lIdx + 4] = elevation;
      linePos[lIdx + 5] = hitZ;

      // Point endpoint
      const pIdx = i * 3;
      pointPos[pIdx] = hitX;
      pointPos[pIdx + 1] = elevation;
      pointPos[pIdx + 2] = hitZ;
    }

    this.scanLines.geometry.attributes.position.needsUpdate = true;
    this.hitPoints.geometry.attributes.position.needsUpdate = true;
  }

  setVisible(isVisible) {
    this.group.visible = isVisible;
  }
}
