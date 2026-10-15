/**
 * AGV Nexus - Robot Model Builder & Kinematic Pose Controller
 * Procedurally constructed from mobile_robot.urdf specifications with optional GLTF loading.
 */

import { CONFIG } from './config.js';
import { CoordinateTransforms } from './transforms.js';

export class RobotManager {
  constructor(scene) {
    this.scene = scene;
    this.robotId = CONFIG.DEFAULT_ROBOT_ID;

    this.root = new THREE.Group();
    this.root.name = 'AGV_Titan01_Root';
    this.scene.add(this.root);

    // Dynamic Visual Sub-elements
    this.haloRing = null;
    this.headingArrow = null;
    this.wheels = [];

    // State Tracking
    this.currentPose = { x: 2.5, y: 3.0, z: 0.0, yaw: 0.0 };
    this.targetPose = { x: 2.5, y: 3.0, z: 0.0, yaw: 0.0 };
    this.interpolationFactor = 0.15; // Smooth pose damping

    this.init();
  }

  init() {
    this._buildProceduralURDFModel();
    this._buildGroundHalo();
    this._buildHeadingIndicator();
  }

  _buildProceduralURDFModel() {
    const { ROBOT } = CONFIG;
    const bodyMat = new THREE.MeshStandardMaterial({
      color: CONFIG.COLORS.ROBOT_BASE,
      roughness: 0.3,
      metalness: 0.6,
    });
    const woodMat = new THREE.MeshStandardMaterial({
      color: 0x854D0E, // Wood / MDF middle deck as in URDF
      roughness: 0.7,
    });
    const metalMat = new THREE.MeshStandardMaterial({
      color: 0x64748B,
      roughness: 0.3,
      metalness: 0.9,
    });
    const wheelMat = new THREE.MeshStandardMaterial({
      color: CONFIG.COLORS.WHEEL,
      roughness: 0.8,
    });
    const laptopMat = new THREE.MeshStandardMaterial({
      color: 0x0F172A,
      roughness: 0.2,
      metalness: 0.8,
    });

    // 1. Lower Base Plate (0.395m x 0.279m x 0.015m) at Z=0.05
    const baseGeo = new THREE.BoxGeometry(ROBOT.BASE_LENGTH, ROBOT.BASE_THICKNESS, ROBOT.BASE_WIDTH);
    const baseMesh = new THREE.Mesh(baseGeo, bodyMat);
    baseMesh.position.y = ROBOT.BASE_ELEVATION;
    baseMesh.castShadow = true;
    baseMesh.receiveShadow = true;
    this.root.add(baseMesh);

    // 2. Differential Drive Rear Wheels (Radius 0.05m, Width 0.04m, Track 0.35m)
    // Left Wheel (Z = -track/2 in Three.js coordinates)
    const wheelGeo = new THREE.CylinderGeometry(ROBOT.WHEEL_RADIUS, ROBOT.WHEEL_RADIUS, ROBOT.WHEEL_WIDTH, 24);
    wheelGeo.rotateX(Math.PI / 2); // Cylinder along Z axis

    const wheelLeft = new THREE.Mesh(wheelGeo, wheelMat);
    wheelLeft.position.set(-0.09, ROBOT.WHEEL_RADIUS, -ROBOT.WHEEL_TRACK / 2);
    wheelLeft.castShadow = true;
    this.root.add(wheelLeft);
    this.wheels.push(wheelLeft);

    // Right Wheel
    const wheelRight = new THREE.Mesh(wheelGeo, wheelMat);
    wheelRight.position.set(-0.09, ROBOT.WHEEL_RADIUS, ROBOT.WHEEL_TRACK / 2);
    wheelRight.castShadow = true;
    this.root.add(wheelRight);
    this.wheels.push(wheelRight);

    // Front Passive Casters
    const casterGeo = new THREE.SphereGeometry(0.025, 16, 16);
    const casterMat = new THREE.MeshStandardMaterial({ color: 0x334155, metalness: 0.9 });
    const c1 = new THREE.Mesh(casterGeo, casterMat);
    c1.position.set(0.12, 0.025, -0.08);
    this.root.add(c1);

    const c2 = new THREE.Mesh(casterGeo, casterMat);
    c2.position.set(0.12, 0.025, 0.08);
    this.root.add(c2);

    // 3. 4 Vertical Support Rods from Base to Middle Deck
    const rodGeo = new THREE.CylinderGeometry(0.005, 0.005, 0.08, 12);
    [
      [0.15, 0.10],
      [0.15, -0.10],
      [-0.15, 0.10],
      [-0.15, -0.10],
    ].forEach(([rx, rz]) => {
      const rod = new THREE.Mesh(rodGeo, metalMat);
      rod.position.set(rx, ROBOT.BASE_ELEVATION + 0.04, rz);
      rod.castShadow = true;
      this.root.add(rod);
    });

    // 4. Middle Shelf Plate (Z=0.145)
    const midGeo = new THREE.BoxGeometry(ROBOT.BASE_LENGTH, ROBOT.BASE_THICKNESS, ROBOT.BASE_WIDTH);
    const midMesh = new THREE.Mesh(midGeo, woodMat);
    midMesh.position.y = ROBOT.MIDDLE_PLATE_ELEVATION;
    midMesh.castShadow = true;
    this.root.add(midMesh);

    // 5. On-board Compute Deck / Laptop on Middle Shelf
    const laptopBaseGeo = new THREE.BoxGeometry(0.24, 0.015, 0.18);
    const laptopMesh = new THREE.Mesh(laptopBaseGeo, laptopMat);
    laptopMesh.position.set(0, ROBOT.MIDDLE_PLATE_ELEVATION + 0.015, 0);
    this.root.add(laptopMesh);

    // 6. 4 Aluminium Corner Extrusions to Top Plate (Height 0.36m)
    const columnGeo = new THREE.BoxGeometry(0.02, 0.36, 0.02);
    [
      [0.14, 0.09],
      [0.14, -0.09],
      [-0.14, 0.09],
      [-0.14, -0.09],
    ].forEach(([cx, cz]) => {
      const col = new THREE.Mesh(columnGeo, metalMat);
      col.position.set(cx, ROBOT.MIDDLE_PLATE_ELEVATION + 0.18, cz);
      col.castShadow = true;
      this.root.add(col);
    });

    // 7. Top Shelf Plate (0.33m x 0.228m) at Z=0.5075
    const topGeo = new THREE.BoxGeometry(ROBOT.TOP_PLATE_LENGTH, ROBOT.BASE_THICKNESS, ROBOT.TOP_PLATE_WIDTH);
    const topMesh = new THREE.Mesh(topGeo, bodyMat);
    topMesh.position.y = ROBOT.TOP_PLATE_ELEVATION;
    topMesh.castShadow = true;
    this.root.add(topMesh);

    // 8. 2D Planar LiDAR Scanner Head (Cylinder Radius 0.035m, Height 0.04m)
    const lidarGeo = new THREE.CylinderGeometry(ROBOT.LIDAR_RADIUS, ROBOT.LIDAR_RADIUS, ROBOT.LIDAR_HEIGHT, 32);
    const lidarMat = new THREE.MeshStandardMaterial({
      color: 0x0F172A,
      metalness: 0.8,
      roughness: 0.2,
    });
    const lidarMesh = new THREE.Mesh(lidarGeo, lidarMat);
    lidarMesh.position.set(0.06, ROBOT.TOP_PLATE_ELEVATION + 0.03, 0);
    lidarMesh.castShadow = true;
    this.root.add(lidarMesh);

    // LiDAR Optics Ring (Cyan emissive indicator)
    const ringGeo = new THREE.TorusGeometry(ROBOT.LIDAR_RADIUS + 0.002, 0.003, 8, 32);
    ringGeo.rotateX(Math.PI / 2);
    const ringMat = new THREE.MeshBasicMaterial({ color: CONFIG.COLORS.ROBOT_ACCENT });
    const ringMesh = new THREE.Mesh(ringGeo, ringMat);
    ringMesh.position.set(0.06, ROBOT.TOP_PLATE_ELEVATION + 0.035, 0);
    this.root.add(ringMesh);
  }

