# Java AI Reference Architecture

A reproducible, local-first playground for building and testing enterprise agentic AI apps in Java — Spring Boot, Spring AI, MCP, PostgreSQL, and Angular.

The goal is an inexpensive, self-contained development environment for agentic AI: everything runs locally in Docker, with no infrastructure to provision and no cloud spend beyond the model API calls themselves. It assembles the database, sample business data, MCP tools, an AI-enabled Java service, a REST API, health checks, and an engineering console into a reproducible local environment, so that new agent ideas and new applications can be built on the same foundation instead of starting from scratch each time.

The first application built on this foundation is a natural-language-to-SQL agent. It is not the point of the project — it's the reference example that proves the environment works end to end.

## One-command local environment

```
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

| Capability                                      | Status                                    |
| ------------------------------------------------ | ------------------------------------------ |
| Containerized local environment                  | ✅ Working                                 |
| Chinook data import into PostgreSQL              | ✅ Working                                 |
| Spring AI and OpenAI integration                 | ✅ Working                                 |
| Natural-language questions against the database  | ✅ Working                                 |
| MCP database tool invocation                     | ✅ Working                                 |
| Angular engineering console                      | 🚧 Shell only — no NL query UI or trace view yet |
| Generated SQL and tool trace visualization        | 🔭 Not started                             |
| Repeated-run consistency testing                 | 🔭 Future exploration                      |
| Multi-agent validation and orchestration         | 🔭 Future exploration                      |

## Project purpose

Many AI examples demonstrate an isolated prompt or a console-based agent. This project instead aims to provide a reusable local environment for developing and validating AI-powered enterprise applications — one that's cheap enough to run repeatedly and reproducible enough to build multiple, unrelated applications on top of.

The current implementation accepts a natural-language business question, allows Spring AI to select and invoke database tools through MCP, dynamically queries the Chinook database, and returns a natural-language answer.

The longer-term goal is to explore how enterprise teams can make AI workflows more deterministic, observable, testable, and suitable for production use — and to use this same Docker Compose foundation for other agentic applications beyond NL-to-SQL (for example, document or spreadsheet data extraction).

The Angular application under `console/` is intended to become an engineering and validation console rather than an end-user chatbot. It currently exists only as an unmodified Angular scaffold. The plan is to use it to inspect natural-language questions, generated SQL, tool invocations, raw database results, final answers, repeated-run consistency, and validation results — none of which is implemented yet.

## Inspiration

This project is modeled after the LangGraph natural-language-to-SQL example in Docker's Compose for Agents repository:

<https://github.com/docker/compose-for-agents/tree/main/langgraph>

The original example demonstrates how an LLM can interpret a question, inspect a local database, generate SQL dynamically, execute the query, and formulate an answer.

This project adapts that workflow to a Java enterprise application using Spring Boot and Spring AI and exposes it through a REST API.

## Current capabilities

The project currently provides:

- A PostgreSQL database running in Docker
- Automatic import of the Chinook SQLite database into PostgreSQL
- An MCP gateway exposing database tools
- A Spring Boot and Spring AI application
- OpenAI model integration
- A REST endpoint for asking natural-language questions
- An Angular console running in Docker (unmodified scaffold — no custom UI yet)
- Health checks and startup dependency management
- Access to PostgreSQL from tools such as DBeaver

## Architecture

```
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

- `list_tables`
- `describe_table`
- `execute_sql`

## Repository structure

```
java-ai-reference-arch/
├── application/          Spring Boot and Spring AI application
├── console/              Angular engineering console (unmodified scaffold)
├── database/             Chinook database and importer image
├── docs/                 Architecture and development documentation
├── compose.yaml          Base infrastructure and application services
├── compose.openai.yaml   OpenAI-specific application configuration
├── mcp-config.yaml       MCP database-server configuration
└── README.md
```

## Sample business data

The application uses the Chinook sample database, which models a digital media store with employees, customers, artists, albums, tracks, playlists, invoices, and invoice lines.

