FROM ghcr.io/pramalin/llmsim-build:0.3.0 AS build

COPY src/main/scala/com/example/langgraph/llmsim/LangGraphEmployeeCountFlow.scala \
  /build/src/main/scala/com/example/langgraph/llmsim/LangGraphEmployeeCountFlow.scala

RUN sbt assembly

FROM eclipse-temurin:21-jre-jammy

COPY --from=build \
  /build/target/scala-3.3.3/llmsim.jar \
  /app/llmsim.jar

ENV LLMSIM_SCRIPT=com.example.langgraph.llmsim.LangGraphEmployeeCountFlow

EXPOSE 8089

ENTRYPOINT ["java", "-jar", "/app/llmsim.jar"]
