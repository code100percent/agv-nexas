/**
 * AGV Nexus - Stations and Operational Landmarks Manager
 * Renders verified 3D station markers, holographic beacons, and interactive raycaster selection.
 */

import { CONFIG } from './config.js';
import { CoordinateTransforms } from './transforms.js';

export class StationManager {
  constructor(scene, camera, onSelectCallback) {
    this.scene = scene;
    this.camera = camera;
    this.onSelectCallback = onSelectCallback;

    this.group = new THREE.Group();
    this.group.name = 'FactoryStations';
    this.scene.add(this.group);

    this.stations = [];
    this.stationMeshes = [];
    this.selectedStation = null;

    this.raycaster = new THREE.Raycaster();
    this.mouse = new THREE.Vector2();

    this.init();
  }

  init() {
    window.addEventListener('click', this._onPointerClick.bind(this));
  }

  async loadStations(mapId = CONFIG.DEFAULT_MAP_ID, token = null) {
    try {
      const headers = {};
      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
      }
      const response = await fetch(`${CONFIG.API_BASE_URL}/stations`, { headers });
      if (response.ok) {
        this.stations = await response.json();
      } else {
        // Fallback to verified seed stations
        this.stations = this._getSeedStations();
      }
    } catch (e) {
      this.stations = this._getSeedStations();
    }
    this.renderStations();
  }

  _getSeedStations() {
    return [
      {
        id: 'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380d01',
        name: 'Warehouse Bay A',
        station_type: 'pickup',
        x: 2.5,
        y: 3.0,
        yaw: 0.0,
        description: 'Raw material pallet intake bay with optical alignment markings',
      },
      {
        id: 'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380d02',
        name: 'Assembly Line 4',
        station_type: 'dropoff',
        x: 14.2,
        y: 8.5,
        yaw: 1.57,
        description: 'Main production feeder station for automated line cell 4',
      },
      {
        id: 'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380d03',
        name: 'Charging Dock 01',
        station_type: 'charging',
        x: 1.2,
        y: 1.0,
        yaw: 3.14,
        description: 'Automated inductive floor charging station with magnetic guide strip',
      },
      {
        id: 'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380d04',
        name: 'Quality Inspection 2',
        station_type: 'staging',
        x: 8.0,
        y: 12.0,
        yaw: 0.78,
        description: 'Finished goods staging area for optical QC scanning',
      },
    ];
  }

  renderStations() {
    // Clear previous
    while (this.group.children.length > 0) {
      const obj = this.group.children.pop();
      if (obj.geometry) obj.geometry.dispose();
      if (obj.material) obj.material.dispose();
    }
    this.stationMeshes = [];

    this.stations.forEach((stn) => {
      const threePos = CoordinateTransforms.ros2ToThreePos(stn.x, stn.y, 0);
      const stnGroup = new THREE.Group();
      stnGroup.position.set(threePos.x, 0, threePos.z);
      stnGroup.userData = stn;

      const color = this._getColorForType(stn.station_type);

      // 1. Concentric Ground Target Disc
      const padGeo = new THREE.RingGeometry(0.6, 0.9, 32);
      const padMat = new THREE.MeshBasicMaterial({
        color: color,
        side: THREE.DoubleSide,
        transparent: true,
        opacity: 0.7,
      });
      const pad = new THREE.Mesh(padGeo, padMat);
      pad.rotation.x = -Math.PI / 2;
      pad.position.y = 0.005;
      stnGroup.add(pad);

      // 2. Holographic Vertical Beacon Beam
      const beaconGeo = new THREE.CylinderGeometry(0.04, 0.25, 2.8, 16, 1, true);
      const beaconMat = new THREE.MeshBasicMaterial({
        color: color,
        transparent: true,
        opacity: 0.35,
        side: THREE.DoubleSide,
        depthWrite: false,
      });
      const beacon = new THREE.Mesh(beaconGeo, beaconMat);
      beacon.position.y = 1.4;
      stnGroup.add(beacon);

      // 3. Floating 3D Diamond / Marker Head (Selectable hit target)
      const diamondGeo = new THREE.OctahedronGeometry(0.28, 0);
      const diamondMat = new THREE.MeshStandardMaterial({
        color: color,
        emissive: color,
        emissiveIntensity: 0.5,
        roughness: 0.2,
      });
      const diamond = new THREE.Mesh(diamondGeo, diamondMat);
      diamond.position.y = 2.8;
      diamond.castShadow = true;
      diamond.userData = { isStationHead: true, station: stn };
      stnGroup.add(diamond);
      this.stationMeshes.push(diamond);

      // 4. Orientation Alignment Arrow
      const arrowDir = new THREE.Vector3(Math.cos(stn.yaw), 0, -Math.sin(stn.yaw));
      const arrow = new THREE.ArrowHelper(arrowDir, new THREE.Vector3(0, 0.02, 0), 0.8, color, 0.2, 0.1);
      stnGroup.add(arrow);

      this.group.add(stnGroup);
    });
  }

  _getColorForType(type) {
    switch (type?.toLowerCase()) {
      case 'pickup':
        return CONFIG.COLORS.STATION_PICKUP;
      case 'dropoff':
      case 'delivery':
        return CONFIG.COLORS.STATION_DROPOFF;
      case 'charging':
        return CONFIG.COLORS.STATION_CHARGING;
      case 'staging':
      default:
        return CONFIG.COLORS.STATION_STAGING;
    }
  }

  _onPointerClick(event) {
    if (!this.camera || this.stationMeshes.length === 0) return;

    // Convert mouse to normalized device coordinates
    this.mouse.x = (event.clientX / window.innerWidth) * 2 - 1;
    this.mouse.y = -(event.clientY / window.innerHeight) * 2 + 1;

    this.raycaster.setFromCamera(this.mouse, this.camera);
    const intersects = this.raycaster.intersectObjects(this.stationMeshes);

    if (intersects.length > 0) {
      const selected = intersects[0].object.userData.station;
      if (selected && this.onSelectCallback) {
        this.selectedStation = selected;
        this.onSelectCallback(selected);
      }
    }
  }

  update(time) {
    // Subtle hover animation for station marker heads
    this.stationMeshes.forEach((mesh, idx) => {
      mesh.rotation.y += 0.015;
      mesh.position.y = 2.8 + Math.sin(time * 2.0 + idx) * 0.08;
    });
  }

  setVisible(isVisible) {
    this.group.visible = isVisible;
  }
}
