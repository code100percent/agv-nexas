/**
 * AGV Nexus - 3D Digital Twin Master Application
 */

import { CONFIG } from './config.js';
import { SceneManager } from './scene.js';
import { CameraController } from './camera.js';
import { EnvironmentBuilder } from './environment.js';
import { OccupancyGridLayer } from './occupancy.js';
import { RobotManager } from './robot.js';
import { LidarVisualizer } from './lidar.js';
import { StationManager } from './stations.js';
import { MissionVisualizer } from './missions.js';
import { TelemetryClient } from './telemetry.js';

class DigitalTwinApp {
  constructor() {
    this.canvas = document.getElementById('twin-canvas');
    this.loadingOverlay = document.getElementById('loading-overlay');

    // Parse URL Parameters
    const urlParams = new URLSearchParams(window.location.search);
    this.robotId = urlParams.get('robot_id') || CONFIG.DEFAULT_ROBOT_ID;
    this.token = urlParams.get('token') || null;

    // Component Instances
    this.sceneManager = null;
    this.cameraController = null;
    this.environment = null;
    this.occupancyGrid = null;
    this.robot = null;
    this.lidar = null;
    this.stations = null;
    this.missions = null;
    this.telemetryClient = null;

    this.clock = new THREE.Clock();
    this.isRunning = false;

    this.init();
  }

  async init() {
    try {
      // 1. Core Scene & Camera
      this.sceneManager = new SceneManager(this.canvas);
      this.cameraController = new CameraController(this.canvas);

      // 2. Factory Environment & Static Arena
      this.environment = new EnvironmentBuilder(this.sceneManager.scene);

      // 3. Occupancy Grid Overlay
      this.occupancyGrid = new OccupancyGridLayer(this.sceneManager.scene);
      await this.occupancyGrid.loadMap(this.robotId, this.token);

      // 4. Robot & Planar LiDAR Visualizer
      this.robot = new RobotManager(this.sceneManager.scene);
      this.cameraController.setFollowTarget(this.robot.root);
      this.lidar = new LidarVisualizer(this.robot.root);

      // 5. Stations & Landmarks
      this.stations = new StationManager(
        this.sceneManager.scene,
        this.cameraController.camera,
        this.onStationSelected.bind(this)
      );
      await this.stations.loadStations(CONFIG.DEFAULT_MAP_ID, this.token);

      // 6. Mission Visualization
      this.missions = new MissionVisualizer(this.sceneManager.scene);

      // 7. Telemetry Streaming Client
      this.telemetryClient = new TelemetryClient({
        robotId: this.robotId,
        token: this.token,
        onTelemetry: this.onTelemetryReceived.bind(this),
        onConnectionStatus: this.onConnectionStatusChanged.bind(this),
      });
      this.telemetryClient.connect();

      // 8. Bind UI Events & Flutter Interop
      this._bindUIEvents();
      this._bindPostMessageBridge();

      // 9. Start Animation Loop
      this.isRunning = true;
      this._animate();

      // Hide Loading Overlay
      if (this.loadingOverlay) {
        this.loadingOverlay.classList.add('hidden');
      }
    } catch (err) {
      console.error('[DigitalTwinApp] Initialization error:', err);
      const loadingText = document.querySelector('.loading-text');
      if (loadingText) {
        loadingText.textContent = `Initialization Error: ${err.message}. Retrying fallback...`;
      }
    }
  }

  _animate() {
    if (!this.isRunning) return;
    requestAnimationFrame(this._animate.bind(this));

    const delta = this.clock.getDelta();
    const elapsedTime = this.clock.getElapsedTime();

    // Update dynamic entities
    if (this.robot) this.robot.update(delta);
    if (this.cameraController) this.cameraController.update(delta);
    if (this.stations) this.stations.update(elapsedTime);
    if (this.missions) this.missions.update(elapsedTime);

    // Render Scene
    if (this.sceneManager && this.cameraController) {
      this.sceneManager.render(this.cameraController.camera);
    }
  }

  onTelemetryReceived(telemetry) {
    // 1. Update Robot Kinematic Target Pose
    if (this.robot && telemetry.position_x !== undefined && telemetry.position_y !== undefined) {
      this.robot.updatePose(
        telemetry.position_x,
        telemetry.position_y,
        telemetry.position_z || 0.0,
        telemetry.yaw || 0.0
      );
      this.robot.setStatus(telemetry.robot_operating_state || 'idle');

      // Add to trajectory breadcrumb trail
      if (this.missions) {
        this.missions.addBreadcrumb(telemetry.position_x, telemetry.position_y);
      }
    }

    // 2. Update HUD Telemetry Readouts
    this._updateHUDTelemetry(telemetry);
  }

  onConnectionStatusChanged(status) {
    const badge = document.getElementById('connection-status-badge');
    const badgeText = document.getElementById('connection-status-text');
    if (!badge || !badgeText) return;

    badge.className = 'badge';
    if (status === 'connected') {
      badge.classList.add('badge-connected');
      badgeText.textContent = 'GATEWAY: LIVE';
    } else if (status === 'stale') {
      badge.classList.add('badge-stale');
      badgeText.textContent = 'GATEWAY: STALE';
    } else {
      badge.classList.add('badge-simulated');
      badgeText.textContent = 'GATEWAY: RECONNECTING';
    }
  }

