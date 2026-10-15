-- AGV Nexus: Phase 2 Database Schema Migration
-- Migration: 20261015000001_create_agv_nexus_schema.sql
-- Description: Core relational schema with multi-tenant organizations, profiles,
--              robots, maps, stations, missions, events, alerts, telemetry, and audit logs.

-- 1. Enable required PostgreSQL extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 2. Organizations Table
-- Represents a factory tenant, logistics facility, or enterprise operating AGV Nexus.
CREATE TABLE IF NOT EXISTS public.organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL CHECK (char_length(trim(name)) >= 2),
    slug TEXT UNIQUE CHECK (slug ~ '^[a-z0-9-]+$'),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 3. Profiles Table
-- Extends Supabase auth.users with operator metadata, linked directly by UUID.
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    display_name TEXT NOT NULL DEFAULT 'Operator',
    avatar_path TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 4. Organization Members Table
-- Maps users to organizations with explicit industrial RBAC roles.
CREATE TABLE IF NOT EXISTS public.organization_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'operator', 'engineer', 'viewer')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    UNIQUE (organization_id, user_id)
);

-- 5. Robots Table
-- Identity, payload limits, and configuration metadata for each physical or simulated AGV.
CREATE TABLE IF NOT EXISTS public.robots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL CHECK (char_length(trim(name)) >= 1),
    robot_code TEXT NOT NULL CHECK (char_length(trim(robot_code)) >= 1),
    description TEXT,
    robot_type TEXT NOT NULL DEFAULT 'differential_drive',
    max_payload_kg NUMERIC NOT NULL DEFAULT 15.0 CHECK (max_payload_kg >= 0.0),
    last_seen_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    UNIQUE (organization_id, robot_code)
);

-- 6. Factory Maps Table
-- Metadata and storage pointers for 2D metric occupancy grids and costmaps.
CREATE TABLE IF NOT EXISTS public.factory_maps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL CHECK (char_length(trim(name)) >= 1),
    robot_id UUID REFERENCES public.robots(id) ON DELETE SET NULL,
    storage_path TEXT,
    map_format TEXT NOT NULL DEFAULT 'occupancy_grid',
    resolution NUMERIC CHECK (resolution IS NULL OR resolution > 0.0),
    origin JSONB DEFAULT '{"x": 0.0, "y": 0.0, "yaw": 0.0}'::jsonb,
    width INTEGER CHECK (width IS NULL OR width >= 0),
    height INTEGER CHECK (height IS NULL OR height >= 0),
    frame_id TEXT NOT NULL DEFAULT 'map',
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 7. Stations Table
-- Fixed physical locations (pickup bays, dropoff lines, docking stations, waypoints).
CREATE TABLE IF NOT EXISTS public.stations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    map_id UUID REFERENCES public.factory_maps(id) ON DELETE CASCADE,
    name TEXT NOT NULL CHECK (char_length(trim(name)) >= 1),
    station_type TEXT NOT NULL CHECK (station_type IN ('pickup', 'dropoff', 'charging', 'staging', 'waypoint')),
    x NUMERIC NOT NULL DEFAULT 0.0,
    y NUMERIC NOT NULL DEFAULT 0.0,
    yaw NUMERIC NOT NULL DEFAULT 0.0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 8. Missions Table
-- Autonomous logistics transport orders and their application lifecycle.
CREATE TABLE IF NOT EXISTS public.missions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    robot_id UUID REFERENCES public.robots(id) ON DELETE SET NULL,
    pickup_station_id UUID REFERENCES public.stations(id) ON DELETE RESTRICT,
    dropoff_station_id UUID REFERENCES public.stations(id) ON DELETE RESTRICT,
    status TEXT NOT NULL DEFAULT 'queued' CHECK (status IN ('queued', 'assigned', 'in_progress', 'completed', 'failed', 'cancelled')),
    priority INTEGER NOT NULL DEFAULT 2 CHECK (priority BETWEEN 1 AND 4),
    requested_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

