# ==============================================================================
# AGV Nexus Robotics Gateway & 3D Digital Twin Container
# Multi-stage security-hardened container for FastAPI + Three.js WebGL
# ==============================================================================

FROM python:3.13-slim AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY backend/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Final minimal runtime image
FROM python:3.13-slim AS runtime

# Security: Create unprivileged application user
RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup -s /sbin/nologin -d /app appuser

WORKDIR /app

# Copy installed Python packages from builder
COPY --from=builder /install /usr/local

# Copy application source code
COPY backend/app ./app
COPY backend/pyproject.toml* ./

# Copy 3D Digital Twin Three.js viewer static assets
COPY viewer /viewer

# Set ownership to unprivileged user
RUN chown -R appuser:appgroup /app /viewer

USER appuser

# Environment parameters
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    API_HOST=0.0.0.0 \
    API_PORT=8000 \
    APP_ENV=production

EXPOSE 8000

# Container liveness health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health/live')" || exit 1

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "2"]
