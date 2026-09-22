#!/usr/bin/env bash
set -u
API_URL="${TIMELINE_API_URL:-}"
API_TOKEN="${TIMELINE_API_TOKEN:-}"
RUN_ID="${1:-}"
GZIP_FILE="${2:-}"
if [[ -z "$API_URL" || -z "$API_TOKEN" || -z "$RUN_ID" || ! -r "$GZIP_FILE" ]]; then
    printf '%s\n' 'ASE: log upload skipped because configuration or file is missing.' >&2
    exit 0
fi
curl --silent --show-error --fail-with-body --connect-timeout 2 --max-time 30 --retry 2 \
    -X PUT -H "Authorization: Bearer ${API_TOKEN}" -H 'Content-Type: text/plain; charset=UTF-8' \
    -H 'Content-Encoding: gzip' --data-binary "@${GZIP_FILE}" \
    "${API_URL%/}/api/v1/executions/${RUN_ID}/log" >/dev/null ||
    printf '%s\n' 'ASE: execution trace not delivered; the supervised command continues.' >&2
exit 0