-- 9. Mission Events Table
-- Granular state machine transition log for dispatch auditability.
CREATE TABLE IF NOT EXISTS public.mission_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    mission_id UUID NOT NULL REFERENCES public.missions(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (char_length(trim(event_type)) >= 1),
    message TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 10. Robot Alerts Table
-- Persistent application and fleet diagnostics alerts.
CREATE TABLE IF NOT EXISTS public.robot_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    robot_id UUID REFERENCES public.robots(id) ON DELETE CASCADE,
    severity TEXT NOT NULL CHECK (severity IN ('critical', 'warning', 'info')),
    title TEXT NOT NULL CHECK (char_length(trim(title)) >= 1),
    description TEXT,
    acknowledged_at TIMESTAMPTZ,
    acknowledged_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 11. Robot Telemetry Table (Sampled Historical Diagnostics)
-- Sampled sensor telemetry logs; does NOT store raw unthrottled LiDAR packets.
CREATE TABLE IF NOT EXISTS public.robot_telemetry (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    robot_id UUID NOT NULL REFERENCES public.robots(id) ON DELETE CASCADE,
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now()),
    source TEXT NOT NULL CHECK (source IN ('simulation', 'robot_gateway')),
    position_x NUMERIC,
    position_y NUMERIC,
    yaw NUMERIC,
    linear_velocity NUMERIC,
    angular_velocity NUMERIC,
    battery_percent NUMERIC CHECK (battery_percent IS NULL OR (battery_percent >= 0.0 AND battery_percent <= 100.0)),
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 12. Audit Logs Table
-- Immutable record of administrative operations and security events.
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    actor_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    action TEXT NOT NULL CHECK (char_length(trim(action)) >= 1),
    resource_type TEXT,
    resource_id UUID,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc', now())
);

-- 13. Performance Indexes
CREATE INDEX IF NOT EXISTS idx_org_members_user_id ON public.organization_members(user_id);
CREATE INDEX IF NOT EXISTS idx_org_members_org_id ON public.organization_members(organization_id);
CREATE INDEX IF NOT EXISTS idx_robots_org_id ON public.robots(organization_id);
CREATE INDEX IF NOT EXISTS idx_factory_maps_org_id ON public.factory_maps(organization_id);
CREATE INDEX IF NOT EXISTS idx_stations_org_map ON public.stations(organization_id, map_id);
CREATE INDEX IF NOT EXISTS idx_missions_org_status ON public.missions(organization_id, status);
CREATE INDEX IF NOT EXISTS idx_missions_robot_id ON public.missions(robot_id);
CREATE INDEX IF NOT EXISTS idx_mission_events_mission ON public.mission_events(mission_id);
CREATE INDEX IF NOT EXISTS idx_robot_alerts_org_sev ON public.robot_alerts(organization_id, severity);
CREATE INDEX IF NOT EXISTS idx_robot_telemetry_robot_time ON public.robot_telemetry(robot_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_org_time ON public.audit_logs(organization_id, created_at DESC);

-- 14. Timestamp Synchronization Trigger Procedure
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc', now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Attach updated_at triggers
DROP TRIGGER IF EXISTS set_org_updated_at ON public.organizations;
CREATE TRIGGER set_org_updated_at BEFORE UPDATE ON public.organizations FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_org_members_updated_at ON public.organization_members;
CREATE TRIGGER set_org_members_updated_at BEFORE UPDATE ON public.organization_members FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_robots_updated_at ON public.robots;
CREATE TRIGGER set_robots_updated_at BEFORE UPDATE ON public.robots FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_factory_maps_updated_at ON public.factory_maps;
CREATE TRIGGER set_factory_maps_updated_at BEFORE UPDATE ON public.factory_maps FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_stations_updated_at ON public.stations;
CREATE TRIGGER set_stations_updated_at BEFORE UPDATE ON public.stations FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_missions_updated_at ON public.missions;
CREATE TRIGGER set_missions_updated_at BEFORE UPDATE ON public.missions FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- 15. Automatic Profile Provisioning on User Signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, display_name, avatar_path)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email, 'Operator'),
        NULL
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
