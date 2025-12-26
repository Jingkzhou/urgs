FROM python:3.10-slim-bullseye

WORKDIR /app

# Install Java 11 (Standard in Bullseye) to avoid clone3/EPERM issues in restricted envs
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-11-jre-headless \
    libjaxb-java \
    libjaxb-api-java \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME (Multi-arch support)
RUN ln -s /usr/lib/jvm/java-11-openjdk-$(dpkg --print-architecture) /usr/lib/jvm/default-java
ENV JAVA_HOME=/usr/lib/jvm/default-java

COPY requirements.txt .
RUN pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --no-cache-dir -r requirements.txt

COPY . .

# Add current directory to PYTHONPATH
ENV PYTHONPATH=/app

# Fix OpenBLAS issue in restricted Docker environments
ENV OPENBLAS_NUM_THREADS=1
ENV GOTO_NUM_THREADS=1
ENV OMP_NUM_THREADS=1

# This container seems to be a CLI tool, but for composition we might want it to stay alive or run a specific command.
# For now, we set the entrypoint so arguments can be passed.
# Or if it's meant to be a service, we'd need a server wrapper.
# Based on analysis, it is a CLI tool. We'll keep the entrypoint as bash or the CLI runner.
ENTRYPOINT ["/bin/bash", "./run.sh"]
