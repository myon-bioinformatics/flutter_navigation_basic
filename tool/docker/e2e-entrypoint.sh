#!/usr/bin/env bash
# Entrypoint for Dockerfile.e2e: serve the prebuilt Flutter web release,
# wait for it to answer, then run the Python Playwright CLI wrapper.
#
# Docker log format:
#   2026-09-20T07:00:00Z [INFO] [entrypoint] message
set -euo pipefail

cd /repo

timestamp() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

log() {
  local level="$1"
  local component="$2"
  shift 2
  printf '%s [%s] [%s] %s\n' "$(timestamp)" "$level" "$component" "$*"
}

stream_log() {
  local level="$1"
  local component="$2"
  local line
  while IFS= read -r line || [[ -n "$line" ]]; do
    log "$level" "$component" "$line"
  done
}

server_pid=""

cleanup() {
  local exit_code=$?
  if [[ -n "$server_pid" ]] && kill -0 "$server_pid" 2>/dev/null; then
    log INFO entrypoint "stopping HTTP server pid=$server_pid"
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
  log INFO entrypoint "container exiting code=$exit_code"
  exit "$exit_code"
}
trap cleanup EXIT INT TERM

log INFO entrypoint "starting Flutter web server address=0.0.0.0 port=8080 directory=build/web"
python3 -u -m http.server 8080 --directory build/web \
  > >(stream_log INFO http_server) \
  2> >(stream_log WARN http_server) &
server_pid=$!
log INFO entrypoint "HTTP server started pid=$server_pid"

ready=false
for attempt in $(seq 1 30); do
  if ! kill -0 "$server_pid" 2>/dev/null; then
    log ERROR entrypoint "HTTP server exited before readiness check completed"
    exit 1
  fi

  if curl -fsS "http://127.0.0.1:8080" >/dev/null; then
    ready=true
    log INFO entrypoint "Flutter web server ready attempt=$attempt url=http://127.0.0.1:8080"
    break
  fi

  if (( attempt == 1 || attempt % 5 == 0 )); then
    log DEBUG entrypoint "waiting for Flutter web server attempt=$attempt/30"
  fi
  sleep 1
done

if [[ "$ready" != true ]]; then
  log ERROR entrypoint "Flutter web server readiness timeout attempts=30"
  exit 1
fi

if [[ "$#" -eq 0 ]]; then
  log INFO playwright "starting command=default"
else
  log INFO playwright "starting command=$*"
fi

set +e
python3 -u tool/python/playwright.py "$@" \
  > >(stream_log INFO playwright) \
  2> >(stream_log ERROR playwright)
playwright_exit=$?
set -e

if [[ "$playwright_exit" -eq 0 ]]; then
  log INFO playwright "completed exit_code=0"
else
  log ERROR playwright "failed exit_code=$playwright_exit"
fi

exit "$playwright_exit"
