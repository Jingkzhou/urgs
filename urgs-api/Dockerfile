# Build Stage
FROM maven:3.9-eclipse-temurin-21-alpine AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
# Use Aliyun mirror settings
COPY settings.xml /usr/share/maven/conf/settings.xml
# Skip tests to speed up the build for now
RUN mvn clean package -DskipTests

# Run Stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080

# Install docker-cli to allow calling sibling containers, and bash for java ProcessBuilder
# Use Aliyun mirror for Alpine
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories && \
    apk add --no-cache docker-cli bash

COPY bridge.sh /app/bridge.sh
RUN chmod +x /app/bridge.sh

ENTRYPOINT ["java", "-jar", "app.jar"]
