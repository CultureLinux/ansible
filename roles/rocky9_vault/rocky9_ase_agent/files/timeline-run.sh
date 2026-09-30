#!/usr/bin/env bash

# Usage: timeline-run.sh <task-key> -- <command> [arguments...]
set -uo pipefail

if [[ -n "${TIMELINE_ENV_FILE:-}" ]]; then
    if [[ ! -r "$TIMELINE_ENV_FILE" ]]; then
        printf 'ASE: unreadable configuration file: %s\n' "$TIMELINE_ENV_FILE" >&2
        exit 66
    fi
    # Export variables so the reporter child process receives the API token.
    # shellcheck source=/dev/null
    set -a
    source "$TIMELINE_ENV_FILE"
    set +a
fi

TASK_KEY="${1:-}"
if [[ -z "$TASK_KEY" || "${2:-}" != "--" || $# -lt 3 ]]; then
    printf 'Usage: %s <task-key> -- <command> [arguments...]\n' "$0" >&2
    exit 64
fi
shift 2

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPORTER="${TIMELINE_REPORTER:-${SCRIPT_DIR}/report-execution.sh}"
LOG_UPLOADER="${TIMELINE_LOG_UPLOADER:-${SCRIPT_DIR}/upload-execution-log.sh}"
if [[ ! -f "$REPORTER" ]]; then
    printf 'ASE: reporter not found: %s\n' "$REPORTER" >&2
    exit 66
fi

if command -v uuidgen >/dev/null 2>&1; then
    RUN_ID="$(uuidgen | tr '[:upper:]' '[:lower:]')"
elif [[ -r /proc/sys/kernel/random/uuid ]]; then
    RUN_ID="$(tr '[:upper:]' '[:lower:]' </proc/sys/kernel/random/uuid)"
else
    printf '%s\n' 'ASE: uuidgen or /proc/sys/kernel/random/uuid is required.' >&2
    exit 69
fi

HOST_NAME="${TIMELINE_HOST:-$(hostname)}"
SOURCE_NAME="${TIMELINE_SOURCE:-$(basename -- "$1")}"
STARTED_AT="$(date +%s)"
TERMINAL_STATE=''
LOG_FILE="$(mktemp "${TMPDIR:-/tmp}/ase-execution.XXXXXX")"

report() {
    bash "$REPORTER" "$TASK_KEY" "$RUN_ID" "$1" "$HOST_NAME" "$SOURCE_NAME" "${2:-}" "${3:-}"
}

finish() {
    local exit_code=$?
    local duration state
    trap - EXIT
    duration=$(($(date +%s) - STARTED_AT))
    if [[ -n "$TERMINAL_STATE" ]]; then
        state="$TERMINAL_STATE"
    elif [[ $exit_code -eq 0 ]]; then
        state='success'
    else
        state='failed'
    fi
    report "$state" "Command finished in ${duration}s with exit code ${exit_code}." "$exit_code"
    if [[ "${TIMELINE_LOG_UPLOAD:-1}" == "1" && -x "$LOG_UPLOADER" && -s "$LOG_FILE" ]]; then
        local gzip_file="${LOG_FILE}.gz"
        gzip -c "$LOG_FILE" > "$gzip_file" && "$LOG_UPLOADER" "$RUN_ID" "$gzip_file" || true
        rm -f "$gzip_file"
    fi
    rm -f "$LOG_FILE"
    exit "$exit_code"
}

abort() {
    TERMINAL_STATE='aborted'
    exit "$1"
}

trap finish EXIT
trap 'abort 130' INT
trap 'abort 143' TERM

report started "Starting command: $*" ''
set +e
"$@" 2>&1 | tee "$LOG_FILE"
COMMAND_EXIT=${PIPESTATUS[0]}
exit "$COMMAND_EXIT"
