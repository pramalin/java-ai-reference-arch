# Java AI Reference Architecture

A reproducible local environment for building and testing enterprise AI applications in Java using **Spring Boot**, **Spring AI**, **Model Context Protocol (MCP)**, PostgreSQL, and Angular.

The first application in this repository accepts natural-language business questions, invokes database tools through MCP, queries the Chinook sample database, and returns an answer through a REST API.

## Working Configurations

The natural-language question application has been run successfully with the following combinations:

| Environment | Model provider | Compose files | Status |
|---|---|---|---|
| Dell Latitude 5400 Chromebook Linux environment | OpenAI | `compose.yaml` + `compose.openai.yaml` | Working |
| Dell Inspiron 15 7000 Gaming laptop | Docker Model Runner with a local LLM | `compose.yaml` + `compose.model-runner.yaml` | Working |

Local-model behavior depends on the selected model, available hardware, and compatibility with the OpenAI-compatible API used by Spring AI.

## Architecture

```text
+-----------------------------+
| Angular Engineering Console |
| http://localhost:4200       |
+--------------+--------------+
               |
               | REST/JSON
               v
+--------------+--------------+
| Spring Boot REST API        |
| Spring AI ChatClient        |
| http://localhost:8080       |
+--------------+--------------+
               |
               | Model Context Protocol
               v
+--------------+--------------+
| Docker MCP Gateway          |
| Database tool exposure      |
+--------------+--------------+
               |
               | list_tables
               | describe_table
               | execute_sql
               v
+--------------+--------------+
| PostgreSQL                  |
| Chinook sample data         |
+-----------------------------+
```

## Repository Structure

```text
java-ai-reference-arch/
├── application/                 Spring Boot and Spring AI application
├── console/                     Angular engineering console
├── database/                    Chinook database and importer
├── docs/                        Supporting documentation
├── tools/
│   └── model-validator/         Local model compatibility utility
├── compose.yaml                 Provider-independent application stack
├── compose.openai.yaml          OpenAI configuration
├── compose.model-runner.yaml    Docker Model Runner configuration
├── mcp-config.yaml              MCP database-server configuration
└── README.md
```

## Prerequisites

### Required

- Docker Engine
- Docker Compose
- Git
- Internet access for the initial image and dependency downloads

The application, database, importer, MCP gateway, and Angular console run in containers. JDK, Maven, Node.js, and Angular CLI are not required merely to run the project.

### Optional development tools

- JDK 26
- Maven or the included Maven wrapper
- Node.js
- Angular CLI
- DBeaver or another PostgreSQL client
- `curl`

## Run with OpenAI

Create a `.env` file in the repository root:

```text
OPENAI_API_KEY=sk-proj-...
```

Do not commit this file.

Start the environment:

```bash
docker compose \
  -f compose.yaml \
  -f compose.openai.yaml \
  up --build
```

Stop it:

```bash
docker compose \
  -f compose.yaml \
  -f compose.openai.yaml \
  down
```

This combination is verified in the Linux development environment of a Dell Latitude 5400 Chromebook.

## Run with Docker Model Runner

Verify Docker Model Runner:

```bash
docker model status
docker model list
```

Start the environment:

```bash
docker compose \
  -f compose.yaml \
  -f compose.model-runner.yaml \
  up --build
```

Stop it:

```bash
docker compose \
  -f compose.yaml \
  -f compose.model-runner.yaml \
  down
```

This combination is verified on a Dell Inspiron 15 7000 Gaming laptop using a local model.

For Docker Model Runner details and model-selection notes, see [`docs/model-runner.md`](docs/model-runner.md).

## Application Endpoints

```text
Angular console:       http://localhost:4200 (unmodified scaffold)
Spring Boot API:       http://localhost:8080
Application health:    http://localhost:8080/actuator/health
Application readiness: http://localhost:8080/actuator/health/readiness
PostgreSQL:             localhost:5432
```

## Verify the Backend

Application information:

```bash
curl http://localhost:8080/api/info
```

Health:

```bash
curl http://localhost:8080/actuator/health
```

## Ask Natural-Language Questions

The API accepts requests through:

```text
POST /api/questions
```

### Which sales agent made the most in sales in 2010?

```bash
curl -X POST http://localhost:8080/api/questions \
  -H 'Content-Type: application/json' \
  -d '{
    "question": "Which sales agent made the most in sales in 2010?"
  }'
```

### How many employees are in the system?

```bash
curl -X POST http://localhost:8080/api/questions \
  -H 'Content-Type: application/json' \
  -d '{
    "question": "How many employees are in the system?"
  }'
```

### How many employees have manager in their title?

```bash
curl -X POST http://localhost:8080/api/questions \
  -H 'Content-Type: application/json' \
  -d '{
    "question": "How many employees have manager in their title?"
  }'
```

Because the model interprets the question and determines how to query the database, answers may vary across models and runs. Questions should state the intended business meaning as clearly as possible.

## Sample Data

The project uses the Chinook sample database, which models a digital media store with employees, customers, artists, albums, tracks, playlists, invoices, and invoice lines.

The bundled SQLite database is imported into PostgreSQL automatically. See [`docs/sample-data.md`](docs/sample-data.md) for provenance, licensing, schema details, row counts, and validation queries.

## Current Scope

Working today:

- Containerized PostgreSQL environment
- Automatic Chinook data import
- MCP database tools
- Spring Boot REST API
- Spring AI integration
- OpenAI configuration
- Docker Model Runner configuration
- Natural-language database questions
- Docker health checks and startup ordering

Still under development:

- Angular query and trace interface
- Generated SQL and tool-trace visualization
- Repeated-run consistency checks
- Answer validation
- Broader local-model compatibility testing
- Additional agents and reference applications

## Documentation

- [`docs/model-runner.md`](docs/model-runner.md)
- [`docs/sample-data.md`](docs/sample-data.md)
- [`tools/model-validator/README.md`](tools/model-validator/README.md)

## Project Status

This repository is a development and architectural reference, not a production-ready system. Its purpose is to provide a practical environment for exploring how enterprise AI workflows can be made observable, testable, and easier to validate.