  _updateHUDTelemetry(t) {
    const setVal = (id, text) => {
      const el = document.getElementById(id);
      if (el) el.textContent = text;
    };

    setVal('hud-pos-x', `${(t.position_x || 0).toFixed(2)} m`);
    setVal('hud-pos-y', `${(t.position_y || 0).toFixed(2)} m`);
    setVal('hud-pos-z', `${(t.position_z || 0).toFixed(2)} m`);

    const yawDeg = (((t.yaw || 0) * 180) / Math.PI).toFixed(1);
    setVal('hud-yaw', `${yawDeg}°`);

    const half = (t.yaw || 0) / 2;
    setVal('hud-qw', Math.cos(half).toFixed(4));
    setVal('hud-qz', Math.sin(half).toFixed(4));

    setVal('hud-vel-lin', `${(t.linear_velocity || 0).toFixed(2)} m/s`);
    setVal('hud-vel-ang', `${(t.angular_velocity || 0).toFixed(2)} rad/s`);
    setVal('hud-battery', `${(t.battery_percentage || 0).toFixed(1)}%`);
    setVal('hud-state', (t.robot_operating_state || 'IDLE').toUpperCase());
  }

  onStationSelected(station) {
    const modal = document.getElementById('station-modal');
    if (!modal) return;

    document.getElementById('modal-station-name').textContent = station.name;
    document.getElementById('modal-station-type').textContent = (station.station_type || 'WAYPOINT').toUpperCase();
    document.getElementById('modal-station-coords').textContent = `X: ${station.x.toFixed(2)}m, Y: ${station.y.toFixed(2)}m`;
    document.getElementById('modal-station-desc').textContent = station.description || 'Verified factory navigation landmark.';

    modal.classList.add('active');

    // Focus Camera Action Button inside modal
    const focusBtn = document.getElementById('modal-station-focus');
    focusBtn.onclick = () => {
      this.cameraController.focusOn({ x: station.x, y: 0, z: -station.y });
    };
  }

  _bindUIEvents() {
    // Camera Preset Buttons
    const camButtons = {
      'btn-cam-iso': 'isometric',
      'btn-cam-top': 'topdown',
      'btn-cam-follow': 'follow',
      'btn-cam-free': 'free',
    };

    Object.entries(camButtons).forEach(([btnId, mode]) => {
      const btn = document.getElementById(btnId);
      if (!btn) return;
      btn.addEventListener('click', () => {
        document.querySelectorAll('.camera-controls-bar .btn-icon').forEach((b) => b.classList.remove('active'));
        btn.classList.add('active');
        this.cameraController.setMode(mode);
      });
    });

    // Reset Camera
    const resetBtn = document.getElementById('btn-cam-reset');
    if (resetBtn) {
      resetBtn.addEventListener('click', () => {
        this.cameraController.fitToEnvironment();
      });
    }

    // Layer Toggles
    const layerToggles = [
      { id: 'toggle-layer-ground', fn: (v) => this.environment.setVisible('ground', v) },
      { id: 'toggle-layer-occupancy', fn: (v) => this.occupancyGrid.setVisible(v) },
      { id: 'toggle-layer-walls', fn: (v) => this.environment.setVisible('walls', v) },
      { id: 'toggle-layer-stations', fn: (v) => this.stations.setVisible(v) },
      { id: 'toggle-layer-robot', fn: (v) => this.robot.setVisible(v) },
      { id: 'toggle-layer-lidar', fn: (v) => this.lidar.setVisible(v) },
      { id: 'toggle-layer-routes', fn: (v) => this.missions.setVisible(v) },
    ];

    layerToggles.forEach(({ id, fn }) => {
      const input = document.getElementById(id);
      if (input) {
        input.addEventListener('change', (e) => fn(e.target.checked));
      }
    });

    // Station Modal Close Button
    const closeBtn = document.getElementById('modal-station-close');
    if (closeBtn) {
      closeBtn.addEventListener('click', () => {
        document.getElementById('station-modal').classList.remove('active');
      });
    }
  }

  _bindPostMessageBridge() {
    // Allows parent Flutter application (via iframe postMessage) to control viewer
    window.addEventListener('message', (event) => {
      const data = event.data;
      if (!data || typeof data !== 'object') return;

      switch (data.action) {
        case 'setCamera':
          if (data.mode) this.cameraController.setMode(data.mode);
          break;
        case 'focusRobot':
          if (this.robot) {
            this.cameraController.focusOn(this.robot.root.position);
          }
          break;
        case 'setRobot':
          if (data.robotId && data.robotId !== this.robotId) {
            this.robotId = data.robotId;
            this.telemetryClient.disconnect();
            this.telemetryClient.robotId = this.robotId;
            this.telemetryClient.connect();
          }
          break;
        case 'setLayer':
          if (data.layer && data.visible !== undefined) {
            const input = document.getElementById(`toggle-layer-${data.layer}`);
            if (input) {
              input.checked = data.visible;
              input.dispatchEvent(new Event('change'));
            }
          }
          break;
      }
    });
  }
}

// Instantiate on DOM load
window.addEventListener('DOMContentLoaded', () => {
  new DigitalTwinApp();
});
