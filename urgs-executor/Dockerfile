# Build Stage
FROM maven:3.9-eclipse-temurin-21-alpine AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
# Use Aliyun mirror settings
COPY settings.xml /usr/share/maven/conf/settings.xml
RUN mvn clean package -DskipTests

# Run Stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8082
# Check if a different port is defined in properties, but usually distinct services use different internal ports or are mapped differently
ENTRYPOINT ["java", "-jar", "app.jar"]
