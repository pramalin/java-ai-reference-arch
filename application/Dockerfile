FROM eclipse-temurin:26-jdk AS build
WORKDIR /workspace

COPY .mvn .mvn
COPY mvnw pom.xml ./
RUN chmod +x mvnw && ./mvnw dependency:go-offline

COPY src src
RUN ./mvnw clean package -DskipTests

FROM eclipse-temurin:26-jre
WORKDIR /application

COPY --from=build /workspace/target/*.jar application.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "application.jar"]
