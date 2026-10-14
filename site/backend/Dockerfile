# ---- Build stage: compile the Spring Boot jar ----
FROM maven:3.9.9-eclipse-temurin-21 AS build
WORKDIR /app

# Download dependencies first so they are cached between builds
COPY pom.xml .
RUN mvn -q -B dependency:go-offline

COPY src ./src
RUN mvn -q -B -DskipTests package

# ---- Run stage: slim Java 21 runtime only ----
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

# Run as a non-root user
RUN useradd --system --create-home spring
USER spring

COPY --from=build /app/target/backend-0.0.1-SNAPSHOT.jar app.jar

# Render's free instance has 512 MB RAM: cap the heap so the JVM fits.
# Render injects PORT; application.properties reads it (server.port=${PORT:8080}).
ENV SPRING_PROFILES_ACTIVE=prod
ENV JAVA_OPTS="-XX:MaxRAMPercentage=70 -XX:+UseSerialGC -Xss512k -XX:TieredStopAtLevel=1"
EXPOSE 8080

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
