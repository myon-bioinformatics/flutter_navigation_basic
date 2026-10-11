#!/usr/bin/env python3
"""Opt-in local HTTP bridge for the 091-099 Python validation producer.

Run separately: python3 -S tool/python/validation_http.py --port 8765
Bind loopback only; do not expose this development endpoint publicly.

Browsers send Origin on same-origin POSTs, so the bound host and port are
always accepted for both 127.0.0.1 and localhost (including --port and port 0).
Extra origins are an explicit allowlist. The default extra origin is the
Flutter web dev server at http://localhost:8080, where `flutter run -d
web-server --web-port=8080` and the portable Playwright suite serve the app.
That allowance is not a Flutter screen integration. There is no wildcard CORS.
"""
from __future__ import annotations

import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
from html import escape
from urllib.parse import urlsplit
from validation_patterns import run


OPERATIONS = ('required', 'email', 'password', 'phone', 'url', 'date', 'range', 'regex', 'form')
# Flutter web dev server. Kept as the default extra origin, not the only one.
DEFAULT_EXTRA_ORIGINS = ("http://localhost:8080",)


def explicit_origin(value):
    """Return a browser Origin (scheme://host[:port]) or raise ValueError.

    Wildcard and path-bearing values are refused so CORS cannot be opened up.
    """
    if not isinstance(value, str) or "*" in value or any(c.isspace() for c in value):
        raise ValueError(value)
    parts = urlsplit(value)
    if (parts.scheme not in ("http", "https") or not parts.hostname
            or parts.path not in ("",) or parts.query or parts.fragment
            or parts.username or parts.password):
        raise ValueError(value)
    port = f":{parts.port}" if parts.port else ""
    host = parts.hostname
    return f"{parts.scheme}://{host}{port}"


class Handler(BaseHTTPRequestHandler):
    # Socket read timeout: a client that never sends its body is dropped instead
    # of holding a worker forever (http.server closes on TimeoutError).
    timeout = 10

    def _loopback_names(self):
        port = self.server.server_address[1]
        return {f"127.0.0.1:{port}", f"localhost:{port}"}

    def _extra_origins(self):
        configured = getattr(self.server, "allowed_origins", None)
        if configured is None:
            return set(DEFAULT_EXTRA_ORIGINS)
        return set(configured)

    def _own_origins(self):
        return {"http://" + name for name in self._loopback_names()}

    def _allowed_origins(self):
        return self._extra_origins() | self._own_origins()

    def _trusted(self):
        """Reject DNS-rebinding hosts and foreign origins.

        The form is served from this server itself, and browsers send Origin on
        same-origin POSTs too, so this server's own origin must be accepted.
        127.0.0.1 and localhost are the same loopback origin for the bound port.
        """
        if self.headers.get("Host") not in self._loopback_names():
            return False
        origin = self.headers.get("Origin")
        return origin is None or origin in self._allowed_origins()

    def _cors_headers(self):
        origin = self.headers.get("Origin")
        if origin is not None and origin in self._allowed_origins():
            self.send_header("Access-Control-Allow-Origin", origin)
            self.send_header("Vary", "Origin")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")

    def _json(self, status, payload, *, cors=False):
        body = json.dumps(payload, ensure_ascii=False).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        if cors:
            self._cors_headers()
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if not self._trusted():
            self._json(403, {"error": "origin not allowed"})
            return
        if self.path != '/':
            self.send_error(404)
            return
        options = ''.join(f'<option value="{escape(op)}">{escape(op)}</option>' for op in OPERATIONS)
        body = ('''<!doctype html><html lang="ja"><meta charset="utf-8"><title>Validation 091-099</title>
<h1>Validation 091–099 (Python)</h1><p>ローカル検証デモ。セキュリティ上の保証はありません。</p>
<label>検証種別 <select id="op">''' + options + '''</select></label>
<label>入力 <input id="value" autocomplete="off"></label>
<button id="run">検証</button><pre id="result" role="status"></pre>
<script>
const output = document.getElementById('result');
document.getElementById('run').addEventListener('click', async () => {
 const operation = document.getElementById('op').value;
 const value = document.getElementById('value').value;
 let payload = {operation, value};
 if (operation === 'range') payload = {operation, value: Number(value), options:{minimum:0,maximum:100}};
 if (operation === 'regex') payload.options = {pattern:'ascii_identifier'};
 if (operation === 'form') payload = {operation, fields:[{name:'required',rule:'required',value}]};
 try { const response = await fetch('/validate',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(payload)});
   const text = await response.text(); let data;
   try { data = JSON.parse(text); } catch { data = {error: 'non-JSON response'}; }
   output.textContent = JSON.stringify({http_status:response.status,...data},null,2);
 } catch (error) { output.textContent = '通信エラー: '+String(error); }
});
</script></html>''').encode('utf-8')
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        self.wfile.write(body)

    def do_OPTIONS(self):
        if not self._trusted():
            self._json(403, {"error": "origin not allowed"})
            return
        self.send_response(204)
        self._cors_headers()
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", "0")
        self.end_headers()

    def do_POST(self):
        if self.path != "/validate":
            self.send_error(404)
            return
        if not self._trusted():
            self._json(403, {"error": "origin not allowed"})
            return
        try:
            size = int(self.headers.get("Content-Length", "0"))
            if not 0 < size <= 65536:
                raise ValueError("invalid request size")
            payload = json.loads(self.rfile.read(size))
            result = run(payload)
            status, body = 200, result
        except (ValueError, TypeError, UnicodeError, KeyError, RecursionError, OverflowError):
            status, body = 400, {"error": "invalid validation request"}
        self._json(status, body, cors=True)


def build_server(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=8765)
    parser.add_argument(
        "--allow-origin",
        action="append",
        default=None,
        dest="allow_origins",
        metavar="ORIGIN",
        help=(
            "Extra browser origin allowed to call this server, besides its own "
            "loopback origin. Repeat for more than one. When omitted, the Flutter "
            "web dev server at http://localhost:8080 is allowed. Wildcards are refused."
        ),
    )
    args = parser.parse_args(argv)
    if not 0 <= args.port <= 65535:
        parser.error("port must be between 0 and 65535")
    raw_origins = args.allow_origins if args.allow_origins is not None else list(DEFAULT_EXTRA_ORIGINS)
    try:
        origins = [explicit_origin(origin) for origin in raw_origins]
    except ValueError:
        parser.error("allow-origin must be scheme://host[:port] and must not contain *")
    http = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    http.allowed_origins = frozenset(origins)
    return http


def main(argv=None):
    http = build_server(argv)
    print(f"listening http://127.0.0.1:{http.server_address[1]}/", flush=True)
    try:
        http.serve_forever()
    finally:
        http.server_close()


if __name__ == "__main__":
    main()
