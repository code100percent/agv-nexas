-- AGV Nexus: Seed Data for Testing & Development
-- File: supabase/seed.sql

-- 1. Insert Sample Tenant Organization
INSERT INTO public.organizations (id, name, slug)
VALUES (
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Nexus Gigafactory Alpha',
    'nexus-gigafactory-alpha'
)
ON CONFLICT (id) DO NOTHING;

-- 2. Insert Fleet Robots
INSERT INTO public.robots (id, organization_id, name, robot_code, description, robot_type, max_payload_kg, last_seen_at)
VALUES
    (
        'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b01',
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'Titan-01',
        'AGV-01',
        'Heavy-duty differential drive pallet mover with safety LiDAR',
        'differential_drive',
        15.0,
        timezone('utc', now())
    ),
    (
        'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b02',
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'Atlas-02',
        'AGV-02',
        'High-speed line supply AMR with optical dock guidance',
        'differential_drive',
        15.0,
        timezone('utc', now())
    ),
    (
        'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b04',
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'Hermes-04',
        'AGV-04',
        'Precision parts delivery AGV with top roller deck',
        'differential_drive',
        10.0,
        timezone('utc', now())
    )
ON CONFLICT (id) DO NOTHING;

-- 3. Insert Factory Map Metadata
INSERT INTO public.factory_maps (id, organization_id, name, robot_id, storage_path, map_format, resolution, origin, width, height, frame_id)
VALUES (
    'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380c01',
    'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
    'Gigafactory Floor 1 (Zone Alpha)',
    'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b01',
    'factory-maps/a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11/floor1_zone_alpha.yaml',
    'occupancy_grid',
    0.05,
    '{"x": 0.0, "y": 0.0, "yaw": 0.0}'::jsonb,
    400,
    300,
    'map'
)
ON CONFLICT (id) DO NOTHING;

-- 4. Insert Operational Stations
INSERT INTO public.stations (id, organization_id, map_id, name, station_type, x, y, yaw)
VALUES
    (
        'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380d01',
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380c01',
        'Warehouse Bay A',
        'pickup',
        2.5,
        3.0,
        0.0
    ),
    (
        'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380d02',
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380c01',
        'Assembly Line 4',
        'dropoff',
        14.2,
        8.5,
        1.57
    ),
    (
        'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380d03',
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380c01',
        'Charging Dock 01',
        'charging',
        1.2,
        1.0,
        3.14
    ),
    (
        'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380d04',
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'c0eebc99-9c0b-4ef8-bb6d-6bb9bd380c01',
        'Quality Inspection 2',
        'staging',
        8.0,
        12.0,
        0.78
    )
ON CONFLICT (id) DO NOTHING;

-- 5. Insert Sample Transport Missions
INSERT INTO public.missions (id, organization_id, robot_id, pickup_station_id, dropoff_station_id, status, priority, started_at)
VALUES
    (
        'e0eebc99-9c0b-4ef8-bb6d-6bb9bd380e01',
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b01',
        'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380d01',
        'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380d02',
        'in_progress',
        2,
        timezone('utc', now()) - interval '10 minutes'
    ),
    (
        'e0eebc99-9c0b-4ef8-bb6d-6bb9bd380e02',
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b02',
        'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380d01',
        'd0eebc99-9c0b-4ef8-bb6d-6bb9bd380d04',
        'queued',
        3,
        NULL
    )
ON CONFLICT (id) DO NOTHING;

-- 6. Insert Sample Robot Alerts
INSERT INTO public.robot_alerts (id, organization_id, robot_id, severity, title, description)
VALUES
    (
        'f0eebc99-9c0b-4ef8-bb6d-6bb9bd380f01',
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11',
        'b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b04',
        'warning',
        'LiDAR Reflectance Anomaly',
        'Forward SICK/Hokuyo laser scanner lens obstruction detected during transit corridor sweep.'
    )
ON CONFLICT (id) DO NOTHING;
