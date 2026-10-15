import pytest
from httpx import ASGITransport, AsyncClient
from app.main import app


@pytest.mark.asyncio
async def test_viewer_static_mount():
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as client:
        # Request index.html from viewer
        resp = await client.get("/viewer/index.html")
        assert resp.status_code == 200
        assert "AGV Nexus Digital Twin" in resp.text
        assert "twin-canvas" in resp.text

        # Request css
        css_resp = await client.get("/viewer/css/viewer.css")
        assert css_resp.status_code == 200
        assert "--accent-cyan" in css_resp.text

        # Request js modules
        js_resp = await client.get("/viewer/js/config.js")
        assert js_resp.status_code == 200
        assert "DEFAULT_ROBOT_ID" in js_resp.text

        transforms_resp = await client.get("/viewer/js/transforms.js")
        assert transforms_resp.status_code == 200
        assert "ros2ToThreePos" in transforms_resp.text
