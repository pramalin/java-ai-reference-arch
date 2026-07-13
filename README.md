# Java AI Reference Architecture

A reference implementation for building enterprise AI applications with Spring Boot, Spring AI, Angular, PostgreSQL, Docker Compose, and the Model Context Protocol (MCP).

The project goes beyond a standalone prompt or chatbot demonstration. It assembles the database, sample business data, MCP tools, AI-enabled Java service, REST API, health checks, and engineering console into a reproducible local environment. Its purpose is to help development teams explore how AI workflows can become more deterministic, observable, testable, and suitable for enterprise use.

## One-command local environment

```bash
docker compose \
  -f compose.yaml \
  -f compose.openai.yaml \
  up --build
```

This command starts the complete environment:

- PostgreSQL
- Chinook business data importer
- Docker MCP Gateway
- Spring Boot and Spring AI application
- Angular engineering console

## Current maturity

| Capability | Status |
|---|---|
| Containerized local environment | ✅ Working |
| Chinook data import into PostgreSQL | ✅ Working |
| Spring AI and OpenAI integration | ✅ Working |
| Natural-language questions against the database | ✅ Working |
| MCP database tool invocation | ✅ Working |
| Angular engineering console | 🚧 Baseline available |
| Generated SQL and tool trace visualization | 🚧 In progress |
| Repeated-run consistency testing | 🔭 Future exploration |
| Multi-agent validation and orchestration | 🔭 Future exploration |

## Project purpose

Many AI examples demonstrate an isolated prompt or a console-based agent. This project instead provides a reproducible baseline for developing and validating AI-powered enterprise applications.

The current implementation accepts a natural-language business question, allows Spring AI to select and invoke database tools through MCP, dynamically queries the Chinook database, and returns a natural-language answer.

The longer-term goal is to explore how enterprise teams can make AI workflows more deterministic, observable, testable, and suitable for production use.

The Angular application under `console/` is intended to become an engineering and validation console rather than an end-user chatbot. It will be used to inspect generated SQL, tool invocations, raw database results, final answers, repeated-run consistency, and validation results.

## Inspiration

This project is modeled after the LangGraph natural-language-to-SQL example in Docker's Compose for Agents repository:

https://github.com/docker/compose-for-agents/tree/main/langgraph

The original example demonstrates how an LLM can interpret a question, inspect a local database, generate SQL dynamically, execute the query, and formulate an answer.

This project adapts that workflow to a Java enterprise application using Spring Boot and Spring AI and exposes it through a REST API.

## Current capabilities

The project currently provides:

* A PostgreSQL database running in Docker
* Automatic import of the Chinook SQLite database into PostgreSQL
* An MCP gateway exposing database tools
* A Spring Boot and Spring AI application
* OpenAI model integration
* A REST endpoint for asking natural-language questions
* An Angular console running in Docker
* Health checks and startup dependency management
* Access to PostgreSQL from tools such as DBeaver

