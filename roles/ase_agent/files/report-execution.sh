#!/usr/bin/env bash

# Reports one event to ASE without making the supervised command fail.
set -u

API_URL="${TIMELINE_API_URL:-http://127.0.0.1:8000}"
API_TOKEN="${TIMELINE_API_TOKEN:-}"
TASK_KEY="${1:-}"
RUN_ID="${2:-}"
STATE="${3:-}"
HOST_NAME="${4:-$(hostname)}"
SOURCE_NAME="${5:-script}"
MESSAGE="${6:-}"
EXIT_CODE="${7:-}"

if [[ -z "$API_TOKEN" || -z "$TASK_KEY" || -z "$RUN_ID" || -z "$STATE" ]]; then
    printf '%s\n' 'ASE: missing parameters or TIMELINE_API_TOKEN.' >&2
    exit 0
fi

payload="$(jq -cn \
    --arg task "$TASK_KEY" \
    --arg run_id "$RUN_ID" \
    --arg state "$STATE" \
    --arg occurred_at "$(date --iso-8601=seconds)" \
    --arg host "$HOST_NAME" \
    --arg source "$SOURCE_NAME" \
    --arg message "$MESSAGE" \
    --arg exit_code "$EXIT_CODE" \
    '{
        task: $task,
        run_id: $run_id,
        state: $state,
        occurred_at: $occurred_at,
        host: $host,
        source: $source,
        message: (if $message == "" then null else $message end),
        exit_code: (if $exit_code == "" then null else ($exit_code | tonumber) end),
        log_url: null,
        metadata: {}
    }' 2>/dev/null)"

if [[ -z "$payload" ]]; then
    printf '%s\n' 'ASE: unable to build the event payload.' >&2
    exit 0
fi

if ! curl --silent --show-error --fail-with-body \
    --connect-timeout 2 --max-time 5 --retry 2 \
    -H "Authorization: Bearer ${API_TOKEN}" \
    -H 'Content-Type: application/json' \
    --data "$payload" \
    "${API_URL%/}/api/v1/execution-events" >/dev/null; then
    printf '%s\n' 'ASE: event not delivered; the supervised command continues.' >&2
fi

exit 0

