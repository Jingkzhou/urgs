FROM python:3.10-slim

WORKDIR /app

# Install Java 21 and system dependencies for OpenCV
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-21-jre-headless \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64

COPY requirements.txt .
RUN pip install -i https://pypi.tuna.tsinghua.edu.cn/simple --no-cache-dir -r requirements.txt

COPY . .

# Expose port (default 8001)
EXPOSE 8001

# Command to run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001"]
