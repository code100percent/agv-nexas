import math
from datetime import datetime, timezone
import pytest
from app.schemas.map import MapOrigin, OccupancyGridMap


@pytest.fixture
def test_grid():
    # 10x10 grid with 0.1m resolution (1.0m x 1.0m area), origin at (0.0, 0.0)
    width = 10
    height = 10
    resolution = 0.1
    data = [0] * (width * height)
    return OccupancyGridMap(
        map_id="test-map",
        robot_id="test-robot",
        frame_id="map",
        width=width,
        height=height,
        resolution=resolution,
        origin=MapOrigin(x=0.0, y=0.0, yaw=0.0),
        timestamp=datetime.now(timezone.utc),
        encoding="int8_array",
        data=data,
    )


def test_origin_transformation(test_grid: OccupancyGridMap):
    # World (0.0, 0.0) must map to cell (0, 0)
    col, row = test_grid.world_to_grid(0.0, 0.0)
    assert col == 0
    assert row == 0

    # Cell (0, 0) center must map to world (0.05, 0.05)
    wx, wy = test_grid.grid_to_world(0, 0)
    assert math.isclose(wx, 0.05, abs_tol=1e-5)
    assert math.isclose(wy, 0.05, abs_tol=1e-5)


def test_grid_center_transformation(test_grid: OccupancyGridMap):
    # Center of 1.0m x 1.0m grid is (0.5, 0.5)
    # With resolution 0.1m, this should be col 5, row 5
    col, row = test_grid.world_to_grid(0.55, 0.55)
    assert col == 5
    assert row == 5


def test_grid_corners(test_grid: OccupancyGridMap):
    # Top-right corner (0.95m, 0.95m) -> col 9, row 9
    col, row = test_grid.world_to_grid(0.95, 0.95)
    assert col == 9
    assert row == 9

    # Far corner center back to world
    wx, wy = test_grid.grid_to_world(9, 9)
    assert math.isclose(wx, 0.95, abs_tol=1e-5)
    assert math.isclose(wy, 0.95, abs_tol=1e-5)


def test_rotated_origin_transformation():
    # Grid rotated 90 degrees (pi/2) with origin at (1.0, 1.0)
    grid = OccupancyGridMap(
        map_id="rotated-map",
        robot_id="test-robot",
        frame_id="map",
        width=10,
        height=10,
        resolution=0.1,
        origin=MapOrigin(x=1.0, y=1.0, yaw=math.pi / 2),
        timestamp=datetime.now(timezone.utc),
        encoding="int8_array",
        data=[0] * 100,
    )

    # Origin world (1.0, 1.0) maps to (0, 0)
    col, row = grid.world_to_grid(1.0, 1.0)
    assert col == 0
    assert row == 0


def test_out_of_bounds_positions(test_grid: OccupancyGridMap):
    # Negative coordinates
    col, row = test_grid.world_to_grid(-0.5, -0.5)
    assert col < 0
    assert row < 0

    # Outside upper bounds
    col, row = test_grid.world_to_grid(2.5, 3.0)
    assert col >= test_grid.width
    assert row >= test_grid.height
