from typing import List
from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Production-grade environment configuration for AGV Nexus Robotics Gateway."""

    model_config = SettingsConfigDict(
        env_file=(".env", "../.env"),
        env_file_encoding="utf-8",
        extra="ignore",
    )

    APP_NAME: str = "AGV Nexus Robotics Gateway"
    APP_VERSION: str = "1.0.0-phase6"
    APP_ENV: str = Field(default="development", description="Runtime environment")
    API_PREFIX: str = "/api/v1"
    API_HOST: str = "0.0.0.0"
    API_PORT: int = 8000

    # CORS configuration
    CORS_ALLOWED_ORIGINS: List[str] = [
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8000",
        "http://localhost:8080",
        "http://127.0.0.1",
        "http://127.0.0.1:8000",
        "http://127.0.0.1:8080",
    ]

    # Supabase Integration
    SUPABASE_URL: str = "https://bphxvupyupfbzmdrcnqs.supabase.co"
    SUPABASE_ANON_KEY: str = "sb_publishable_V4W0iPAjRfqQe4pJygifnw_pXPGNk0b"
    SUPABASE_SERVICE_ROLE_KEY: str = ""
    SUPABASE_JWT_SECRET: str = ""
    REQUIRE_AUTH: bool = False  # Set to True in production; allows dev token bypass for local tests

    # Robot Adapter Configuration
    ROBOT_ADAPTER_MODE: str = Field(
        default="simulated",
        description="One of: 'simulated', 'ros2', 'disconnected'",
    )
    ROS_DOMAIN_ID: int = 0
    ROS_NAMESPACE: str = ""

    # Telemetry and Heartbeat timing
    TELEMETRY_STALE_AFTER_SECONDS: float = 5.0
    WEBSOCKET_HEARTBEAT_INTERVAL_SECONDS: float = 10.0
    TELEMETRY_BROADCAST_HZ: float = 10.0
    MAX_MAP_PAYLOAD_BYTES: int = 10 * 1024 * 1024  # 10MB limit

    # Default Identifiers (matching Supabase seed)
    DEFAULT_ORG_ID: str = "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"
    DEFAULT_ROBOT_ID: str = "b0eebc99-9c0b-4ef8-bb6d-6bb9bd380b01"
    DEFAULT_MAP_ID: str = "c0eebc99-9c0b-4ef8-bb6d-6bb9bd380c01"


settings = Settings()
