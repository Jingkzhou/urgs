FROM python:3.10-slim

WORKDIR /app

# Install Java 21
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-21-jre-headless \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64

COPY requirements.txt .
RUN pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --no-cache-dir -r requirements.txt

COPY . .

# Add current directory to PYTHONPATH
ENV PYTHONPATH=/app

# This container seems to be a CLI tool, but for composition we might want it to stay alive or run a specific command.
# For now, we set the entrypoint so arguments can be passed.
# Or if it's meant to be a service, we'd need a server wrapper.
# Based on analysis, it is a CLI tool. We'll keep the entrypoint as bash or the CLI runner.
ENTRYPOINT ["/bin/bash", "./run.sh"]
