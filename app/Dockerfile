# Multi-stage build: compile & test with Maven JDK 11, run on a slim JRE.
FROM maven:3.8-jdk-11 AS build
WORKDIR /workspace

COPY pom.xml .
COPY src ./src

RUN mvn -B -DskipTests=false test package

FROM eclipse-temurin:11-jre
WORKDIR /app

COPY --from=build /workspace/target/sample-java-app-*.jar /app/app.jar

EXPOSE 8080

ENV APP_COLOR=blue

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
