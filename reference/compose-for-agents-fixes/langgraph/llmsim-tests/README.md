# llmsim test for the LangGraph SQL agent

This directory runs the existing LangGraph example against llmsim instead of
Docker Model Runner or OpenAI.

No existing project file is replaced. The Compose override:

- disables the model-runner attachment on the agent;
- points the OpenAI-compatible client to llmsim;
- asks `How many employees are in the system?`;
- adds a custom llmsim image containing the deterministic tool-call script.

Run:

```bash
./run-test.sh
```

To preserve containers after a failure for inspection:

```bash
KEEP_TEST_STACK=1 ./run-test.sh
```

Inspect the journal while the stack is preserved:

```bash
curl -s http://localhost:8089/_llmsim/calls | jq
```

The test uses its own Compose project name, `langgraph-llmsim-test`.
