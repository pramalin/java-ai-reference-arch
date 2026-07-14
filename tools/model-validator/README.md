# Spring AI Model Validator

The Model Validator is a lightweight Spring Boot application used to evaluate whether a local Large Language Model (LLM) is compatible with Spring AI's tool-calling capabilities.

It is intended as a development utility for evaluating models before using them with the Java AI Reference Architecture.

Unlike the reference application, the validator does not require PostgreSQL, MCP Gateway, Angular, or the Chinook sample database. It focuses exclusively on validating the interaction between:

- Spring AI
- Docker Model Runner
- an OpenAI-compatible local model
- Spring AI Tool Calling

## Why?

Many local models advertise "tool calling" support.

In practice, models differ in how they implement function calling:

- some return OpenAI-compatible `tool_calls`
- some generate tool-call-like JSON as plain text
- some generate Python or JavaScript code instead of invoking tools
- some support only provider-specific formats

Spring AI requires models to produce OpenAI-compatible structured tool calls in order to execute Java tools automatically.

The validator provides a repeatable way to verify that behavior.

## What it validates

The validator performs a complete Spring AI tool-calling workflow:

1. Sends a prompt requesting weather information.
2. Registers a Java tool (`getWeather`).
3. Allows Spring AI to execute the tool.
4. Returns the tool result to the model.
5. Verifies that the model successfully completed the interaction.

This validates the complete integration rather than only checking whether the model can generate function-call syntax.

## Running

Select the model to evaluate:

```bash
MODEL_NAME=<model-name> \
docker compose -f compose.model-validator.yaml up --build
```

Example:

```bash
MODEL_NAME=hf.co/Manojb/Qwen3-4B-toolcalling-gguf-codex \
docker compose -f compose.model-validator.yaml up --build
```

Run the validation:

```bash
curl http://localhost:8081/api/validate-tool-calling
```

Example response:

```json
{
  "model": "...",
  "passed": true,
  "elapsedMilliseconds": 1523
}
```

## Current observations

During development the validator produced the following observations:

| Model | Result |
|--------|--------|
| Gemma 3 4B | Generates responses but does not produce structured OpenAI tool calls |
| Qwen3 4B Tool Calling | Produces tool-call semantics but was too slow on the development hardware to complete the Spring AI interaction |

These observations are hardware dependent and should not be interpreted as general benchmarks.

## Future work

Possible future enhancements include:

- validating multiple tool calls
- testing MCP tools
- measuring latency
- collecting token statistics
- generating compatibility reports
- comparing local and hosted models