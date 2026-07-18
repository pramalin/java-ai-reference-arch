# Fixes for docker/compose-for-agents on modest hardware

Copies of examples from
[docker/compose-for-agents](https://github.com/docker/compose-for-agents),
with the changes needed to run them on hardware without a GPU (tested on
a Dell Latitude 5400 Chromebook), using the OpenAI API instead of local
model inference via Docker Model Runner.

Each folder is a full copy of the upstream example's source files, plus
`compose.yaml.orig` (the untouched upstream file) alongside the patched
`compose.yaml`. Diff them directly to see exactly what changed:

```
diff compose.yaml.orig compose.yaml
```

## Why these changes are needed

The upstream examples default to local model inference via Docker Model
Runner, which requires GPU support. Running with `compose.openai.yaml`
instead removes that requirement, but two things generally need to
change in the base `compose.yaml`:

### 1. Remove local model runner config

The `models:` block — both the per-service reference (e.g.
`endpoint_var: MODEL_RUNNER_URL`) and the top-level `models:` definition
— routes through Docker Model Runner. Not needed when using the OpenAI
overlay; remove both.

### 2. `--allow-unauthenticated` on `mcp-gateway`

The MCP gateway defaults to requiring an authenticated client handshake.
In a local, single-user dev environment (no reverse proxy, no
multi-tenant access), this handshake fails. Adding
`--allow-unauthenticated` bypasses it.

**This is a local-development-only workaround, not a production fix.**
A real deployment should configure proper client authentication instead
of disabling it.

## Examples covered

| Example    | Local model config removed | `--allow-unauthenticated` added | Additional changes |
|------------|:---------------------------:|:--------------------------------:|:-------------------:|
| langgraph  | ✅                           | ✅                                | See notes below |
| crew-ai    | ✅                           | ✅                                | — |
| spring-ai  | ✅                           | ✅                                | See notes below |

### langgraph — additional notes

Beyond the two-part fix above, this example needed startup-ordering and
reliability changes, likely due to slower relative startup times on
modest hardware:

- **MCP gateway's database connection changed from a Docker secret to a
  mounted config file**: original used
  `--secrets=/run/secrets/database-url` with `--servers=postgres`
  `--tools=query`; patched version uses `--config=/mcp-config.yaml`
  with `--servers=database-server`
  `--tools=execute_sql,list_tables,describe_table`, mounting
  `mcp-config.yaml` read-only.
- **Postgres healthcheck loosened**: `interval` 1s → 2s, `retries` 10 →
  20, added `start_period: 5s`.
- **Stricter `depends_on` conditions**: `agent` now waits for
  `importer: service_completed_successfully` and
  `mcp-gateway: service_started`, instead of just waiting on the
  database container. `mcp-gateway` itself now also waits for the
  importer to finish. The original's simple `depends_on: - database`
  only confirmed Postgres was healthy, not that the Chinook data had
  actually finished importing — a likely source of race conditions,
  especially on slower hardware.

### spring-ai — additional notes

Beyond the two-part fix above, this example's `compose.yaml` also has a
couple of changes made during verification (not required to run on
modest hardware, but kept for reference):

- Added `LOGGING_LEVEL_*` env vars (DEBUG/TRACE for WebClient, OpenAI,
  tool calls, and chat) to confirm the MCP tool-calling path was
  actually being exercised.
- Changed the `QUESTION` prompt to explicitly force tool use
  ("You must use the available search tool before answering... Do not
  answer from memory"), since the original question ("Does Spring AI
  support MCP?") could plausibly be answered from the model's training
  data without exercising MCP at all. The original question is left
  commented out in the file for comparison.

## Not a maintained fork

These are point-in-time patch notes against the upstream examples as of
when each was verified, not a tracked fork. If upstream changes, these
patches may no longer apply cleanly.