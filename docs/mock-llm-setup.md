# Testing with mock-llm

This project can run against [mock-llm](https://github.com/dwmkerr/mock-llm)
instead of a real OpenAI endpoint — a scripted, deterministic backend that
lets you test the full Spring AI ↔ MCP ↔ Postgres pipeline without a live
model in the loop.

## Why this is here

Most of an agentic application's complexity isn't the model itself — it's
everything wired around it: does the tool-calling loop correctly hand a
tool's result back to the model, does the app handle a malformed tool call,
does a rate-limit response get retried or surfaced correctly, does the same
question produce the same answer twice in a row. None of that requires a
real model to test — it requires a scripted, repeatable stand-in for one.

Only the LLM is mocked here. Postgres, the Chinook data import, and the real
MCP gateway all run unchanged — mock-llm's scripted responses still drive
real `list_tables` and `execute_sql` calls against real data. That's
deliberate: the thing worth pinning down is the Spring AI ↔ MCP tool-calling
loop, not the database underneath it.

## Files

Two files support this, alongside the existing `compose.yaml` and
`compose.openai.yaml`:

- `compose.mockllm.yaml` — Compose overlay adding the `mock-llm` service and
  pointing `application` at it. Follows the same provider-overlay pattern
  `compose.openai.yaml` already uses.
- `mock-llm.yaml` — the scripted rules mock-llm serves.

### `compose.mockllm.yaml`

```yaml
services:
  mock-llm:
    image: ghcr.io/dwmkerr/mock-llm:latest
    container_name: mock-llm
    volumes:
      - ./mock-llm.yaml:/app/mock-llm.yaml:ro
    ports:
      - "6556:6556"

  application:
    environment:
      - OPENAI_MODEL_NAME=gpt-4.1-mini
      - OPENAI_API_KEY=mock-key
      - OPENAI_BASE_URL=http://mock-llm:6556/v1
      - MCP_SERVER_URL=http://mcp-gateway:8811
    depends_on:
      - mock-llm
```

No healthcheck is configured on `mock-llm` — in some Docker network
configurations, an in-container health probe (`wget localhost:...`) can fail
even though the server itself is fine and reachable from the host. A plain
`depends_on` is sufficient since mock-llm starts in well under a second.

If `application/src/main/resources/application.yaml` doesn't already
externalize the OpenAI base URL, add:

```yaml
spring:
  ai:
    openai:
      base-url: ${OPENAI_BASE_URL:https://api.openai.com}
```

## Writing scenarios

`mock-llm.yaml` matches incoming requests with JMESPath expressions and
returns a scripted response. A few things worth knowing before writing your
own scenarios — each of these came from a real, non-obvious failure:

**Every `chat.completion` response needs `id`, `object`, `model`, and
`usage`, and every entry in `choices` needs `index`.** The `openai-java` SDK
(used by Spring AI 2.0) validates these strictly and will throw
`OpenAIInvalidDataException` naming the exact missing field if you skip one.

**For multi-turn tool-calling scenarios, match on `tool_call_id`, not on
sequence or repeated message content.** After a tool call executes, the last
message in the conversation is the tool's result, not the original
question — so content-matching only works for the first turn. Minting a
`tool_call_id` in each scripted response and matching the next turn against
it is stateless and safe to re-run any number of times:

```yaml
- path: "/v1/chat/completions"
  match: "contains(body.messages[-1].content, 'How many employees are in the system')"
  response:
    status: 200
    content: |
      {
        "id": "chatcmpl-{{timestamp}}", "object": "chat.completion",
        "model": "{{jmes request body.model}}",
        "choices": [{
          "index": 0,
          "message": { "role": "assistant", "content": null,
            "tool_calls": [{"id": "call_1", "type": "function",
              "function": {"name": "list_tables", "arguments": "{}"}}] },
          "finish_reason": "tool_calls"
        }],
        "usage": {"prompt_tokens": 10, "completion_tokens": 10, "total_tokens": 20}
      }

- path: "/v1/chat/completions"
  match: "body.messages[-1].tool_call_id == 'call_1'"
  response:
    # ...tool call to execute_sql, minting id: call_2

- path: "/v1/chat/completions"
  match: "body.messages[-1].tool_call_id == 'call_2'"
  response:
    status: 200
    content: |
      {
        "id": "chatcmpl-{{timestamp}}", "object": "chat.completion",
        "model": "{{jmes request body.model}}",
        "choices": [{ "index": 0,
          "message": {"role": "assistant", "content": "There are 8 employees in the system."},
          "finish_reason": "stop" }],
        "usage": {"prompt_tokens": 10, "completion_tokens": 10, "total_tokens": 20}
      }
```

**`sequence` is fine for "same input, different answer each run" scenarios**
(e.g. testing how your app handles disagreement across runs), but its
counter is global per path, shared across every rule and every repeated
test run — not scoped to one conversation. Call `DELETE /config` on
mock-llm before an isolated run of a sequence-based scenario if other
traffic may have touched the same path in between.

**Rule order matters: mock-llm uses "last match wins."** A catch-all rule
(`match: "@"`) must be listed *before* your specific rules, not after, or it
will win over them for every request since it matches unconditionally.

**Avoid interpolating raw request content into a JSON response template.**
Tool-result content can contain real newlines/control characters; splicing
it directly into a JSON string produces invalid JSON ("Bad control
character in string literal"). Keep fallback/echo responses to fixed,
static text instead.

## Running it

```bash
docker compose -f compose.yaml -f compose.mockllm.yaml up --build -d
```

Verify mock-llm is serving:

```bash
curl http://localhost:6556/health
```

Run the scripted scenario:

```bash
for i in 1 2 3 4 5; do
  curl -s -X POST http://localhost:8080/api/questions \
    -H 'Content-Type: application/json' \
    -d '{"question": "How many employees are in the system?"}'
  echo
done
```

All five should return an identical answer — confirming a real Spring AI ↔
MCP ↔ Postgres round trip behaves deterministically end to end.

## Debugging checklist

If a request 500s, hangs, or returns something unexpected:

1. **Check the application logs first.**
   ```bash
   docker compose -f compose.yaml -f compose.mockllm.yaml logs application --tail=100
   ```
   The `openai-java` SDK's exceptions name the exact problem (missing
   field, 404 from a wrong base path, etc).

2. **Check mock-llm's logs to see which rule matched (or didn't).**
   ```bash
   docker compose -f compose.yaml -f compose.mockllm.yaml logs mock-llm
   ```

3. **Reset sequence counters if a `sequence`-based scenario returns stale
   or unexpected results.**
   ```bash
   curl -X DELETE http://localhost:6556/config
   ```

4. **If `mock-llm` shows as unhealthy in `docker compose ps` but `curl
   http://localhost:6556/health` works from the host,** it's likely a
   Docker-network quirk in how the in-container healthcheck resolves
   `localhost`, not an actual outage. Removing the healthcheck (plain
   `depends_on` instead of `condition: service_healthy`) is the simplest
   fix, since mock-llm starts fast enough that the health gate isn't
   needed.
