/**
 * AGV Nexus - Camera Controller & Orbital Navigation
 */

export class CameraController {
  constructor(canvasElement) {
    this.canvas = canvasElement;
    this.camera = null;
    this.controls = null;

    this.mode = 'isometric'; // 'isometric' | 'topdown' | 'follow' | 'free'
    this.targetPos = new THREE.Vector3(0, 0, 0);
    this.followTarget = null; // Reference to Object3D (robot)

    this.transitioning = false;
    this.transitionStartCamPos = new THREE.Vector3();
    this.transitionEndCamPos = new THREE.Vector3();
    this.transitionStartLookAt = new THREE.Vector3();
    this.transitionEndLookAt = new THREE.Vector3();
    this.transitionProgress = 0.0;
    this.transitionDuration = 0.6; // seconds

    this.init();
  }

  init() {
    const aspect = window.innerWidth / window.innerHeight;
    this.camera = new THREE.PerspectiveCamera(45, aspect, 0.1, 200);

    // Initial Isometric Perspective
    this.camera.position.set(22, 20, 22);

    // OrbitControls
    if (window.THREE && THREE.OrbitControls) {
      this.controls = new THREE.OrbitControls(this.camera, this.canvas);
      this.controls.enableDamping = true;
      this.controls.dampingFactor = 0.08;
      this.controls.screenSpacePanning = true;
      this.controls.minDistance = 3.0;
      this.controls.maxDistance = 65.0;
      this.controls.maxPolarAngle = Math.PI / 2 - 0.05; // Prevent camera from going under floor
      this.controls.target.set(0, 0, 0);
    }

    window.addEventListener('resize', this.onWindowResize.bind(this));
  }

  onWindowResize() {
    if (!this.camera) return;
    this.camera.aspect = window.innerWidth / window.innerHeight;
    this.camera.updateProjectionMatrix();
  }

  setMode(modeName) {
    this.mode = modeName;
    if (modeName === 'isometric') {
      this.animateTo(new THREE.Vector3(22, 20, 22), new THREE.Vector3(0, 0, 0));
    } else if (modeName === 'topdown') {
      this.animateTo(new THREE.Vector3(0, 36, 0.01), new THREE.Vector3(0, 0, 0));
    } else if (modeName === 'follow') {
      // Handled in update() when followTarget is present
    } else if (modeName === 'free') {
      // Retain current position, unlock controls
    }
  }

  animateTo(targetCamPos, targetLookAt) {
    this.transitionStartCamPos.copy(this.camera.position);
    this.transitionEndCamPos.copy(targetCamPos);
    this.transitionStartLookAt.copy(this.controls ? this.controls.target : this.targetPos);
    this.transitionEndLookAt.copy(targetLookAt);
    this.transitionProgress = 0.0;
    this.transitioning = true;
  }

  focusOn(position, offsetDistance = 6.0) {
    const targetCamPos = new THREE.Vector3(
      position.x + offsetDistance * 0.7,
      position.y + offsetDistance * 0.8,
      position.z + offsetDistance * 0.7
    );
    this.animateTo(targetCamPos, new THREE.Vector3(position.x, position.y, position.z));
  }

  fitToEnvironment() {
    this.animateTo(new THREE.Vector3(25, 24, 25), new THREE.Vector3(0, 0, 0));
  }

  setFollowTarget(object3D) {
    this.followTarget = object3D;
  }

  update(deltaSeconds) {
    if (this.transitioning) {
      this.transitionProgress += deltaSeconds / this.transitionDuration;
      const t = Math.min(this.transitionProgress, 1.0);
      // Smooth cubic easing
      const ease = t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;

      this.camera.position.lerpVectors(this.transitionStartCamPos, this.transitionEndCamPos, ease);
      if (this.controls) {
        this.controls.target.lerpVectors(this.transitionStartLookAt, this.transitionEndLookAt, ease);
      }

      if (t >= 1.0) {
        this.transitioning = false;
      }
    } else if (this.mode === 'follow' && this.followTarget) {
      // Smoothly follow behind the robot chassis
      const robotPos = this.followTarget.position;
      const targetLookAt = new THREE.Vector3(robotPos.x, robotPos.y + 0.3, robotPos.z);
      const targetCamPos = new THREE.Vector3(
        robotPos.x - 4.5 * Math.sin(this.followTarget.rotation.y),
        robotPos.y + 3.0,
        robotPos.z - 4.5 * Math.cos(this.followTarget.rotation.y)
      );

      this.camera.position.lerp(targetCamPos, 0.08);
      if (this.controls) {
        this.controls.target.lerp(targetLookAt, 0.1);
      }
    }

    if (this.controls) {
      this.controls.update();
    }
  }

  dispose() {
    window.removeEventListener('resize', this.onWindowResize);
    if (this.controls) {
      this.controls.dispose();
    }
  }
}
