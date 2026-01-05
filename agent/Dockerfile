FROM ghcr.io/astral-sh/uv:python3.13-bookworm-slim

WORKDIR /app

# Environment variables
ENV UV_SYSTEM_PYTHON=1 \
    UV_COMPILE_BYTECODE=1 \
    UV_NO_PROGRESS=1 \
    PYTHONUNBUFFERED=1 \
    DOCKER_CONTAINER=1 \
    AWS_REGION=us-east-1 \
    AWS_DEFAULT_REGION=us-east-1

# Install dependencies (separate layer for caching)
COPY requirements.txt .
RUN uv pip install -r requirements.txt && \
    uv pip install aws-opentelemetry-distro>=0.10.1

# Create non-root user
RUN useradd -m -u 1000 bedrock_agentcore

# Copy application code
COPY . .

# Switch to non-root user
USER bedrock_agentcore

# AgentCore HTTP endpoint
EXPOSE 8080

# Health check using the /ping endpoint provided by AgentCore SDK
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/ping', timeout=3)" || exit 1

# Run agent with OpenTelemetry instrumentation
CMD ["opentelemetry-instrument", "python", "-m", "strands_agent"]
