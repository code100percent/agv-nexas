# AGV Nexus: Production Deployment Guide

**Document Version**: 1.0.0 (Phase 5 Production Readiness)  
**Classification**: Operations & Infrastructure Specification  

---

## 1. Prerequisites & Environment Setup

### Required Host Tools
- **Docker Engine**: Version 24.0+ and Docker Compose v2.20+
- **Python**: Version 3.13+ (if running bare-metal)
- **Flutter SDK**: Version 3.35.7+ (Channel stable, Dart 3.9.2+)
- **PostgreSQL / Supabase**: PostgreSQL 15+ with `pgcrypto` and `uuid-ossp` extensions

---

## 2. Secrets & Environment Configuration

Configuration is managed via `.env` files or container environment variables.

### Environment Variable Matrix

| Variable | Target | Recommended Production Value | Description |
|---|---|---|---|
| `APP_ENV` | Backend | `production` | Enables production security checks & disables debug reload. |
| `API_HOST` | Backend | `0.0.0.0` | Bind host address. |
| `API_PORT` | Backend | `8000` | Gateway listening port. |
| `REQUIRE_AUTH` | Backend | `true` | Enforces mandatory JWT validation on all protected endpoints. |
| `SUPABASE_URL` | Both | `https://<ref>.supabase.co` | Remote Supabase project URL. |
| `SUPABASE_ANON_KEY` | Both | `<anon_jwt>` | Client-safe publishable anonymous key. |
| `SUPABASE_JWT_SECRET` | Backend | `<secret_32b_min>` | Shared HMAC secret for verifying Supabase auth tokens ($\ge 32$ bytes). |
| `ROBOT_ADAPTER_MODE` | Backend | `ros2` or `simulated` | Driver mode: use `ros2` for physical AMRs; `simulated` for dev/staging. |
| `CORS_ALLOWED_ORIGINS` | Backend | `["https://agv.factory.local"]` | Explicit list of trusted UI origins. |

> [!CAUTION]
> Never set `SUPABASE_SERVICE_ROLE_KEY` on the client application or expose it in container environment files that client devices can read.

---

## 3. Database Migration Procedure

Database migrations reside in `supabase/migrations/` and are strictly additive and idempotent.

### Clean Disposable Environment Migration
```bash
# Using Supabase CLI:
supabase db reset
supabase migration up

# Or executing directly against disposable PostgreSQL:
psql -h <host> -U postgres -d agvnexus -f supabase/migrations/20261015000001_create_agv_nexus_schema.sql
psql -h <host> -U postgres -d agvnexus -f supabase/migrations/20261015000002_enable_rls_and_policies.sql
```

### Production Migration Rules
1. Never run destructive migrations (no `DROP TABLE` or `DROP COLUMN`).
2. Always test migrations against an isolated staging snapshot first.
3. Keep database backup before executing any DDL.

---

## 4. Containerized Gateway & 3D Viewer Deployment

The unified Docker container packages both the FastAPI gateway and the Three.js WebGL Digital Twin viewer.

### Building and Launching with Docker Compose
```bash
# 1. Clone repository and verify environment variables
cp .env.example .env
# Edit .env with production parameters

# 2. Build and launch container in background
docker compose up -d --build

# 3. Verify container health
docker compose ps
curl -f http://localhost:8000/health/ready
```

### Manual Docker Build
```bash
docker build -t agvnexus-gateway:1.0.0 -f backend/Dockerfile .
docker run -d --name agvnexus -p 8000:8000 --env-file .env agvnexus-gateway:1.0.0
```

---

## 5. Flutter Web / Desktop Client Build

### Building Flutter Web (Production)
```bash
cd agvnexus
flutter clean
flutter pub get

flutter build web --release \
  --dart-define=ENV=production \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=API_BASE_URL=https://gateway.factory.local/api/v1 \
  --dart-define=WS_BASE_URL=wss://gateway.factory.local/ws/telemetry
```
Output directory: `agvnexus/build/web/` (deployable behind Nginx or Caddy with HTTPS).

### Building Flutter Windows Desktop
```bash
cd agvnexus
flutter build windows --release
```
Output directory: `agvnexus/build/windows/x64/runner/Release/`

---

## 6. Health Checks & Verification

### Probes
- **Liveness Probe**:
  `GET http://localhost:8000/health/live`
  - Expected: HTTP `200 OK`, `{"status": "alive"}`
- **Readiness Probe**:
  `GET http://localhost:8000/health/ready`
  - Expected: HTTP `200 OK`, `{"status": "ready", "adapter_health": {...}}`
  - Returns `503 Service Unavailable` if adapter connection is degraded or severed.

---

## 7. Rollback Guidance

In the event of an unsuccessful deployment:
1. **Container Rollback**:
   ```bash
   docker stop agvnexus-gateway
   docker tag agvnexus-gateway:previous agvnexus-gateway:latest
   docker compose up -d
   ```
2. **Database Rollback**:
   Because Phase 5 migrations are additive, previous backend revisions remain compatible with the schema. If an emergency rollback of a specific policy is needed, revert only the specific `CREATE POLICY` statements using explicit `DROP POLICY`.
