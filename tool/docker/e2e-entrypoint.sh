#!/usr/bin/env bash
# Shared Docker E2E entrypoint; native test exit status is authoritative.
set -euo pipefail

cd "${E2E_REPO_ROOT:-/repo}"

timestamp() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
log() {
  local level="$1" component="$2"
  shift 2
  printf '%s [%s] [%s] %s\n' "$(timestamp)" "$level" "$component" "$*"
}
stream_log() {
  local level="$1" component="$2" line
  while IFS= read -r line || [[ -n "$line" ]]; do
    log "$level" "$component" "$line"
  done
}

runtime=false
case "${CURL_RUNTIME_E2E:-false}" in
  1|true) runtime=true; export CURL_RUNTIME_E2E=1 ;;
  0|false|'') ;;
  *) log ERROR entrypoint "invalid CURL_RUNTIME_E2E mode"; exit 2 ;;
esac

server_pid=""
cleanup() {
  local exit_code=$?
  trap - EXIT
  if [[ -n "$server_pid" ]] && kill -0 "$server_pid" 2>/dev/null; then
    log INFO entrypoint "stopping HTTP server pid=$server_pid"
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
  log INFO entrypoint "container exiting code=$exit_code"
  exit "$exit_code"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if [[ "$runtime" == true ]]; then
  mkdir -p build/curl-runtime
  timeout 20s python3 -S tool/python/vendor/yourself.py --minimal --format json \
    > build/curl-runtime/environment.json
  # Fixed read-only observations, not arbitrary user-supplied commands.
  {
    timeout 20s python3 --version
    timeout 20s node --version
    timeout 20s npm --version
    timeout 20s npx --version
    timeout 20s deno --version
    (cd e2e && timeout 20s npx --no-install playwright --version)
    timeout 20s deno run --no-config --no-lock --no-remote tool/docker/toolchain_smoke.ts
  } > build/curl-runtime/toolchain.log
  log INFO entrypoint "starting local Python parser and Flutter web server port=8080"
  python3 -u -S tool/python/curl_runtime_server.py --web-root build/web --port 8080 \
    > build/curl-runtime/server.log 2>&1 &
else
  log INFO entrypoint "starting Flutter web server address=0.0.0.0 port=8080 directory=build/web"
  python3 -u -m http.server 8080 --directory build/web \
    > >(stream_log INFO http_server) \
    2> >(stream_log WARN http_server) &
fi
server_pid=$!
log INFO entrypoint "HTTP server started pid=$server_pid"

ready=false
for attempt in $(seq 1 30); do
  if ! kill -0 "$server_pid" 2>/dev/null; then
    log ERROR entrypoint "HTTP server exited before readiness check completed"
    exit 1
  fi
  if curl --max-time 2 -fsS "http://127.0.0.1:8080" >/dev/null; then
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

runner=(python3 -u tool/python/playwright.py)
if [[ "$runtime" == true ]]; then
  # Browser test stalls cannot outlive the bounded CI/evidence run.
  runner=(timeout --signal=TERM --kill-after=10s 900s "${runner[@]}")
fi
log INFO playwright "starting command=${*:-default}"
set +e
"${runner[@]}" "$@" \
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
