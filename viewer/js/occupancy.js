/**
 * AGV Nexus - 2.5D Occupancy Grid Layer Manager
 * Fetches and renders nav_msgs/OccupancyGrid from FastAPI /api/v1/robots/{id}/map.
 */

import { CONFIG } from './config.js';
import { CoordinateTransforms } from './transforms.js';

export class OccupancyGridLayer {
  constructor(scene) {
    this.scene = scene;
    this.group = new THREE.Group();
    this.group.name = 'OccupancyGridLayer';
    this.scene.add(this.group);

    this.gridData = null;
    this.mesh = null;
  }

  async loadMap(robotId = CONFIG.DEFAULT_ROBOT_ID, token = null) {
    try {
      const headers = {};
      if (token) {
        headers['Authorization'] = `Bearer ${token}`;
      }
      const response = await fetch(`${CONFIG.API_BASE_URL}/robots/${robotId}/map`, { headers });
      if (!response.ok) {
        console.warn(`[OccupancyGrid] Map fetch returned ${response.status}`);
        return;
      }
      this.gridData = await response.json();
      this.renderGrid();
    } catch (err) {
      console.warn('[OccupancyGrid] Could not fetch live occupancy grid:', err);
    }
  }

  renderGrid() {
    if (!this.gridData) return;

    // Clear previous mesh
    while (this.group.children.length > 0) {
      const obj = this.group.children.pop();
      if (obj.geometry) obj.geometry.dispose();
      if (obj.material) obj.material.dispose();
    }

    const { width, height, resolution, origin, data } = this.gridData;
    const originX = origin ? origin.x : 0.0;
    const originY = origin ? origin.y : 0.0;

    // Use InstancedMesh for high performance when rendering occupied cell blocks
    const occupiedIndices = [];
    for (let i = 0; i < data.length; i++) {
      if (data[i] === 100) {
        occupiedIndices.push(i);
      }
    }

    if (occupiedIndices.length === 0) return;

    const blockHeight = 0.5; // 0.5m extruded height for occupied obstacles
    const boxGeo = new THREE.BoxGeometry(resolution * 0.95, blockHeight, resolution * 0.95);
    const boxMat = new THREE.MeshStandardMaterial({
      color: 0x8B0000, // Deep burgundy hazard color matching AGV Nexus palette
      roughness: 0.7,
      metalness: 0.3,
      transparent: true,
      opacity: 0.85,
    });

    const instancedMesh = new THREE.InstancedMesh(boxGeo, boxMat, occupiedIndices.length);
    instancedMesh.castShadow = true;
    instancedMesh.receiveShadow = true;

    const matrix = new THREE.Matrix4();
    const dummy = new THREE.Object3D();

    occupiedIndices.forEach((cellIdx, instanceIdx) => {
      const col = cellIdx % width;
      const row = Math.floor(cellIdx / width);

      const { worldX, worldY } = CoordinateTransforms.gridToWorld(col, row, resolution, originX, originY);
      const threePos = CoordinateTransforms.ros2ToThreePos(worldX, worldY, blockHeight / 2);

      dummy.position.set(threePos.x, threePos.y, threePos.z);
      dummy.updateMatrix();
      instancedMesh.setMatrixAt(instanceIdx, dummy.matrix);
    });

    instancedMesh.instanceMatrix.needsUpdate = true;
    this.group.add(instancedMesh);
  }

  setVisible(isVisible) {
    this.group.visible = isVisible;
  }

  dispose() {
    while (this.group.children.length > 0) {
      const obj = this.group.children.pop();
      if (obj.geometry) obj.geometry.dispose();
      if (obj.material) obj.material.dispose();
    }
    this.scene.remove(this.group);
  }
}
