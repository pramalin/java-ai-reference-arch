FROM eclipse-temurin:26-jdk AS build

WORKDIR /workspace

COPY application/.mvn .mvn
COPY application/mvnw mvnw
COPY tools/model-validator/pom.xml pom.xml
COPY tools/model-validator/src src

RUN chmod +x mvnw \
    && ./mvnw package -DskipTests \
    && find target -maxdepth 1 -type f -name "*.jar" -print \
    && cp "$(find target -maxdepth 1 -type f -name '*.jar' \
         ! -name '*.original' | head -1)" /workspace/application.jar

FROM eclipse-temurin:26-jre

WORKDIR /app

COPY --from=build /workspace/application.jar application.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "application.jar"]