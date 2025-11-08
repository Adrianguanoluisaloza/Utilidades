# Multi-stage build to create a runnable fat JAR and run it on a slim JRE

# 1) Build stage (uses Maven inside a container if you prefer containerized builds)
# You can skip this stage if you build on the host with: mvn -f backends/delivery-api/pom.xml -DskipTests package
FROM eclipse-temurin:21-jre as runtime

WORKDIR /app

# Copy the fat JAR built by maven-assembly-plugin
# Expected artifact: target/delivery-api-*-jar-with-dependencies.jar
ARG JAR_PATH=target/delivery-api-1.0-SNAPSHOT-jar-with-dependencies.jar
COPY ${JAR_PATH} app.jar

# Copy .env file to the container
COPY .env /app/.env

# AWS typically sets PORT. Our app auto-resolves PORT/DEFAULT 7070. Set a sane default.
ENV PORT=7070

# JVM runtime flags can be tuned via JAVA_OPTS environment variable
ENV JAVA_OPTS="-Xms256m -Xmx512m"

# Expose the configured port (informational for many platforms)
EXPOSE 7070

# Health check (optional). Adjust path if needed.
# HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD curl -fsS http://localhost:${PORT}/health || exit 1
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS http://localhost:${PORT}/health || exit 1

ENTRYPOINT ["sh", "-c", "exec java $JAVA_OPTS -jar app.jar"]
