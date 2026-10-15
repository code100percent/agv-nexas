/**
 * AGV Nexus - Factory Arena & Warehouse Environment Builder
 * Modeled from verified geometry in agv_robot/mobile_robot/config/factory_arenas2.sdf
 */

import { CONFIG } from './config.js';
import { CoordinateTransforms } from './transforms.js';

export class EnvironmentBuilder {
  constructor(scene) {
    this.scene = scene;
    this.group = new THREE.Group();
    this.group.name = 'FactoryEnvironment';
    this.scene.add(this.group);

    this.wallsGroup = new THREE.Group();
    this.racksGroup = new THREE.Group();
    this.groundGroup = new THREE.Group();

    this.group.add(this.groundGroup);
    this.group.add(this.wallsGroup);
    this.group.add(this.racksGroup);

    this.init();
  }

  init() {
    this._buildFloor();
    this._buildOuterWalls();
    this._buildWarehouseRacks();
    this._buildPalletsAndCrates();
    this._buildHazardStripes();
  }

  _buildFloor() {
    const { FLOOR_WIDTH, FLOOR_HEIGHT } = CONFIG.ARENA;

    // 1. Base Concrete Floor Plane
    const floorGeo = new THREE.PlaneGeometry(FLOOR_WIDTH, FLOOR_HEIGHT);
    const floorMat = new THREE.MeshStandardMaterial({
      color: CONFIG.COLORS.FLOOR,
      roughness: 0.85,
      metalness: 0.15,
    });
    const floorMesh = new THREE.Mesh(floorGeo, floorMat);
    floorMesh.rotation.x = -Math.PI / 2;
    floorMesh.receiveShadow = true;
    this.groundGroup.add(floorMesh);

    // 2. Metric Grid Overlay (1m minor lines, 5m major lines)
    const gridHelper = new THREE.GridHelper(
      FLOOR_WIDTH,
      FLOOR_WIDTH,
      CONFIG.COLORS.FLOOR_GRID_MAJOR,
      CONFIG.COLORS.FLOOR_GRID_MINOR
    );
    gridHelper.position.y = 0.002; // Slightly above floor plane to avoid z-fighting
    this.groundGroup.add(gridHelper);

    // 3. Coordinate Axes Marker at World Origin (0,0) (REP-103: X Red forward, Y Green left, Z Blue up)
    const axesHelper = new THREE.AxesHelper(1.5);
    axesHelper.position.set(0, 0.01, 0);
    this.groundGroup.add(axesHelper);
  }

  _buildOuterWalls() {
    const { FLOOR_WIDTH, FLOOR_HEIGHT, WALL_HEIGHT, WALL_THICKNESS } = CONFIG.ARENA;
    const wallMat = new THREE.MeshStandardMaterial({
      color: CONFIG.COLORS.WALL,
      roughness: 0.7,
      metalness: 0.2,
    });
    const trimMat = new THREE.MeshStandardMaterial({
      color: CONFIG.COLORS.WALL_TRIM,
      roughness: 0.6,
      metalness: 0.3,
    });

    const createWall = (width, depth, x, z) => {
      const geo = new THREE.BoxGeometry(width, WALL_HEIGHT, depth);
      const mesh = new THREE.Mesh(geo, wallMat);
      mesh.position.set(x, WALL_HEIGHT / 2, z);
      mesh.castShadow = true;
      mesh.receiveShadow = true;
      this.wallsGroup.add(mesh);

      // Yellow/Black kickboard trim on wall base
      const trimGeo = new THREE.BoxGeometry(width, 0.15, depth + 0.04);
      const trimMesh = new THREE.Mesh(trimGeo, trimMat);
      trimMesh.position.set(x, 0.075, z);
      this.wallsGroup.add(trimMesh);
    };

    // North Wall (+Z in Gazebo / -Z in Three)
    createWall(FLOOR_WIDTH + WALL_THICKNESS * 2, WALL_THICKNESS, 0, -(FLOOR_HEIGHT / 2));
    // South Wall
    createWall(FLOOR_WIDTH + WALL_THICKNESS * 2, WALL_THICKNESS, 0, FLOOR_HEIGHT / 2);
    // East Wall
    createWall(WALL_THICKNESS, FLOOR_HEIGHT, FLOOR_WIDTH / 2, 0);
    // West Wall
    createWall(WALL_THICKNESS, FLOOR_HEIGHT, -(FLOOR_WIDTH / 2), 0);
  }

  _buildWarehouseRacks() {
    // Modeled after stor_rack_00 and stor_rack_01 from factory_arenas2.sdf
    const rackLocations = [
      { x: 15.867, y: -4.200 },
      { x: 9.467, y: -4.200 },
      { x: 3.067, y: -4.200 },
    ];

    rackLocations.forEach((loc) => {
      const threePos = CoordinateTransforms.ros2ToThreePos(loc.x, loc.y, 0);
      const rack = this._createIndustrialRack(2.8, 0.9, 3.2);
      rack.position.set(threePos.x, 0, threePos.z);
      this.racksGroup.add(rack);
    });
  }

