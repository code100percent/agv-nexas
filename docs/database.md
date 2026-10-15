# AGV Nexus - PostgreSQL Database & Security Specification (Phase 2)

## 1. Overview & Strategy

AGV Nexus uses **Supabase PostgreSQL** as its multi-tenant persistence layer.
All tables enforce **Row Level Security (RLS)** with organization-scoped multi-tenancy.
Direct database access from untrusted clients is strictly prevented; every query and mutation is filtered through membership helper functions.

---

## 2. Relational Schema Architecture

### 2.1 Table Catalog

| Table | Description | Primary Key | Key Constraints |
| :--- | :--- | :--- | :--- |
| `organizations` | Tenant / smart factory facility | `id UUID` | `slug UNIQUE` |
| `profiles` | Operator user profile linked to `auth.users` | `id UUID` | `FK -> auth.users(id) ON DELETE CASCADE` |
| `organization_members` | Tenant membership & RBAC role | `id UUID` | `UNIQUE(organization_id, user_id)`, `role IN ('owner','admin','operator','engineer','viewer')` |
| `robots` | Physical / simulated AGV metadata | `id UUID` | `UNIQUE(organization_id, robot_code)`, `max_payload_kg >= 0` |
| `factory_maps` | 2D occupancy grid metadata & storage paths | `id UUID` | `FK -> robots(id) ON DELETE SET NULL`, `resolution > 0` |
| `stations` | Fixed bays, docks, and waypoints | `id UUID` | `FK -> factory_maps(id) ON DELETE CASCADE`, `station_type IN (...)` |
| `missions` | Transport requests & state lifecycle | `id UUID` | `status IN ('queued','assigned','in_progress','completed','failed','cancelled')`, `priority BETWEEN 1 AND 4` |
| `mission_events` | Granular mission state machine log | `id UUID` | `FK -> missions(id) ON DELETE CASCADE` |
| `robot_alerts` | Diagnostics and safety alerts | `id UUID` | `severity IN ('critical','warning','info')` |
| `robot_telemetry` | Sampled historical sensor diagnostics | `id UUID` | `source IN ('simulation','robot_gateway')`, `battery_percent BETWEEN 0 AND 100` |
| `audit_logs` | Immutable audit trail for security events | `id UUID` | Append-only (no UPDATE/DELETE policies) |

---

## 3. Row Level Security (RLS) & Role Matrix

Every application table has RLS enabled (`ALTER TABLE ... ENABLE ROW LEVEL SECURITY`).
Access is evaluated through `SECURITY DEFINER` functions with `search_path = public`:
* `public.is_org_member(org_id UUID)`
* `public.get_org_role(org_id UUID)`
* `public.is_org_admin(org_id UUID)`
* `public.is_org_operator_or_higher(org_id UUID)`

### 3.1 Role Capabilities Matrix

| Role | Organization Settings | Manage Members | Register Robots / Maps | Create Missions | View Telemetry & History | Acknowledge Alerts |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Owner** | Full | Full | Full | Yes | Yes | Yes |
| **Admin** | View / Update | Full (non-owner) | Full | Yes | Yes | Yes |
| **Engineer** | View only | View only | Create / Update | Yes | Yes | Yes |
| **Operator** | View only | View only | View only | Create / Cancel own | Yes | Yes |
| **Viewer** | View only | View only | View only | View only | View only | View only |

---

## 4. Supabase Storage: `factory-maps`

* **Bucket Name**: `factory-maps`
* **Visibility**: Private (not public)
* **Path Convention**: `factory-maps/{organization_id}/{map_file}.yaml`
* **Access Rules**:
  * `SELECT`: Authenticated users belonging to `{organization_id}`.
  * `INSERT`: Authenticated users with role `owner`, `admin`, or `engineer` in `{organization_id}`.

---

## 5. Applying Migrations

Migrations are stored in version-controlled SQL files:
1. `supabase/migrations/20261015000001_create_agv_nexus_schema.sql`
2. `supabase/migrations/20261015000002_enable_rls_and_policies.sql`

To apply locally or against a Supabase CLI project:
```bash
supabase db reset
# or
supabase migration up
```

To seed initial test data:
```bash
supabase db query --file supabase/seed.sql
```
