# Debugging Journey: Getting the LangGraph + MCP Gateway + Postgres Example Working

This document walks through the issues encountered while running (and later porting)
[Docker's `compose-for-agents` LangGraph example](https://github.com/docker/compose-for-agents/tree/main/langgraph),
in the order they were hit. Each section describes the symptom, the root cause, and the fix.
If you're setting up a similar MCP Gateway + Postgres + Docker Compose stack and something
isn't working, this is a useful checklist of things to verify.

## Environment

- Docker Compose v2 (`docker compose`, not `docker-compose`)
- `docker/mcp-gateway:latest`
- Postgres (official image), seeded from a SQLite `Chinook.db` via `pgloader`
- A LangGraph ReAct agent (Python), configured to use either a local model via Docker Model
  Runner or hosted OpenAI

---

## Issue 1: `--allow-unauthenticated` needed to avoid an "unauthorized" error

**Symptom:** the gateway rejected client connections by default.

**Fix:** add `--allow-unauthenticated` to the `mcp-gateway` command. This exposes the gateway
without authentication on all interfaces — fine for local development, but worth reverting
(or binding to `127.0.0.1`) before running anywhere less trusted.

---

## Issue 2: Agent always saw `MCP tools loaded: []`

**Symptom:** `mcp-gateway` logs showed `> 0 tools listed in X µs` — consistently, on every run,
in single-digit **microseconds**. The agent's LangChain MCP adapter reported an empty tool
list, so it could only narrate SQL as text instead of executing it.

**First (wrong) hypothesis — a startup race condition:** the gateway's one-shot tool listing
(`--servers` disables dynamic/lazy discovery) appeared, in the interleaved `docker compose up`
log output, to happen *before* Postgres or the `pgloader` import step had finished. This looked
exactly like a classic Compose ordering bug, so `depends_on` conditions were added:

```yaml
database:
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U user -d database"]
    interval: 2s
    timeout: 3s
    retries: 20
    start_period: 5s

importer:
  depends_on:
    database:
      condition: service_healthy

mcp-gateway:
  depends_on:
    importer:
      condition: service_completed_successfully

agent:
  depends_on:
    importer:
      condition: service_completed_successfully
    mcp-gateway:
      condition: service_started
```

This is good practice regardless, but **it did not fix the 0-tools problem.** The real
diagnostic clue came later: even after confirming (via the actual interactive console output,
not the buffered `docker compose logs`) that `importer` genuinely exited 0 *before*
`mcp-gateway` started, the gateway still reported 0 tools in microseconds. A real attempt to
reach Postgres — successful or failed — takes measurably longer than that. This ruled out
timing entirely.

**Lesson:** `docker compose logs` output can interleave in a way that *looks* like a race
condition even when Compose's dependency ordering is working correctly. Don't trust log
ordering as proof of execution ordering — check actual container start timestamps
(`docker inspect --format '{{.State.StartedAt}}'`) or watch the live interactive console output
instead.

---

## Issue 3: The `postgres_url` secret file had a stray key prefix

**Symptom (contributing factor):** the secret file mounted for the old `--secrets=` flag
contained:

```
postgres.url=postgres://user:password@database:5432/database
```

instead of just the raw connection string. The `--secrets=` flag expects the *entire file
content* to be the value, so `postgres.url=` broke parsing.

**Fix:**

```
postgres://user:password@database:5432/database
```

Always `cat -A` your secret files when debugging — this also reveals hidden characters like
Windows line endings (`^M`) that can silently break parsing.

This fixed one real bug, but the 0-tools symptom persisted — a sign there was a second,
independent problem underneath it.

---

## Issue 4: The `postgres` MCP catalog entry no longer exists

**Root cause, finally identified.** A working reference example (using an older gateway/catalog
version) showed a distinct log sequence before tool listing:

```
- Using images:
  - mcp/postgres@sha256:...
> Images pulled in ...
- Verifying images [...]
> Images verified in ...
- Listing MCP tools...
```

Our logs never showed this image-pull/verify stage at all — they jumped straight from
`Reading configuration...` to `0 tools listed`. That meant the gateway wasn't even attempting
to resolve an image for `postgres`; it was failing at **catalog name resolution**, before any
network call to Postgres was ever made. This explained the sub-microsecond "0 tools" result
regardless of database readiness, secret content, or dependency ordering — none of those
mattered because the server name itself didn't match anything in the current catalog.

**Confirmation:** pulling the actual catalog (`docker mcp catalog show <name> > catalog.txt`)
and searching it directly showed **no `mcp/postgres` image anywhere**. The dedicated `postgres`
server from the older catalog version had been removed/consolidated. The closest equivalent in
the current catalog is a generic multi-database server:

```yaml
name: database-server
image: souhardyak/mcp-db-server@...
tools:
  - query_database
  - list_tables
  - describe_table
  - execute_sql
  - connect_to_database
  - get_connection_examples
  - get_current_database_info
config:
  - name: database-server
    properties:
      database_url: { type: string }
    required: [database_url]
```

**Fix:** update the gateway command:

```yaml
command:
  - --transport=sse
  - --allow-unauthenticated
  - --servers=database-server
  - --tools=execute_sql,list_tables,describe_table
```

**Lesson:** Docker's hosted MCP catalog is a moving target. If a `--servers=<name>` flag
produces an instant, suspiciously-fast empty tool list, check whether that server name still
exists in the current catalog before debugging anything else — it's a much cheaper check than
chasing timing/config theories.

---

## Issue 5: `database-server` needs its connection string via `--config`, not `--secrets`

**Symptom:** after fixing the server name, tools loaded correctly (3 tools), but the agent's
`list_tables` call came back empty. The gateway logs revealed why:

```
database-server: INFO:mcp-database-server:Connected to database: sqlite+aiosqlite:////data/default.db
```

It had silently fallen back to a built-in default SQLite database, because the templated
config value `{{database-server.database_url}}` was never resolved — the old `--secrets=`
mechanism doesn't populate catalog `config:` values, only catalog `secrets:` values, and this
server's catalog entry defines `database_url` under `config:`.

**Fix:** supply the value via a mounted config file and the `--config` flag:

`mcp-config.yaml`:
```yaml
database-server:
  database_url: postgresql+asyncpg://user:password@database:5432/database
```

`compose.yaml`:
```yaml
mcp-gateway:
  command:
    - --transport=sse
    - --allow-unauthenticated
    - --config=/mcp-config.yaml
    - --servers=database-server
    - --tools=execute_sql,list_tables,describe_table
  volumes:
    - ./mcp-config.yaml:/mcp-config.yaml:ro
```

The old `--secrets=/run/secrets/database-url` flag and its associated `secrets:` block could
be removed once this was in place.

---

## Issue 6: Wrong Postgres URL scheme/driver for this server's engine

**Symptom:** with `--config` wired up correctly, the server now read the real connection
string — and immediately failed:

```
ERROR:db:Failed to initialize database engine: Can't load plugin: sqlalchemy.dialects:postgres
```

**Root cause:** two problems in one URL:
1. Modern SQLAlchemy dropped the bare `postgres` dialect alias — it must be `postgresql`.
2. This server uses `create_async_engine`, which requires an explicit async driver in the URL.

**Fix:**

```
postgres://user:password@database:5432/database        ❌
postgresql+asyncpg://user:password@database:5432/database   ✅
```

After this change, the logs showed the expected:

```
database-server: INFO:db:Database engine initialized for postgresql
database-server: INFO:mcp-database-server:Connected to database: postgresql+asyncpg://...
```

...and the agent successfully called `list_tables` → `describe_table` → `execute_sql` and
produced a correct, grounded answer.

---

## Issue 7 (separate track): Avoiding an unnecessary local model pull

**Symptom:** even though the app was configured to use OpenAI, Docker Model Runner was still
pulling and running a local `qwen3` model on every `docker compose up`.

**Root cause:** the top-level `models:` block and the `agent` service's `models: qwen3:`
attachment are declarative Compose resources. Compose provisions anything declared under
`models:` as part of bringing the stack up, **independent of whether the application code ever
calls it at runtime.** Merely setting `OPENAI_API_KEY` (or overlaying a `compose.openai.yaml`
that adds the OpenAI secret) does not remove this — Compose override files can add or replace
keys but cannot delete a key from the base file through a normal merge.

**Fix:** remove the `models:` block from the `agent` service and the top-level `models:` section
in `compose.yaml` entirely. Use a separate override file (`compose.openai.yaml`) purely to
inject the OpenAI secret and model name:

```yaml
# compose.openai.yaml
services:
  agent:
    environment:
      - OPENAI_MODEL_NAME=gpt-4.1-mini
    secrets:
      - openai-api-key

secrets:
  openai-api-key:
    file: secret.openai-api-key
```

```bash
docker compose -f compose.yaml -f compose.openai.yaml up --build --force-recreate
```

---

## Summary of the final working configuration

Compared to the original tutorial, the working `compose.yaml` differs in:

1. **Ordering:** `mcp-gateway` and `agent` `depends_on` the `importer` completing successfully
   (`condition: service_completed_successfully`), not just the database being healthy.
2. **No local model:** the `models:` block is removed entirely; OpenAI is wired in via a
   separate `compose.openai.yaml` overlay.
3. **Catalog server name:** `--servers=postgres` → `--servers=database-server` (the old
   `postgres` catalog entry no longer exists).
4. **Tool names:** `--tools=query` → `--tools=execute_sql,list_tables,describe_table`
   (matching the real tool names on `database-server`).
5. **Config delivery:** `--secrets=/run/secrets/database-url` → `--config=/mcp-config.yaml`,
   mounting a config file with `database-server.database_url`.
6. **Connection string format:** `postgres://...` → `postgresql+asyncpg://...`.

## General lessons for debugging MCP Gateway + Compose stacks

- **A near-instant "0 tools listed" is a config/catalog problem, not a timing problem.** A real
  connection attempt — success or failure — takes measurably longer than microseconds.
- **Don't trust interleaved `docker compose logs` ordering as proof of execution ordering.**
  Check real container start timestamps, or watch the live console output of `docker compose up`
  directly.
- **Catalogs change.** A server name that worked in a blog post or older example may no longer
  exist. Pull the catalog yourself (`docker mcp catalog show <name>`) and grep for the expected
  image/server name before assuming your compose file syntax is wrong.
- **`config:` and `secrets:` in a catalog entry are different delivery mechanisms** — check which
  one a given server's catalog definition actually uses before choosing `--config` vs
  `--secrets`.
- **Compose `models:` declarations are provisioned unconditionally.** If you don't want a local
  model pulled, remove the declaration — don't rely on the app simply not calling it.
- Always sanity-check secret/config file contents with `cat -A` to catch stray prefixes, quotes,
  or line-ending issues.