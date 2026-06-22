FROM python:3.11.13-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH=/app/.venv/bin:$PATH

WORKDIR /app
RUN pip install --no-cache-dir uv==0.8.17
COPY pyproject.toml uv.lock* README.md ./
RUN uv sync --frozen --no-dev --no-install-project
COPY src ./src
COPY skills ./skills
COPY LICENSE.upstream ./LICENSE.upstream
COPY vendor ./vendor
RUN uv sync --frozen --no-dev

USER 65532:65532
EXPOSE 8003
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8003/health/live', timeout=3).read()" || exit 1
CMD ["uvicorn", "urgs_deepagents_service.main:app", "--host", "0.0.0.0", "--port", "8003"]