The console UI is currently a generated Angular baseline. Development of the AI validation and observability features is in progress.

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
| Chinook business data       |
+-----------------------------+
```

The main database tools currently exposed through MCP are:

* `list_tables`
* `describe_table`
* `execute_sql`

## Repository structure

```text
java-ai-reference-arch/
├── application/          Spring Boot and Spring AI application
├── console/              Angular engineering console
├── database/             Chinook database and importer image
├── docs/                 Architecture and development documentation
├── compose.yaml          Base infrastructure and application services
├── compose.openai.yaml   OpenAI-specific application configuration
├── mcp-config.yaml       MCP database-server configuration
└── README.md
```

## Sample business data

The application uses the Chinook sample database, which models a digital media store with employees, customers, artists, albums, tracks, playlists, invoices, and invoice lines.

The bundled SQLite database is imported into PostgreSQL automatically when the Compose environment starts. Detailed provenance, licensing, row counts, relationships, schema notes, and validation queries are documented in [`docs/sample-data.md`](docs/sample-data.md).

## Minimal requirements

### Required to run the complete environment

* A machine capable of running Docker
* Docker Engine with Docker Compose support
* Git
* An OpenAI API key
* Internet access during the initial image and dependency download

Because the application, database, importer, MCP gateway, and Angular console run inside containers, JDK, Maven, Node.js, and Angular CLI are not required merely to run the project.

### Optional development tools

These tools are useful when modifying or debugging individual components:

* JDK 26
* Maven, or the included Maven wrapper
* Node.js
* Angular CLI 22
* Visual Studio Code or another IDE
* DBeaver or another PostgreSQL client
* `curl`
* Git

## Tested hardware

The project has been developed and run successfully in the Linux environment of an inexpensive Dell Latitude 5400 Chromebook.
```text
Device: Dell Latitude 5400 Chromebook
Operating environment: ChromeOS Linux development environment
Processor: Intel(R) Core(TM) i5-8365U CPU @ 1.60GHz (8 threads, 4.100GHz)
Memory: 16GB
Storage: 150GB SSD
```

This project does not run a local LLM. The model inference is performed through the OpenAI API, which keeps the local hardware requirements relatively modest.

## Configure the OpenAI API key

Create a file named `.env` in the repository root:

```text
OPENAI_API_KEY=sk-proj-...
```

The `.env` file must not be committed. Confirm that `.gitignore` contains:

```text
.env
```

A safe `.env.example` may be committed with an empty value:

```text
OPENAI_API_KEY=
```

## Start the application

Clone the repository and move into it:

```bash
git clone https://github.com/pramalin/java-ai-reference-arch.git
cd java-ai-reference-arch
```

Create the `.env` file containing the OpenAI API key.

Start the complete environment:

```bash
docker compose \
  -f compose.yaml \
  -f compose.openai.yaml \
  up --build
```

To recreate all containers after configuration changes:

```bash
docker compose \
  -f compose.yaml \
  -f compose.openai.yaml \
  up --build --force-recreate
```

To stop the environment:

```bash
docker compose \
  -f compose.yaml \
  -f compose.openai.yaml \
  down
```

To stop the environment and remove persisted volumes:

```bash
docker compose \
  -f compose.yaml \
  -f compose.openai.yaml \
  down -v
```

Removing volumes causes the Chinook database to be imported again the next time the environment starts.

## Application endpoints

Once startup completes:

```text
Angular console:       http://localhost:4200
Spring Boot API:       http://localhost:8080
Application health:    http://localhost:8080/actuator/health
Application readiness: http://localhost:8080/actuator/health/readiness
PostgreSQL:             localhost:5432
```

## Verify the backend

Application information:

```bash
curl http://localhost:8080/api/info
```

Health:

```bash
curl http://localhost:8080/actuator/health
```

## Ask natural-language questions

The API accepts a JSON request through:

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

Example response:

```json
{
  "question": "Which sales agent made the most in sales in 2010?",
  "answer": "The sales agent who made the most in sales in 2010 is Jane Peacock with total sales amounting to 221.92."
}
```

### How many employees are in the system?

```bash
curl -X POST http://localhost:8080/api/questions \
  -H 'Content-Type: application/json' \
  -d '{
    "question": "How many employees are in the system?"
  }'
```

Example response:

```json
{
  "question": "How many employees are in the system?",
  "answer": "There are 8 employees in the system."
}
```

### How many employees have a manager title?

```bash
curl -X POST http://localhost:8080/api/questions \
  -H 'Content-Type: application/json' \
  -d '{
    "question": "How many employees have manager in their title?"
  }'
