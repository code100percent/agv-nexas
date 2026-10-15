# AGV Nexus: Security Architecture & Vulnerability Management

**Document Version**: 1.0.0 (Phase 5 Production Readiness)  
**Classification**: Security Policy & Implementation Specification  

---

## 1. Authentication Architecture

AGV Nexus implements a defense-in-depth authentication model:
- **Client Identity**: Managed via Supabase Auth (GoTrue) using short-lived cryptographically signed JSON Web Tokens (JWT) signed via HMAC-SHA256 (`HS256`).
- **Token Verification**: Handled at the FastAPI gateway via `decode_supabase_jwt`:
  - Enforces standard claim validation: expiration (`exp`), subject identifier (`sub`), and token format.
  - Secret keys must strictly adhere to RFC 7518 ($\ge 256$ bits / 32 bytes).
- **Session Expiration**: Expired tokens immediately return `HTTP 401 Unauthorized`. Clients automatically redirect unauthenticated requests to `/sign-in`.

---

## 2. Authorization & Multi-Tenant Isolation

### 2.1 Tenant Isolation Model
Every database table and API resource is scoped to an `organization_id` UUID:
- Cross-tenant data leakage is prohibited at the database level by PostgreSQL Row Level Security (RLS) policies.
- In the FastAPI gateway, `check_robot_authorization(user, robot.organization_id)` rejects any request where the user's organization does not match the target robot (returning `HTTP 403 Forbidden`).

### 2.2 Role-Based Access Control (RBAC) Matrix

| Operation | `viewer` | `operator` | `engineer` | `admin` | `owner` |
|---|:---:|:---:|:---:|:---:|:---:|
| View Fleet Dashboard & Telemetry | ✅ | ✅ | ✅ | ✅ | ✅ |
| View 2D Occupancy Grid Maps | ✅ | ✅ | ✅ | ✅ | ✅ |
| View 3D Digital Twin Viewer | ✅ | ✅ | ✅ | ✅ | ✅ |
| View Mission History | ✅ | ✅ | ✅ | ✅ | ✅ |
| Dispatch Transport Missions | ❌ (403) | ✅ | ✅ | ✅ | ✅ |
| Manual Velocity Teleop (`/teleop`) | ❌ (403) | ✅ | ✅ | ✅ | ✅ |
| Acknowledge Fleet Faults | ❌ (403) | ✅ | ✅ | ✅ | ✅ |
| Modify Station Coordinates | ❌ (403) | ❌ (403) | ✅ | ✅ | ✅ |
| Manage Organization Members | ❌ (403) | ❌ (403) | ❌ (403) | ✅ | ✅ |

---

## 3. Secrets Management & Zero-Leakage Policy

1. **Client Storage**: Only public configuration and anonymous client keys (`SUPABASE_ANON_KEY`) are stored on client devices. Service-role keys, database master passwords, and robot onboard credentials are **NEVER** embedded in client builds.
2. **Environment Files**: Real `.env` files are excluded from Git version control via `.gitignore`. Only sanitized templates (`.env.example`) are checked into the repository.
3. **Log Redaction**: A custom `SensitiveDataRedactingFilter` in `backend/app/core/logging.py` sanitizes stdout logs, intercepting Bearer tokens, raw JWTs, passwords, and API secrets.
4. **Transport Encryption**: All production traffic must be terminated with TLS 1.3 (`https://` and `wss://`).

---

## 4. Robotics Safety & Hardware Interlocks

> [!CRITICAL]
> **Safety Interlock Notice**:
> Under ISO 3691-4, software application commands and network packets cannot be considered functional safety devices.
> 1. In the event of network drop, the robot onboard watchdog timer automatically decelerates the AGV to a standstill within 200 ms.
> 2. Velocity commands sent via `/teleop` are capped on the robot controller to safe maximum speeds ($0.8 \text{ m/s}$ linear, $1.2 \text{ rad/s}$ angular).
> 3. Emergency stops must always be executed using certified physical hardware switches or safety LiDAR scanners.

---

## 5. Security Vulnerability Reporting Process

If you discover a security vulnerability within AGV Nexus, please do not open a public issue.
Instead, submit a confidential report to:
`security@agvnexus.local`

Include:
- Summary of the vulnerability and attack vector
- Steps to reproduce or proof-of-concept payload
- Impact assessment
All legitimate vulnerabilities will receive an acknowledgment within 24 business hours.
