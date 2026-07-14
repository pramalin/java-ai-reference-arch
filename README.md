# Java AI Reference Architecture

A minimal reference application demonstrating how to build an enterprise
AI application using **Spring AI**, **Model Context Protocol (MCP)**,
PostgreSQL, and Angular.

## Purpose

This project provides a clean baseline for enterprise AI applications
that use natural language to interact with enterprise data. It
intentionally focuses on simplicity so it can be used as a starting
point for experimentation, learning, and extension.

## Architecture

``` text
Angular UI
     │
     ▼
Spring AI Application
     │
     ▼
MCP Gateway
     │
     ▼
PostgreSQL (Chinook Sample Database)
```

## Repository Layout

``` text
application/              Spring AI backend
console/                  Angular frontend
database/                 Sample database importer
docs/                     Additional documentation
tools/
  model-validator/        Spring AI tool-calling validator

compose.yaml
compose.openai.yaml
compose.model-runner.yaml
```

## Prerequisites

-   Java 26
-   Docker Engine
-   Docker Compose

## Run with OpenAI

``` bash
export OPENAI_API_KEY=<your-api-key>

docker compose \
  -f compose.yaml \
  -f compose.openai.yaml \
  up --build
```

## Run with Docker Model Runner

``` bash
docker compose \
  -f compose.yaml \
  -f compose.model-runner.yaml \
  up --build
```

Before using a local model, validate that it supports Spring AI tool
calling using the Model Validator.

## Verify the Backend

Application information:

``` bash
curl http://localhost:8080/api/info
```

Health:

``` bash
curl http://localhost:8080/actuator/health
```

Ask a question:

``` bash
curl -X POST http://localhost:8080/api/questions \
  -H "Content-Type: application/json" \
  -d '{
        "question":"Which sales agent made the most in sales in 2010?"
      }'
```

## Open the UI

http://localhost:4200

## Additional Documentation

-   docs/model-runner.md
-   docs/sample-data.md
-   docs/architecture.md
-   docs/development.md
-   tools/model-validator/README.md