  _createIndustrialRack(length, depth, height) {
    const rackGroup = new THREE.Group();
    const pillarMat = new THREE.MeshStandardMaterial({
      color: CONFIG.COLORS.RACK_STEEL,
      roughness: 0.4,
      metalness: 0.8,
    });
    const beamMat = new THREE.MeshStandardMaterial({
      color: CONFIG.COLORS.RACK_BEAM,
      roughness: 0.5,
      metalness: 0.5,
    });

    const pillarRadius = 0.04;
    const halfL = length / 2;
    const halfD = depth / 2;

    // 4 Corner Steel Pillars
    [
      [-halfL, -halfD],
      [-halfL, halfD],
      [halfL, -halfD],
      [halfL, halfD],
    ].forEach(([px, pz]) => {
      const pillarGeo = new THREE.BoxGeometry(pillarRadius * 2, height, pillarRadius * 2);
      const pillar = new THREE.Mesh(pillarGeo, pillarMat);
      pillar.position.set(px, height / 2, pz);
      pillar.castShadow = true;
      rackGroup.add(pillar);
    });

    // 3 Horizontal Shelf Shelves (Levels)
    const shelfLevels = [0.2, 1.2, 2.3];
    shelfLevels.forEach((elev) => {
      const shelfGeo = new THREE.BoxGeometry(length, 0.05, depth);
      const shelf = new THREE.Mesh(shelfGeo, beamMat);
      shelf.position.set(0, elev, 0);
      shelf.castShadow = true;
      shelf.receiveShadow = true;
      rackGroup.add(shelf);

      // Place 2-3 crates on each shelf
      for (let c = -1; c <= 1; c++) {
        const crateGeo = new THREE.BoxGeometry(0.55, 0.45, 0.55);
        const crateMat = new THREE.MeshStandardMaterial({
          color: CONFIG.COLORS.CRATE,
          roughness: 0.8,
        });
        const crate = new THREE.Mesh(crateGeo, crateMat);
        crate.position.set(c * 0.75, elev + 0.25, 0);
        crate.castShadow = true;
        rackGroup.add(crate);
      }
    });

    return rackGroup;
  }

  _buildPalletsAndCrates() {
    // Modeled after load_pallet_0, load_pallet_1 from SDF
    const palletLocations = [
      { x: -8.667, y: 4.200 },
      { x: -16.667, y: 4.200 },
      { x: -8.667, y: 9.500 },
    ];

    palletLocations.forEach((loc) => {
      const threePos = CoordinateTransforms.ros2ToThreePos(loc.x, loc.y, 0);
      const palletGroup = new THREE.Group();

      // Wooden Pallet Base (1.2m x 0.8m x 0.16m)
      const palletGeo = new THREE.BoxGeometry(1.2, 0.14, 0.8);
      const palletMat = new THREE.MeshStandardMaterial({
        color: CONFIG.COLORS.PALLET_WOOD,
        roughness: 0.9,
      });
      const palletMesh = new THREE.Mesh(palletGeo, palletMat);
      palletMesh.position.set(0, 0.07, 0);
      palletMesh.castShadow = true;
      palletGroup.add(palletMesh);

      // Staged Stack of 2 Crates on pallet
      const crateGeo = new THREE.BoxGeometry(0.5, 0.5, 0.5);
      const crateMat = new THREE.MeshStandardMaterial({
        color: CONFIG.COLORS.CRATE,
        roughness: 0.7,
      });
      const c1 = new THREE.Mesh(crateGeo, crateMat);
      c1.position.set(-0.25, 0.14 + 0.25, 0);
      c1.castShadow = true;
      palletGroup.add(c1);

      const c2 = new THREE.Mesh(crateGeo, crateMat);
      c2.position.set(0.25, 0.14 + 0.25, 0);
      c2.castShadow = true;
      palletGroup.add(c2);

      palletGroup.position.set(threePos.x, 0, threePos.z);
      this.racksGroup.add(palletGroup);
    });
  }

  _buildHazardStripes() {
    // Staging and charging bay safety zone outlines
    const zones = [
      { x: 2.5, y: 3.0, w: 2.0, h: 2.0, label: 'BAY-A' },
      { x: 1.2, y: 1.0, w: 1.8, h: 1.8, label: 'DOCK-01' },
      { x: 14.2, y: 8.5, w: 2.2, h: 2.2, label: 'ASSY-04' },
    ];

    zones.forEach((z) => {
      const threePos = CoordinateTransforms.ros2ToThreePos(z.x, z.y, 0);
      const ringGeo = new THREE.RingGeometry(z.w * 0.45, z.w * 0.5, 32);
      const ringMat = new THREE.MeshBasicMaterial({
        color: 0xF59E0B,
        side: THREE.DoubleSide,
        transparent: true,
        opacity: 0.6,
      });
      const ring = new THREE.Mesh(ringGeo, ringMat);
      ring.rotation.x = -Math.PI / 2;
      ring.position.set(threePos.x, 0.005, threePos.z);
      this.groundGroup.add(ring);
    });
  }

  setVisible(layer, isVisible) {
    if (layer === 'ground') this.groundGroup.visible = isVisible;
    if (layer === 'walls') this.wallsGroup.visible = isVisible;
    if (layer === 'racks') this.racksGroup.visible = isVisible;
  }
}
