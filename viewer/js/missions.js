/**
 * AGV Nexus - Mission Route & Trajectory Visualizer
 * Renders verified navigation routes, planned waypoints, active navigation vectors,
 * and traversed breadcrumb trails.
 */

import { CONFIG } from './config.js';
import { CoordinateTransforms } from './transforms.js';

export class MissionVisualizer {
  constructor(scene) {
    this.scene = scene;
    this.group = new THREE.Group();
    this.group.name = 'MissionRoutes';
    this.scene.add(this.group);

    this.activeRouteLine = null;
    this.breadcrumbLine = null;
    this.breadcrumbs = [];
    this.maxBreadcrumbs = 80;

    this.currentMission = null;

    this.init();
  }

  init() {
    this.renderDefaultSampleMission();
  }

  renderDefaultSampleMission() {
    // Verified transport corridor from Warehouse Bay A (2.5, 3.0) to Assembly Line 4 (14.2, 8.5)
    const waypoints = [
      { x: 2.5, y: 3.0 },
      { x: 5.0, y: 3.0 },
      { x: 7.5, y: 5.5 },
      { x: 10.0, y: 5.5 },
      { x: 12.0, y: 8.5 },
      { x: 14.2, y: 8.5 },
    ];

    this.setMissionRoute(waypoints, 'in_progress');
  }

  setMissionRoute(waypoints, status = 'in_progress') {
    // Clear previous line
    if (this.activeRouteLine) {
      this.group.remove(this.activeRouteLine);
      this.activeRouteLine.geometry.dispose();
      this.activeRouteLine.material.dispose();
      this.activeRouteLine = null;
    }

    if (!waypoints || waypoints.length < 2) return;

    const points3D = waypoints.map((wp) => {
      const p = CoordinateTransforms.ros2ToThreePos(wp.x, wp.y, 0.05);
      return new THREE.Vector3(p.x, p.y, p.z);
    });

    const curve = new THREE.CatmullRomCurve3(points3D);
    const curvePoints = curve.getPoints(60);

    const geo = new THREE.BufferGeometry().setFromPoints(curvePoints);
    const mat = new THREE.LineDashedMaterial({
      color: status === 'in_progress' ? CONFIG.COLORS.ROUTE_ACTIVE : CONFIG.COLORS.ROUTE_PLANNED,
      linewidth: 3,
      scale: 1,
      dashSize: 0.4,
      gapSize: 0.2,
    });

    this.activeRouteLine = new THREE.Line(geo, mat);
    this.activeRouteLine.computeLineDistances();
    this.group.add(this.activeRouteLine);

    // Goal Destination Beacon at the final waypoint
    const finalWp = points3D[points3D.length - 1];
    const goalGeo = new THREE.RingGeometry(0.35, 0.45, 24);
    const goalMat = new THREE.MeshBasicMaterial({
      color: CONFIG.COLORS.ROUTE_ACTIVE,
      side: THREE.DoubleSide,
      transparent: true,
      opacity: 0.8,
    });
    const goalRing = new THREE.Mesh(goalGeo, goalMat);
    goalRing.rotation.x = -Math.PI / 2;
    goalRing.position.set(finalWp.x, 0.02, finalWp.z);
    this.group.add(goalRing);
  }

  addBreadcrumb(x, y, z = 0.0) {
    const p = CoordinateTransforms.ros2ToThreePos(x, y, 0.015);
    this.breadcrumbs.push(new THREE.Vector3(p.x, p.y, p.z));

    if (this.breadcrumbs.length > this.maxBreadcrumbs) {
      this.breadcrumbs.shift();
    }

    if (this.breadcrumbLine) {
      this.group.remove(this.breadcrumbLine);
      this.breadcrumbLine.geometry.dispose();
      this.breadcrumbLine.material.dispose();
    }

    if (this.breadcrumbs.length >= 2) {
      const geo = new THREE.BufferGeometry().setFromPoints(this.breadcrumbs);
      const mat = new THREE.LineBasicMaterial({
        color: CONFIG.COLORS.ROUTE_COMPLETED,
        transparent: true,
        opacity: 0.4,
      });
      this.breadcrumbLine = new THREE.Line(geo, mat);
      this.group.add(this.breadcrumbLine);
    }
  }

  update(time) {
    // Animate dashed line offset to suggest forward path flow
    if (this.activeRouteLine && this.activeRouteLine.material) {
      this.activeRouteLine.material.dashSize = 0.4 + 0.1 * Math.sin(time * 4.0);
    }
  }

  setVisible(isVisible) {
    this.group.visible = isVisible;
  }
}
