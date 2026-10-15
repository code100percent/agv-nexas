/**
 * AGV Nexus - Three.js WebGL Scene & Renderer Lifecycle Manager
 */

import { CONFIG } from './config.js';

export class SceneManager {
  constructor(canvasElement) {
    this.canvas = canvasElement;
    this.scene = null;
    this.renderer = null;
    this.lights = [];
    this.isContextLost = false;

    this.init();
  }

  init() {
    // 1. Scene
    this.scene = new THREE.Scene();
    this.scene.background = new THREE.Color(CONFIG.COLORS.BACKGROUND);
    this.scene.fog = new THREE.FogExp2(CONFIG.COLORS.BACKGROUND, 0.015);

    // 2. High Performance WebGL Renderer
    this.renderer = new THREE.WebGLRenderer({
      canvas: this.canvas,
      antialias: true,
      powerPreference: 'high-performance',
      alpha: false,
    });

    const pixelRatio = Math.min(window.devicePixelRatio, 2.0);
    this.renderer.setPixelRatio(pixelRatio);
    this.renderer.setSize(window.innerWidth, window.innerHeight);

    // Shadows & Tone Mapping
    this.renderer.shadowMap.enabled = true;
    this.renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    this.renderer.toneMapping = THREE.ACESFilmicToneMapping;
    this.renderer.toneMappingExposure = 1.1;

    // 3. Lighting Setup
    this._setupLighting();

    // 4. Handle WebGL Context Loss Gracefully
    this.canvas.addEventListener('webglcontextlost', (event) => {
      event.preventDefault();
      this.isContextLost = true;
      console.warn('[SceneManager] WebGL Context lost. Halting render cycle.');
    });

    this.canvas.addEventListener('webglcontextrestored', () => {
      console.info('[SceneManager] WebGL Context restored. Reinitializing renderer.');
      this.isContextLost = false;
      this.init();
    });

    // 5. Window Resize Handler
    window.addEventListener('resize', this.onWindowResize.bind(this));
  }

  _setupLighting() {
    // Ambient Light
    const ambientLight = new THREE.AmbientLight(0x2A364F, 0.7);
    this.scene.add(ambientLight);
    this.lights.push(ambientLight);

    // Hemisphere Fill (Sky blue down to ground dark slate)
    const hemiLight = new THREE.HemisphereLight(0x4A6B82, 0x0A0E17, 0.5);
    hemiLight.position.set(0, 20, 0);
    this.scene.add(hemiLight);
    this.lights.push(hemiLight);

    // Directional Sun Light (simulating warehouse roof skylights / primary shadow source)
    const sunLight = new THREE.DirectionalLight(0xE2E8F0, 1.2);
    sunLight.position.set(15, 25, 10);
    sunLight.castShadow = true;
    sunLight.shadow.mapSize.width = 2048;
    sunLight.shadow.mapSize.height = 2048;
    sunLight.shadow.camera.near = 0.5;
    sunLight.shadow.camera.far = 60;
    sunLight.shadow.camera.left = -25;
    sunLight.shadow.camera.right = 25;
    sunLight.shadow.camera.top = 20;
    sunLight.shadow.camera.bottom = -20;
    sunLight.shadow.bias = -0.0005;
    this.scene.add(sunLight);
    this.lights.push(sunLight);

    // Overhead Bay Lights matching factory_arenas2.sdf luminaires
    const bayPositions = [
      { x: 0, y: 8, z: 0 },
      { x: 12, y: 8, z: 6 },
      { x: -12, y: 8, z: 6 },
      { x: 12, y: 8, z: -6 },
      { x: -12, y: 8, z: -6 },
    ];

    bayPositions.forEach((pos) => {
      const pointLight = new THREE.PointLight(0xF8FAFC, 0.4, 22, 1.5);
      pointLight.position.set(pos.x, pos.y, pos.z);
      this.scene.add(pointLight);
      this.lights.push(pointLight);
    });
  }

  onWindowResize() {
    if (!this.renderer) return;
    this.renderer.setSize(window.innerWidth, window.innerHeight);
    const pixelRatio = Math.min(window.devicePixelRatio, 2.0);
    this.renderer.setPixelRatio(pixelRatio);
  }

  render(camera) {
    if (this.isContextLost || !this.renderer || !this.scene || !camera) return;
    this.renderer.render(this.scene, camera);
  }

  dispose() {
    window.removeEventListener('resize', this.onWindowResize);
    if (this.renderer) {
      this.renderer.dispose();
      this.renderer.forceContextLoss();
    }
  }
}
