# Build from the repository root so sibling folders the app reads are in the context:
#   docker build -f <backend>/Dockerfile -t <app>-backend .
# Adjust the Python version to pyproject's requires-python. Uses uv; for pip replace the
# two uv sync lines with `pip install --no-cache-dir -r requirements.txt`.
FROM python:3.13-slim

COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PROJECT_ENVIRONMENT=/opt/venv \
    PATH=/opt/venv/bin:$PATH

# Mirror the repository layout so code that finds the repo root from __file__ keeps
# working (a flat /app breaks Path(__file__).parents[N]). Adjust depth to match the repo.
WORKDIR /srv/<repo>/<backend>

COPY <backend>/pyproject.toml <backend>/uv.lock ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-install-project

COPY <backend>/ ./
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev

# Folders the app reads at runtime, placed where the code expects them.
# COPY <data-folder> /srv/<repo>/<data-folder>

# 127.0.0.1 because the container runs on host networking behind nginx.
CMD ["uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "8000"]