```

Example response:

```json
{
  "question": "How many employees have manager in their title?",
  "answer": "There are 3 employees with the title containing \"manager\"."
}
```

## Important note about AI-generated answers

The system can produce different interpretations or SQL queries for ambiguous questions.

For example, the question:

```text
How many employees are managers?
```

could mean:

* Employees whose title contains `manager`
* Employees who supervise at least one other employee
* Employees who do not report to another employee
* Employees who hold a particular organizational role

For more reliable results, questions should define the intended business meaning explicitly.

The engineering console is being developed to expose:

* The interpretation selected by the model
* Tools invoked
* Generated SQL
* Raw database results
* Final natural-language answer
* Repeated execution consistency
* Validation findings

This is central to the project's goal of exploring deterministic and trustworthy enterprise AI workflows.

## Access the database with DBeaver

Create a PostgreSQL connection with:

```text
Host: localhost
Port: 5432
Database: database
Username: user
Password: password
```

DBeaver can be used to inspect the Chinook schema, run SQL directly, and validate answers returned by the AI application.

The current credentials are development-only defaults and must not be used in a production deployment.

## Docker Compose components

### `database`

Runs PostgreSQL and publishes port `5432`.

It creates the development database and reports readiness through `pg_isready`.

### `importer`

Builds from `database/Dockerfile.importer`.

It waits for PostgreSQL to become healthy and then uses `pgloader` to copy the Chinook SQLite database into PostgreSQL.

The importer exits successfully after the data migration completes.

### `mcp-gateway`

Runs Docker's MCP gateway.

It waits for the importer to finish and exposes the configured database tools over Server-Sent Events on port `8811` inside the Compose network.

The current gateway is configured with unauthenticated access for local development only.

### `application`

Builds and runs the Spring Boot application.

It connects to the MCP gateway through:

```text
http://mcp-gateway:8811
```

The application exposes the REST API on host port `8080`.

The OpenAI API key, model name, and MCP gateway URL are supplied through the OpenAI Compose overlay.

### `console`

Builds and runs the Angular engineering console.

It waits for the Spring Boot application to become healthy and publishes the Angular development server on port `4200`.

## Configuration files

### `compose.yaml`

Defines the provider-independent local environment:

* PostgreSQL
* Chinook importer
* MCP gateway
* Spring Boot application
* Angular console
* Service health checks
* Startup dependencies
* Published ports

### `compose.openai.yaml`

Adds OpenAI-specific configuration to the application service:

```text
OPENAI_MODEL_NAME
OPENAI_API_KEY
MCP_SERVER_URL
```

Keeping this configuration in a Compose overlay allows other model providers to be added later without redesigning the base environment.

Possible future overlays include:

```text
compose.ollama.yaml
compose.bedrock.yaml
```

### `mcp-config.yaml`

Defines the MCP database server and supplies its PostgreSQL connection configuration.

The MCP gateway uses this file to start the database MCP server and expose its tools to Spring AI.

### `.env`

Contains local environment values that must not be committed, especially:

```text
OPENAI_API_KEY=<your-key>
```

Docker Compose reads the file automatically when invoked from the repository root.

## Current maturity

- ✅ End-to-end natural language → SQL through MCP
- ✅ Containerized local development environment
- ✅ Spring AI + OpenAI integration
- ✅ Angular engineering console (baseline)
- 🚧 SQL trace visualization
- 🚧 Determinism and validation support
- 🚧 Multi-agent orchestration

## Current development status

Completed:

* Containerized PostgreSQL database
* Chinook database import
* MCP database tools
* Spring Boot REST service
* Spring AI and OpenAI integration
* Natural-language database questions
* Angular console baseline
* Docker health checks and startup ordering

In progress:

* Question entry through the Angular console
* Display of generated SQL
* Display of raw query results
* Tool invocation tracking
* Repeated execution comparison
* Answer validation
* Prompt and model comparison

Future exploration:

* Saved AI test cases
* Regression testing
* Prompt versioning
* Structured execution traces
* Deterministic validation rules
* Second-agent review and orchestration
* Authentication and authorization
* Metrics and distributed tracing
* Additional model providers
* AWS deployment

## Project direction

The project is evolving toward an Enterprise AI Engineering Console and reference architecture for:

- Building AI-powered Java applications
- Observing agent and tool activity
- Testing natural-language workflows
- Detecting ambiguity and nondeterminism
- Validating answers against source data
- Comparing prompts, models, and orchestration strategies
- Establishing confidence before AI features are released to end users

## Vision

The objective is not merely to build AI-powered applications. It is to provide development teams with the tools and architectural patterns needed to understand, validate, observe, and gain confidence in AI-assisted workflows before those workflows reach production.

The long-term emphasis is on deterministic enterprise AI through transparent execution, evidence-backed answers, repeatable testing, structured validation, and observable orchestration.

This repository is intended as a development and architectural reference, not as a production-ready system in its current form.