The bundled SQLite database is imported into PostgreSQL automatically when the Compose environment starts. Detailed provenance, licensing, row counts, relationships, schema notes, and validation queries are documented in [`docs/sample-data.md`](https://github.com/pramalin/java-ai-reference-arch/blob/main/docs/sample-data.md).

## Minimal requirements

### Required to run the complete environment

- A machine capable of running Docker
- Docker Engine with Docker Compose support
- Git
- An OpenAI API key
- Internet access during the initial image and dependency download

Because the application, database, importer, MCP gateway, and Angular console run inside containers, JDK, Maven, Node.js, and Angular CLI are not required merely to run the project.

### Optional development tools

These tools are useful when modifying or debugging individual components:

- JDK 26
- Maven, or the included Maven wrapper
- Node.js
- Angular CLI 22
- Visual Studio Code or another IDE
- DBeaver or another PostgreSQL client
- `curl`
- Git

## Tested hardware

The project has been developed and run successfully in the Linux environment of an inexpensive Dell Latitude 5400 Chromebook.

```
Device: Dell Latitude 5400 Chromebook
Operating environment: ChromeOS Linux development environment
Processor: Intel(R) Core(TM) i5-8365U CPU @ 1.60GHz (8 threads, 4.100GHz)
Memory: 16GB
Storage: 150GB SSD
```

This project does not currently run a local LLM — model inference is performed through the OpenAI API, so there is still a per-call cost even though the rest of the stack is free and local. A local-model overlay (e.g. Ollama) is on the roadmap to make the environment fully self-contained.

## Configure the OpenAI API key

Create a file named `.env` in the repository root:

```
OPENAI_API_KEY=sk-proj-...
```

The `.env` file must not be committed. Confirm that `.gitignore` contains:

```
.env
```

A safe `.env.example` may be committed with an empty value:

```
OPENAI_API_KEY=
```

## Start the application

Clone the repository and move into it:

```
git clone https://github.com/pramalin/java-ai-reference-arch.git
cd java-ai-reference-arch
```

Create the `.env` file containing the OpenAI API key.

Start the complete environment:

```
docker compose \
  -f compose.yaml \
  -f compose.openai.yaml \
  up --build
```

To recreate all containers after configuration changes:

```
docker compose \
  -f compose.yaml \
  -f compose.openai.yaml \
  up --build --force-recreate
```

To stop the environment:

```
docker compose \
  -f compose.yaml \
  -f compose.openai.yaml \
  down
```

To stop the environment and remove persisted volumes:

```
docker compose \
  -f compose.yaml \
  -f compose.openai.yaml \
  down -v
```

Removing volumes causes the Chinook database to be imported again the next time the environment starts.

## Application endpoints

Once startup completes:

```
Angular console:       http://localhost:4200
Spring Boot API:       http://localhost:8080
Application health:    http://localhost:8080/actuator/health
Application readiness: http://localhost:8080/actuator/health/readiness
PostgreSQL:             localhost:5432
```

## Verify the backend

Application information:

```
curl http://localhost:8080/api/info
```

Health:

```
curl http://localhost:8080/actuator/health
```

## Ask natural-language questions

The API accepts a JSON request through:

```
POST /api/questions
```

### Which sales agent made the most in sales in 2010?

```
curl -X POST http://localhost:8080/api/questions \
  -H 'Content-Type: application/json' \
  -d '{
    "question": "Which sales agent made the most in sales in 2010?"
  }'
```

Example response:

```
{
  "question": "Which sales agent made the most in sales in 2010?",
  "answer": "The sales agent who made the most in sales in 2010 is Jane Peacock with total sales amounting to 221.92."
}
```

### How many employees are in the system?

```
curl -X POST http://localhost:8080/api/questions \
  -H 'Content-Type: application/json' \
  -d '{
    "question": "How many employees are in the system?"
  }'
```

Example response:

```
{
  "question": "How many employees are in the system?",
  "answer": "There are 8 employees in the system."
}
```

### How many employees have a manager title?

```
curl -X POST http://localhost:8080/api/questions \
  -H 'Content-Type: application/json' \
  -d '{
    "question": "How many employees have manager in their title?"
  }'
```

Example response:

```
{
  "question": "How many employees have manager in their title?",
  "answer": "There are 3 employees with the title containing \"manager\"."
}
```

## Important note about AI-generated answers

Because the SQL is generated by the model at runtime rather than fixed in code, the system can produce different interpretations or different SQL for the same or similar question across runs. For example, the question:

```
How many employees are managers?
```

could mean:

- Employees whose title contains `manager`
- Employees who supervise at least one other employee
- Employees who do not report to another employee
- Employees who hold a particular organizational role

For more reliable results, questions should define the intended business meaning explicitly.

This nondeterminism is not just a theoretical concern — repeated runs of the same sales-total question have produced different dollar totals depending on exactly which SQL the model generated (e.g. differences in how employee titles were matched). There is currently no tooling in this project to capture, compare, or diagnose that automatically; doing so is the main near-term goal of the engineering console described below.

The engineering console is planned to expose:

- The interpretation selected by the model
- Tools invoked
- Generated SQL
- Raw database results
- Final natural-language answer
- Repeated execution consistency
- Validation findings

None of this is implemented yet. This is the central near-term goal of the project — going from "an agent that answers questions" to "an agent whose answers can be inspected, trusted, and validated."

## Access the database with DBeaver

Create a PostgreSQL connection with:

```
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

```
http://mcp-gateway:8811
```

The application exposes the REST API on host port `8080`.

The OpenAI API key, model name, and MCP gateway URL are supplied through the OpenAI Compose overlay.

### `console`

Builds and runs the Angular engineering console.

It waits for the Spring Boot application to become healthy and publishes the Angular development server on port `4200`. It is currently an unmodified Angular scaffold with no custom functionality.

## Configuration files

### `compose.yaml`

Defines the provider-independent local environment:

- PostgreSQL
- Chinook importer
- MCP gateway
- Spring Boot application
- Angular console
- Service health checks
- Startup dependencies
- Published ports

### `compose.openai.yaml`

Adds OpenAI-specific configuration to the application service:

```
OPENAI_MODEL_NAME
OPENAI_API_KEY
MCP_SERVER_URL
```

Keeping this configuration in a Compose overlay allows other model providers to be added later without redesigning the base environment. Possible future overlays include:

```
compose.ollama.yaml
compose.bedrock.yaml
```

A local-model overlay (Ollama) is the priority among these, since it is what would make the environment fully self-contained rather than dependent on a paid API.

### `mcp-config.yaml`

Defines the MCP database server and supplies its PostgreSQL connection configuration.

The MCP gateway uses this file to start the database MCP server and expose its tools to Spring AI.

### `.env`

Contains local environment values that must not be committed, especially:

```
OPENAI_API_KEY=<your-key>
```

Docker Compose reads the file automatically when invoked from the repository root.

## Current development status

Completed:

- Containerized PostgreSQL database
- Chinook database import
- MCP database tools
- Spring Boot REST service
- Spring AI and OpenAI integration
- Natural-language database questions
- Docker health checks and startup ordering

Not started:

- Angular console UI (currently an unmodified scaffold)
- Display of generated SQL and tool traces in the console
- Display of raw query results in the console
- Repeated-run consistency comparison
- Answer validation
- Local-model (Ollama) overlay
- Additional agents / multi-agent orchestration
- Second reference application beyond NL-to-SQL

## Project direction

The project is evolving toward a reusable, low-cost local environment for building and testing enterprise agentic AI applications in Java — with the current NL-to-SQL agent as the first proof point, not the end goal. The near-term focus is making the system's behavior inspectable (tool traces, generated SQL, repeated-run comparison) before adding more agents or providers, since observability is what turns "an agent that answers questions" into something an enterprise team could actually trust and build on.

Planned directions include:

- A visible trace of every tool call and generated SQL statement, surfaced in the console
- Repeated-run consistency checks to catch and diagnose nondeterminism
- A local-model (Ollama) overlay, to make the environment cost-free and fully offline-capable
- A second reference application (e.g. spreadsheet or document data extraction) on the same Compose foundation, to prove the environment generalizes beyond NL-to-SQL
- Multi-agent orchestration, motivated by concrete needs (e.g. a validator agent that checks a primary agent's SQL before returning an answer) rather than added for its own sake
- Production deployment patterns, once the above observability and validation work is in place

## Vision

The objective is not merely to build AI-powered applications. It is to provide development teams with the tools and architectural patterns needed to understand, validate, observe, and gain confidence in AI-assisted workflows before those workflows reach production — in a development environment that's cheap and simple enough to actually iterate in.

This repository is intended as a development and architectural reference, not as a production-ready system in its current form.
