-- AGV Nexus: Phase 2 Row Level Security (RLS) & Multi-Tenant Authorization
-- Migration: 20261015000002_enable_rls_and_policies.sql
-- Description: Enables RLS on all 11 application tables and sets up membership-based
--              least-privilege access policies and secure storage access controls.

-- ============================================================================
-- 1. SECURITY DEFINER HELPER FUNCTIONS (Safe Search Path & Non-Recursive)
-- ============================================================================

-- Check if current authenticated user is a verified member of the organization
CREATE OR REPLACE FUNCTION public.is_org_member(lookup_org_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.organization_members
        WHERE organization_id = lookup_org_id
          AND user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Fetch the organization role for current authenticated user
CREATE OR REPLACE FUNCTION public.get_org_role(lookup_org_id UUID)
RETURNS TEXT AS $$
DECLARE
    user_role TEXT;
BEGIN
    SELECT role INTO user_role
    FROM public.organization_members
    WHERE organization_id = lookup_org_id
      AND user_id = auth.uid();
    RETURN user_role;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Check if current authenticated user holds administrative rights (owner or admin)
CREATE OR REPLACE FUNCTION public.is_org_admin(lookup_org_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.organization_members
        WHERE organization_id = lookup_org_id
          AND user_id = auth.uid()
          AND role IN ('owner', 'admin')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Check if current user holds operational capabilities (owner, admin, engineer, operator)
CREATE OR REPLACE FUNCTION public.is_org_operator_or_higher(lookup_org_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM public.organization_members
        WHERE organization_id = lookup_org_id
          AND user_id = auth.uid()
          AND role IN ('owner', 'admin', 'engineer', 'operator')
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- 2. ENABLE ROW LEVEL SECURITY ON ALL TABLES
-- ============================================================================

ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.robots ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.factory_maps ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.stations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mission_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.robot_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.robot_telemetry ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 3. RLS POLICIES PER TABLE
-- ============================================================================

-- --- A. ORGANIZATIONS ---
DROP POLICY IF EXISTS "Members can view their own organizations" ON public.organizations;
CREATE POLICY "Members can view their own organizations"
    ON public.organizations FOR SELECT
    USING (public.is_org_member(id));

DROP POLICY IF EXISTS "Authenticated users can create an organization" ON public.organizations;
CREATE POLICY "Authenticated users can create an organization"
    ON public.organizations FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Admins can update their organization" ON public.organizations;
CREATE POLICY "Admins can update their organization"
    ON public.organizations FOR UPDATE
    USING (public.is_org_admin(id))
    WITH CHECK (public.is_org_admin(id));

-- --- B. PROFILES ---
DROP POLICY IF EXISTS "Profiles are readable by authenticated users" ON public.profiles;
CREATE POLICY "Profiles are readable by authenticated users"
    ON public.profiles FOR SELECT
    USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- --- C. ORGANIZATION MEMBERS ---
DROP POLICY IF EXISTS "Members can view fellow organization members" ON public.organization_members;
CREATE POLICY "Members can view fellow organization members"
    ON public.organization_members FOR SELECT
    USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "Admins can add new members" ON public.organization_members;
CREATE POLICY "Admins can add new members"
    ON public.organization_members FOR INSERT
    WITH CHECK (
        public.is_org_admin(organization_id)
        -- Self-invitation creation allowed if user is first member (owner)
        OR (auth.uid() = user_id AND role = 'owner')
    );

DROP POLICY IF EXISTS "Admins can update member roles" ON public.organization_members;
CREATE POLICY "Admins can update member roles"
    ON public.organization_members FOR UPDATE
    USING (public.is_org_admin(organization_id) AND user_id <> auth.uid())
    WITH CHECK (public.is_org_admin(organization_id) AND user_id <> auth.uid());

DROP POLICY IF EXISTS "Admins can remove members" ON public.organization_members;
CREATE POLICY "Admins can remove members"
    ON public.organization_members FOR DELETE
    USING (public.is_org_admin(organization_id) AND user_id <> auth.uid());

-- --- D. ROBOTS ---
DROP POLICY IF EXISTS "Members can view organization robots" ON public.robots;
CREATE POLICY "Members can view organization robots"
    ON public.robots FOR SELECT
    USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "Engineers and Admins can register robots" ON public.robots;
CREATE POLICY "Engineers and Admins can register robots"
    ON public.robots FOR INSERT
    WITH CHECK (
        public.is_org_member(organization_id)
        AND public.get_org_role(organization_id) IN ('owner', 'admin', 'engineer')
    );

DROP POLICY IF EXISTS "Engineers and Admins can update robots" ON public.robots;
CREATE POLICY "Engineers and Admins can update robots"
    ON public.robots FOR UPDATE
    USING (
        public.is_org_member(organization_id)
        AND public.get_org_role(organization_id) IN ('owner', 'admin', 'engineer')
    );

DROP POLICY IF EXISTS "Admins can delete robots" ON public.robots;
CREATE POLICY "Admins can delete robots"
    ON public.robots FOR DELETE
    USING (public.is_org_admin(organization_id));

-- --- E. FACTORY MAPS ---
DROP POLICY IF EXISTS "Members can view organization maps" ON public.factory_maps;
CREATE POLICY "Members can view organization maps"
    ON public.factory_maps FOR SELECT
    USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "Engineers and Admins can create maps" ON public.factory_maps;
CREATE POLICY "Engineers and Admins can create maps"
    ON public.factory_maps FOR INSERT
    WITH CHECK (
        public.is_org_member(organization_id)
        AND public.get_org_role(organization_id) IN ('owner', 'admin', 'engineer')
    );

DROP POLICY IF EXISTS "Engineers and Admins can update maps" ON public.factory_maps;
CREATE POLICY "Engineers and Admins can update maps"
    ON public.factory_maps FOR UPDATE
    USING (
        public.is_org_member(organization_id)
        AND public.get_org_role(organization_id) IN ('owner', 'admin', 'engineer')
    );

DROP POLICY IF EXISTS "Admins can delete maps" ON public.factory_maps;
CREATE POLICY "Admins can delete maps"
    ON public.factory_maps FOR DELETE
    USING (public.is_org_admin(organization_id));

-- --- F. STATIONS ---
DROP POLICY IF EXISTS "Members can view organization stations" ON public.stations;
CREATE POLICY "Members can view organization stations"
    ON public.stations FOR SELECT
    USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "Engineers and Admins can create stations" ON public.stations;
CREATE POLICY "Engineers and Admins can create stations"
    ON public.stations FOR INSERT
    WITH CHECK (
        public.is_org_member(organization_id)
        AND public.get_org_role(organization_id) IN ('owner', 'admin', 'engineer')
    );

DROP POLICY IF EXISTS "Engineers and Admins can update stations" ON public.stations;
CREATE POLICY "Engineers and Admins can update stations"
    ON public.stations FOR UPDATE
    USING (
        public.is_org_member(organization_id)
        AND public.get_org_role(organization_id) IN ('owner', 'admin', 'engineer')
    );

DROP POLICY IF EXISTS "Admins can delete stations" ON public.stations;
CREATE POLICY "Admins can delete stations"
    ON public.stations FOR DELETE
    USING (public.is_org_admin(organization_id));

-- --- G. MISSIONS ---
DROP POLICY IF EXISTS "Members can view organization missions" ON public.missions;
CREATE POLICY "Members can view organization missions"
    ON public.missions FOR SELECT
    USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "Operators and higher can request missions" ON public.missions;
CREATE POLICY "Operators and higher can request missions"
    ON public.missions FOR INSERT
    WITH CHECK (
        public.is_org_operator_or_higher(organization_id)
        AND status = 'queued'
    );

DROP POLICY IF EXISTS "Authorized members can update missions" ON public.missions;
CREATE POLICY "Authorized members can update missions"
    ON public.missions FOR UPDATE
    USING (public.is_org_operator_or_higher(organization_id));

DROP POLICY IF EXISTS "Admins can delete missions" ON public.missions;
CREATE POLICY "Admins can delete missions"
    ON public.missions FOR DELETE
    USING (public.is_org_admin(organization_id));

-- --- H. MISSION EVENTS ---
DROP POLICY IF EXISTS "Members can view mission events" ON public.mission_events;
CREATE POLICY "Members can view mission events"
    ON public.mission_events FOR SELECT
    USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "Operational members can append mission events" ON public.mission_events;
CREATE POLICY "Operational members can append mission events"
    ON public.mission_events FOR INSERT
    WITH CHECK (public.is_org_operator_or_higher(organization_id));

-- Note: No UPDATE or DELETE policy on mission_events ensures immutability.

-- --- I. ROBOT ALERTS ---
DROP POLICY IF EXISTS "Members can view robot alerts" ON public.robot_alerts;
CREATE POLICY "Members can view robot alerts"
    ON public.robot_alerts FOR SELECT
    USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "System and members can insert alerts" ON public.robot_alerts;
CREATE POLICY "System and members can insert alerts"
    ON public.robot_alerts FOR INSERT
    WITH CHECK (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "Operators and higher can acknowledge alerts" ON public.robot_alerts;
CREATE POLICY "Operators and higher can acknowledge alerts"
    ON public.robot_alerts FOR UPDATE
    USING (public.is_org_operator_or_higher(organization_id));

-- --- J. ROBOT TELEMETRY ---
DROP POLICY IF EXISTS "Members can view robot telemetry" ON public.robot_telemetry;
CREATE POLICY "Members can view robot telemetry"
    ON public.robot_telemetry FOR SELECT
    USING (public.is_org_member(organization_id));

DROP POLICY IF EXISTS "Members can record telemetry samples" ON public.robot_telemetry;
CREATE POLICY "Members can record telemetry samples"
    ON public.robot_telemetry FOR INSERT
    WITH CHECK (public.is_org_member(organization_id));

-- --- K. AUDIT LOGS ---
DROP POLICY IF EXISTS "Admins can view audit logs" ON public.audit_logs;
CREATE POLICY "Admins can view audit logs"
    ON public.audit_logs FOR SELECT
    USING (public.is_org_admin(organization_id));

DROP POLICY IF EXISTS "Members can record audit log events" ON public.audit_logs;
CREATE POLICY "Members can record audit log events"
    ON public.audit_logs FOR INSERT
    WITH CHECK (public.is_org_member(organization_id));

-- Note: No UPDATE or DELETE policy on audit_logs ensures an append-only audit trail.

-- ============================================================================
-- 4. SUPABASE STORAGE BUCKET & STORAGE RLS POLICIES
-- ============================================================================

-- Create private bucket for factory maps if not existing
INSERT INTO storage.buckets (id, name, public)
VALUES ('factory-maps', 'factory-maps', false)
ON CONFLICT (id) DO NOTHING;

-- Map files are stored in organization-keyed folders: factory-maps/{organization_id}/*
DROP POLICY IF EXISTS "Org members can read factory map assets" ON storage.objects;
CREATE POLICY "Org members can read factory map assets"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (
        bucket_id = 'factory-maps'
        AND public.is_org_member((storage.foldername(name))[1]::uuid)
    );

DROP POLICY IF EXISTS "Engineers and Admins can upload factory map assets" ON storage.objects;
CREATE POLICY "Engineers and Admins can upload factory map assets"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
        bucket_id = 'factory-maps'
        AND public.is_org_member((storage.foldername(name))[1]::uuid)
        AND public.get_org_role((storage.foldername(name))[1]::uuid) IN ('owner', 'admin', 'engineer')
    );
