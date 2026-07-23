#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LANGGRAPH_DIR="$(cd "${TEST_DIR}/.." && pwd)"

PROJECT_NAME="${COMPOSE_PROJECT_NAME:-langgraph-llmsim-test}"
LLMSIM_PORT="${LLMSIM_PORT:-8089}"
LLMSIM_BASE_URL="http://localhost:${LLMSIM_PORT}"
KEEP_TEST_STACK="${KEEP_TEST_STACK:-0}"

COMPOSE=(
  docker compose
  --project-name "${PROJECT_NAME}"
  --project-directory "${LANGGRAPH_DIR}"
  -f "${LANGGRAPH_DIR}/compose.yaml"
  -f "${TEST_DIR}/compose.llmsim.yaml"
)

require_command() {
  local command_name="$1"

  if ! command -v "${command_name}" >/dev/null 2>&1; then
    echo "Required command not found: ${command_name}" >&2
    exit 2
  fi
}

cleanup() {
  local exit_code=$?

  if [[ "${KEEP_TEST_STACK}" == "1" ]]; then
    echo
    echo "KEEP_TEST_STACK=1: preserving the Compose project ${PROJECT_NAME}."
    echo "Clean it up with:"
    printf "  "
    printf "%q " "${COMPOSE[@]}"
    echo "down -v --remove-orphans"
  else
    "${COMPOSE[@]}" down -v --remove-orphans >/dev/null 2>&1 || true
  fi

  exit "${exit_code}"
}

wait_for_llmsim() {
  local attempts=0

  until curl --fail --silent \
    "${LLMSIM_BASE_URL}/_llmsim/status" >/dev/null; do
    attempts=$((attempts + 1))

    if [[ "${attempts}" -ge 120 ]]; then
      echo "llmsim did not become ready." >&2
      "${COMPOSE[@]}" logs llmsim >&2 || true
      return 1
    fi

    sleep 0.5
  done
}

require_command docker
require_command curl
require_command jq

trap cleanup EXIT

echo "Starting PostgreSQL, importer, MCP gateway, and llmsim..."
"${COMPOSE[@]}" up \
  --detach \
  --build \
  database \
  importer \
  mcp-gateway \
  llmsim

echo "Waiting for the Chinook import to finish..."

importer_container="$("${COMPOSE[@]}" ps --all --quiet importer)"

if [[ -z "${importer_container}" ]]; then
  echo "Could not locate the importer container." >&2
  "${COMPOSE[@]}" ps --all >&2
  exit 1
fi

docker wait "${importer_container}" >/dev/null

importer_exit_code="$(
  docker inspect \
    --format '{{.State.ExitCode}}' \
    "${importer_container}"
)"

if [[ "${importer_exit_code}" -ne 0 ]]; then
  echo "The Chinook importer failed with exit code ${importer_exit_code}." >&2
  "${COMPOSE[@]}" logs importer >&2
  exit "${importer_exit_code}"
fi

echo "Chinook import completed successfully."

wait_for_llmsim

curl --fail --silent \
  --request POST \
  "${LLMSIM_BASE_URL}/_llmsim/reset" >/dev/null

sleep 2

echo "Running the real LangGraph agent against llmsim..."
agent_output_file="$(mktemp)"

set +e
"${COMPOSE[@]}" run --rm --no-deps agent \
  2>&1 | tee "${agent_output_file}"
agent_status=${PIPESTATUS[0]}
set -e

if [[ "${agent_status}" -ne 0 ]]; then
  echo "The LangGraph agent exited with status ${agent_status}." >&2
  "${COMPOSE[@]}" logs mcp-gateway llmsim >&2 || true
  rm -f "${agent_output_file}"
  exit "${agent_status}"
fi

calls_file="$(mktemp)"
curl --fail --silent \
  "${LLMSIM_BASE_URL}/_llmsim/calls" > "${calls_file}"

jq --exit-status 'length == 4' "${calls_file}" >/dev/null

jq --exit-status '
  all(.[];
    .provider == "openai"
    and .model == "llmsim-demo"
    and .outcome.type == "responded"
    and has("streamed")
  )
' "${calls_file}" >/dev/null

jq --exit-status '
  [.[].sequence] == [1, 2, 3, 4]
  and [.[].stepIndex] == [0, 1, 2, 3]
' "${calls_file}" >/dev/null

jq --exit-status '
  .[0].outcome.body.choices[0].finish_reason == "tool_calls"
  and .[1].outcome.body.choices[0].finish_reason == "tool_calls"
  and .[2].outcome.body.choices[0].finish_reason == "tool_calls"
  and .[3].outcome.body.choices[0].finish_reason == "stop"
' "${calls_file}" >/dev/null

jq --exit-status '
  .[0].outcome.body.choices[0].message.tool_calls[0].function.name
    == "list_tables"
  and
  .[1].outcome.body.choices[0].message.tool_calls[0].function.name
    == "describe_table"
  and
  .[2].outcome.body.choices[0].message.tool_calls[0].function.name
    == "execute_sql"
' "${calls_file}" >/dev/null

jq --exit-status '
  ((.[1].messages | tostring) | contains("Error:") | not)
  and
  ((.[2].messages | tostring) | contains("Error:") | not)
  and
  ((.[3].messages | tostring) | contains("Error:") | not)
' "${calls_file}" >/dev/null

jq --exit-status '
  ((.[1].messages | tostring) | test("employee"; "i"))
  and
  ((.[2].messages | tostring) | test("employee"; "i"))
  and
  ((.[3].messages | tostring) | contains("employee_count"))
  and
  ((.[3].messages | tostring) | test("(^|[^0-9])8([^0-9]|$)"))
' "${calls_file}" >/dev/null

if ! grep --quiet \
  "There are 8 employees in the system" \
  "${agent_output_file}"; then
  echo "The final answer was not derived from the database count." >&2
  echo "Agent output:" >&2
  cat "${agent_output_file}" >&2
  rm -f "${agent_output_file}" "${calls_file}"
  exit 1
fi

rm -f "${agent_output_file}" "${calls_file}"

echo
echo "LangGraph llmsim integration test passed."
echo "Verified list_tables, describe_table, execute_sql, and the real count result."