  _buildGroundHalo() {
    const haloGeo = new THREE.RingGeometry(0.38, 0.42, 48);
    const haloMat = new THREE.MeshBasicMaterial({
      color: CONFIG.COLORS.ROBOT_ACCENT,
      side: THREE.DoubleSide,
      transparent: true,
      opacity: 0.8,
    });
    this.haloRing = new THREE.Mesh(haloGeo, haloMat);
    this.haloRing.rotation.x = -Math.PI / 2;
    this.haloRing.position.y = 0.005; // Hugs floor
    this.root.add(this.haloRing);
  }

  _buildHeadingIndicator() {
    // Arrow pointing in the +X forward heading direction
    const arrowDir = new THREE.Vector3(1, 0, 0);
    const arrowOrigin = new THREE.Vector3(0.18, 0.06, 0);
    this.headingArrow = new THREE.ArrowHelper(arrowDir, arrowOrigin, 0.35, CONFIG.COLORS.ROBOT_ACCENT, 0.1, 0.06);
    this.root.add(this.headingArrow);
  }

  updatePose(x, y, z = 0.0, yaw = 0.0) {
    if (!CoordinateTransforms.isValidCoordinate(x, y, z)) return;

    this.targetPose.x = x;
    this.targetPose.y = y;
    this.targetPose.z = z;
    this.targetPose.yaw = yaw;
  }

  update(deltaSeconds) {
    // Smoothly interpolate position and orientation
    this.currentPose.x += (this.targetPose.x - this.currentPose.x) * this.interpolationFactor;
    this.currentPose.y += (this.targetPose.y - this.currentPose.y) * this.interpolationFactor;
    this.currentPose.z += (this.targetPose.z - this.currentPose.z) * this.interpolationFactor;

    // Shortest angular difference interpolation
    let dYaw = this.targetPose.yaw - this.currentPose.yaw;
    while (dYaw < -Math.PI) dYaw += Math.PI * 2;
    while (dYaw > Math.PI) dYaw -= Math.PI * 2;
    this.currentPose.yaw += dYaw * this.interpolationFactor;

    // Apply coordinate transformation to Three.js Object3D root
    const threePos = CoordinateTransforms.ros2ToThreePos(
      this.currentPose.x,
      this.currentPose.y,
      this.currentPose.z
    );

    this.root.position.set(threePos.x, threePos.y, threePos.z);
    this.root.rotation.y = CoordinateTransforms.ros2YawToThreeRot(this.currentPose.yaw);
  }

  setStatus(status) {
    // Green = active/navigating, Amber = idle/warning, Red = fault/disconnected
    if (!this.haloRing) return;
    if (status === 'navigating') {
      this.haloRing.material.color.setHex(CONFIG.COLORS.STATION_PICKUP);
    } else if (status === 'idle') {
      this.haloRing.material.color.setHex(CONFIG.COLORS.ROBOT_ACCENT);
    } else if (status === 'fault' || status === 'disconnected') {
      this.haloRing.material.color.setHex(CONFIG.COLORS.ROBOT_BURGUNDY);
    }
  }

  setVisible(isVisible) {
    this.root.visible = isVisible;
  }
}
