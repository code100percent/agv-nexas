import sys
import os
from typing import Generator
import pytest
from fastapi.testclient import TestClient

# Ensure backend root is in sys.path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app.main import app
from app.config import settings
from app.adapters import SimulatedRobotAdapter, set_robot_adapter


@pytest.fixture(autouse=True)
def setup_test_adapter():
    """Ensure each test runs with a fresh SimulatedRobotAdapter."""
    settings.REQUIRE_AUTH = False
    adapter = SimulatedRobotAdapter()
    set_robot_adapter(adapter)
    yield adapter


@pytest.fixture
def client() -> Generator[TestClient, None, None]:
    with TestClient(app) as test_client:
        yield test_client
