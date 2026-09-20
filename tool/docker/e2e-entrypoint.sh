#!/usr/bin/env bash
# Entrypoint for Dockerfile.e2e: serve the prebuilt Flutter web release,
# wait for it to answer, then hand off to the Python Playwright CLI wrapper
# with whatever args the container was invoked with.
set -euo pipefail

cd /repo

python3 -m http.server 8080 --directory build/web &
server_pid=$!
trap 'kill "$server_pid" 2>/dev/null || true' EXIT

for _ in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:8080" >/dev/null; then
    break
  fi
  sleep 1
done

exec python3 tool/python/playwright.py "$@"
