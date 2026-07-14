# Docker Model Runner

## Overview

This project supports running entirely against Docker Model Runner using
OpenAI-compatible APIs.

## Start

``` bash
docker compose \
  -f compose.yaml \
  -f compose.model-runner.yaml \
  up --build
```

## Verify Docker Model Runner

``` bash
docker model status
docker model list
```

## Validate Models

Not every local model correctly supports structured tool calling.

Use the Model Validator before configuring a model in the main
application.

See:

``` text
tools/model-validator/
```

The validator performs an end-to-end Spring AI tool-calling validation
against the selected model.

## Notes

-   Docker Model Runner exposes an OpenAI-compatible endpoint.
-   Model quality and tool-calling support vary.
-   Performance depends on available CPU/GPU resources.
