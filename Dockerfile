# STAGE 1: Compile and package
FROM maven:3.9-eclipse-temurin-25 AS build

WORKDIR /app

# Download dependencies first. It will save your time next time you build this
# image, if pom files did not change.
COPY pom.xml .
COPY reactive/pom.xml ./reactive/
COPY thread-pool/pom.xml ./thread-pool/
COPY virtual-thread/pom.xml ./virtual-thread/
RUN mvn dependency:go-offline

COPY . .

ARG APP
RUN if [ "$APP" != "reactive" ] && [ "$APP" != "thread-pool" ] && [ "$APP" != "virtual-thread" ]; then \
    echo "ERROR: APP build argument is required and must be: reactive, thread-pool, or virtual-thread"; \
    exit 1; \
fi

RUN mvn clean package -am -pl $APP && \
    mv $APP/target/*.jar $APP.jar && \
    mvn clean

# STAGE 2: Build the target Docker image
FROM eclipse-temurin:25-jdk

WORKDIR /app

# Copy only the built JAR and usage.sh from the first stage
ARG APP
ARG LOG_DIR="/logs"

ENV APP=$APP LOG_DIR=$LOG_DIR

COPY --from=build /app/$APP.jar /app/usage.sh ./

# Raise file descriptor limits for the Reactive event loop's sockets
RUN echo "* soft nofile 200000" >> /etc/security/limits.conf && \
    echo "* hard nofile 200000" >> /etc/security/limits.conf

EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar $APP.jar"]