# AGV Nexus: Autonomous Mobile Robot Fleet Control & 3D Digital Twin Platform

[![CI/CD Pipeline](https://github.com/code100percent/agv-nexus/actions/workflows/ci.yml/badge.svg)](.github/workflows/ci.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.35.7-blue.svg)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-009688.svg)](https://fastapi.tiangolo.com)
[![Three.js](https://img.shields.io/badge/Three.js-r128-black.svg)](https://threejs.org)
[![ROS 2](https://img.shields.io/badge/ROS_2-Humble-orange.svg)](https://docs.ros.org/en/humble/)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)]()

AGV Nexus is an enterprise-grade autonomous mobile robot (AMR) fleet management, live telemetry monitoring, and interactive 3D digital twin platform. It connects responsive operator clients (Flutter Web, Desktop, Mobile) to ROS 2 AMRs and Supabase relational databases through a high-performance FastAPI Robotics Gateway.

> **Hardware Integration & Teammate Setup:**
> For physical AGV setup, teammate laptop instructions, ROS 2 topics, and safe connectivity verification, see the [Teammate Setup & Physical AGV Guide](TEAMMATE_SETUP_AND_AGV_GUIDE.md).

---

## 🏛️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│               AGV Nexus Operator Experience                 │
│  ┌───────────────────────────┐  ┌────────────────────────┐  │
│  │ Flutter 3.35 Command UI   │  │ Three.js 3D Twin & HUD │  │
│  │ (Riverpod 3, Dark Theme)  │  │ (REP-103 Spatial Sync) │  │
│  └─────────────┬─────────────┘  └───────────┬────────────┘  │
└────────────────┼────────────────────────────┼───────────────┘
                 │ REST / WebSocket           │ PostMessage / REST
┌────────────────▼────────────────────────────▼───────────────┐
│        AGV Nexus Robotics Gateway (FastAPI / Python 3.13)   │
│  ┌───────────────────────────┐  ┌────────────────────────┐  │
│  │ Security & RBAC Guard     │  │ Log Redaction Filter   │  │
│  │ (JWT, Rate/Payload Size)  │  │ (Zero Credential Leak) │  │
│  └─────────────┬─────────────┘  └───────────┬────────────┘  │
│                │                            │               │
│  ┌─────────────▼────────────────────────────▼────────────┐  │
│  │ Multi-Tenant Robot Adapter Layer                      │  │
│  │ (Simulated Kinematic Driver / ROS 2 Humble Adapter)   │  │
│  └─────────────┬────────────────────────────┬────────────┘  │
└────────────────┼────────────────────────────┼───────────────┘
                 │ DDS / ROS 2 Topics         │ PostgreSQL / Storage
┌────────────────▼─────────────┐ ┌────────────▼───────────────┐
│ AMR Fleet / ROS 2 Hardware   │ │ Supabase Cloud / Edge DB    │
│ (/odom, /cmd_vel, /scan, TF) │ │ (11 Tables, Strict RLS)     │
└──────────────────────────────┘ └────────────────────────────┘
```

---

## 📁 Repository Structure

```
Agv Nexus/
├── .github/workflows/ci.yml     # Automated multi-job CI pipeline
├── docker-compose.yml           # Unified container deployment
├── README.md                    # Primary operational documentation
│
├── agvnexus/                    # [Frontend] Flutter Command Center & Mobile App
│   ├── lib/
│   │   ├── app/                 # App router (go_router), industrial dark theme
│   │   ├── core/                # Tokens, connection badges, failsafe painters
│   │   └── features/            # Auth, Robots, Telemetry, 2D Maps, Digital Twin
│   ├── test/                    # 45 automated unit, widget, and resilience tests
│   └── pubspec.yaml
│
├── backend/                     # [Gateway] FastAPI Async Edge Robotics Gateway
│   ├── app/
│   │   ├── adapters/            # Simulated, ROS 2, and Disconnected robot adapters
│   │   ├── api/v1/              # REST endpoints (robots, telemetry, missions, maps)
│   │   ├── core/                # JWT decoding, RBAC checks, log redaction filter
│   │   └── schemas/             # Pydantic v2 domain contracts
│   ├── tests/                   # 38 automated pytest tests (Auth, failure, transforms)
│   ├── Dockerfile               # Security-hardened multi-stage container
│   └── requirements.txt
│
├── viewer/                      # [Digital Twin] Three.js r128 WebGL Factory Simulation
│   ├── index.html               # Canvas and responsive telemetry HUD
│   ├── js/app.js                # Spatial transform math and render loop
│   └── css/style.css            # Dark industrial glassmorphism styling
│
├── supabase/                    # [Database] Relational persistence
│   └── migrations/              # Additive PostgreSQL migrations with strict RLS
│
├── agv_robot/                   # [Robotics Stack] ROS 2 Humble packages & URDFs
│   └── mobile_robot/            # Gazebo arenas, odometry drivers, and launch files
│
└── docs/                        # Complete Phase 5 Operational & Architecture Docs
    ├── ARCHITECTURE.md          # End-to-end data flow and architectural specifications
    ├── DEPLOYMENT.md            # Production deployment, Docker, and migration steps
    ├── TESTING.md               # Test coverage matrix, test commands, and fixtures
    ├── OPERATIONS_RUNBOOK.md    # SRE incident triage and operator recovery procedures
    └── SECURITY.md              # Vulnerability policy, RBAC matrix, and safety boundaries
```

---

## 🛠️ Prerequisites

- **Python**: 3.13+
- **Flutter SDK**: 3.35.7+ (Channel stable, Dart 3.9.2+)
- **Docker Engine**: 24.0+ & Docker Compose v2.20+
- **Node.js / Modern Browser**: Chrome, Edge, or Firefox with WebGL enabled

---

## ⚡ Local Development Setup

### 1. Launch FastAPI Gateway & 3D Digital Twin
```bash
cd backend
python -m venv .venv
# Windows:
.venv\Scripts\activate
# Linux/macOS:
# source .venv/bin/activate

pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
- API Docs: `http://localhost:8000/docs`
- 3D Digital Twin Viewer: `http://localhost:8000/viewer`
- Health Readiness: `http://localhost:8000/health/ready`

### 2. Launch Flutter Command Center
```bash
cd agvnexus
flutter pub get
flutter run -d chrome
```

Demo Operator Persona:
- Email: `operator@agvnexus.local`
- Password: `nexus-demo-2025`

---

## 🧪 Testing Commands

### Backend Test Suite (38 Tests)
```bash
cd backend
pytest -v
```

### Flutter Test Suite (45 Tests)
```bash
cd agvnexus
flutter test
```
*Total repository automated test coverage: **83 tests passing (100% pass rate)**.*

---

## 🐳 Containerized Production Deployment

To launch the complete containerized gateway and digital twin:
```bash
# Build and run containers
docker compose up -d --build

# Inspect status
docker compose ps
curl -f http://localhost:8000/health/ready
```

---

## ⚠️ Known Limitations & Physical Safety Notice

1. **Hardware Verification Boundary (Release Gate 6)**:
   All robotics integration tests currently execute against the verified deterministic kinematic simulation engine (`SimulatedRobotAdapter`). Physical AMR hardware is not connected to this development workstation and must be independently verified in an approved factory staging environment.
2. **ISO 3691-4 Functional Safety Mandate**:
   The web application, mobile UI, and cloud backend are non-deterministic monitoring interfaces and **CANNOT** replace physical dual-channel hardware emergency-stop circuits.

---

## 📚 Complete Documentation
- [System Architecture](docs/ARCHITECTURE.md)
- [Production Deployment Guide](docs/DEPLOYMENT.md)
- [Testing & Quality Assurance Guide](docs/TESTING.md)
- [Operations & Incident Runbook](docs/OPERATIONS_RUNBOOK.md)
- [Security Architecture & RBAC](docs/SECURITY.md)
